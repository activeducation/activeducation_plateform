"""School admin lessons endpoints."""

from fastapi import APIRouter, Depends, UploadFile, File

from app.core.logging import get_logger
from app.core.security import get_current_school_admin
from app.core.exceptions import NotFoundError
from app.schemas.school_admin import SchoolLessonCreate, SchoolLessonUpdate
from app.repositories.school_admin_repository import get_school_admin_repository

logger = get_logger("api.school.lessons")

router = APIRouter()


@router.get("/modules/{module_id}/lessons")
async def list_lessons(
    module_id: str,
    admin: dict = Depends(get_current_school_admin),
):
    """Liste les lecons d'un module de l'ecole."""
    repo = get_school_admin_repository()
    lessons = repo.get_lessons(module_id, admin["school_id"])
    return {"lessons": lessons, "total": len(lessons)}


@router.post("/modules/{module_id}/lessons", status_code=201)
async def create_lesson(
    module_id: str,
    body: SchoolLessonCreate,
    admin: dict = Depends(get_current_school_admin),
):
    """Cree une nouvelle lecon dans un module."""
    repo = get_school_admin_repository()
    data = body.model_dump(exclude_none=True)
    lesson = repo.create_lesson(module_id, admin["school_id"], data)
    if not lesson:
        raise NotFoundError("Module", module_id)
    return lesson


@router.put("/lessons/{lesson_id}")
async def update_lesson(
    lesson_id: str,
    body: SchoolLessonUpdate,
    admin: dict = Depends(get_current_school_admin),
):
    """Met a jour une lecon."""
    repo = get_school_admin_repository()
    data = body.model_dump(exclude_none=True)
    if not data:
        raise NotFoundError("Lecon", lesson_id)
    lesson = repo.update_lesson(lesson_id, admin["school_id"], data)
    if not lesson:
        raise NotFoundError("Lecon", lesson_id)
    return lesson


@router.delete("/lessons/{lesson_id}")
async def delete_lesson(
    lesson_id: str,
    admin: dict = Depends(get_current_school_admin),
):
    """Supprime une lecon."""
    repo = get_school_admin_repository()
    deleted = repo.delete_lesson(lesson_id, admin["school_id"])
    if not deleted:
        raise NotFoundError("Lecon", lesson_id)
    return {"success": True, "message": "Lecon supprimee"}


@router.post("/lessons/{lesson_id}/upload-video")
async def upload_video(
    lesson_id: str,
    file: UploadFile = File(...),
    admin: dict = Depends(get_current_school_admin),
):
    """
    Upload une video pour une lecon via Supabase Storage.
    Stocke l'URL dans le contenu de la lecon.
    """
    from app.db.supabase_client import get_supabase_client

    db = get_supabase_client()

    # Verifier l'appartenance de la lecon
    lesson = db.client.table("elearning_lessons").select("module_id").eq("id", lesson_id).limit(1).execute()
    if not lesson.data:
        raise NotFoundError("Lecon", lesson_id)

    repo = get_school_admin_repository()
    if not repo._verify_module_ownership(lesson.data[0]["module_id"], admin["school_id"]):
        raise NotFoundError("Lecon", lesson_id)

    # Upload vers Supabase Storage
    content = await file.read()
    file_path = f"school/{admin['school_id']}/lessons/{lesson_id}/{file.filename}"

    try:
        db.client.storage.from_("elearning-videos").upload(
            path=file_path,
            file=content,
            file_options={"content-type": file.content_type or "video/mp4"},
        )
    except Exception as e:
        # Si le fichier existe, on le remplace
        if "Duplicate" in str(e) or "already exists" in str(e):
            db.client.storage.from_("elearning-videos").update(
                path=file_path,
                file=content,
                file_options={"content-type": file.content_type or "video/mp4"},
            )
        else:
            raise

    # Construire l'URL publique
    public_url = db.client.storage.from_("elearning-videos").get_public_url(file_path)

    # Mettre a jour le contenu de la lecon
    existing = db.client.table("elearning_lesson_content").select("id").eq("lesson_id", lesson_id).limit(1).execute()
    video_data = {"video_url": public_url, "type": "video"}
    if existing.data:
        db.client.table("elearning_lesson_content").update({"content_data": video_data}).eq("lesson_id", lesson_id).execute()
    else:
        db.client.table("elearning_lesson_content").insert({"lesson_id": lesson_id, "content_data": video_data}).execute()

    logger.info(f"Video uploaded for lesson {lesson_id} by school admin {admin['user_id']}")

    return {
        "success": True,
        "video_url": public_url,
        "message": "Video uploadee avec succes",
    }
