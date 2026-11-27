"""Midtrans Sandbox Snap payment endpoints for SPPG subscriptions."""
from __future__ import annotations

import base64

import httpx
from fastapi import APIRouter, Depends, HTTPException

from app.config import get_settings
from app.dependencies import verify_api_key
from app.schemas import MidtransTransactionRequest, MidtransTransactionResponse

router = APIRouter(prefix="/payment", tags=["payment"])


@router.post("/create-transaction", response_model=MidtransTransactionResponse)
async def create_midtrans_transaction(
    payload: MidtransTransactionRequest,
    _api_key: str | None = Depends(verify_api_key),
) -> MidtransTransactionResponse:
    settings = get_settings()
    if not settings.midtrans_server_key:
        # Simulator fallback so local demos work without Midtrans credentials
        return MidtransTransactionResponse(
            mode="sandbox_simulator",
            order_id=payload.order_id,
            snap_token=None,
            redirect_url=f"https://app.sandbox.midtrans.com/snap/v2/vtweb/{payload.order_id}",
            status="pending",
        )

    snap_url = (
        "https://app.midtrans.com/snap/v1/transactions"
        if settings.midtrans_is_production
        else "https://app.sandbox.midtrans.com/snap/v1/transactions"
    )
    auth = base64.b64encode(f"{settings.midtrans_server_key}:".encode("utf-8")).decode(
        "ascii"
    )

    body = {
        "transaction_details": {
            "order_id": payload.order_id,
            "gross_amount": payload.gross_amount,
        },
        "item_details": [
            {
                "id": payload.plan_id,
                "price": payload.gross_amount,
                "quantity": 1,
                "name": payload.plan_name[:50],
            }
        ],
        "customer_details": {
            "first_name": payload.customer_name,
            "email": payload.customer_email,
        },
    }

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
        mode="midtrans_sandbox_api" if not settings.midtrans_is_production else "midtrans_production",
        order_id=payload.order_id,
        snap_token=data.get("token"),
        redirect_url=data.get(
            "redirect_url",
            f"https://app.sandbox.midtrans.com/snap/v2/vtweb/{payload.order_id}",
        ),
        status="pending",
    )


@router.get("/status/{order_id}")
async def check_midtrans_status(
    order_id: str,
    _api_key: str | None = Depends(verify_api_key),
) -> dict[str, str]:
    settings = get_settings()
    if not settings.midtrans_server_key:
        return {"order_id": order_id, "transaction_status": "pending", "mode": "sandbox_simulator"}

    core_base = (
        "https://api.midtrans.com/v2"
        if settings.midtrans_is_production
        else "https://api.sandbox.midtrans.com/v2"
    )
    auth = base64.b64encode(f"{settings.midtrans_server_key}:".encode("utf-8")).decode(
        "ascii"
    )

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
    return {
        "order_id": order_id,
        "transaction_status": str(data.get("transaction_status", "pending")),
        "mode": "midtrans_sandbox_api" if not settings.midtrans_is_production else "midtrans_production",
    }
