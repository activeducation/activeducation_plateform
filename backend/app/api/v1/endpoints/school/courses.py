"""School admin courses endpoints."""

from fastapi import APIRouter, Depends

from app.core.logging import get_logger
from app.core.security import get_current_school_admin
from app.core.exceptions import NotFoundError
from app.schemas.school_admin import (
    SchoolCourseCreate,
    SchoolCourseUpdate,
    SchoolCourseResponse,
    PublishRequest,
)
from app.repositories.school_admin_repository import get_school_admin_repository

logger = get_logger("api.school.courses")

router = APIRouter()


@router.get("/courses")
async def list_courses(admin: dict = Depends(get_current_school_admin)):
    """Liste les cours de l'ecole."""
    repo = get_school_admin_repository()
    courses = repo.get_courses(admin["school_id"])
    return {"courses": courses, "total": len(courses)}


@router.post("/courses", status_code=201)
async def create_course(
    body: SchoolCourseCreate,
    admin: dict = Depends(get_current_school_admin),
):
    """Cree un nouveau cours pour l'ecole."""
    repo = get_school_admin_repository()
    data = body.model_dump(exclude_none=True)
    course = repo.create_course(admin["school_id"], data)
    logger.info(f"Course created by school admin {admin['user_id']}: {course.get('id')}")
    return course


@router.get("/courses/{course_id}")
async def get_course(
    course_id: str,
    admin: dict = Depends(get_current_school_admin),
):
    """Detail d'un cours (avec modules et lecons)."""
    repo = get_school_admin_repository()
    course = repo.get_course(course_id, admin["school_id"])
    if not course:
        raise NotFoundError("Cours", course_id)
    return course


@router.put("/courses/{course_id}")
async def update_course(
    course_id: str,
    body: SchoolCourseUpdate,
    admin: dict = Depends(get_current_school_admin),
):
    """Met a jour un cours."""
    repo = get_school_admin_repository()
    data = body.model_dump(exclude_none=True)
    if not data:
        raise NotFoundError("Cours", course_id)
    course = repo.update_course(course_id, admin["school_id"], data)
    if not course:
        raise NotFoundError("Cours", course_id)
    return course


@router.delete("/courses/{course_id}")
async def delete_course(
    course_id: str,
    admin: dict = Depends(get_current_school_admin),
):
    """Supprime un cours."""
    repo = get_school_admin_repository()
    deleted = repo.delete_course(course_id, admin["school_id"])
    if not deleted:
        raise NotFoundError("Cours", course_id)
    return {"success": True, "message": "Cours supprime"}


@router.patch("/courses/{course_id}/publish")
async def toggle_publish(
    course_id: str,
    body: PublishRequest,
    admin: dict = Depends(get_current_school_admin),
):
    """Active/desactive la publication d'un cours."""
    repo = get_school_admin_repository()
    course = repo.publish_course(course_id, admin["school_id"], body.is_published)
    if not course:
        raise NotFoundError("Cours", course_id)
    status_msg = "publie" if body.is_published else "depublie"
    return {"success": True, "message": f"Cours {status_msg}", "course": course}
