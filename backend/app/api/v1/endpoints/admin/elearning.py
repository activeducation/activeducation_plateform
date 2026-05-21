"""Admin e-learning courses management endpoints."""

from typing import Optional

from fastapi import APIRouter, Depends, Query

from app.core.logging import get_logger
from app.core.security import get_current_admin
from app.db.supabase_client import get_admin_supabase_client
from app.schemas.admin.elearning import (
    CourseCreate,
    CourseUpdate,
    ModuleCreate,
    ModuleUpdate,
    LessonCreate,
    LessonUpdate,
)

logger = get_logger("api.admin.elearning")

router = APIRouter()


def _log_audit(admin, action, entity_type, entity_id, changes=None):
    try:
        from app.db.supabase_client import get_admin_supabase_client
        db = get_admin_supabase_client()
        db.client.table("admin_audit_log").insert({
            "admin_id": str(admin["user_id"]),
            "action": action,
            "entity_type": entity_type,
            "entity_id": str(entity_id) if entity_id else None,
            "changes": changes,
        }).execute()
    except Exception:
        logger.error("Audit log failed, blocking action", exc_info=True)
        raise


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
        safe = search.replace("%", r"\%").replace("_", r"\_")
        query = query.or_(f"title.ilike.%{safe}%,description.ilike.%{safe}%")

    result = query.order("created_at", desc=True).range(offset, offset + per_page - 1).execute()
    courses = result.data or []
    total = result.count or 0

    if not courses:
        return {"items": [], "total": 0, "page": page,
                "per_page": per_page, "total_pages": 0}

    course_ids = [c["id"] for c in courses]

    # Requête 1 : comptes modules (batch)
    mod_res = db.client.table("elearning_modules").select(
        "course_id", count="exact"
    ).in_("course_id", course_ids).execute()
    modules_by_course: dict[str, int] = {}
    for row in (mod_res.data or []):
        cid = row["course_id"]
        modules_by_course[cid] = modules_by_course.get(cid, 0) + 1

    # Requête 2 : comptes leçons (batch)
    les_res = db.client.table("elearning_lessons").select(
        "course_id", count="exact"
    ).in_("course_id", course_ids).execute()
    lessons_by_course: dict[str, int] = {}
    for row in (les_res.data or []):
        cid = row["course_id"]
        lessons_by_course[cid] = lessons_by_course.get(cid, 0) + 1

    # Requête 3 : noms d'écoles (batch)
    school_ids = list({c["school_id"] for c in courses if c.get("school_id")})
    schools_map: dict[str, str] = {}
    if school_ids:
        sch_res = db.client.table("schools").select(
            "id, name"
        ).in_("id", school_ids).execute()
        schools_map = {s["id"]: s["name"] for s in (sch_res.data or [])}

    # Enrichissement en mémoire
    for course in courses:
        course["modules_count"] = modules_by_course.get(course["id"], 0)
        course["lessons_count"] = lessons_by_course.get(course["id"], 0)
        course["school_name"] = schools_map.get(course.get("school_id"))

    total_pages = (total + per_page - 1) // per_page
    return {"items": courses, "total": total, "page": page,
            "per_page": per_page, "total_pages": total_pages}


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

    db.client.table("elearning_courses").delete().eq("id", course_id).execute()

    _log_audit(admin, "delete", "elearning_course", course_id)
    return {"success": True, "message": "Cours supprimé"}


@router.post("/courses", status_code=201)
async def create_course(
    body: CourseCreate,
    admin: dict = Depends(get_current_admin),
):
    """Créer un nouveau cours e-learning."""
    db = get_admin_supabase_client()

    course_data = body.model_dump()
    course_data["is_published"] = False

    result = db.client.table("elearning_courses").insert(course_data).execute()

    if not result.data:
        from app.core.exceptions import DatabaseError
        raise DatabaseError("Erreur lors de la création du cours", operation="insert_course")

    course = result.data[0]
    _log_audit(admin, "create", "elearning_course", course["id"])
    return course


@router.put("/courses/{course_id}")
async def update_course(
    course_id: str,
    body: CourseUpdate,
    admin: dict = Depends(get_current_admin),
):
    """Mettre à jour un cours e-learning."""
    db = get_admin_supabase_client()

    existing = db.client.table("elearning_courses").select("id").eq("id", course_id).execute()
    if not existing.data:
        from app.core.exceptions import NotFoundError
        raise NotFoundError("Cours", course_id)

    update_data = body.model_dump(exclude_unset=True)
    if not update_data:
        return existing.data[0]

    result = db.client.table("elearning_courses").update(update_data).eq("id", course_id).execute()
    course = result.data[0]
    _log_audit(admin, "update", "elearning_course", course_id, update_data)
    return course


@router.post("/courses/{course_id}/modules")
async def create_module(
    course_id: str,
    body: ModuleCreate,
    admin: dict = Depends(get_current_admin),
):
    """Créer un module dans un cours."""
    db = get_admin_supabase_client()

    course = db.client.table("elearning_courses").select("id").eq("id", course_id).execute()
    if not course.data:
        from app.core.exceptions import NotFoundError
        raise NotFoundError("Cours", course_id)

    module_data = body.model_dump()
    module_data["course_id"] = course_id
    result = db.client.table("elearning_modules").insert(module_data).execute()

    if not result.data:
        from app.core.exceptions import DatabaseError
        raise DatabaseError("Erreur lors de la création du module", operation="insert_module")

    _log_audit(admin, "create", "elearning_module", result.data[0]["id"])
    return result.data[0]


@router.put("/modules/{module_id}")
async def update_module(
    module_id: str,
    body: ModuleUpdate,
    admin: dict = Depends(get_current_admin),
):
    """Mettre à jour un module."""
    db = get_admin_supabase_client()

    existing = db.client.table("elearning_modules").select("id").eq("id", module_id).execute()
    if not existing.data:
        from app.core.exceptions import NotFoundError
        raise NotFoundError("Module", module_id)

    update_data = body.model_dump(exclude_unset=True)
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

    db.client.table("elearning_modules").delete().eq("id", module_id).execute()

    _log_audit(admin, "delete", "elearning_module", module_id)
    return {"success": True, "message": "Module supprimé"}


@router.post("/modules/{module_id}/lessons")
async def create_lesson(
    module_id: str,
    body: LessonCreate,
    admin: dict = Depends(get_current_admin),
):
    """Creer une lecon dans un module."""
    db = get_admin_supabase_client()

    module = db.client.table("elearning_modules").select("id, course_id").eq("id", module_id).execute()
    if not module.data:
        from app.core.exceptions import NotFoundError
        raise NotFoundError("Module", module_id)

    lesson_data = body.model_dump()
    lesson_data["module_id"] = module_id
    lesson_data["course_id"] = module.data[0]["course_id"]
    result = db.client.table("elearning_lessons").insert(lesson_data).execute()

    if not result.data:
        from app.core.exceptions import DatabaseError
        raise DatabaseError("Erreur lors de la création de la leçon", operation="insert_lesson")

    _log_audit(admin, "create", "elearning_lesson", result.data[0]["id"])
    return result.data[0]


@router.put("/lessons/{lesson_id}")
async def update_lesson(
    lesson_id: str,
    body: LessonUpdate,
    admin: dict = Depends(get_current_admin),
):
    """Mettre à jour une leçon."""
    db = get_admin_supabase_client()

    existing = db.client.table("elearning_lessons").select("id").eq("id", lesson_id).execute()
    if not existing.data:
        from app.core.exceptions import NotFoundError
        raise NotFoundError("Leçon", lesson_id)

    update_data = body.model_dump(exclude_unset=True)
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

    result = db.client.table("elearning_courses").select(
        "school_id"
    ).not_.is_("school_id", "null").execute()

    counts: dict[str, int] = {}
    for row in (result.data or []):
        sid = row["school_id"]
        counts[sid] = counts.get(sid, 0) + 1

    if not counts:
        return []

    sch_res = db.client.table("schools").select(
        "id, name, city"
    ).in_("id", list(counts.keys())).execute()

    return [
        {
            "id": s["id"],
            "name": s["name"],
            "city": s.get("city"),
            "courses_count": counts.get(s["id"], 0),
        }
        for s in (sch_res.data or [])
    ]