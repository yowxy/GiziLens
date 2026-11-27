"""Subscription payments (Midtrans order lifecycle)."""
from __future__ import annotations

import uuid
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from app.api_utils import format_rupiah, iso_or_none, plan_icon
from app.database.models import (
    Organization,
    OrganizationMember,
    Payment,
    Plan,
    QuotaBucket,
    Subscription,
)
from app.database.session import get_db
from app.dependencies import verify_api_key, require_admin
from app.schemas_api import (
    TransactionCreate,
    TransactionListOut,
    TransactionOut,
    TransactionStatusPatch,
)

router = APIRouter(
    prefix="/transactions",
    tags=["transactions"],
)

BILLING_MONTHS = {"MONTHLY": 1, "QUARTERLY": 3, "ANNUAL": 12}
CLIENT_TO_SQL = {
    "pending": "PENDING",
    "settlement": "PAID",
    "paid": "PAID",
    "failed": "FAILED",
    "expired": "EXPIRED",
    "cancelled": "CANCELLED",
    "refunded": "REFUNDED",
}
STATUS_LABELS = {
    "PAID": "Terkonfirmasi",
    "PENDING": "Diproses",
    "FAILED": "Gagal",
    "EXPIRED": "Kedaluwarsa",
    "CANCELLED": "Dibatalkan",
    "REFUNDED": "Dikembalikan",
    "PARTIALLY_REFUNDED": "Dikembalikan Sebagian",
}


def serialize_payment(payment: Payment) -> TransactionOut:
    plan = payment.plan
    org = payment.organization
    return TransactionOut(
        order_id=payment.order_id,
        user=org.name if org else "Pelanggan GiziLens",
        organization=org.name if org else None,
        plan=plan.name if plan else "Paket GiziLens",
        plan_icon=plan_icon(plan.name if plan else None),
        amount=format_rupiah(payment.gross_amount),
        status=STATUS_LABELS.get(payment.status, "Diproses"),
        plan_id=plan.code if plan else None,
        plan_price=payment.gross_amount,
        total_amount=payment.gross_amount,
        payment_status=payment.status.lower(),
        created_at=iso_or_none(payment.created_at),
        va_number=None,
    )


@router.get("", response_model=TransactionListOut, dependencies=[Depends(require_admin)])
def list_transactions(
    search: str | None = Query(default=None),
    status: str | None = Query(default=None),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100, alias="pageSize"),
    db: Session = Depends(get_db),
) -> TransactionListOut:
    filters = []
    if search:
        pattern = f"%{search.strip()}%"
        filters.append(
            or_(
                Payment.order_id.ilike(pattern),
                Plan.name.ilike(pattern),
                Organization.name.ilike(pattern),
            )
        )
    if status:
        filters.append(
            Payment.status == CLIENT_TO_SQL.get(status.strip().lower(), status.strip().upper())
        )

    count_statement = (
        select(func.count())
        .select_from(Payment)
        .join(Plan, Plan.id == Payment.plan_id)
        .join(Organization, Organization.id == Payment.organization_id)
    )
    list_statement = (
        select(Payment)
        .join(Plan, Plan.id == Payment.plan_id)
        .join(Organization, Organization.id == Payment.organization_id)
    )
    for condition in filters:
        count_statement = count_statement.where(condition)
        list_statement = list_statement.where(condition)

    total = int(db.scalar(count_statement) or 0)
    rows = db.scalars(
        list_statement.order_by(Payment.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    ).all()

    return TransactionListOut(
        items=[serialize_payment(row) for row in rows],
        total=total,
        page=page,
        page_size=page_size,
    )


def _resolve_organization(
    db: Session, uid: str | None, name: str | None
) -> Organization:
    if uid:
        member = db.scalar(
            select(OrganizationMember)
            .where(OrganizationMember.firebase_uid == uid)
            .order_by(OrganizationMember.joined_at)
        )
        if member is not None:
            return member.organization

    label = (name or "").strip() or "Organisasi GiziLens"
    org = db.scalar(
        select(Organization).where(
            func.lower(func.btrim(Organization.name)) == label.lower(),
            Organization.type == "SPPG",
        )
    )
    if org is not None:
        return org
    org = Organization(name=label, type="SPPG", status="PENDING")
    db.add(org)
    db.flush()
    return org


def _resolve_plan(db: Session, plan_id: str | None, plan_name: str | None) -> Plan:
    if plan_id:
        plan = db.scalar(select(Plan).where(Plan.code == plan_id))
        if plan is not None:
            return plan
        try:
            plan = db.get(Plan, uuid.UUID(plan_id))
        except (ValueError, AttributeError):
            plan = None
        if plan is not None:
            return plan
    if plan_name:
        plan = db.scalar(select(Plan).where(Plan.name == plan_name))
        if plan is not None:
            return plan
    plan = (
        db.scalar(select(Plan).where(Plan.code == "plan_premium"))
        or db.scalar(select(Plan).where(Plan.is_active.is_(True)).order_by(Plan.price))
        or db.scalar(select(Plan).order_by(Plan.price))
    )
    if plan is not None:
        return plan

    plan = Plan(
        code="plan_premium",
        name="GiziLens Premium",
        description="Akses penuh audit gizi AI, ekspor laporan PDF resmi, dan sinkronisasi SPPG Cloud",
        price=99000,
        billing_cycle="MONTHLY",
        quota_cycle="MONTHLY",
        scan_quota=None,
        max_members=None,
        history_retention_days=365,
        features=[
            "Scan Ompreng AI tanpa batas kuota",
            "Ekspor laporan PDF resmi & XLSX",
            "Multi-demografis AKG",
        ],
        is_active=True,
    )
    db.add(plan)
    db.flush()
    return plan


def sync_payment_status(
    db: Session,
    payment: Payment,
    status_sql: str,
    *,
    gateway_transaction_id: str | None = None,
    payment_method: str | None = None,
) -> Payment:
    """Update a Payment row and activate its Subscription when paid."""
    now = datetime.now(timezone.utc)
    payment.status = status_sql
    payment.updated_at = now
    if gateway_transaction_id:
        payment.gateway_transaction_id = gateway_transaction_id
    if payment_method and not payment.payment_method:
        payment.payment_method = payment_method

    if status_sql == "PAID":
        payment.paid_at = payment.paid_at or now
        if payment.subscription_id is None:
            _activate(db, payment, payment.plan)
    return payment


def _entitlement(plan: Plan) -> dict:
    return {
        "planCode": plan.code,
        "planName": plan.name,
        "price": plan.price,
        "billingCycle": plan.billing_cycle,
        "scanQuota": plan.scan_quota,
        "maxMembers": plan.max_members,
        "historyRetentionDays": plan.history_retention_days,
    }


def _activate(db: Session, payment: Payment, plan: Plan) -> None:
    now = datetime.now(timezone.utc)
    months = BILLING_MONTHS.get(plan.billing_cycle, 1)

    for active in db.scalars(
        select(Subscription).where(
            Subscription.organization_id == payment.organization_id,
            Subscription.status == "ACTIVE",
        )
    ).all():
        active.status = "EXPIRED"
        active.updated_at = now

    subscription = Subscription(
        organization_id=payment.organization_id,
        plan_id=plan.id,
        status="ACTIVE",
        starts_at=now,
        expires_at=now + timedelta(days=30 * months),
        price_snapshot=payment.gross_amount,
        entitlement_snapshot=_entitlement(plan),
    )
    db.add(subscription)
    db.flush()

    db.add(
        QuotaBucket(
            organization_id=payment.organization_id,
            subscription_id=subscription.id,
            quota_type="SUBSCRIPTION",
            scan_limit=plan.scan_quota or 100,
            period_start=now,
            period_end=subscription.expires_at,
        )
    )
    payment.subscription_id = subscription.id
    payment.paid_at = payment.paid_at or now
    payment.updated_at = now


@router.post("", response_model=TransactionOut, status_code=201, dependencies=[Depends(verify_api_key)])
def create_transaction(
    payload: TransactionCreate,
    db: Session = Depends(get_db),
) -> TransactionOut:
    existing = db.scalar(select(Payment).where(Payment.order_id == payload.order_id))
    if existing is not None:
        return serialize_payment(existing)

    plan = _resolve_plan(db, payload.plan_id, payload.plan_name)
    org = _resolve_organization(db, payload.user_uid, payload.sppg_unit)
    gross = plan.price
    status_sql = "PENDING"
    
    payment = Payment(
        organization_id=org.id,
        plan_id=plan.id,
        payer_firebase_uid=payload.user_uid or "anonymous",
        order_id=payload.order_id,
        gross_amount=max(gross, 1),
        currency="IDR",
        entitlement_snapshot=_entitlement(plan),
        payment_method=(payload.selected_method or {}).get("label")
        or (payload.selected_method or {}).get("method"),
        status=status_sql,
        paid_at=datetime.now(timezone.utc) if status_sql == "PAID" else None,
    )
    db.add(payment)
    db.flush()

    if status_sql == "PAID":
        _activate(db, payment, plan)

    db.commit()
    db.refresh(payment)
    return serialize_payment(payment)


@router.patch("/{order_id}/status", response_model=TransactionOut, dependencies=[Depends(require_admin)])
def update_transaction_status(
    order_id: str,
    payload: TransactionStatusPatch,
    db: Session = Depends(get_db),
) -> TransactionOut:
    payment = db.scalar(select(Payment).where(Payment.order_id == order_id))
    if payment is None:
        raise HTTPException(status_code=404, detail="Transaksi tidak ditemukan.")

    status_sql = CLIENT_TO_SQL.get(payload.status, "PENDING")
    sync_payment_status(db, payment, status_sql)

    db.commit()
    db.refresh(payment)
    return serialize_payment(payment)
