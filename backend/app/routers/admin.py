from fastapi import APIRouter, Depends

from app.dependencies import require_admin

router = APIRouter(
    prefix="/admin",
    tags=["admin"]
)


@router.get("/me")
def get_admin_profile(
    user: dict = Depends(require_admin)
):
    email = user.get("email", "")

    return {
        "uid": user["uid"],
        "name": user.get("name") or email.split("@")[0],
        "email": email,
        "role": "admin",
        "institution": "GiziLens",
        "status": "Verified",
        "createdAtLabel": "-"
    }
