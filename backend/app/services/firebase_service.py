import json
import logging
import os
from pathlib import Path
from threading import Lock

import firebase_admin
from firebase_admin import auth, credentials

logger = logging.getLogger(__name__)

_init_lock = Lock()


def _resolve_credential():
    """Build a Firebase service-account credential from the environment.

    Supports either the raw JSON (FIREBASE_CREDENTIALS_JSON) or a file path
    (FIREBASE_CREDENTIALS_FILE). When neither is set the Admin SDK falls back
    to Application Default Credentials, which requires
    GOOGLE_APPLICATION_CREDENTIALS to be configured.
    """
    raw = (os.getenv("FIREBASE_CREDENTIALS_JSON") or "").strip()
    if raw:
        try:
            return credentials.Certificate(json.loads(raw))
        except ValueError as exc:
            raise RuntimeError("FIREBASE_CREDENTIALS_JSON bukan JSON yang valid.") from exc

    path = (os.getenv("FIREBASE_CREDENTIALS_FILE") or "").strip()
    if path:
        file = Path(path).expanduser()
        if not file.is_file():
            raise RuntimeError(f"FIREBASE_CREDENTIALS_FILE tidak ditemukan: {file}")
        return credentials.Certificate(str(file))

    return None


def get_firebase_app():
    with _init_lock:
        try:
            return firebase_admin.get_app()
        except ValueError:
            options = {
                "projectId": os.getenv("FIREBASE_PROJECT_ID", "gizilens-32aa6")
            }
            credential = _resolve_credential()

            if credential is None:
                logger.warning(
                    "Firebase Admin tanpa service account. Verifikasi Bearer token "
                    "akan gagal (503). Set FIREBASE_CREDENTIALS_FILE atau "
                    "GOOGLE_APPLICATION_CREDENTIALS."
                )
                return firebase_admin.initialize_app(options=options)

            return firebase_admin.initialize_app(credential, options=options)


def verify_firebase_token(token: str) -> dict:
    return auth.verify_id_token(
        token,
        app=get_firebase_app(),
        check_revoked=True
    )
