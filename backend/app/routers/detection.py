"""Detection endpoints."""
from __future__ import annotations

import time

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile

from app.config import get_settings
from app.dependencies import verify_api_key
from app.schemas import DetectionResponse
from app.services import llm_detector, onnx_detector

router = APIRouter(prefix="/detect", tags=["detection"])


def _sniff_mime(content: bytes) -> str | None:
    if content[:3] == b"\xff\xd8\xff":
        return "image/jpeg"
    if content[:8] == b"\x89PNG\r\n\x1a\n":
        return "image/png"
    if content[:4] == b"RIFF" and content[8:12] == b"WEBP":
        return "image/webp"
    if content[:3] == b"GIF":
        return "image/gif"
    return None


def _check_upload(content: bytes, content_type: str | None) -> str:
    settings = get_settings()
    if not content:
        raise HTTPException(status_code=400, detail="Gambar kosong.")
    if len(content) > settings.max_upload_bytes:
        raise HTTPException(
            status_code=413,
            detail=f"Ukuran gambar melebihi {settings.max_upload_mb} MB.",
        )

    mime = _sniff_mime(content)
    if mime:
        return mime
    if content_type and content_type.startswith("image/"):
        return content_type
    raise HTTPException(status_code=415, detail="File harus berupa gambar.")


@router.post("", response_model=DetectionResponse)
async def detect_food(
    image: UploadFile = File(...),
    engine: str = Form("auto"),
    target_group: str = Form("SD Kelas 4 – 6 (10 – 12 Tahun)"),
    target_calories: float = Form(633.75),
    target_protein: float = Form(16.25),
    target_fat: float = Form(21.125),
    target_carbohydrate: float = Form(94.25),
    target_fiber: float = Form(8.9375),
    _api_key: str | None = Depends(verify_api_key),
) -> DetectionResponse:
    settings = get_settings()
    started = time.perf_counter()

    content = await image.read()
    mime_type = _check_upload(content, image.content_type)

    selected = engine.strip().lower()
    if selected == "auto":
        selected = settings.detection_engine.lower()

    try:
        if selected == "llm":
            result = await llm_detector.detect(
                settings=settings,
                image_bytes=content,
                mime_type=mime_type,
                target_group=target_group,
                calories=target_calories,
                protein=target_protein,
                fat=target_fat,
                carbohydrate=target_carbohydrate,
                fiber=target_fiber,
            )
        elif selected == "onnx":
            result = onnx_detector.detect(settings, content)
        else:
            raise HTTPException(
                status_code=400,
                detail="Engine harus 'llm', 'onnx', atau 'auto'.",
            )
    except llm_detector.LlmError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc
    except onnx_detector.OnnxError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc

    result.processing_ms = int((time.perf_counter() - started) * 1000)
    return result
