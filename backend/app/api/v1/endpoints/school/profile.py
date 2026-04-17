"""School admin profile endpoints."""

from fastapi import APIRouter, Depends, UploadFile, File

from app.core.logging import get_logger
from app.core.security import get_current_school_admin
from app.core.exceptions import NotFoundError
from app.schemas.school_admin import SchoolProfileUpdate
from app.repositories.school_admin_repository import get_school_admin_repository

logger = get_logger("api.school.profile")

router = APIRouter()


@router.get("/profile")
async def get_school_profile(admin: dict = Depends(get_current_school_admin)):
    """Retourne le profil de l'ecole."""
    repo = get_school_admin_repository()
    school = repo.get_school_profile(admin["school_id"])
    if not school:
        raise NotFoundError("Ecole", admin["school_id"])
    return school


@router.put("/profile")
async def update_school_profile(
    body: SchoolProfileUpdate,
    admin: dict = Depends(get_current_school_admin),
):
    """Met a jour le profil de l'ecole."""
    repo = get_school_admin_repository()
    data = body.model_dump(exclude_none=True)
    if not data:
        raise NotFoundError("Ecole", admin["school_id"])
    school = repo.update_school_profile(admin["school_id"], data)
    if not school:
        raise NotFoundError("Ecole", admin["school_id"])
    return school


@router.post("/profile/logo")
async def upload_logo(
    file: UploadFile = File(...),
    admin: dict = Depends(get_current_school_admin),
):
    """Upload le logo de l'ecole."""
    from app.db.supabase_client import get_supabase_client

    db = get_supabase_client()
    content = await file.read()
    file_path = f"school/{admin['school_id']}/logo/{file.filename}"

    try:
        db.client.storage.from_("school-assets").upload(
            path=file_path,
            file=content,
            file_options={"content-type": file.content_type or "image/png"},
        )
    except Exception as e:
        if "Duplicate" in str(e) or "already exists" in str(e):
            db.client.storage.from_("school-assets").update(
                path=file_path,
                file=content,
                file_options={"content-type": file.content_type or "image/png"},
            )
        else:
            raise

    public_url = db.client.storage.from_("school-assets").get_public_url(file_path)

    # Mettre a jour le logo_url
    repo = get_school_admin_repository()
    repo.update_school_profile(admin["school_id"], {"logo_url": public_url})

    logger.info(f"Logo uploaded for school {admin['school_id']}")
    return {"success": True, "logo_url": public_url}
