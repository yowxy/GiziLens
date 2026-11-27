from __future__ import annotations

import os
import logging

from fastapi import Depends, Header, HTTPException
from firebase_admin import auth

from app.config import get_settings
from app.services.firebase_service import verify_firebase_token

logger = logging.getLogger(__name__)


async def verify_api_key(
    x_api_key: str | None = Header(default=None)
) -> str | None:
    settings = get_settings()

    if not settings.require_api_key:
        return x_api_key

    if not x_api_key or x_api_key not in settings.allowed_api_keys:
        raise HTTPException(
            status_code=401,
            detail="API key tidak valid atau tidak aktif.",
            headers={"WWW-Authenticate": "X-API-Key"}
        )

    return x_api_key


def get_current_user(
    authorization: str | None = Header(default=None)
) -> dict:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=401,
            detail="Firebase ID Token diperlukan.",
            headers={"WWW-Authenticate": "Bearer"}
        )

    token = authorization[7:].strip()

    try:
        return verify_firebase_token(token)

    except (
        auth.InvalidIdTokenError,
        auth.ExpiredIdTokenError,
        auth.RevokedIdTokenError,
        auth.UserDisabledError,
        ValueError
    ) as exc:
        raise HTTPException(
            status_code=401,
            detail="Firebase ID Token tidak valid."
        ) from exc

    except Exception as exc:
        logger.exception("Firebase verification unavailable")
        raise HTTPException(
            status_code=503,
            detail="Layanan autentikasi tidak tersedia."
        ) from exc


def require_admin(
    user: dict = Depends(get_current_user)
) -> dict:
    admin_uids = {
        uid.strip()
        for uid in os.getenv("FIREBASE_ADMIN_UIDS", "").split(",")
        if uid.strip()
    }

    is_admin = (
        user.get("admin") is True
        or user.get("uid") in admin_uids
    )

    if not is_admin:
        raise HTTPException(
            status_code=403,
            detail="Akses khusus administrator."
        )

    return user
