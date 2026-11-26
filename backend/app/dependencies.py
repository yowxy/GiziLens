"""Authentication hook for the future subscription system.

For now it only checks a static set of API keys. A real subscription service can
replace ``verify_api_key`` later (look up the key, check plan/quota, etc.) without
touching the detection endpoints.
"""
from __future__ import annotations

from fastapi import Header, HTTPException, status

from app.config import get_settings


async def verify_api_key(x_api_key: str | None = Header(default=None)) -> str | None:
    settings = get_settings()
    if not settings.require_api_key:
        return x_api_key

    allowed = settings.allowed_api_keys
    if not x_api_key or x_api_key not in allowed:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="API key tidak valid atau tidak aktif.",
            headers={"WWW-Authenticate": "X-API-Key"},
        )
    return x_api_key
