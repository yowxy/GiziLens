"""Subscription plan catalog (single GiziLens Premium plan)."""
from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database.models import Plan
from app.database.session import get_db
from app.dependencies import verify_api_key
from app.schemas_api import PlanListOut, PlanOut

router = APIRouter(
    prefix="/plans",
    tags=["plans"],
    dependencies=[Depends(verify_api_key)],
)

BILLING_MONTHS = {"MONTHLY": 1, "QUARTERLY": 3, "ANNUAL": 12}
BILLING_LABELS = {"MONTHLY": "per bulan", "QUARTERLY": "per 3 bulan", "ANNUAL": "per tahun"}

DEFAULT_PREMIUM_PLAN = PlanOut(
    id="plan_premium",
    name="GiziLens Premium",
    tagline="Akses penuh audit gizi AI, ekspor laporan PDF resmi, dan sinkronisasi SPPG Cloud",
    monthly_equivalent_price=99000,
    billed_price=99000,
    original_price=149000,
    billing_period="per bulan",
    is_popular=True,
    badge_text="PAKET PREMIUM RESMI",
    bundle_highlights=["Unlimited Scan AI", "Ekspor PDF & XLSX", "Prioritas BGN"],
    features=[
        "Scan Ompreng AI tanpa batas kuota harian/bulanan",
        "Ekspor laporan resmi PDF (Watermark + SHA-256) & Excel (XLSX)",
        "Multi-demografis sasaran AKG (SD 1-3, SD 4-6, SMP, SMA)",
        "Notifikasi otomatis & peringatan defisit porsi >15%",
        "Sinkronisasi cloud terenkripsi & riwayat audit tanpa batas",
        "Dukungan teknis prioritas tim BGN & SPPG",
    ],
    cta_label="Aktifkan GiziLens Premium",
)


@router.get("", response_model=PlanListOut)
def list_plans(db: Session = Depends(get_db)) -> PlanListOut:
    row = (
        db.scalar(select(Plan).where(Plan.code == "plan_premium", Plan.is_active.is_(True)))
        or db.scalar(select(Plan).where(Plan.is_active.is_(True)).order_by(Plan.price))
        or db.scalar(select(Plan).where(Plan.code == "plan_premium"))
    )

    if row is None:
        return PlanListOut(items=[DEFAULT_PREMIUM_PLAN])

    months = BILLING_MONTHS.get(row.billing_cycle, 1)
    return PlanListOut(
        items=[
            PlanOut(
                id=row.code,
                name=row.name,
                tagline=row.description or DEFAULT_PREMIUM_PLAN.tagline,
                monthly_equivalent_price=round(row.price / months),
                billed_price=row.price,
                original_price=149000 if row.price < 149000 else None,
                billing_period=BILLING_LABELS.get(row.billing_cycle, row.billing_cycle),
                is_popular=True,
                badge_text="PAKET PREMIUM RESMI",
                bundle_highlights=DEFAULT_PREMIUM_PLAN.bundle_highlights,
                features=row.features or DEFAULT_PREMIUM_PLAN.features,
                cta_label="Aktifkan GiziLens Premium",
            )
        ]
    )
