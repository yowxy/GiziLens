from datetime import datetime, timedelta, timezone
from uuid import UUID, uuid4

from fastapi import HTTPException
from sqlalchemy import select, text
from sqlalchemy.orm import Session

from app.database.models import (
    OrganizationMember,
    Subscription,
)

FREE_LIMIT = 10
PREMIUM_LIMIT = 500
WIB = timezone(timedelta(hours=7))


def month_bounds(now: datetime):
    local = now.astimezone(WIB)

    start = datetime(
        local.year,
        local.month,
        1,
        tzinfo=WIB,
    )

    end = datetime(
        local.year + (local.month == 12),
        local.month % 12 + 1,
        1,
        tzinfo=WIB,
    )

    return (
        start.astimezone(timezone.utc),
        end.astimezone(timezone.utc),
    )


def _uid(user: dict) -> str:
    uid = user.get("uid") or user.get("sub")

    if not isinstance(uid, str) or not uid or len(uid) > 128:
        raise HTTPException(
            status_code=401,
            detail="Identitas Firebase tidak valid.",
        )

    return uid


def _limit(db: Session, uid: str, now: datetime) -> int:
    subscription = db.scalar(
        select(Subscription)
        .join(
            OrganizationMember,
            OrganizationMember.organization_id
            == Subscription.organization_id,
        )
        .where(
            OrganizationMember.firebase_uid == uid,
            OrganizationMember.status == "ACTIVE",
            Subscription.status == "ACTIVE",
            Subscription.starts_at <= now,
            Subscription.expires_at > now,
        )
        .order_by(Subscription.expires_at.desc())
        .limit(1)
    )

    if subscription is None:
        return FREE_LIMIT

    snapshot = subscription.entitlement_snapshot or {}

    value = (
        snapshot.get("scanQuota")
        or subscription.plan.scan_quota
        or PREMIUM_LIMIT
    )

    return max(1, int(value))


def _usage(db, uid, start, end, now):
    row = db.execute(
        text("""
            SELECT
                count(*) FILTER (
                    WHERE status = 'USED'
                ) AS used,

                count(*) FILTER (
                    WHERE status = 'RESERVED'
                    AND reservation_expires_at > :now
                ) AS reserved

            FROM detection_usage

            WHERE firebase_uid = :uid
            AND started_at >= :start
            AND started_at < :end
        """),
        {
            "uid": uid,
            "start": start,
            "end": end,
            "now": now,
        },
    ).one()

    return int(row.used), int(row.reserved)


def quota_for_user(db: Session, user: dict) -> dict:
    uid = _uid(user)
    now = datetime.now(timezone.utc)

    start, end = month_bounds(now)
    limit = _limit(db, uid, now)

    used, reserved = _usage(
        db, uid, start, end, now
    )

    return {
        "used": used,
        "reserved": reserved,
        "limit": limit,
        "remaining": max(0, limit - used - reserved),
        "periodStart": start.isoformat(),
        "periodEnd": end.isoformat(),
    }


def reserve(
    db: Session,
    user: dict,
    timeout_seconds: float,
) -> UUID:

    uid = _uid(user)

    db.execute(
        text("""
            SELECT pg_advisory_xact_lock(
                hashtextextended(:uid, 0)
            )
        """),
        {"uid": uid},
    )

    now = datetime.now(timezone.utc)
    start, end = month_bounds(now)

    used, reserved = _usage(
        db, uid, start, end, now
    )

    limit = _limit(db, uid, now)

    if used + reserved >= limit:
        db.rollback()

        raise HTTPException(
            status_code=429,
            detail="Kuota scan bulan ini sudah habis.",
        )

    usage_id = uuid4()

    expiry = now + timedelta(
        seconds=max(
            600,
            timeout_seconds * 3 + 120,
        )
    )

    db.execute(
        text("""
            INSERT INTO detection_usage (
                id,
                firebase_uid,
                started_at,
                status,
                reservation_expires_at
            )
            VALUES (
                :id,
                :uid,
                :now,
                'RESERVED',
                :expiry
            )
        """),
        {
            "id": usage_id,
            "uid": uid,
            "now": now,
            "expiry": expiry,
        },
    )

    db.commit()

    return usage_id


def finish(
    db: Session,
    usage_id: UUID,
    *,
    success: bool,
) -> None:

    result = db.execute(
        text("""
            UPDATE detection_usage

            SET
                status = :status,
                reservation_expires_at = NULL

            WHERE id = :id
            AND status = 'RESERVED'

            AND (
                NOT :success
                OR reservation_expires_at > clock_timestamp()
            )
        """),
        {
            "status": "USED" if success else "RELEASED",
            "id": usage_id,
            "success": success,
        },
    )

    if success and result.rowcount != 1:
        db.rollback()

        raise HTTPException(
            status_code=503,
            detail="Reservasi scan kedaluwarsa. Silakan coba lagi.",
        )

    db.commit()
