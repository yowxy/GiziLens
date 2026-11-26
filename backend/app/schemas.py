"""Pydantic request / response schemas for the detection API."""
from __future__ import annotations

from pydantic import BaseModel, Field


class Nutrition(BaseModel):
    calories: float = 0
    protein: float = 0
    fat: float = 0
    carbohydrate: float = 0
    fiber: float = 0


class BoundingBox(BaseModel):
    """Normalized bounding box (0..1) relative to the image dimensions."""

    x: float = Field(ge=0, le=1)
    y: float = Field(ge=0, le=1)
    width: float = Field(ge=0, le=1)
    height: float = Field(ge=0, le=1)


class FoodItem(BaseModel):
    name: str
    category: str = "Lainnya"
    estimated_gram: int = 0
    confidence: float = 0
    bbox: BoundingBox | None = None
    nutrition: Nutrition = Nutrition()


class DetectionResponse(BaseModel):
    engine: str
    model: str
    items: list[FoodItem] = []
    summary: str = ""
    akg_assessment: str = ""
    processing_ms: int = 0


class HealthResponse(BaseModel):
    status: str
    engine: str
    llm_configured: bool
    onnx_available: bool
