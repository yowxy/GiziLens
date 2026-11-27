"""Menu recommendation endpoints."""
from __future__ import annotations

import httpx
from fastapi import APIRouter, Depends, HTTPException

from app.config import get_settings
from app.dependencies import verify_api_key
from app.schemas_api import MenuRecommendationIn, MenuRecommendationOut
from app.services import llm_detector, menu_recommender

router = APIRouter(
    prefix="/recommendations",
    tags=["recommendations"],
    dependencies=[Depends(verify_api_key)],
)


@router.post("/menu", response_model=MenuRecommendationOut)
async def recommend_menu(payload: MenuRecommendationIn) -> MenuRecommendationOut:
    settings = get_settings()
    try:
        return await menu_recommender.recommend(settings, payload)
    except httpx.TimeoutException as exc:
        raise HTTPException(
            status_code=504, detail="Layanan AI terlalu lama merespons. Coba lagi."
        ) from exc
    except httpx.RequestError as exc:
        raise HTTPException(
            status_code=502, detail="Server gagal terhubung ke layanan AI. Coba lagi."
        ) from exc
    except llm_detector.LlmError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc
