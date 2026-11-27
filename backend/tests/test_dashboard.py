"""PostgreSQL integration tests. Set DASHBOARD_TEST_DATABASE_URL to run them."""
import os
import unittest
from datetime import date, datetime, timedelta, timezone
from uuid import uuid4

from fastapi.testclient import TestClient
from sqlalchemy import create_engine, text
from sqlalchemy.orm import Session

from app.database.base import Base
from app.database.models import Organization, OrganizationMember
from app.database.session import get_db
from app.dependencies import require_admin
from app.main import create_app
from app.routers.dashboard import WIB


@unittest.skipUnless(os.getenv("DASHBOARD_TEST_DATABASE_URL"), "Requires a PostgreSQL test database")
class DashboardTest(unittest.TestCase):
    def setUp(self):
        engine = create_engine(os.environ["DASHBOARD_TEST_DATABASE_URL"])
        self.addCleanup(engine.dispose)
        conn = engine.connect()
        self.addCleanup(conn.close)
        transaction = conn.begin()
        self.addCleanup(transaction.rollback)
        schema = "dashboard_test_" + uuid4().hex
        conn.execute(text(f"CREATE SCHEMA {schema}"))
        conn.execute(text(f"SET LOCAL search_path TO {schema}"))
        Base.metadata.create_all(conn)

        def database():
            with Session(conn, join_transaction_mode="create_savepoint") as session:
                yield session

        self.conn = conn
        app = create_app()
        app.dependency_overrides[get_db] = database
        app.dependency_overrides[require_admin] = lambda: {
           "uid": "test-admin",
           "admin": True,
        }
        self.client = TestClient(app, base_url="http://testserver/api/v1/")
        self.addCleanup(self.client.close)

    def report(self, path, **params):
        response = self.client.get("dashboard/" + path, params=params)
        response.raise_for_status()
        return response.json()

    def test_scan_time_round_trips_across_wib_midnight(self):
        inputs = ("2026-12-31T17:05:00Z", "2027-01-01T00:05:00",
                  "2027-01-01T02:05:00+09:00")
        expected = datetime(2026, 12, 31, 17, 5, tzinfo=timezone.utc)
        for index, stamp in enumerate(inputs):
            self.client.post("inspections", json=dict(
                id=f"wib-{index}", scannedAt=stamp, userUid="time-test",
                unitOperational="SPPG Test", targetGroup="Target Uji", components=[],
            )).raise_for_status()
        response = self.client.get("inspections/full", params={
            "userId": "time-test", "since": "2026-12-31T17:00:00Z",
        })
        response.raise_for_status()
        rows = response.json()["items"]
        self.assertEqual(len(rows), len(inputs))
        for row in rows:
            self.assertEqual(datetime.fromisoformat(row["scannedAt"].replace("Z", "+00:00")), expected)
            self.assertEqual(row["batchCode"], "BATCH-20270101")
        self.assertEqual(self.conn.scalar(text("SELECT production_date FROM batches")), date(2027, 1, 1))

    def test_empty_periods_and_custom_dates(self):
        for period, size in (("Harian", 24), ("Mingguan", 7), ("Bulanan", 30)):
            result = self.report("activity", granularity=period)
            self.assertEqual(len(result["points"]), size)
            self.assertEqual(sum(p["evaluated"] for p in result["points"]), 0)
        for period in ("Hari Ini", "7 Hari Terakhir", "30 Hari Terakhir", "Tahun Ini", "Kustom"):
            self.assertEqual(self.report("kpi", timeframe=period)["totalRevenue"], "Rp 0")
        self.assertEqual(self.report("regions")["items"], [])
        self.assertEqual(self.report("compliance")["total"], 0)
        r = self.client.get("dashboard/kpi", params={"timeframe": "Kustom", "startDate": "2025-01-01"})
        self.assertEqual(r.status_code, 400)

    def test_writes_update_all_reports(self):
        sppg = Organization(name="SPPG A", type="SPPG", province="Jawa Timur", status="VERIFIED")
        school = Organization(name="SD B", type="SCHOOL", province="Jawa Timur", status="VERIFIED")
        self.conn.execute(Organization.__table__.insert(), [
            dict(id=sppg.id, name=sppg.name, type=sppg.type, province=sppg.province,
                 status=sppg.status, created_at=datetime.now(WIB), updated_at=datetime.now(WIB)),
            dict(id=school.id, name=school.name, type=school.type, province=school.province,
                 status=school.status, created_at=datetime.now(WIB), updated_at=datetime.now(WIB)),
        ])
        self.conn.execute(OrganizationMember.__table__.insert(), dict(
            id=uuid4(), organization_id=sppg.id, firebase_uid="member-a",
            membership_role="OFFICER", status="ACTIVE", joined_at=datetime.now(WIB),
            updated_at=datetime.now(WIB),
        ))

        start = datetime.now(WIB).replace(hour=0, minute=0, second=0, microsecond=0)
        for ident, scanned, status in (
            ("one", start - timedelta(seconds=1), "SESUAI"),
            ("two", start, "TIDAK SESUAI"),
            ("three", start, "SESUAI"),
        ):
            self.client.post("inspections", json=dict(
                id=ident, batchCode=ident, schoolName="SD B", scannedAt=scanned.isoformat(),
                userUid="member-a", unitOperational="SPPG A", complianceStatus=status,
                components=[dict(name="Nasi", gram=100, nutrition=dict(calories=100))],
            )).raise_for_status()

        report = self.report("kpi", timeframe="Hari Ini")
        self.assertEqual((report["totalUsers"], report["registeredSppg"], report["registeredSchools"]), (1, 1, 1))
        self.assertEqual(report["totalAssessments"], 2)
        yesterday = (start - timedelta(days=1)).date().isoformat()
        custom = self.report("kpi", timeframe="Kustom", startDate=yesterday, endDate=yesterday)
        self.assertEqual(custom["totalAssessments"], 1)
        compliance = self.report("compliance")
        self.assertEqual(compliance["total"], 3)
        self.assertEqual([c["bakiCount"] for c in compliance["categories"]], [2, 0, 1])
        region, = self.report("regions", q="timur")["items"]
        self.assertEqual((region["sppgUnits"], region["schools"], region["assessments"]), (1, 1, 3))

        self.client.post("transactions", json=dict(
            orderId="order", planName="Paket Mandiri", planPrice=1000, totalAmount=1110,
            userUid="member-a",
        )).raise_for_status()
        self.assertEqual(self.report("kpi")["totalRevenue"], "Rp 0")
        self.client.patch("transactions/order/status", json={"status": "settlement"}).raise_for_status()
        updated = self.report("kpi")
        self.assertEqual((updated["totalRevenue"], updated["activePremium"]), ("Rp 1.110", 1))
