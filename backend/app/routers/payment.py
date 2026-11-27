"""Midtrans Snap payment gateway endpoints & webhook for SPPG subscriptions."""
from __future__ import annotations

import base64
import hashlib
import hmac
from typing import Any

import httpx
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.config import get_settings
from app.database.models import Payment
from app.database.session import get_db
from app.dependencies import verify_api_key
from app.routers.transactions import _resolve_plan, invoice_total, sync_payment_status
from app.schemas import MidtransTransactionRequest, MidtransTransactionResponse

router = APIRouter(prefix="/payment", tags=["payment"])

PPN_RATE = 0.11

ENABLED_PAYMENTS_MAP: dict[str, list[str]] = {
    "qris": ["gopay", "shopeepay", "other_qris"],
    "bca_va": ["bca_va"],
    "mandiri_va": ["echannel"],
    "bri_va": ["bri_va"],
    "bni_va": ["bni_va"],
    "credit_card": ["credit_card"],
}


def _map_midtrans_status(transaction_status: str, fraud_status: str = "") -> str:
    status = transaction_status.strip().lower()
    fraud = fraud_status.strip().lower()
    if status == "settlement":
        return "PAID"
    if status == "capture":
        return "PAID" if fraud in ("", "accept") else "PENDING"
    if status == "expire":
        return "EXPIRED"
    if status == "cancel":
        return "CANCELLED"
    if status in ("deny", "failure"):
        return "FAILED"
    if status in ("refund", "partial_refund"):
        return "REFUNDED"
    return "PENDING"


def _verify_midtrans_signature(
    order_id: str,
    status_code: str,
    gross_amount: str,
    signature_key: str,
    server_key: str,
) -> bool:
    raw = f"{order_id}{status_code}{gross_amount}{server_key}".encode("utf-8")
    expected = hashlib.sha512(raw).hexdigest()
    return hmac.compare_digest(expected.lower(), signature_key.strip().lower())


@router.post("/create-transaction", response_model=MidtransTransactionResponse)
async def create_midtrans_transaction(
    payload: MidtransTransactionRequest,
    db: Session = Depends(get_db),
    _api_key: str | None = Depends(verify_api_key),
) -> MidtransTransactionResponse:
    settings = get_settings()
    server_key = settings.midtrans_server_key.strip()
    client_key = settings.midtrans_client_key.strip() or None

    # The amount is derived from the plan catalog, never from the client, so a
    # tampered request cannot buy a subscription at an arbitrary price.
    plan = _resolve_plan(db, payload.plan_id, payload.plan_name, strict=True)
    plan_price = int(plan.price)
    tax_amount = round(plan_price * PPN_RATE)
    gross_amount = invoice_total(plan)

    if not server_key:
        if settings.midtrans_is_production:
            raise HTTPException(
                status_code=503,
                detail="MIDTRANS_SERVER_KEY belum dikonfigurasi pada server produksi.",
            )
        return MidtransTransactionResponse(
            mode="sandbox_simulator",
            order_id=payload.order_id,
            snap_token=None,
            redirect_url=f"https://app.sandbox.midtrans.com/snap/v2/vtweb/{payload.order_id}",
            status="pending",
            client_key=client_key,
        )

    snap_url = (
        "https://app.midtrans.com/snap/v1/transactions"
        if settings.midtrans_is_production
        else "https://app.sandbox.midtrans.com/snap/v1/transactions"
    )
    auth = base64.b64encode(f"{server_key}:".encode("utf-8")).decode("ascii")

    method_key = payload.payment_method.strip().lower()
    enabled_payments = ENABLED_PAYMENTS_MAP.get(method_key)
    first_name = payload.customer_name.strip()
    if not first_name or first_name == "-":
        first_name = "Petugas SPPG"

    body: dict[str, Any] = {
        "transaction_details": {
            "order_id": payload.order_id,
            "gross_amount": gross_amount,
        },
        "item_details": [
            {
                "id": plan.code[:50],
                "price": plan_price,
                "quantity": 1,
                "name": plan.name[:50],
            },
            {
                "id": "ppn_11",
                "price": tax_amount,
                "quantity": 1,
                "name": "PPN 11%",
            },
        ],
        "customer_details": {
            "first_name": first_name[:50],
            "email": payload.customer_email,
        },
        # Snap link expires after 24 hours; the app recreates the order anyway.
        "expiry": {"unit": "hours", "duration": 24},
    }
    if enabled_payments:
        body["enabled_payments"] = enabled_payments
    if method_key == "credit_card":
        body["credit_card"] = {"secure": True}

    async with httpx.AsyncClient(timeout=15.0) as client:
        response = await client.post(
            snap_url,
            headers={
                "Accept": "application/json",
                "Content-Type": "application/json",
                "Authorization": f"Basic {auth}",
            },
            json=body,
        )

    if response.status_code < 200 or response.status_code >= 300:
        raise HTTPException(
            status_code=502,
            detail=f"Midtrans Snap API gagal ({response.status_code}): {response.text}",
        )

    data = response.json()
    return MidtransTransactionResponse(
        mode=(
            "midtrans_production"
            if settings.midtrans_is_production
            else "midtrans_sandbox_api"
        ),
        order_id=payload.order_id,
        snap_token=data.get("token"),
        redirect_url=data.get(
            "redirect_url",
            f"https://app.sandbox.midtrans.com/snap/v2/vtweb/{payload.order_id}",
        ),
        status="pending",
        client_key=client_key,
    )


@router.get("/status/{order_id}")
async def check_midtrans_status(
    order_id: str,
    _api_key: str | None = Depends(verify_api_key),
    db: Session = Depends(get_db),
) -> dict[str, str]:
    settings = get_settings()
    server_key = settings.midtrans_server_key.strip()
    if not server_key:
        if settings.midtrans_is_production:
            raise HTTPException(
                status_code=503,
                detail="MIDTRANS_SERVER_KEY belum dikonfigurasi pada server produksi.",
            )
        payment = db.scalar(select(Payment).where(Payment.order_id == order_id))
        local_status = "settlement" if payment and payment.status == "PAID" else "pending"
        return {
            "order_id": order_id,
            "transaction_status": local_status,
            "mode": "sandbox_simulator",
        }

    core_base = (
        "https://api.midtrans.com/v2"
        if settings.midtrans_is_production
        else "https://api.sandbox.midtrans.com/v2"
    )
    auth = base64.b64encode(f"{server_key}:".encode("utf-8")).decode("ascii")

    async with httpx.AsyncClient(timeout=10.0) as client:
        response = await client.get(
            f"{core_base}/{order_id}/status",
            headers={
                "Accept": "application/json",
                "Authorization": f"Basic {auth}",
            },
        )

    if response.status_code < 200 or response.status_code >= 300:
        raise HTTPException(
            status_code=502,
            detail=f"Midtrans status check gagal ({response.status_code}): {response.text}",
        )

    data = response.json()
    tx_status = str(data.get("transaction_status", "pending"))
    fraud_status = str(data.get("fraud_status", ""))
    mapped_sql = _map_midtrans_status(tx_status, fraud_status)

    payment = db.scalar(select(Payment).where(Payment.order_id == order_id))
    if payment is not None and mapped_sql != payment.status:
        sync_payment_status(
            db,
            payment,
            mapped_sql,
            gateway_transaction_id=data.get("transaction_id"),
            payment_method=data.get("payment_type"),
        )
        db.commit()

    return {
        "order_id": order_id,
        "transaction_status": tx_status,
        "mode": (
            "midtrans_production"
            if settings.midtrans_is_production
            else "midtrans_sandbox_api"
        ),
    }


@router.post("/notification")
async def midtrans_webhook_notification(
    payload: dict[str, Any],
    db: Session = Depends(get_db),
) -> dict[str, str]:
    """Webhook endpoint called directly by Midtrans upon payment state changes."""
    settings = get_settings()
    server_key = settings.midtrans_server_key.strip()
    if not server_key:
        raise HTTPException(
            status_code=503,
            detail="MIDTRANS_SERVER_KEY belum dikonfigurasi pada server.",
        )

    order_id = str(payload.get("order_id", "")).strip()
    status_code = str(payload.get("status_code", "")).strip()
    gross_amount = str(payload.get("gross_amount", "")).strip()
    signature_key = str(payload.get("signature_key", "")).strip()

    if not order_id or not status_code or not gross_amount or not signature_key:
        raise HTTPException(status_code=400, detail="Payload notifikasi Midtrans tidak lengkap.")

    if not _verify_midtrans_signature(
        order_id=order_id,
        status_code=status_code,
        gross_amount=gross_amount,
        signature_key=signature_key,
        server_key=server_key,
    ):
        raise HTTPException(status_code=403, detail="Signature Midtrans tidak valid.")

    payment = db.scalar(select(Payment).where(Payment.order_id == order_id))
    if payment is None:
        raise HTTPException(status_code=404, detail="Transaksi tidak ditemukan.")

    # Reject notifications whose amount differs from the recorded invoice so a
    # forged or mismatched payload can never unlock a subscription.
    try:
        notified_amount = int(round(float(gross_amount)))
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="gross_amount tidak valid.") from exc
    if notified_amount != int(payment.gross_amount):
        raise HTTPException(
            status_code=409,
            detail="Nominal notifikasi tidak sesuai dengan tagihan.",
        )

    payment.gateway_environment = (
        "PRODUCTION" if settings.midtrans_is_production else "SANDBOX"
    )

    tx_status = str(payload.get("transaction_status", "pending"))
    fraud_status = str(payload.get("fraud_status", ""))
    mapped_sql = _map_midtrans_status(tx_status, fraud_status)

    sync_payment_status(
        db,
        payment,
        mapped_sql,
        gateway_transaction_id=payload.get("transaction_id"),
        payment_method=payload.get("payment_type"),
    )
    db.commit()
    return {"status": "ok", "order_id": order_id, "payment_status": mapped_sql}
