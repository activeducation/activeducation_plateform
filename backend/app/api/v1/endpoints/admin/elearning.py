"""Admin e-learning courses management endpoints."""

from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, Query

from app.core.cache import invalidate_cache
from app.core.logging import get_logger
from app.core.security import get_current_admin
from app.db.supabase_client import get_admin_supabase_client
from app.repositories.exam_repository import get_exam_repository
from app.schemas.admin.elearning import (
    CourseCreate,
    CourseUpdate,
    LessonCreate,
    LessonUpdate,
    ModuleCreate,
    ModuleUpdate,
)
from app.schemas.exam import ExamResponse, ExamUpsert
from ._helpers import log_audit_action

logger = get_logger("api.admin.elearning")

router = APIRouter()


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
    if is_published is not None:
        query = query.eq("is_published", is_published)
    if search:
        safe = search.replace("%", r"\%").replace("_", r"\_")
        query = query.or_(f"title.ilike.%{safe}%,description.ilike.%{safe}%")

    result = query.order("created_at", desc=True).range(offset, offset + per_page - 1).execute()
    courses = result.data or []
    total = result.count or 0

    if not courses:
        return {"items": [], "total": 0, "page": page, "per_page": per_page, "total_pages": 0}

    course_ids = [c["id"] for c in courses]

    # Requête 1 : comptes modules (batch)
    mod_res = (
        db.client.table("elearning_modules")
        .select("id, course_id")
        .in_("course_id", course_ids)
        .execute()
    )
    modules_by_course: dict[str, int] = {}
    module_ids: list[str] = []
    for row in mod_res.data or []:
        cid = row["course_id"]
        modules_by_course[cid] = modules_by_course.get(cid, 0) + 1
        module_ids.append(row["id"])

    # Requête 2 : comptes leçons via module_id (batch)
    lessons_by_course: dict[str, int] = {}
    if module_ids:
        les_res = (
            db.client.table("elearning_lessons")
            .select("module_id", count="exact")
            .in_("module_id", module_ids)
            .execute()
        )
        lessons_by_module: dict[str, int] = {}
        for row in les_res.data or []:
            mid = row["module_id"]
            lessons_by_module[mid] = lessons_by_module.get(mid, 0) + 1

        module_to_course = {r["id"]: r["course_id"] for r in (mod_res.data or [])}
        for mid, count in lessons_by_module.items():
            cid = module_to_course.get(mid)
            if cid:
                lessons_by_course[cid] = lessons_by_course.get(cid, 0) + count

    # Enrichissement en mémoire
    for course in courses:
        course["modules_count"] = modules_by_course.get(course["id"], 0)
        course["lessons_count"] = lessons_by_course.get(course["id"], 0)

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

    modules = (
        db.client.table("elearning_modules")
        .select("*")
        .eq("course_id", course_id)
        .order("display_order")
        .execute()
    )
    course_data["modules"] = modules.data or []

    for module in course_data["modules"]:
        lessons = (
            db.client.table("elearning_lessons")
            .select("*")
            .eq("module_id", module["id"])
            .order("display_order")
            .execute()
        )
        module["lessons"] = lessons.data or []

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

    log_audit_action(admin, "delete", "elearning_course", course_id)
    invalidate_cache("elearning:courses:*")
    invalidate_cache("elearning:course:*")
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
    log_audit_action(admin, "create", "elearning_course", course["id"])
    invalidate_cache("elearning:courses:*")
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
    log_audit_action(admin, "update", "elearning_course", course_id, update_data)

    invalidate_cache("elearning:courses:*")
    invalidate_cache("elearning:course:*")

    if body.is_published is True:
        try:
            from app.core import email as email_service
            await email_service.notify_internal(
                subject=f"Cours publié : {course.get('title', 'Sans titre')}",
                html_body=f"<p>Le cours <b>{course.get('title', 'Sans titre')}</b> a été publié par {admin.get('full_name', admin.get('email', 'Admin'))}.</p>",
            )
        except Exception:
            pass

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

    log_audit_action(admin, "create", "elearning_module", result.data[0]["id"])
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
    log_audit_action(admin, "update", "elearning_module", module_id, update_data)
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

    log_audit_action(admin, "delete", "elearning_module", module_id)
    return {"success": True, "message": "Module supprimé"}


def _build_content_data(body: LessonCreate) -> dict:
    """Construit le content_data JSONB selon le type de lecon."""
    content_data: dict = {}
    if body.lesson_type == "video":
        content_data["url"] = body.video_url or ""
        content_data["provider"] = body.video_provider or "youtube"
        content_data["duration_seconds"] = 0
    elif body.lesson_type in ("article", "text"):
        content_data["body"] = body.markdown_body or body.content or ""
        content_data["format"] = "markdown"
    elif body.lesson_type == "challenge":
        content_data["instructions"] = body.challenge_instructions or ""
        content_data["starter_code"] = body.challenge_starter_code or ""
        content_data["language"] = body.challenge_language or ""
    elif body.lesson_type == "quiz":
        # Quiz integre dans la lecon (non-examen de fin de cours)
        content_data["questions"] = []
    elif body.lesson_type == "pdf":
        content_data["url"] = body.content or ""
        content_data["filename"] = ""
    return content_data


@router.post("/modules/{module_id}/lessons")
async def create_lesson(
    module_id: str,
    body: LessonCreate,
    admin: dict = Depends(get_current_admin),
):
    """Creer une lecon dans un module."""
    db = get_admin_supabase_client()

    module = (
        db.client.table("elearning_modules").select("id, course_id").eq("id", module_id).execute()
    )
    if not module.data:
        from app.core.exceptions import NotFoundError

        raise NotFoundError("Module", module_id)

    lesson_data = {
        "module_id": module_id,
        "title": body.title,
        "lesson_type": body.lesson_type,
        "display_order": body.display_order,
    }
    result = db.client.table("elearning_lessons").insert(lesson_data).execute()

    if not result.data:
        from app.core.exceptions import DatabaseError

        raise DatabaseError("Erreur lors de la création de la leçon", operation="insert_lesson")

    lesson_id = result.data[0]["id"]

    # Creer le contenu structure si applicable
    content_data = _build_content_data(body)
    if content_data:
        db.client.table("elearning_lesson_content").insert(
            {"lesson_id": lesson_id, "content_data": content_data}
        ).execute()

    log_audit_action(admin, "create", "elearning_lesson", lesson_id)
    return result.data[0]


@router.put("/lessons/{lesson_id}")
async def update_lesson(
    lesson_id: str,
    body: LessonUpdate,
    admin: dict = Depends(get_current_admin),
):
    """Mettre à jour une leçon."""
    db = get_admin_supabase_client()

    existing = db.client.table("elearning_lessons").select("id, lesson_type").eq("id", lesson_id).execute()
    if not existing.data:
        from app.core.exceptions import NotFoundError

        raise NotFoundError("Leçon", lesson_id)

    lesson_type = body.lesson_type or existing.data[0]["lesson_type"]
    update_data = body.model_dump(exclude_unset=True)
    if not update_data:
        return existing.data[0]

    result = db.client.table("elearning_lessons").update(update_data).eq("id", lesson_id).execute()

    # Mettre a jour le contenu structure si fourni
    content_data = _build_content_data_update(body, lesson_type)
    if content_data is not None:
        existing_content = (
            db.client.table("elearning_lesson_content")
            .select("id")
            .eq("lesson_id", lesson_id)
            .limit(1)
            .execute()
        )
        if existing_content.data:
            db.client.table("elearning_lesson_content").update(
                {"content_data": content_data}
            ).eq("lesson_id", lesson_id).execute()
        elif content_data:
            db.client.table("elearning_lesson_content").insert(
                {"lesson_id": lesson_id, "content_data": content_data}
            ).execute()

    log_audit_action(admin, "update", "elearning_lesson", lesson_id, update_data)
    return result.data[0]


def _build_content_data_update(body: LessonUpdate, lesson_type: str) -> Optional[dict]:
    """Construit le content_data pour les mises a jour, ou None si rien a changer."""
    content_data: Optional[dict] = None
    if lesson_type == "video" and (body.video_url is not None or body.video_provider is not None):
        content_data = {}
        if body.video_url is not None:
            content_data["url"] = body.video_url
        if body.video_provider is not None:
            content_data["provider"] = body.video_provider
    elif lesson_type in ("article", "text") and body.markdown_body is not None:
        content_data = {"body": body.markdown_body, "format": "markdown"}
    elif lesson_type == "challenge" and (
        body.challenge_instructions is not None
        or body.challenge_starter_code is not None
        or body.challenge_language is not None
    ):
        content_data = {}
        if body.challenge_instructions is not None:
            content_data["instructions"] = body.challenge_instructions
        if body.challenge_starter_code is not None:
            content_data["starter_code"] = body.challenge_starter_code
        if body.challenge_language is not None:
            content_data["language"] = body.challenge_language
    return content_data


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

    log_audit_action(admin, "delete", "elearning_lesson", lesson_id)
    return {"success": True, "message": "Leçon supprimée"}


@router.get("/schools")
async def list_schools_with_courses(
    search: Optional[str] = Query(None, description="Recherche par nom (ILIKE)"),
    page: int = Query(1, ge=1, description="Numero de page"),
    per_page: int = Query(50, ge=1, le=100, description="Resultats par page"),
    admin: dict = Depends(get_current_admin),
):
    """Liste paginee des ecoles actives pour le selecteur de cours.

    Audit #13 (2026-07-30) : l'ancien endpoint faisait un SELECT * FROM
    schools ORDER BY name, ce qui retournait toutes les ecoles (actives
    + desactivees) d'un coup. Avec ~100 ecoles c'est OK, mais le contrat
    de pagination est attendu par le frontend (memes query params que les
    autres listes admin) et le filtre is_active evitait de proposer une
    ecole archivee dans le selecteur.

    Fix :
    - Filtre is_active=True par defaut
    - Pagination avec cap a 100 (defaut 50, adapte aux selecteurs)
    - Recherche par nom optionnelle (ILIKE %search%)
    - Reponse { items, total, page, per_page } pour coherence
    """
    db = get_admin_supabase_client()
    offset = (page - 1) * per_page

    query = db.client.table("schools").select("id, name, city", count="exact").eq("is_active", True)
    if search:
        query = query.ilike("name", f"%{search}%")

    result = query.order("name").range(offset, offset + per_page - 1).execute()

    items = [
        {
            "id": s["id"],
            "name": s["name"],
            "city": s.get("city"),
            "courses_count": 0,
        }
        for s in (result.data or [])
    ]
    return {
        "items": items,
        "total": result.count or len(items),
        "page": page,
        "per_page": per_page,
    }


# ============================================================================
# DUPLICATION
# ============================================================================


@router.post("/courses/{course_id}/duplicate")
async def duplicate_course(
    course_id: str,
    body: dict = {},  # {"new_title": "Copie de ..."} optionnel
    admin: dict = Depends(get_current_admin),
):
    """Duplique un cours : metadonnees, modules, lecons, contenu, examen."""
    db = get_admin_supabase_client()

    # 1. Charger le cours source
    course = db.client.table("elearning_courses").select("*").eq("id", course_id).execute()
    if not course.data:
        from app.core.exceptions import NotFoundError
        raise NotFoundError("Cours", course_id)
    src = course.data[0]

    # 2. Creer le nouveau cours
    new_title = body.get("new_title") or f"{src['title']} (copie)"
    new_course = {
        "title": new_title,
        "description": src.get("description"),
        "thumbnail_url": src.get("thumbnail_url"),
        "category": src.get("category"),
        "difficulty": src.get("difficulty", "debutant"),
        "duration_minutes": src.get("duration_minutes", 0),
        "points_reward": src.get("points_reward", 0),
        "is_published": False,
        "display_order": 999,
    }
    res = db.client.table("elearning_courses").insert(new_course).execute()
    new_course_id = res.data[0]["id"]

    # 3. Copier les modules
    modules = (
        db.client.table("elearning_modules")
        .select("*")
        .eq("course_id", course_id)
        .order("display_order")
        .execute()
    )
    module_id_map: dict[str, str] = {}
    for mod in modules.data or []:
        new_mod = {
            "course_id": new_course_id,
            "title": mod["title"],
            "description": mod.get("description"),
            "display_order": mod["display_order"],
        }
        r = db.client.table("elearning_modules").insert(new_mod).execute()
        old_id = mod["id"]
        new_id = r.data[0]["id"]
        module_id_map[old_id] = new_id

    # 4. Copier les lecons + contenu
    for old_mod_id, new_mod_id in module_id_map.items():
        lessons = (
            db.client.table("elearning_lessons")
            .select("*")
            .eq("module_id", old_mod_id)
            .order("display_order")
            .execute()
        )
        for les in lessons.data or []:
            new_lesson = {
                "module_id": new_mod_id,
                "title": les["title"],
                "lesson_type": les["lesson_type"],
                "duration_minutes": les.get("duration_minutes", 0),
                "points_reward": les.get("points_reward", 0),
                "is_free": les.get("is_free", False),
                "display_order": les["display_order"],
            }
            r = db.client.table("elearning_lessons").insert(new_lesson).execute()
            new_lesson_id = r.data[0]["id"]

            # Copier le contenu structure
            content = (
                db.client.table("elearning_lesson_content")
                .select("content_data")
                .eq("lesson_id", les["id"])
                .limit(1)
                .execute()
            )
            if content.data:
                db.client.table("elearning_lesson_content").insert(
                    {"lesson_id": new_lesson_id, "content_data": content.data[0]["content_data"]}
                ).execute()

    # 5. Copier l'examen
    exam = (
        db.client.table("course_exams")
        .select("*")
        .eq("course_id", course_id)
        .limit(1)
        .execute()
    )
    if exam.data:
        src_exam = exam.data[0]
        new_exam = {
            "course_id": new_course_id,
            "title": src_exam.get("title", "Examen final"),
            "description": src_exam.get("description"),
            "passing_score": src_exam.get("passing_score", 80),
            "xp_reward": src_exam.get("xp_reward", 100),
            "badge_title": src_exam.get("badge_title"),
            "badge_icon": src_exam.get("badge_icon"),
            "is_active": False,
        }
        r = db.client.table("course_exams").insert(new_exam).execute()
        new_exam_id = r.data[0]["id"]

        # Copier les questions
        questions = (
            db.client.table("exam_questions")
            .select("*")
            .eq("exam_id", src_exam["id"])
            .order("display_order")
            .execute()
        )
        for q in questions.data or []:
            db.client.table("exam_questions").insert(
                {
                    "exam_id": new_exam_id,
                    "question": q["question"],
                    "options": q["options"],
                    "points": q.get("points", 1),
                    "display_order": q["display_order"],
                }
            ).execute()

    log_audit_action(admin, "duplicate", "elearning_course", new_course_id)
    invalidate_cache("elearning:courses:*")
    return {"id": new_course_id, "title": new_title, "message": "Cours dupliqué avec succès"}


# ============================================================================
# REORDONNANCEMENT
# ============================================================================


@router.put("/courses/{course_id}/modules/reorder")
async def reorder_modules(
    course_id: str,
    body: dict,  # {"module_ids": ["uuid1", "uuid2", ...]}
    admin: dict = Depends(get_current_admin),
):
    """Reordonne les modules d'un cours par ordre de module_ids."""
    db = get_admin_supabase_client()
    module_ids = body.get("module_ids", [])
    for i, mid in enumerate(module_ids):
        db.client.table("elearning_modules").update({"display_order": i}).eq("id", mid).eq(
            "course_id", course_id
        ).execute()
    log_audit_action(admin, "reorder", "elearning_module", course_id, {"count": len(module_ids)})
    return {"success": True}


@router.put("/modules/{module_id}/lessons/reorder")
async def reorder_lessons(
    module_id: str,
    body: dict,  # {"lesson_ids": ["uuid1", "uuid2", ...]}
    admin: dict = Depends(get_current_admin),
):
    """Reordonne les lecons d'un module par ordre de lesson_ids."""
    db = get_admin_supabase_client()
    lesson_ids = body.get("lesson_ids", [])
    for i, lid in enumerate(lesson_ids):
        db.client.table("elearning_lessons").update({"display_order": i}).eq("id", lid).eq(
            "module_id", module_id
        ).execute()
    log_audit_action(admin, "reorder", "elearning_lesson", module_id, {"count": len(lesson_ids)})
    return {"success": True}


# ============================================================================
# EXAMENS DE COURS (QCM + badge)
# ============================================================================


@router.get("/courses/{course_id}/exam")
async def get_course_exam(
    course_id: UUID,
    admin: dict = Depends(get_current_admin),
):
    """Recupere l'examen d'un cours (avec questions + bonnes reponses)."""
    exam = get_exam_repository().get_exam_by_course(course_id)
    return exam or {}


@router.put("/courses/{course_id}/exam", response_model=ExamResponse)
async def upsert_course_exam(
    course_id: UUID,
    body: ExamUpsert,
    admin: dict = Depends(get_current_admin),
):
    """Cree ou met a jour l'examen d'un cours (+ ses questions QCM)."""
    questions = [q.model_dump() for q in body.questions]
    data = body.model_dump(exclude={"questions"})
    exam = get_exam_repository().upsert_exam(course_id, data, questions)
    log_audit_action(admin, "upsert", "course_exam", course_id, {"questions": len(questions)})
    return exam


@router.delete("/courses/{course_id}/exam", status_code=204)
async def delete_course_exam(
    course_id: UUID,
    admin: dict = Depends(get_current_admin),
):
    """Supprime l'examen d'un cours."""
    get_exam_repository().delete_exam(course_id)
    log_audit_action(admin, "delete", "course_exam", course_id, None)
    return None
