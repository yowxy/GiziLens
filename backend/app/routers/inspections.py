"""Inspection (ompreng audit) endpoints used by Flutter and the admin dashboard.

The client performs detection and sends the audited result. The backend stores
it as an immutable scan snapshot (``scans`` + ``scan_images``) plus the final
locked inspection (``inspections`` + ``inspection_items``).
"""
from __future__ import annotations

import base64
import binascii
import hashlib
import io
import re
import time
from datetime import date, datetime, timezone
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException, Query
from PIL import Image, ImageOps
from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session, selectinload

from app.api_utils import iso_or_none, parse_datetime
from app.config import BASE_DIR
from app.database.models import (
    AkgTarget,
    Batch,
    Inspection,
    InspectionItem,
    Organization,
    OrganizationMember,
    Scan,
    ScanImage,
)
from app.database.session import get_db
from app.dependencies import verify_api_key
from app.schemas_api import (
    BoundingBoxIn,
    ComponentIn,
    ComponentOut,
    InspectionCreate,
    InspectionCreateOut,
    InspectionDetailListOut,
    InspectionDetailOut,
    InspectionListOut,
    InspectionSummaryOut,
    NutritionIn,
)

router = APIRouter(
    prefix="/inspections",
    tags=["inspections"],
    dependencies=[Depends(verify_api_key)],
)

METRIC_NAMES = ["Kalori", "Protein", "Lemak", "Karbohidrat", "Serat"]
METRIC_KEYS = ["calories", "protein", "fat", "carbohydrate", "fiber"]
METRIC_UNITS = ["kkal", "g", "g", "g", "g"]

# SQL enum -> label used by the Flutter widgets
SQL_TO_API_STATUS = {
    "SESUAI": "SESUAI",
    "TIDAK_SESUAI": "TIDAK SESUAI",
    "NOT_ASSESSED": "BELUM DINILAI",
}
API_TO_SQL_STATUS = {
    "SESUAI": "SESUAI",
    "TIDAK SESUAI": "TIDAK_SESUAI",
    "BELUM DINILAI": "NOT_ASSESSED",
}

MEDIA_ROOT = BASE_DIR / "storage"
INSPECTION_IMAGE_DIR = MEDIA_ROOT / "inspections"
POLICY_VERSION = "APP_POLICY_V1"


def save_scan_image(scan_id: str, encoded: str | None) -> dict | None:
    """Decode a base64 photo, normalize it to JPEG and store it on disk."""
    if not encoded:
        return None

    payload = encoded.split(",", 1)[-1] if encoded.startswith("data:") else encoded
    try:
        raw = base64.b64decode(payload, validate=True)
    except (binascii.Error, ValueError):
        return None

    if not raw or len(raw) > 12 * 1024 * 1024:
        return None

    try:
        with Image.open(io.BytesIO(raw)) as image:
            # Camera JPEGs carry the real orientation in EXIF while the pixels
            # stay in sensor order. Dropping EXIF without rotating the pixels
            # makes the stored photo appear sideways later, so bake the
            # orientation in before saving.
            oriented = ImageOps.exif_transpose(image) or image
            converted = oriented.convert("RGB")
            width, height = converted.size
            INSPECTION_IMAGE_DIR.mkdir(parents=True, exist_ok=True)
            safe_id = re.sub(r"[^A-Za-z0-9._-]", "_", scan_id)
            filename = f"{safe_id}.jpg"
            converted.save(INSPECTION_IMAGE_DIR / filename, format="JPEG", quality=86)
    except Exception:
        return None

    stored = INSPECTION_IMAGE_DIR / filename
    return {
        "object_key": f"inspections/{filename}",
        "width": width,
        "height": height,
        "size_bytes": stored.stat().st_size,
        "sha256": hashlib.sha256(stored.read_bytes()).hexdigest(),
    }


def original_image(scan: Scan | None) -> ScanImage | None:
    if scan is None:
        return None
    for image in scan.images:
        if image.image_type == "ORIGINAL" and image.deleted_at is None:
            return image
    return None


def image_url_for(scan: Scan | None) -> str | None:
    image = original_image(scan)
    return f"/media/{image.object_key}" if image else None


def build_nutrition(inspection: Inspection, target: dict | None) -> dict[str, dict]:
    """Recreate the metric map the Flutter history detail screen reads."""
    snapshot = target or {}
    current_values = {
        "calories": inspection.total_calories,
        "protein": inspection.total_protein,
        "fat": inspection.total_fat,
        "carbohydrate": inspection.total_carbohydrate,
        "fiber": inspection.total_fiber,
    }
    nutrition: dict[str, dict] = {}
    for index, key in enumerate(METRIC_KEYS):
        current = float(current_values[key] or 0)
        target_value = float(snapshot.get(key, 0) or 0)
        percentage = round(current / target_value * 100) if target_value else 0
        nutrition[METRIC_NAMES[index]] = {
            "currentValue": round(current, 2),
            "targetValue": target_value,
            "unit": METRIC_UNITS[index],
            "percentageOfTarget": percentage,
        }
    return nutrition


def serialize_summary(inspection: Inspection) -> InspectionSummaryOut:
    scan = inspection.scan
    batch = scan.batch if scan else None
    school = batch.school if batch else None
    image = original_image(scan)
    return InspectionSummaryOut(
        id=str(inspection.id),
        batch_code=batch.batch_code if batch else "-",
        school_name=school.name if school else None,
        session=None,
        compliance_status=SQL_TO_API_STATUS.get(
            inspection.compliance_status, inspection.compliance_status
        ),
        total_net_weight=f"{float(inspection.total_weight):g} gram",
        scanned_at=iso_or_none(scan.created_at if scan else inspection.created_at),
        target_group=scan.akg_target.group_name if scan and scan.akg_target else None,
        officer_name=None,
        unit_operational=scan.organization.name if scan and scan.organization else None,
        created_at=iso_or_none(inspection.created_at),
        image_url=image_url_for(scan),
        image_width=image.width if image else None,
        image_height=image.height if image else None,
    )


def serialize_detail(inspection: Inspection) -> InspectionDetailOut:
    summary = serialize_summary(inspection)
    scan = inspection.scan
    target = (scan.target_snapshot if scan else None) or {}
    return InspectionDetailOut(
        **summary.model_dump(),
        user_uid=scan.firebase_uid if scan else None,
        user_email=None,
        officer_id=None,
        verifier_role=None,
        detection_provider=None,
        detection_model=scan.ai_model if scan else None,
        is_locked=True,
        notes=inspection.notes,
        target_akg2019=target,
        nutrition=build_nutrition(inspection, target),
        components=[
            ComponentOut(
                id=str(item.id),
                name=item.name,
                gram=float(item.estimated_gram),
                compartment_number=item.compartment_number or 0,
                category=item.category,
                confidence_percentage=round(float(item.confidence or 0) * 100, 2),
                is_verified=item.is_verified,
                nutrition=NutritionIn(
                    calories=float(item.calories),
                    protein=float(item.protein),
                    fat=float(item.fat),
                    carbohydrate=float(item.carbohydrate),
                    fiber=float(item.fiber),
                ),
                bbox=(
                    BoundingBoxIn(**item.bounding_box)
                    if item.bounding_box
                    else None
                ),
            )
            for item in inspection.items
        ],
    )


def _filters(
    user_id: str | None,
    status: str | None,
    search: str | None,
    since: str | None,
) -> list:
    filters = []
    if user_id:
        filters.append(Scan.firebase_uid == user_id)
    if status:
        filters.append(
            Inspection.compliance_status == API_TO_SQL_STATUS.get(
                status.strip().upper(), status.strip().upper()
            )
        )
    if since:
        since_dt = parse_datetime(since)
        if since_dt is not None:
            filters.append(Inspection.created_at >= since_dt)
    if search:
        pattern = f"%{search.strip()}%"
        filters.append(
            or_(
                Batch.batch_code.ilike(pattern),
                Organization.name.ilike(pattern),
            )
        )
    return filters


def _base_statement():
    return (
        select(Inspection)
        .join(Scan, Scan.id == Inspection.scan_id)
        .join(Batch, Batch.id == Scan.batch_id)
        .outerjoin(Organization, Organization.id == Batch.school_id)
        .options(
            selectinload(Inspection.items),
            selectinload(Inspection.scan).selectinload(Scan.images),
            selectinload(Inspection.scan).selectinload(Scan.batch).selectinload(Batch.school),
            selectinload(Inspection.scan).selectinload(Scan.akg_target),
            selectinload(Inspection.scan).selectinload(Scan.organization),
        )
    )


@router.get("", response_model=InspectionListOut)
def list_inspections(
    user_id: str | None = Query(default=None, alias="userId"),
    status: str | None = Query(default=None),
    search: str | None = Query(default=None),
    since: str | None = Query(default=None),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100, alias="pageSize"),
    db: Session = Depends(get_db),
) -> InspectionListOut:
    filters = _filters(user_id, status, search, since)

    count_statement = (
        select(func.count())
        .select_from(Inspection)
        .join(Scan, Scan.id == Inspection.scan_id)
        .join(Batch, Batch.id == Scan.batch_id)
        .outerjoin(Organization, Organization.id == Batch.school_id)
    )
    list_statement = _base_statement()
    for condition in filters:
        count_statement = count_statement.where(condition)
        list_statement = list_statement.where(condition)

    total = int(db.scalar(count_statement) or 0)
    rows = db.scalars(
        list_statement.order_by(Inspection.locked_at.desc(), Inspection.id.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    ).all()

    return InspectionListOut(
        items=[serialize_summary(row) for row in rows],
        total=total,
        page=page,
        page_size=page_size,
    )


@router.get("/full", response_model=InspectionDetailListOut)
def list_inspections_full(
    user_id: str | None = Query(default=None, alias="userId"),
    status: str | None = Query(default=None),
    search: str | None = Query(default=None),
    since: str | None = Query(default=None),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100, alias="pageSize"),
    db: Session = Depends(get_db),
) -> InspectionDetailListOut:
    """Full inspection records (components + nutrition) for the Flutter client."""
    filters = _filters(user_id, status, search, since)

    count_statement = (
        select(func.count())
        .select_from(Inspection)
        .join(Scan, Scan.id == Inspection.scan_id)
        .join(Batch, Batch.id == Scan.batch_id)
        .outerjoin(Organization, Organization.id == Batch.school_id)
    )
    list_statement = _base_statement()
    for condition in filters:
        count_statement = count_statement.where(condition)
        list_statement = list_statement.where(condition)

    total = int(db.scalar(count_statement) or 0)
    rows = db.scalars(
        list_statement.order_by(Inspection.locked_at.desc(), Inspection.id.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    ).all()

    return InspectionDetailListOut(
        items=[serialize_detail(row) for row in rows],
        total=total,
        page=page,
        page_size=page_size,
    )


@router.get("/{inspection_id}", response_model=InspectionDetailOut)
def get_inspection(inspection_id: str, db: Session = Depends(get_db)) -> InspectionDetailOut:
    inspection = db.scalar(_base_statement().where(Inspection.id == inspection_id))
    if inspection is None:
        raise HTTPException(status_code=404, detail="Inspeksi tidak ditemukan.")
    return serialize_detail(inspection)


# ---------------------------------------------------------------------------
# Write path
# ---------------------------------------------------------------------------


def _get_or_create_org(db: Session, name: str | None, org_type: str) -> Organization:
    label = (name or "").strip()
    if not label:
        label = "SPPG Mitra GiziLens" if org_type == "SPPG" else "Sekolah Mitra"
    existing = db.scalar(
        select(Organization).where(
            func.lower(func.btrim(Organization.name)) == label.lower(),
            Organization.type == org_type,
        )
    )
    if existing is not None:
        return existing
    org = Organization(name=label, type=org_type, status="PENDING")
    db.add(org)
    db.flush()
    return org


def _get_or_create_member(db: Session, org: Organization, uid: str) -> OrganizationMember:
    member = db.scalar(
        select(OrganizationMember).where(
            OrganizationMember.organization_id == org.id,
            OrganizationMember.firebase_uid == uid,
        )
    )
    if member is not None:
        return member
    member = OrganizationMember(
        organization_id=org.id,
        firebase_uid=uid,
        membership_role="OFFICER",
        status="ACTIVE",
    )
    db.add(member)
    db.flush()
    return member


def _get_or_create_batch(
    db: Session,
    sppg: Organization,
    school: Organization | None,
    batch_code: str,
    production_date: date,
    uid: str,
) -> Batch:
    batch = db.scalar(
        select(Batch).where(Batch.sppg_id == sppg.id, Batch.batch_code == batch_code)
    )
    if batch is not None:
        if school is not None and batch.school_id is None:
            batch.school_id = school.id
        return batch
    batch = Batch(
        sppg_id=sppg.id,
        school_id=school.id if school else None,
        batch_code=batch_code,
        production_date=production_date,
        created_by_uid=uid,
    )
    db.add(batch)
    db.flush()
    return batch


def _get_or_create_akg(db: Session, payload: InspectionCreate) -> AkgTarget:
    group_name = (payload.target_group or "").strip()
    if group_name:
        target = db.scalar(
            select(AkgTarget)
            .where(AkgTarget.group_name == group_name)
            .order_by(AkgTarget.is_active.desc(), AkgTarget.created_at)
        )
        if target is not None:
            return target

    snapshot = payload.target_akg2019 or {}

    def value(key: str) -> float:
        raw = float(snapshot.get(key, 0) or 0)
        return raw if raw > 0 else 1.0

    label = group_name or "Kelompok AKG Aplikasi"
    code = re.sub(r"[^A-Z0-9]+", "_", label.upper()).strip("_") or "DEFAULT"
    target = AkgTarget(
        group_code=code[:50],
        group_name=label[:150],
        standard_version="APP_SNAPSHOT",
        calories=value("calories"),
        protein=value("protein"),
        fat=value("fat"),
        carbohydrate=value("carbohydrate"),
        fiber=value("fiber"),
        is_active=False,
    )
    db.add(target)
    db.flush()
    return target


@router.post("", response_model=InspectionCreateOut, status_code=201)
def create_inspection(
    payload: InspectionCreate,
    db: Session = Depends(get_db),
) -> InspectionCreateOut:
    client_id = payload.id or f"insp-{int(time.time() * 1000)}"

    existing = db.scalar(
        select(Scan).where(Scan.legacy_firestore_id == client_id)
    )
    if existing is not None:
        inspection = db.scalar(select(Inspection).where(Inspection.scan_id == existing.id))
        return InspectionCreateOut(
            id=str(inspection.id) if inspection else client_id, created=False
        )

    scanned_at = parse_datetime(payload.scanned_at) or datetime.now(timezone.utc)
    uid = payload.user_uid or "anonymous"
    batch_code = (payload.batch_code or "").strip() or f"BATCH-{scanned_at:%Y%m%d}"
    sppg = _get_or_create_org(db, payload.unit_operational, "SPPG")
    school = _get_or_create_org(db, payload.school_name, "SCHOOL") if payload.school_name else None
    _get_or_create_member(db, sppg, uid)
    batch = _get_or_create_batch(
        db, sppg, school, batch_code, scanned_at.date(), uid
    )
    akg = _get_or_create_akg(db, payload)
    target_snapshot = payload.target_akg2019 or {}

    components = payload.components
    totals = {
        key: sum(float(getattr(component.nutrition, key)) for component in components)
        for key in METRIC_KEYS
    }
    total_weight = sum(float(component.gram) for component in components)
    if payload.total_net_weight:
        digits = re.findall(r"\d+(?:[.,]\d+)?", payload.total_net_weight)
        if digits:
            total_weight = float(digits[0].replace(",", "."))

    scan = Scan(
        organization_id=sppg.id,
        firebase_uid=uid,
        batch_id=batch.id,
        akg_target_id=akg.id,
        quota_bucket_id=None,
        idempotency_key=client_id[:100],
        origin="LEGACY_FIRESTORE",
        legacy_firestore_id=client_id,
        status="SUCCESS",
        quota_status="NOT_APPLICABLE",
        ai_model=payload.detection_model,
        raw_result={
            "components": [
                {
                    "name": component.name,
                    "gram": component.gram,
                    "nutrition": component.nutrition.model_dump(),
                    "bbox": component.bbox.model_dump() if component.bbox else None,
                }
                for component in components
            ],
            "nutrition": payload.nutrition or {},
        },
        target_snapshot=target_snapshot,
        created_at=scanned_at,
        completed_at=scanned_at,
    )
    db.add(scan)
    db.flush()

    stored_image = save_scan_image(str(scan.id), payload.image_base64)
    if stored_image:
        db.add(
            ScanImage(
                scan_id=scan.id,
                storage_backend="LOCAL",
                bucket="gizilens-local",
                object_key=stored_image["object_key"],
                image_type="ORIGINAL",
                mime_type="image/jpeg",
                size_bytes=stored_image["size_bytes"],
                width=stored_image["width"],
                height=stored_image["height"],
                sha256=stored_image["sha256"],
                created_at=scanned_at,
            )
        )

    status_sql = API_TO_SQL_STATUS.get(
        (payload.compliance_status or "").strip().upper(), "NOT_ASSESSED"
    )
    inspection = Inspection(
        scan_id=scan.id,
        verified_by_uid=uid,
        verifier_snapshot={
            "officerName": payload.officer_name,
            "officerId": payload.officer_id,
            "verifierRole": payload.verifier_role,
        },
        total_weight=round(total_weight, 2),
        total_calories=round(totals["calories"], 4),
        total_protein=round(totals["protein"], 4),
        total_fat=round(totals["fat"], 4),
        total_carbohydrate=round(totals["carbohydrate"], 4),
        total_fiber=round(totals["fiber"], 4),
        compliance_status=status_sql,
        policy_version=POLICY_VERSION,
        notes=payload.notes,
        locked_at=scanned_at,
        created_at=scanned_at,
    )
    db.add(inspection)
    db.flush()

    for component in components:
        db.add(
            InspectionItem(
                inspection_id=inspection.id,
                name=component.name,
                category=(component.category or "Lainnya")[:50],
                compartment_number=component.compartment_number or None,
                estimated_gram=round(max(float(component.gram), 0.01), 2),
                confidence=round(min(max(float(component.confidence_percentage) / 100, 0), 1), 4),
                calories=round(float(component.nutrition.calories), 4),
                protein=round(float(component.nutrition.protein), 4),
                fat=round(float(component.nutrition.fat), 4),
                carbohydrate=round(float(component.nutrition.carbohydrate), 4),
                fiber=round(float(component.nutrition.fiber), 4),
                bounding_box=component.bbox.model_dump() if component.bbox else None,
                is_verified=component.is_verified,
                created_at=scanned_at,
            )
        )

    db.commit()
    return InspectionCreateOut(id=str(inspection.id), created=True)
