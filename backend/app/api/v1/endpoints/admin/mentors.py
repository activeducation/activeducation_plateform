"""Admin mentors management endpoints."""

from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, Query, Request

from app.core.exceptions import NotFoundError
from app.core.logging import get_logger
from app.core.security import get_current_admin
from app.db.supabase_client import get_admin_supabase_client
from app.repositories.mentor_repository import get_mentor_repository
from app.schemas.mentor import (
    MentorCreate,
    MentorTaskCreate,
    MentorTaskResponse,
    MentorTaskUpdate,
)

from ._helpers import log_audit_action

logger = get_logger("api.admin.mentors")

router = APIRouter()


@router.get("")
async def list_mentors(
    request: Request,
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    search: Optional[str] = Query(None),
    is_verified: Optional[bool] = Query(None),
    is_active: Optional[bool] = Query(None),
    admin: dict = Depends(get_current_admin),
):
    """Liste paginee des mentors."""
    db = get_admin_supabase_client()
    offset = (page - 1) * per_page

    query = db.client.table("mentors").select(
        "*, user_profiles(email, first_name, last_name, avatar_url)", count="exact"
    )

    if is_verified is not None:
        query = query.eq("is_verified", is_verified)
    if is_active is not None:
        query = query.eq("is_active", is_active)

    result = query.order("created_at", desc=True).range(offset, offset + per_page - 1).execute()

    if result.data:
        logger.info(f"Mentors data sample: full_name={result.data[0].get('full_name')!r}, profession={result.data[0].get('profession')!r}, user_id={result.data[0].get('user_id')!r}, user_profiles={result.data[0].get('user_profiles')!r}")

    return {
        "items": result.data,
        "total": result.count or len(result.data),
        "page": page,
        "per_page": per_page,
    }


@router.get("/{mentor_id}")
async def get_mentor(
    request: Request,
    mentor_id: UUID,
    admin: dict = Depends(get_current_admin),
):
    """Detail d'un mentor."""
    db = get_admin_supabase_client()
    result = (
        db.client.table("mentors")
        .select("*, user_profiles(email, first_name, last_name, avatar_url, phone_number)")
        .eq("id", str(mentor_id))
        .limit(1)
        .execute()
    )

    if not result.data:
        raise NotFoundError("Mentor", str(mentor_id))

    return result.data[0]


@router.patch("/{mentor_id}/verify")
async def toggle_verify_mentor(
    request: Request,
    mentor_id: UUID,
    admin: dict = Depends(get_current_admin),
):
    """Basculer la verification d'un mentor."""
    db = get_admin_supabase_client()
    mentor = db.fetch_one(table="mentors", id_column="id", id_value=str(mentor_id))
    if not mentor:
        raise NotFoundError("Mentor", str(mentor_id))

    new_value = not mentor.get("is_verified", False)
    result = db.update(
        table="mentors",
        id_column="id",
        id_value=str(mentor_id),
        data={"is_verified": new_value},
    )
    log_audit_action(admin, "verify", "mentor", mentor_id, {"is_verified": new_value})
    return result[0] if result else {"is_verified": new_value}


@router.patch("/{mentor_id}/toggle-active")
async def toggle_active_mentor(
    request: Request,
    mentor_id: UUID,
    admin: dict = Depends(get_current_admin),
):
    """Basculer l'etat actif d'un mentor."""
    db = get_admin_supabase_client()
    mentor = db.fetch_one(table="mentors", id_column="id", id_value=str(mentor_id))
    if not mentor:
        raise NotFoundError("Mentor", str(mentor_id))

    new_value = not mentor.get("is_active", True)
    result = db.update(
        table="mentors",
        id_column="id",
        id_value=str(mentor_id),
        data={"is_active": new_value},
    )
    log_audit_action(admin, "toggle_active", "mentor", mentor_id, {"is_active": new_value})
    return result[0] if result else {"is_active": new_value}


# ============================================================================
# CREATION DIRECTE D'UN MENTOR
# ============================================================================


@router.post("", status_code=201)
async def create_mentor(
    body: MentorCreate,
    admin: dict = Depends(get_current_admin),
):
    """Cree un mentor directement (sans candidature)."""
    repo = get_mentor_repository()
    data = body.model_dump(exclude_none=True)
    data.setdefault("profession", data.get("specialty"))
    data["source"] = "manual"
    data.setdefault("is_active", True)
    data["is_verified"] = True
    if not data.get("bio"):
        data["bio"] = "Mentor"
    mentor = repo.create_mentor(data)
    log_audit_action(admin, "create", "mentor", mentor.get("id"), {"full_name": body.full_name})
    return mentor


# ============================================================================
# TACHES ASSIGNEES AUX MENTORS
# ============================================================================


@router.get("/{mentor_id}/tasks")
async def list_mentor_tasks(
    mentor_id: UUID,
    admin: dict = Depends(get_current_admin),
):
    """Liste les taches d'un mentor."""
    return {"items": get_mentor_repository().list_tasks(mentor_id)}


@router.post("/{mentor_id}/tasks", response_model=MentorTaskResponse, status_code=201)
async def create_mentor_task(
    mentor_id: UUID,
    body: MentorTaskCreate,
    admin: dict = Depends(get_current_admin),
):
    """Assigne une tache a un mentor."""
    db = get_admin_supabase_client()
    mentor = db.fetch_one(table="mentors", id_column="id", id_value=str(mentor_id))
    if not mentor:
        raise NotFoundError("Mentor", str(mentor_id))

    data = body.model_dump(exclude_none=True)
    data["assigned_by"] = str(admin["user_id"])
    task = get_mentor_repository().create_task(mentor_id, data)
    log_audit_action(admin, "create", "mentor_task", task.get("id"), {"title": body.title})
    return task


@router.patch("/tasks/{task_id}", response_model=MentorTaskResponse)
async def update_mentor_task(
    task_id: UUID,
    body: MentorTaskUpdate,
    admin: dict = Depends(get_current_admin),
):
    """Met a jour une tache mentor (statut, priorite...)."""
    changes = body.model_dump(exclude_none=True)
    if not changes:
        raise NotFoundError("Tâche", str(task_id))
    task = get_mentor_repository().update_task(task_id, changes)
    if not task:
        raise NotFoundError("Tâche", str(task_id))
    log_audit_action(admin, "update", "mentor_task", task_id, changes)
    return task


@router.delete("/tasks/{task_id}", status_code=204)
async def delete_mentor_task(
    task_id: UUID,
    admin: dict = Depends(get_current_admin),
):
    """Supprime une tache mentor."""
    get_mentor_repository().delete_task(task_id)
    log_audit_action(admin, "delete", "mentor_task", task_id, None)
    return None
