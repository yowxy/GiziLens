"""Dashboard metrics calculated from the v1 operational schema.

Users are Firebase identities that appear as ``organization_members``; SPPG and
schools are ``organizations``; assessments are locked ``inspections``; revenue
comes from confirmed ``payments`` and premium accounts from active
``subscriptions``.
"""
from __future__ import annotations

from calendar import monthrange
from datetime import date, datetime, time, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import case, func, select, text
from sqlalchemy.orm import Session

from app.api_utils import MONTHS_ID, format_number, format_rupiah
from app.database.models import (
    Inspection,
    Organization,
    OrganizationMember,
    Payment,
    Scan,
    Subscription,
)
from app.database.session import get_db
from app.dependencies import require_admin
from app.schemas_api import (
    ActivityOut,
    ActivityPointOut,
    ComplianceCategoryOut,
    ComplianceOut,
    KpiOut,
    RegionOut,
    RegionsOut,
)

router = APIRouter(
    prefix="/dashboard",
    tags=["dashboard"],
    dependencies=[Depends(require_admin)],
)

WIB = timezone(timedelta(hours=7))
DAY = timedelta(days=1)
PERIOD_DAYS = {"Hari Ini": 1, "7 Hari Terakhir": 7, "30 Hari Terakhir": 30}
ACTIVITY_DAYS = {"Harian": 1, "Mingguan": 7, "Bulanan": 30}
WEEKDAYS = ("Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min")
PAID_STATUSES = ("PAID", "REFUNDED", "PARTIALLY_REFUNDED")


def _midnight(day: date) -> datetime:
    return datetime.combine(day, time.min, WIB)


def _windows(
    timeframe: str, first: date | None, last: date | None
) -> tuple[datetime, datetime, datetime, datetime]:
    today = datetime.now(WIB).date()
    if timeframe == "Tahun Ini":
        first = today.replace(month=1, day=1)
        previous_year = today.year - 1
        previous_day = min(today.day, monthrange(previous_year, today.month)[1])
        previous_last = today.replace(year=previous_year, day=previous_day)
        return (
            _midnight(first), _midnight(today + DAY),
            _midnight(first.replace(year=previous_year)), _midnight(previous_last + DAY),
        )
    if timeframe == "Kustom":
        if first is None and last is None:
            first, last = today - 29 * DAY, today
        elif first is None or last is None or first > last or last > today:
            raise HTTPException(400, "Isi startDate dan endDate dengan rentang valid hingga hari ini.")
    elif timeframe in PERIOD_DAYS:
        first, last = today - (PERIOD_DAYS[timeframe] - 1) * DAY, today
    else:
        raise HTTPException(404, f"Timeframe '{timeframe}' tidak ditemukan.")

    start, end = _midnight(first), _midnight(last + DAY)
    if (end - start).days >= first.toordinal():
        raise HTTPException(400, "Rentang tanggal terlalu panjang untuk periode pembanding.")
    return start, end, start - (end - start), start


def _trend(current: int, previous: int) -> str:
    if previous == 0:
        return "Baru" if current else "0%"
    return f"{(current - previous) * 100 / previous:+.1f}%".replace(".", ",")


@router.get("/kpi", response_model=KpiOut)
def get_kpi(
    timeframe: str = Query(default="30 Hari Terakhir"),
    start_date: date | None = Query(default=None, alias="startDate"),
    end_date: date | None = Query(default=None, alias="endDate"),
    db: Session = Depends(get_db),
) -> KpiOut:
    start, end, prev_start, prev_end = _windows(timeframe, start_date, end_date)

    def registered(created_at):
        return db.execute(
            select(func.count(), func.count().filter(created_at < start))
            .where(created_at < end)
        ).one()

    def period_totals(aggregate, timestamp, *conditions):
        current, previous = db.execute(
            select(
                aggregate.filter(timestamp >= start, timestamp < end),
                aggregate.filter(timestamp >= prev_start, timestamp < prev_end),
            ).where(timestamp >= prev_start, timestamp < end, *conditions)
        ).one()
        return int(current or 0), int(previous or 0)

    members, prev_members = registered(OrganizationMember.joined_at)
    units, prev_units = db.execute(
        select(func.count(), func.count().filter(Organization.created_at < start))
        .where(Organization.type == "SPPG", Organization.created_at < end)
    ).one()
    schools, prev_schools = db.execute(
        select(func.count(), func.count().filter(Organization.created_at < start))
        .where(Organization.type == "SCHOOL", Organization.created_at < end)
    ).one()
    assessments, prev_assessments = period_totals(func.count(), Inspection.locked_at)
    revenue, prev_revenue = period_totals(
        func.sum(Payment.gross_amount),
        func.coalesce(Payment.paid_at, Payment.created_at),
        Payment.status.in_(PAID_STATUSES),
    )
    premium = int(
        db.scalar(
            select(func.count()).select_from(Subscription).where(Subscription.status == "ACTIVE")
        )
        or 0
    )
    total_members = int(db.scalar(select(func.count()).select_from(OrganizationMember)) or 0)
    premium_share = 100 * premium / total_members if total_members else 0

    return KpiOut(
        total_users=int(members or 0), users_trend=_trend(int(members or 0), int(prev_members or 0)),
        users_note="anggota organisasi aktif",
        registered_sppg=int(units or 0), sppg_trend=f"+{format_number(int(units or 0) - int(prev_units or 0))} unit",
        sppg_note="terdaftar pada periode ini",
        registered_schools=int(schools or 0), schools_trend=_trend(int(schools or 0), int(prev_schools or 0)),
        schools_note="sejak awal periode",
        total_assessments=assessments, assessments_trend=_trend(assessments, prev_assessments),
        assessments_note="vs periode sebelumnya",
        active_premium=premium, premium_trend=f"{premium_share:.1f}%".replace(".", ","),
        premium_note="organisasi dengan langganan aktif",
        total_revenue=format_rupiah(revenue), revenue_trend=_trend(revenue, prev_revenue),
        revenue_note="pembayaran terkonfirmasi",
    )


@router.get("/activity", response_model=ActivityOut)
def get_activity(
    granularity: str = Query(default="Mingguan"),
    db: Session = Depends(get_db),
) -> ActivityOut:
    if granularity not in ACTIVITY_DAYS:
        raise HTTPException(400, "Granularity harus salah satu dari: Harian, Mingguan, Bulanan.")
    days = ACTIVITY_DAYS[granularity]
    end = _midnight(datetime.now(WIB).date() + DAY)
    start = end - days * DAY
    hourly = granularity == "Harian"
    step = timedelta(hours=1) if hourly else DAY
    bucket = func.date_trunc(
        "hour" if hourly else "day", func.timezone("Asia/Jakarta", Scan.created_at)
    )
    counts = dict(db.execute(select(bucket, func.count()).where(
        Scan.created_at >= start - days * DAY, Scan.created_at < end
    ).group_by(bucket)).all())

    points = []
    moment = start.replace(tzinfo=None)
    for _ in range((end - start) // step):
        if hourly:
            label = moment.strftime("%H:%M")
        elif granularity == "Mingguan":
            label = WEEKDAYS[moment.weekday()]
        else:
            label = f"{moment.day} {MONTHS_ID[moment.month - 1]}"
        points.append(ActivityPointOut(
            label=label, evaluated=counts.get(moment, 0),
            previous=counts.get(moment - days * DAY, 0),
        ))
        moment += step
    total = sum(point.evaluated for point in points)
    return ActivityOut(
        subtitle=f"Total Penilaian {granularity}", total=format_number(total),
        trend=_trend(total, sum(point.previous for point in points)) + " vs periode sebelumnya",
        highlight_label=f"{format_number(total)} baki", points=points,
    )


@router.get("/compliance", response_model=ComplianceOut)
def get_compliance(db: Session = Depends(get_db)) -> ComplianceOut:
    category = case(
        (Inspection.compliance_status == "SESUAI", "meets_target"),
        (Inspection.compliance_status == "TIDAK_SESUAI", "below_std"),
        else_="needs_review",
    )
    counts = dict(db.execute(select(category, func.count()).group_by(category)).all())
    total = sum(counts.values())
    categories = []
    for key, label, subtitle, color in (
        ("meets_target", "Sesuai Target (AKG)", "Inspeksi terverifikasi", "#10B981"),
        ("needs_review", "Perlu Tinjauan Ahli Gizi", "Inspeksi belum dinilai", "#F59E0B"),
        ("below_std", "Tidak Sesuai Target (AKG)", "Hasil verifikasi tidak sesuai", "#EF4444"),
    ):
        count = counts.get(key, 0)
        categories.append(ComplianceCategoryOut(
            key=key, label=label, subtitle=subtitle, color_hex=color,
            baki_count=count, percentage=round(100 * count / total, 2) if total else 0,
        ))
    return ComplianceOut(categories=categories, total=total)


@router.get("/regions", response_model=RegionsOut)
def get_regions(
    q: str | None = Query(default=None),
    db: Session = Depends(get_db),
) -> RegionsOut:
    today = _midnight(datetime.now(WIB).date())
    rows = db.execute(text("""
        WITH facts AS (
            SELECT province, count(*) AS units, 0 AS schools, 0 AS assessments,
                   0 AS today_count
            FROM organizations WHERE type = 'SPPG' GROUP BY province
            UNION ALL
            SELECT province, 0, count(*), 0, 0
            FROM organizations WHERE type = 'SCHOOL' GROUP BY province
            UNION ALL
            SELECT o.province, 0, 0, count(*),
                   count(*) FILTER (WHERE s.created_at >= :today AND s.created_at < :tomorrow)
            FROM inspections i
            JOIN scans s ON s.id = i.scan_id
            JOIN organizations o ON o.id = s.organization_id
            GROUP BY o.province
        )
        SELECT coalesce(nullif(trim(province), ''), 'Belum diketahui') AS region,
               sum(units) AS units, sum(schools) AS schools, sum(assessments) AS assessments,
               sum(today_count) AS today_count
        FROM facts GROUP BY 1 ORDER BY assessments DESC, region
    """), {"today": today, "tomorrow": today + DAY}).all()

    search = (q or "").strip().casefold()
    return RegionsOut(items=[
        RegionOut(rank=rank, province=row.region, sppg_units=row.units, schools=row.schools,
                  assessments=row.assessments, target_pct=0)
        for rank, row in enumerate(rows, 1) if search in row.region.casefold()
    ])


@router.get("/summary")
def get_summary(db: Session = Depends(get_db)) -> dict[str, int]:
    """Live row counts, useful for ops and quick sanity checks."""
    def count(model) -> int:
        return int(db.scalar(select(func.count()).select_from(model)) or 0)

    return {
        "users": count(OrganizationMember),
        "sppgUnits": int(db.scalar(
            select(func.count()).select_from(Organization).where(Organization.type == "SPPG")
        ) or 0),
        "schools": int(db.scalar(
            select(func.count()).select_from(Organization).where(Organization.type == "SCHOOL")
        ) or 0),
        "inspections": count(Inspection),
        "paymentOrders": count(Payment),
    }
