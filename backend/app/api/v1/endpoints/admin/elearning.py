"""Admin e-learning courses management endpoints."""

from uuid import UUID
from typing import Optional

from fastapi import APIRouter, Depends, Query

from app.core.logging import get_logger
from app.core.security import get_current_admin
from app.db.supabase_client import get_admin_supabase_client

logger = get_logger("api.admin.elearning")

router = APIRouter()


def _log_audit(admin, action, entity_type, entity_id, changes=None):
    try:
        from app.db.supabase_client import get_supabase_client
        db = get_supabase_client()
        db.table("admin_audit_log").insert({
            "admin_id": str(admin["user_id"]),
            "action": action,
            "entity_type": entity_type,
            "entity_id": str(entity_id) if entity_id else None,
            "changes": changes,
        })
    except Exception as e:
        logger.warning(f"Audit log failed: {e}")


@router.get("/courses")
async def list_all_courses(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    search: Optional[str] = None,
    school_id: Optional[str] = None,
    is_published: Optional[bool] = None,
    admin: dict = Depends(get_current_admin),
):
    """Liste de tous les cours e-learning (toutes écoles)."""
    db = get_admin_supabase_client()
    offset = (page - 1) * per_page

    query = db.client.table("elearning_courses").select("*", count="exact")

    if school_id:
        query = query.eq("school_id", school_id)
    if is_published is not None:
        query = query.eq("is_published", is_published)
    if search:
        query = query.or_(f"title.ilike.%{search}%,description.ilike.%{search}%")

    result = query.order("created_at", desc=True).range(offset, offset + per_page - 1).execute()

    courses = result.data or []
    total = result.count or 0

    for course in courses:
        modules_count = 0
        lessons_count = 0
        try:
            mc = db.client.table("elearning_modules").select("id", count="exact").eq("course_id", course["id"]).execute()
            modules_count = mc.count or 0
            lc = db.client.table("elearning_lessons").select("id", count="exact").eq("course_id", course["id"]).execute()
            lessons_count = lc.count or 0
        except Exception:
            pass
        course["modules_count"] = modules_count
        course["lessons_count"] = lessons_count

        if course.get("school_id"):
            school = db.client.table("schools").select("name").eq("id", course["school_id"]).execute()
            course["school_name"] = school.data[0]["name"] if school.data else None

    total_pages = (total + per_page - 1) // per_page

    return {
        "items": courses,
        "total": total,
        "page": page,
        "per_page": per_page,
        "total_pages": total_pages,
    }


@router.get("/courses/{course_id}")
async def get_course(
    course_id: str,
    admin: dict = Depends(get_current_admin),
):
    """Détail d'un cours e-learning."""
    db = get_admin_supabase_client()

    course = db.client.table("elearning_courses").select("*").eq("id", course_id).execute()

    if not course.data:
        from app.core.exceptions import NotFoundError
        raise NotFoundError("Cours", course_id)

    course_data = course.data[0]

    modules = db.client.table("elearning_modules").select("*").eq("course_id", course_id).order("display_order").execute()
    course_data["modules"] = modules.data or []

    for module in course_data["modules"]:
        lessons = db.client.table("elearning_lessons").select("*").eq("module_id", module["id"]).order("display_order").execute()
        module["lessons"] = lessons.data or []

    if course_data.get("school_id"):
        school = db.client.table("schools").select("name").eq("id", course_data["school_id"]).execute()
        course_data["school_name"] = school.data[0]["name"] if school.data else None

    return course_data


@router.delete("/courses/{course_id}")
async def delete_course(
    course_id: str,
    admin: dict = Depends(get_current_admin),
):
    """Supprimer un cours e-learning."""
    db = get_admin_supabase_client()

    course = db.client.table("elearning_courses").select("id").eq("id", course_id).execute()
    if not course.data:
        from app.core.exceptions import NotFoundError
        raise NotFoundError("Cours", course_id)

    db.client.table("elearning_lessons").delete().eq("course_id", course_id).execute()
    db.client.table("elearning_modules").delete().eq("course_id", course_id).execute()
    db.client.table("elearning_courses").delete().eq("id", course_id).execute()

    _log_audit(admin, "delete", "elearning_course", course_id)
    return {"success": True, "message": "Cours supprimé"}


@router.post("/courses", status_code=201)
async def create_course(
    title: str,
    description: str,
    school_id: Optional[str] = None,
    thumbnail_url: Optional[str] = None,
    level: str = "beginner",
    admin: dict = Depends(get_current_admin),
):
    """Créer un nouveau cours e-learning."""
    db = get_admin_supabase_client()

    course_data = {
        "title": title,
        "description": description,
        "level": level,
        "is_published": False,
    }
    if school_id:
        course_data["school_id"] = school_id
    if thumbnail_url:
        course_data["thumbnail_url"] = thumbnail_url

    result = db.client.table("elearning_courses").insert(course_data).execute()

    if not result.data:
        from app.core.exceptions import BadRequestError
        raise BadRequestError("Erreur lors de la création du cours")

    course = result.data[0]
    _log_audit(admin, "create", "elearning_course", course["id"])
    return course


@router.put("/courses/{course_id}")
async def update_course(
    course_id: str,
    title: Optional[str] = None,
    description: Optional[str] = None,
    thumbnail_url: Optional[str] = None,
    level: Optional[str] = None,
    is_published: Optional[bool] = None,
    admin: dict = Depends(get_current_admin),
):
    """Mettre à jour un cours e-learning."""
    db = get_admin_supabase_client()

    existing = db.client.table("elearning_courses").select("id").eq("id", course_id).execute()
    if not existing.data:
        from app.core.exceptions import NotFoundError
        raise NotFoundError("Cours", course_id)

    update_data = {}
    if title is not None:
        update_data["title"] = title
    if description is not None:
        update_data["description"] = description
    if thumbnail_url is not None:
        update_data["thumbnail_url"] = thumbnail_url
    if level is not None:
        update_data["level"] = level
    if is_published is not None:
        update_data["is_published"] = is_published

    if not update_data:
        return existing.data[0]

    result = db.client.table("elearning_courses").update(update_data).eq("id", course_id).execute()
    course = result.data[0]
    _log_audit(admin, "update", "elearning_course", course_id, update_data)
    return course


@router.post("/courses/{course_id}/modules")
async def create_module(
    course_id: str,
    title: str,
    description: Optional[str] = None,
    display_order: int = 0,
    admin: dict = Depends(get_current_admin),
):
    """Créer un module dans un cours."""
    db = get_admin_supabase_client()

    course = db.client.table("elearning_courses").select("id").eq("id", course_id).execute()
    if not course.data:
        from app.core.exceptions import NotFoundError
        raise NotFoundError("Cours", course_id)

    module_data = {
        "course_id": course_id,
        "title": title,
        "description": description,
        "display_order": display_order,
    }
    result = db.client.table("elearning_modules").insert(module_data).execute()

    if not result.data:
        from app.core.exceptions import BadRequestError
        raise BadRequestError("Erreur lors de la création du module")

    _log_audit(admin, "create", "elearning_module", result.data[0]["id"])
    return result.data[0]


@router.put("/modules/{module_id}")
async def update_module(
    module_id: str,
    title: Optional[str] = None,
    description: Optional[str] = None,
    display_order: Optional[int] = None,
    admin: dict = Depends(get_current_admin),
):
    """Mettre à jour un module."""
    db = get_admin_supabase_client()

    existing = db.client.table("elearning_modules").select("id").eq("id", module_id).execute()
    if not existing.data:
        from app.core.exceptions import NotFoundError
        raise NotFoundError("Module", module_id)

    update_data = {}
    if title is not None:
        update_data["title"] = title
    if description is not None:
        update_data["description"] = description
    if display_order is not None:
        update_data["display_order"] = display_order

    if not update_data:
        return existing.data[0]

    result = db.client.table("elearning_modules").update(update_data).eq("id", module_id).execute()
    _log_audit(admin, "update", "elearning_module", module_id, update_data)
    return result.data[0]


@router.delete("/modules/{module_id}")
async def delete_module(
    module_id: str,
    admin: dict = Depends(get_current_admin),
):
    """Supprimer un module et ses leçons."""
    db = get_admin_supabase_client()

    existing = db.client.table("elearning_modules").select("id").eq("id", module_id).execute()
    if not existing.data:
        from app.core.exceptions import NotFoundError
        raise NotFoundError("Module", module_id)

    db.client.table("elearning_lessons").delete().eq("module_id", module_id).execute()
    db.client.table("elearning_modules").delete().eq("id", module_id).execute()

    _log_audit(admin, "delete", "elearning_module", module_id)
    return {"success": True, "message": "Module supprimé"}


@router.post("/modules/{module_id}/lessons")
async def create_lesson(
    module_id: str,
    title: str,
    lesson_type: str = "text",
    content: Optional[str] = None,
    video_url: Optional[str] = None,
    display_order: int = 0,
    admin: dict = Depends(get_current_admin),
):
    """Créer une leçon dans un module."""
    db = get_admin_supabase_client()

    module = db.client.table("elearning_modules").select("id, course_id").eq("id", module_id).execute()
    if not module.data:
        from app.core.exceptions import NotFoundError
        raise NotFoundError("Module", module_id)

    lesson_data = {
        "module_id": module_id,
        "course_id": module.data[0]["course_id"],
        "title": title,
        "lesson_type": lesson_type,
        "content": content,
        "video_url": video_url,
        "display_order": display_order,
    }
    result = db.client.table("elearning_lessons").insert(lesson_data).execute()

    if not result.data:
        from app.core.exceptions import BadRequestError
        raise BadRequestError("Erreur lors de la création de la leçon")

    _log_audit(admin, "create", "elearning_lesson", result.data[0]["id"])
    return result.data[0]


@router.put("/lessons/{lesson_id}")
async def update_lesson(
    lesson_id: str,
    title: Optional[str] = None,
    lesson_type: Optional[str] = None,
    content: Optional[str] = None,
    video_url: Optional[str] = None,
    display_order: Optional[int] = None,
    admin: dict = Depends(get_current_admin),
):
    """Mettre à jour une leçon."""
    db = get_admin_supabase_client()

    existing = db.client.table("elearning_lessons").select("id").eq("id", lesson_id).execute()
    if not existing.data:
        from app.core.exceptions import NotFoundError
        raise NotFoundError("Leçon", lesson_id)

    update_data = {}
    if title is not None:
        update_data["title"] = title
    if lesson_type is not None:
        update_data["lesson_type"] = lesson_type
    if content is not None:
        update_data["content"] = content
    if video_url is not None:
        update_data["video_url"] = video_url
    if display_order is not None:
        update_data["display_order"] = display_order

    if not update_data:
        return existing.data[0]

    result = db.client.table("elearning_lessons").update(update_data).eq("id", lesson_id).execute()
    _log_audit(admin, "update", "elearning_lesson", lesson_id, update_data)
    return result.data[0]


@router.delete("/lessons/{lesson_id}")
async def delete_lesson(
    lesson_id: str,
    admin: dict = Depends(get_current_admin),
):
    """Supprimer une leçon."""
    db = get_admin_supabase_client()

    existing = db.client.table("elearning_lessons").select("id").eq("id", lesson_id).execute()
    if not existing.data:
        from app.core.exceptions import NotFoundError
        raise NotFoundError("Leçon", lesson_id)

    db.client.table("elearning_lessons").delete().eq("id", lesson_id).execute()

    _log_audit(admin, "delete", "elearning_lesson", lesson_id)
    return {"success": True, "message": "Leçon supprimée"}


@router.get("/schools")
async def list_schools_with_courses(
    admin: dict = Depends(get_current_admin),
):
    """Liste des écoles qui ont des cours e-learning."""
    db = get_admin_supabase_client()

    result = db.client.table("elearning_courses").select("school_id").execute()
    school_ids = list(set([c["school_id"] for c in (result.data or []) if c.get("school_id")]))

    schools = []
    for sid in school_ids:
        school = db.client.table("schools").select("id, name, city").eq("id", sid).execute()
        if school.data:
            courses_count = db.client.table("elearning_courses").select("id", count="exact").eq("school_id", sid).execute()
            schools.append({
                "id": school.data[0]["id"],
                "name": school.data[0]["name"],
                "city": school.data[0].get("city"),
                "courses_count": courses_count.count or 0,
            })

    return schools