import asyncio
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
        image=UploadFile(file=BytesIO(b"\xff\xd8\xfftest"), filename="tray.jpg"),
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

