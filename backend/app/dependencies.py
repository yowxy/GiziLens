from __future__ import annotations

import os
import logging

from fastapi import Depends, Header, HTTPException
from firebase_admin import auth
from google.auth.exceptions import DefaultCredentialsError

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
    """Resolve a Firebase ID token from the Authorization header."""
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

    except DefaultCredentialsError as exc:
        logger.error(
            "Firebase service account belum dikonfigurasi. Set "
            "FIREBASE_CREDENTIALS_FILE atau GOOGLE_APPLICATION_CREDENTIALS."
        )
        raise HTTPException(
            status_code=503,
            detail="Konfigurasi service account Firebase belum diset."
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
        if not admin_uids:
            logger.warning(
                "Akses admin ditolak: FIREBASE_ADMIN_UIDS kosong dan token tidak "
                "memiliki klaim admin=true."
            )
        raise HTTPException(
            status_code=403,
            detail="Akses khusus administrator."
        )

    return user


def verify_api_key_or_admin(
    x_api_key: str | None = Header(default=None),
    authorization: str | None = Header(default=None),
) -> dict | None:
    """Allow either the mobile API key or a Firebase admin session.

    The admin dashboard is a static SPA, so shipping a long-lived API key in
    its JavaScript bundle would leak the key to every visitor. Instead the
    dashboard authenticates with the admin's Firebase ID token, while the
    Flutter app keeps using ``X-API-Key``.
    """
    settings = get_settings()

    if not settings.require_api_key:
        return None

    if x_api_key and x_api_key in settings.allowed_api_keys:
        return None

    if authorization and authorization.startswith("Bearer "):
        return require_admin(user=get_current_user(authorization))

    raise HTTPException(
        status_code=401,
        detail="API key atau sesi admin diperlukan.",
        headers={"WWW-Authenticate": "X-API-Key, Bearer"},
    )
