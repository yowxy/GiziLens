"""Small formatting helpers shared by the data API routers."""
from __future__ import annotations

from datetime import date, datetime, timedelta, timezone

WIB = timezone(timedelta(hours=7))

MONTHS_ID = [
    "Jan", "Feb", "Mar", "Apr", "Mei", "Jun",
    "Jul", "Agu", "Sep", "Okt", "Nov", "Des",
]


def format_number(value: int | float) -> str:
    """Format an integer with Indonesian thousands separators (318.450)."""
    return f"{int(value):,}".replace(",", ".")


def format_rupiah(value: int) -> str:
    return "Rp " + format_number(value)


def normalize_role(role: str | None) -> str:
    """Map the free-form role stored in PostgreSQL to the admin union type."""
    raw = (role or "").strip()
    lowered = raw.lower()
    if lowered in {"admin", "super_admin", "superadmin", "bgn national admin"}:
        return "BGN National Admin"
    if "ahli gizi" in lowered:
        return "Ahli Gizi"
    if "petugas sppg" in lowered:
        return "Petugas SPPG"
    if "pic sekolah" in lowered or "sekolah" in lowered:
        return "PIC Sekolah"
    if "supir" in lowered or "distribusi" in lowered:
        return "Supir Distribusi"
    if "penyelia" in lowered:
        return "Petugas SPPG"
    return raw or "Petugas SPPG"


def user_status_label(is_verified: bool) -> str:
    return "Verified" if is_verified else "Pending Approval"


def created_at_label(moment: datetime | None) -> str:
    if moment is None:
        return "Hari ini"
    if moment.tzinfo is None:
        moment = moment.replace(tzinfo=timezone.utc)
    now = datetime.now(WIB)
    local = moment.astimezone(WIB)
    today = now.date()
    delta_days = (today - local.date()).days
    clock = local.strftime("%H:%M")
    if delta_days <= 0:
        return f"Hari ini, {clock}"
    if delta_days == 1:
        return f"Kemarin, {clock}"
    if delta_days < 7:
        return f"{delta_days} hari lalu"
    return f"{local.day} {MONTHS_ID[local.month - 1]} {local.year}"


def plan_icon(plan_name: str | None) -> str:
    name = (plan_name or "").lower()
    if "tahunan" in name or "sentral" in name or "enterprise" in name:
        return "crown" if "tahunan" in name else "building"
    if "sekolah" in name or "multi" in name:
        return "school"
    if "bulanan" in name or "pro" in name:
        return "spark"
    return "crown"


def transaction_status_label(status: str | None) -> str:
    if status == "settlement":
        return "Terkonfirmasi"
    if status == "pending":
        return "Diproses"
    if status == "failed":
        return "Gagal"
    if status == "expired":
        return "Kedaluwarsa"
    return "Terkonfirmasi"


def parse_datetime(value: str | None) -> datetime | None:
    if not value:
        return None
    cleaned = value.strip().replace("Z", "+00:00")
    try:
        parsed = datetime.fromisoformat(cleaned)
    except ValueError:
        return None
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed


def iso_or_none(moment: datetime | None) -> str | None:
    if moment is None:
        return None
    if moment.tzinfo is None:
        moment = moment.replace(tzinfo=timezone.utc)
    return moment.isoformat()


def day_start(moment: date) -> datetime:
    return datetime(moment.year, moment.month, moment.day, tzinfo=timezone.utc)
