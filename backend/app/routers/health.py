"""Health / readiness endpoint."""
from __future__ import annotations

from fastapi import APIRouter

from app.config import get_settings
from app.database.session import ping_db
from app.schemas import HealthResponse
from app.schemas_api import DbHealthOut
from app.services import onnx_detector

router = APIRouter(tags=["health"])


@router.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    settings = get_settings()
    return HealthResponse(
        status="ok",
        engine=settings.detection_engine,
        llm_configured=bool(settings.sumopod_api_key),
        onnx_available=onnx_detector.is_available(settings),
    )


@router.get("/health/db", response_model=DbHealthOut)
def health_db() -> DbHealthOut:
    reachable, latency_ms = ping_db()
    return DbHealthOut(
        status="ok" if reachable else "unavailable",
        database=reachable,
        latency_ms=latency_ms,
    )
