#!/usr/bin/env python3
"""Apply the GiziLens scan quota fix to a local checkout of yowxy/GiziLens.
Run from repository root. All anchors are checked before files are written.
Based on 2e5dcd93ed6b978504d4f65cd69c3d59aa270b4b.
"""
from pathlib import Path
import argparse
import ast

parser = argparse.ArgumentParser()
parser.add_argument('--check', action='store_true', help='Validate source anchors without writing')
args = parser.parse_args()
root = Path.cwd()
changes = {}

def replace(path, old, new, count=1):
    p = root / path
    source = changes.get(p, p.read_text(encoding='utf-8'))
    if source.count(old) != count:
        raise SystemExit(f'Anchor mismatch: {path}. Expected {count}, found {source.count(old)}. Nothing written.')
    changes[p] = source.replace(old, new)


def new_file(path, content):
    p = root / path
    if p.exists():
        raise SystemExit(f'Already exists: {path}. Nothing written.')
    changes[p] = content

new_file('backend/app/database/migrations/alembic/versions/0006_detection_usage.py', '''"""Track successful AI detection independently of saved inspections."""
from alembic import op

revision = "0006"
down_revision = "0005"
branch_labels = None
depends_on = None


def upgrade():
    op.execute("""
        CREATE TABLE detection_usage (
            id uuid PRIMARY KEY,
            firebase_uid varchar(128) NOT NULL,
            started_at timestamptz NOT NULL DEFAULT now(),
            status varchar(20) NOT NULL CHECK (status IN ('RESERVED', 'USED', 'RELEASED')),
            reservation_expires_at timestamptz,
            CHECK (status <> 'RESERVED' OR reservation_expires_at IS NOT NULL)
        )
    """)
    op.execute("""
        CREATE INDEX ix_detection_usage_uid_time
        ON detection_usage (firebase_uid, started_at, status)
    """)
    # Preserve existing saved scan counts, once, without charging future saves.
    op.execute("""
        INSERT INTO detection_usage (id, firebase_uid, started_at, status)
        SELECT id, firebase_uid, created_at, 'USED'
        FROM scans
        WHERE status = 'SUCCESS' AND firebase_uid <> 'anonymous'
    """)


def downgrade():
    op.drop_table('detection_usage')
''')

new_file('backend/app/services/detection_quota.py', '''"""Per-account monthly quota, independent of inspection persistence.

Reserve before invoking AI, then consume on a non-empty successful response.
A short PostgreSQL transaction serializes reservations for a Firebase UID.
"""
from datetime import datetime, timedelta, timezone
from uuid import UUID, uuid4

from fastapi import HTTPException
from sqlalchemy import select, text
from sqlalchemy.orm import Session

from app.database.models import OrganizationMember, Subscription

FREE_LIMIT = 10
PREMIUM_LIMIT = 500
WIB = timezone(timedelta(hours=7))


def month_bounds(now: datetime) -> tuple[datetime, datetime]:
    local = now.astimezone(WIB)
    start = datetime(local.year, local.month, 1, tzinfo=WIB)
    end = datetime(local.year + (local.month == 12), local.month % 12 + 1, 1, tzinfo=WIB)
    return start.astimezone(timezone.utc), end.astimezone(timezone.utc)


def _uid(user: dict) -> str:
    uid = user.get("uid") or user.get("sub")
    if not isinstance(uid, str) or not uid or len(uid) > 128:
        raise HTTPException(status_code=401, detail="Identitas Firebase tidak valid.")
    return uid


def _limit(db: Session, uid: str, now: datetime) -> int:
    subscription = db.scalar(
        select(Subscription)
        .join(OrganizationMember, OrganizationMember.organization_id == Subscription.organization_id)
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
    value = snapshot.get("scanQuota") or subscription.plan.scan_quota or PREMIUM_LIMIT
    return max(1, int(value))


def _usage(db: Session, uid: str, start: datetime, end: datetime, now: datetime) -> tuple[int, int]:
    row = db.execute(text("""
        SELECT count(*) FILTER (WHERE status = 'USED') AS used,
               count(*) FILTER (WHERE status = 'RESERVED' AND reservation_expires_at > :now) AS reserved
        FROM detection_usage
        WHERE firebase_uid = :uid AND started_at >= :start AND started_at < :end
    """), {"uid": uid, "start": start, "end": end, "now": now}).one()
    return int(row.used), int(row.reserved)


def quota_for_user(db: Session, user: dict) -> dict:
    uid = _uid(user)
    now = datetime.now(timezone.utc)
    start, end = month_bounds(now)
    limit = _limit(db, uid, now)
    used, reserved = _usage(db, uid, start, end, now)
    return {"used": used, "reserved": reserved, "limit": limit,
            "remaining": max(0, limit - used - reserved),
            "periodStart": start.isoformat(), "periodEnd": end.isoformat()}


def reserve(db: Session, user: dict, timeout_seconds: float) -> UUID:
    uid = _uid(user)
    # Serializes concurrent requests for this UID across all API processes.
    db.execute(text("SELECT pg_advisory_xact_lock(hashtextextended(:uid, 0))"), {"uid": uid})
    now = datetime.now(timezone.utc)
    start, end = month_bounds(now)
    used, reserved = _usage(db, uid, start, end, now)
    limit = _limit(db, uid, now)
    if used + reserved >= limit:
        db.rollback()
        raise HTTPException(status_code=429, detail="Kuota scan bulan ini sudah habis.")
    usage_id = uuid4()
    # The detector normally times out much sooner. Stale leases do not block
    # the account forever after a process crash.
    expiry = now + timedelta(seconds=max(600, timeout_seconds * 3 + 120))
    db.execute(text("""
        INSERT INTO detection_usage (id, firebase_uid, started_at, status, reservation_expires_at)
        VALUES (:id, :uid, :now, 'RESERVED', :expiry)
    """), {"id": usage_id, "uid": uid, "now": now, "expiry": expiry})
    db.commit()
    return usage_id


def finish(db: Session, usage_id: UUID, *, success: bool) -> None:
    result = db.execute(text("""
        UPDATE detection_usage SET status = :status, reservation_expires_at = NULL
        WHERE id = :id AND status = 'RESERVED'
          AND (NOT :success OR reservation_expires_at > clock_timestamp())
    """), {"status": "USED" if success else "RELEASED", "id": usage_id, "success": success})
    if success and result.rowcount != 1:
        db.rollback()
        raise HTTPException(status_code=503, detail="Reservasi scan kedaluwarsa. Silakan coba lagi.")
    db.commit()
''')

p = 'backend/app/routers/detection.py'
replace(p, 'from app.dependencies import verify_api_key', 'from app.dependencies import get_current_user, verify_api_key\nfrom app.database.session import get_db\nfrom app.services import detection_quota\nfrom sqlalchemy.orm import Session')
replace(p, '@router.post("", response_model=DetectionResponse)', '''@router.get("/quota")
def get_detection_quota(
    user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
    _api_key: str | None = Depends(verify_api_key),
) -> dict:
    return detection_quota.quota_for_user(db, user)


@router.post("", response_model=DetectionResponse)''')
replace(p, '    _api_key: str | None = Depends(verify_api_key),\n) -> DetectionResponse:', '    _api_key: str | None = Depends(verify_api_key),\n    user: dict = Depends(get_current_user),\n    db: Session = Depends(get_db),\n) -> DetectionResponse:')
replace(p, '    try:\n        if selected == "llm":', '''    if selected != "llm":
        if selected == "onnx":
            raise HTTPException(status_code=400, detail="Engine 'onnx' dinonaktifkan. Gunakan 'llm' atau 'auto'.")
        raise HTTPException(status_code=400, detail="Engine harus 'llm' atau 'auto'.")

    usage_id = detection_quota.reserve(db, user, settings.llm_timeout_seconds)
    consumed = False
    try:
        if selected == "llm":''')
replace(p, '''    except httpx.TimeoutException as exc:''', '''        result.processing_ms = int((time.perf_counter() - started) * 1000)
        consumed = any(item.name.strip() for item in result.items)
        return result
    except httpx.TimeoutException as exc:''')
replace(p, '''
    result.processing_ms = int((time.perf_counter() - started) * 1000)
    return result
''', '''    finally:
        # No successful response leaves the API until usage is persisted.
        # Errors and empty detections release the reserved slot.
        db.rollback()
        detection_quota.finish(db, usage_id, success=consumed)
''')

base = 'fe/gizi_lens/lib/'
p = base + 'core/services/detection_api_service.dart'
replace(p, "import '../../features/inspection/models/target_akg_model.dart';", "import '../../features/inspection/models/target_akg_model.dart';\nimport 'firebase_auth_service.dart';")
replace(p, '  Future<DetectionApiResult> analyzeImage(', '''  Future<String?> _idToken() async {
    final user = FirebaseAuthService.instance.currentUser;
    return user == null ? null : await user.getIdToken();
  }

  Future<Map<String, dynamic>> fetchQuota() async {
    final token = await _idToken();
    if (token == null || token.isEmpty) {
      throw const DetectionApiException('Login diperlukan untuk melihat kuota.');
    }
    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/detect/quota'),
      headers: {
        'Authorization': 'Bearer $token',
        if (_apiKey.isNotEmpty) 'X-API-Key': _apiKey,
      },
    ).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw DetectionApiException(_errorMessage(response));
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<DetectionApiResult> analyzeImage(''')
replace(p, "    request.fields\n", "    final token = await _idToken();\n    if (token != null && token.isNotEmpty) {\n      request.headers['Authorization'] = 'Bearer $token';\n    }\n\n    request.fields\n")

p = base + 'core/services/scan_quota_service.dart'
replace(p, "import 'firestore_service.dart';", "import 'detection_api_service.dart';")
replace(p, '    required this.periodStart,\n', '    required this.periodStart,\n    this.available = true,\n    this.reserved = 0,\n')
replace(p, '  final DateTime periodStart;\n', '  final DateTime periodStart;\n  final bool available;\n  final int reserved;\n')
replace(p, '  bool get isExhausted => used >= limit;\n  int get remaining => (limit - used).clamp(0, limit);', '  bool get isExhausted => available && used + reserved >= limit;\n  int get remaining => (limit - used - reserved).clamp(0, limit);')
replace(p, '''/// Counts inspections created in the current calendar month and compares them
/// against the plan allowance, so free accounts stop at 10 scans and premium
/// accounts at 500. The counter resets automatically when the month changes
/// because only records from the first day of the current month are counted.''', '''/// Reads authoritative usage from the backend, independently of saved audits.
/// The server enforces the allowance before starting inference.''')
replace(p, '''    var used = 0;
    try {
      final inspections = await FirestoreService.instance.getInspections(
        limit: 500,
      );
      used = inspections.where((inspection) {
        final created = WibTime.parseInstant(
          (inspection['scannedAt'] ?? inspection['createdDateIso'])?.toString(),
        );
        return created != null && !created.isBefore(monthStart);
      }).length;
    } catch (error) {
      debugPrint('Gagal menghitung pemakaian kuota scan: $error');
    }

    return ScanQuota(used: used, limit: limit, periodStart: monthStart);''', '''    try {
      final data = await DetectionApiService().fetchQuota();
      return ScanQuota(
        used: (data['used'] as num).toInt(),
        reserved: (data['reserved'] as num).toInt(),
        limit: (data['limit'] as num).toInt(),
        periodStart: DateTime.parse(data['periodStart'] as String).toUtc(),
      );
    } catch (error) {
      debugPrint('Gagal mengambil kuota scan: $error');
      // Never present an unavailable quota as a confirmed zero count.
      return ScanQuota(used: 0, limit: limit, periodStart: monthStart, available: false);
    }''')

p = base + 'features/inspection/views/scan_ompreng_screen.dart'
replace(p, '  Future<void> _loadQuota() async {', '  Future<void> _loadQuota({bool showExhausted = true}) async {')
replace(p, '    if (quota.isExhausted) _showQuotaExhaustedSheet(quota);', '    if (showExhausted && quota.isExhausted) _showQuotaExhaustedSheet(quota);')
# Both gallery and camera share capturePhoto. Refresh the authoritative display after every attempt.
replace(p, '      if (success && mounted) {\n        try {\n          context.push(RouteNames.componentDetection);', '      if (mounted) {\n        await _loadQuota(showExhausted: false);\n      }\n      if (success && mounted) {\n        try {\n          context.push(RouteNames.componentDetection);', count=2)

p = base + 'features/profile/controllers/profile_controller.dart'
replace(p, '  int _monthlyScansUsed = 0;', '  int _monthlyScansUsed = 0;\n  ScanQuota? _serverQuota;')
replace(p, '  int get monthlyScansUsed => _monthlyScansUsed;', '  int get monthlyScansUsed => _monthlyScansUsed;\n  int get monthlyQuota => _serverQuota?.limit ?? (account.isPremium ? premiumScanQuota : monthlyScanQuota);\n  bool get quotaAvailable => _serverQuota?.available == true;')
replace(p, '''    if (quota.used != _monthlyScansUsed) {
      _monthlyScansUsed = quota.used;
      notifyListeners();
    }''', '''    _serverQuota = quota;
    if (quota.available) _monthlyScansUsed = quota.used;
    notifyListeners();''')

p = base + 'features/profile/views/profile_screen.dart'
replace(p, '''                      monthlyQuota: _controller.account.isPremium
                          ? ProfileController.premiumScanQuota
                          : ProfileController.monthlyScanQuota,''', '''                      monthlyQuota: _controller.monthlyQuota,''')
replace(p, '                      monthlyQuota: _controller.monthlyQuota,', '                      monthlyQuota: _controller.monthlyQuota,\n                      quotaAvailable: _controller.quotaAvailable,')
p = base + 'features/profile/views/widgets/subscription_plan_card.dart'
replace(p, '  final int monthlyQuota;', '  final int monthlyQuota;\n  final bool quotaAvailable;')
replace(p, '    required this.monthlyQuota,', '    required this.monthlyQuota,\n    this.quotaAvailable = true,')
replace(p, 'AppStrings.planQuotaUsage(scansUsed, monthlyQuota),', "quotaAvailable ? AppStrings.planQuotaUsage(scansUsed, monthlyQuota) : 'Kuota belum tersedia',")
replace(p, 'AppStrings.planQuotaRemaining(remaining),', "quotaAvailable ? AppStrings.planQuotaRemaining(remaining) : 'Coba lagi saat online',")
replace(p, 'final progress = used / safeQuota;', 'final progress = quotaAvailable ? used / safeQuota : 0.0;')

# Existing tests still exercise timeout behavior; add quota display state coverage.
p = 'fe/gizi_lens/test/core/scan_quota_test.dart'
replace(p, "    test('plan allowances match the published pricing', () {", """    test('reserved scans reduce available slots without increasing used', () {
      final quota = ScanQuota(used: 9, reserved: 1, limit: 10, periodStart: periodStart);
      expect(quota.used, 9);
      expect(quota.remaining, 0);
      expect(quota.isExhausted, isTrue);
    });

    test('an unavailable quota is not a confirmed exhausted quota', () {
      final quota = ScanQuota(used: 10, limit: 10, periodStart: periodStart, available: false);
      expect(quota.available, isFalse);
      expect(quota.isExhausted, isFalse);
    });

    test('plan allowances match the published pricing', () {""")

new_file('backend/tests/test_detection_quota_period.py', '''from datetime import datetime, timezone

from app.services.detection_quota import month_bounds


def test_month_boundary_wib():
    before = datetime(2026, 11, 30, 16, 59, tzinfo=timezone.utc)
    after = datetime(2026, 11, 30, 17, 0, tzinfo=timezone.utc)
    assert month_bounds(before)[1] == after
    assert month_bounds(after)[0] == after


def test_december_rolls_into_new_year():
    now = datetime(2026, 12, 20, tzinfo=timezone.utc)
    assert month_bounds(now)[1] == datetime(2026, 12, 31, 17, tzinfo=timezone.utc)
''')

new_file('backend/tests/test_detection_quota_router.py', '''import asyncio
from io import BytesIO
from types import SimpleNamespace
from unittest.mock import AsyncMock, Mock
from uuid import uuid4

import httpx
import pytest
from fastapi import HTTPException, UploadFile

from app.routers import detection
from app.schemas import DetectionResponse, FoodItem


def call_detect(db):
    return asyncio.run(detection.detect_food(
        image=UploadFile(file=BytesIO(b"\\xff\\xd8\\xfftest"), filename="tray.jpg"),
        engine="llm", target_group="test", target_calories=585,
        target_protein=15, target_fat=19.5, target_carbohydrate=87,
        target_fiber=8, _api_key=None, user={"uid": "test-user"}, db=db,
    ))


@pytest.mark.parametrize("items, consumed", [([FoodItem(name="Nasi")], True), ([], False)])
def test_detection_consumes_only_nonempty_success(monkeypatch, items, consumed):
    db = Mock()
    usage_id = uuid4()
    reserve = Mock(return_value=usage_id)
    finish = Mock()
    monkeypatch.setattr(detection, "get_settings", lambda: SimpleNamespace(
        max_upload_bytes=1024, max_upload_mb=1, llm_timeout_seconds=60))
    monkeypatch.setattr(detection.detection_quota, "reserve", reserve)
    monkeypatch.setattr(detection.detection_quota, "finish", finish)
    monkeypatch.setattr(detection.llm_detector, "detect", AsyncMock(return_value=
        DetectionResponse(engine="llm", model="test", items=items)))
    assert call_detect(db).items == items
    reserve.assert_called_once_with(db, {"uid": "test-user"}, 60)
    finish.assert_called_once_with(db, usage_id, success=consumed)


def test_provider_timeout_releases_quota(monkeypatch):
    db = Mock()
    usage_id = uuid4()
    finish = Mock()
    monkeypatch.setattr(detection, "get_settings", lambda: SimpleNamespace(
        max_upload_bytes=1024, max_upload_mb=1, llm_timeout_seconds=60))
    monkeypatch.setattr(detection.detection_quota, "reserve", Mock(return_value=usage_id))
    monkeypatch.setattr(detection.detection_quota, "finish", finish)
    monkeypatch.setattr(detection.llm_detector, "detect", AsyncMock(side_effect=httpx.ReadTimeout("timeout")))
    with pytest.raises(HTTPException) as exc:
        call_detect(db)
    assert exc.value.status_code == 504
    finish.assert_called_once_with(db, usage_id, success=False)
''')

# Validate Python syntax before writing any files.
for p, content in changes.items():
    if p.suffix == '.py':
        ast.parse(content, filename=str(p))

for p, content in changes.items():
    print(('CHECK' if args.check else 'UPDATE') + ' ' + str(p.relative_to(root)))
    if not args.check:
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(content, encoding='utf-8')
print(f'{len(changes)} files; ' + ('no writes performed.' if args.check else 'review git diff and run tests before committing.'))
