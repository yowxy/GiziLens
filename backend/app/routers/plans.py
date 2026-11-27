"""Subscription plan catalog."""
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
BILLING_LABELS = {"MONTHLY": "Bulanan", "QUARTERLY": "Triwulanan", "ANNUAL": "Tahunan"}


@router.get("", response_model=PlanListOut)
def list_plans(db: Session = Depends(get_db)) -> PlanListOut:
    rows = db.scalars(select(Plan).order_by(Plan.price)).all()

    items = []
    for row in rows:
        months = BILLING_MONTHS.get(row.billing_cycle, 1)
        popular = row.code == "plan_pro"
        items.append(
            PlanOut(
                id=row.code,
                name=row.name,
                tagline=row.description,
                monthly_equivalent_price=round(row.price / months),
                billed_price=row.price,
                original_price=None,
                billing_period=BILLING_LABELS.get(row.billing_cycle, row.billing_cycle),
                is_popular=popular,
                badge_text="Paling Populer" if popular else None,
                bundle_highlights=[],
                features=row.features or [],
                cta_label="Pilih Paket Ini",
            )
        )
    return PlanListOut(items=items)
