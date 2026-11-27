from datetime import datetime, timezone

from app.services.detection_quota import month_bounds


def test_month_boundary_wib():
    before = datetime(
        2026, 11, 30, 16, 59,
        tzinfo=timezone.utc,
    )

    after = datetime(
        2026, 11, 30, 17, 0,
        tzinfo=timezone.utc,
    )

    assert month_bounds(before)[1] == after
    assert month_bounds(after)[0] == after


def test_december_rolls_into_new_year():
    now = datetime(
        2026, 12, 20,
        tzinfo=timezone.utc,
    )

    assert month_bounds(now)[1] == datetime(
        2026, 12, 31, 17,
        tzinfo=timezone.utc,
    )
