import os
from threading import Lock

import firebase_admin
from firebase_admin import auth

_init_lock = Lock()


def get_firebase_app():
    with _init_lock:
        try:
            return firebase_admin.get_app()
        except ValueError:
            return firebase_admin.initialize_app(
                options={
                    "projectId": os.getenv(
                        "FIREBASE_PROJECT_ID",
                        "gizilens-32aa6"
                    )
                }
            )


def verify_firebase_token(token: str) -> dict:
    return auth.verify_id_token(
        token,
        app=get_firebase_app(),
        check_revoked=True
    )
