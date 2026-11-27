"""Organization member endpoints.

Firebase owns authentication and profile data. This API exposes the operational
membership rows (``organization_members`` joined to ``organizations``) so the
admin dashboard can verify, suspend and inspect who operates which SPPG.
"""
from __future__ import annotations

import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from app.api_utils import created_at_label, user_status_label
from app.database.models import (
    Organization,
    OrganizationMember,
    Plan,
    Subscription,
)
from app.database.session import get_db
from app.dependencies import require_admin, verify_api_key, verify_api_key_or_admin
from app.schemas_api import UserListOut, UserOut, UserStatusPatch, UserUpsert

router = APIRouter(
    prefix="/users",
    tags=["users"],
)

MEMBERSHIP_ROLES = ("OWNER", "MANAGER", "NUTRITIONIST", "OFFICER", "SCHOOL_PIC", "VIEWER")

# membership_role -> the role union type used by the React dashboard
ROLE_LABELS = {
    "OWNER": "Petugas SPPG",
    "MANAGER": "Petugas SPPG",
    "NUTRITIONIST": "Ahli Gizi",
    "OFFICER": "Petugas SPPG",
    "SCHOOL_PIC": "PIC Sekolah",
    "VIEWER": "Petugas SPPG",
}
ROLE_TO_MEMBERSHIP = {
    "ahli gizi": "NUTRITIONIST",
    "petugas sppg": "OFFICER",
    "pic sekolah": "SCHOOL_PIC",
    "supir distribusi": "OFFICER",
    "admin": "OWNER",
    "bgn national admin": "OWNER",
}


def _membership_role(raw: str | None) -> str:
    key = (raw or "").strip().lower()
    if key in ROLE_TO_MEMBERSHIP:
        return ROLE_TO_MEMBERSHIP[key]
    upper = (raw or "").strip().upper()
    return upper if upper in MEMBERSHIP_ROLES else "OFFICER"


def active_plans(db: Session) -> dict[uuid.UUID, str]:
    """organization_id -> plan code for organizations with an active subscription."""
    rows = db.execute(
        select(Subscription.organization_id, Plan.code)
        .join(Plan, Plan.id == Subscription.plan_id)
        .where(Subscription.status == "ACTIVE")
    ).all()
    return {row[0]: row[1] for row in rows}


def serialize_member(member: OrganizationMember, plans: dict[uuid.UUID, str]) -> UserOut:
    org = member.organization
    region = ", ".join(part for part in (org.province, org.city) if part) or None
    plan_code = plans.get(org.id)
    return UserOut(
        uid=member.firebase_uid,
        name=org.name,
        full_name=org.name,
        email=member.firebase_uid,
        phone=None,
        role=ROLE_LABELS.get(member.membership_role, "Petugas SPPG"),
        institution=org.name,
        status=user_status_label(member.status == "ACTIVE"),
        created_at_label=created_at_label(member.joined_at),
        created_at_ms=int(member.joined_at.timestamp() * 1000) if member.joined_at else None,
        unit=org.name,
        region=region,
        officer_id=None,
        is_verified=member.status == "ACTIVE",
        subscription_plan=plan_code or "GiziLens Free",
        is_premium=plan_code is not None,
        notifications_enabled=True,
    )


@router.get("", response_model=UserListOut, dependencies=[Depends(require_admin)])
def list_users(
    search: str | None = Query(default=None),
    status: str | None = Query(default=None),
    role: str | None = Query(default=None),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=10, ge=1, le=100, alias="pageSize"),
    db: Session = Depends(get_db),
) -> UserListOut:
    filters = []
    if search:
        pattern = f"%{search.strip()}%"
        filters.append(
            or_(
                Organization.name.ilike(pattern),
                OrganizationMember.firebase_uid.ilike(pattern),
                Organization.registration_code.ilike(pattern),
            )
        )
    if status:
        wanted = "ACTIVE" if status.strip().lower() in {"verified", "active"} else None
        filters.append(
            OrganizationMember.status == wanted
            if wanted
            else OrganizationMember.status != "ACTIVE"
        )
    if role:
        filters.append(
            OrganizationMember.membership_role == _membership_role(role)
        )

    base = select(OrganizationMember).join(
        Organization, Organization.id == OrganizationMember.organization_id
    )
    count_statement = select(func.count()).select_from(OrganizationMember).join(
        Organization, Organization.id == OrganizationMember.organization_id
    )
    for condition in filters:
        base = base.where(condition)
        count_statement = count_statement.where(condition)

    total = int(db.scalar(count_statement) or 0)
    rows = db.scalars(
        base.order_by(OrganizationMember.joined_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    ).all()

    plans = active_plans(db)
    return UserListOut(
        items=[serialize_member(row, plans) for row in rows],
        total=total,
        page=page,
        page_size=page_size,
    )


@router.get("/{uid}", response_model=UserOut, dependencies=[Depends(verify_api_key_or_admin)])
def get_user(uid: str, db: Session = Depends(get_db)) -> UserOut:
    member = db.scalar(
        select(OrganizationMember)
        .where(OrganizationMember.firebase_uid == uid)
        .order_by(OrganizationMember.joined_at)
    )
    if member is None:
        raise HTTPException(status_code=404, detail="Anggota organisasi tidak ditemukan.")
    return serialize_member(member, active_plans(db))


def _find_or_create_organization(
    db: Session,
    name: str,
    uid: str,
    region: str | None = None,
) -> Organization:
    clean_region = (region or "").strip() or None
    existing = db.scalar(
        select(Organization).where(
            func.lower(func.btrim(Organization.name)) == name.strip().lower(),
            Organization.type == "SPPG",
        )
    )
    if existing is not None:
        if clean_region:
            existing.province = clean_region
            existing.updated_at = datetime.now(timezone.utc)
        return existing

    org = Organization(
        name=name.strip(),
        type="SPPG",
        province=clean_region,
        registration_code=f"SPPG-{uid[:8].upper()}",
        status="VERIFIED",
    )
    db.add(org)
    db.flush()
    return org


@router.post("", response_model=UserOut, status_code=201, dependencies=[Depends(verify_api_key)])
def upsert_user(payload: UserUpsert, db: Session = Depends(get_db)) -> UserOut:
    uid = payload.uid
    member = db.scalar(
        select(OrganizationMember)
        .where(OrganizationMember.firebase_uid == uid)
        .order_by(OrganizationMember.joined_at)
    )

    org_name = payload.institution or payload.unit or payload.full_name or payload.name
    if not org_name:
        raise HTTPException(status_code=422, detail="Field institution wajib diisi.")

    if member is None:
        org = _find_or_create_organization(db, org_name, uid, region=payload.region)
        member = OrganizationMember(
            organization_id=org.id,
            firebase_uid=uid,
            membership_role=_membership_role(payload.role),
            status="ACTIVE",
        )
        db.add(member)
    else:
        if payload.role:
            member.membership_role = _membership_role(payload.role)
        if payload.institution or payload.unit:
            org = _find_or_create_organization(db, org_name, uid, region=payload.region)
            member.organization_id = org.id
        elif payload.region and member.organization is not None:
            member.organization.province = payload.region.strip()
            member.organization.updated_at = datetime.now(timezone.utc)
        member.updated_at = datetime.now(timezone.utc)

    db.commit()
    db.refresh(member)
    return serialize_member(member, active_plans(db))


@router.patch("/{uid}/status", response_model=UserOut, dependencies=[Depends(require_admin)])
def update_user_status(
    uid: str,
    payload: UserStatusPatch,
    db: Session = Depends(get_db),
) -> UserOut:
    member = db.scalar(
        select(OrganizationMember)
        .where(OrganizationMember.firebase_uid == uid)
        .order_by(OrganizationMember.joined_at)
    )
    if member is None:
        raise HTTPException(status_code=404, detail="Anggota organisasi tidak ditemukan.")

    member.status = "ACTIVE" if payload.status == "Verified" else "SUSPENDED"
    member.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(member)
    return serialize_member(member, active_plans(db))
