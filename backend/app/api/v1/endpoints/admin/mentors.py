"""Admin mentors management endpoints."""

from uuid import UUID
from typing import Optional

from fastapi import APIRouter, Depends, Query, Request

from app.core.logging import get_logger
from app.core.security import get_current_admin
from app.db.supabase_client import get_supabase_client
from app.core.exceptions import NotFoundError


logger = get_logger("api.admin.mentors")

router = APIRouter()


def _log_audit(admin, action, entity_type, entity_id, changes=None):
    try:
        db = get_supabase_client()
        db.insert(table="admin_audit_log", data={
            "admin_id": str(admin["user_id"]),
            "action": action,
            "entity_type": entity_type,
            "entity_id": str(entity_id) if entity_id else None,
            "changes": changes,
        })
    except Exception as e:
        logger.warning(f"Audit log failed: {e}")


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
    db = get_supabase_client()
    offset = (page - 1) * per_page

    query = db.client.table("mentors").select(
        "*, user_profiles(email, first_name, last_name, avatar_url)", count="exact"
    )

    if is_verified is not None:
        query = query.eq("is_verified", is_verified)
    if is_active is not None:
        query = query.eq("is_active", is_active)

    result = query.order("created_at", desc=True).range(offset, offset + per_page - 1).execute()

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
    db = get_supabase_client()
    result = db.client.table("mentors").select(
        "*, user_profiles(email, first_name, last_name, avatar_url, phone_number)"
    ).eq("id", str(mentor_id)).limit(1).execute()

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
    db = get_supabase_client()
    mentor = db.fetch_one(table="mentors", id_column="id", id_value=str(mentor_id))
    if not mentor:
        raise NotFoundError("Mentor", str(mentor_id))

    new_value = not mentor.get("is_verified", False)
    result = db.update(
        table="mentors", id_column="id", id_value=str(mentor_id),
        data={"is_verified": new_value},
    )
    _log_audit(admin, "verify", "mentor", mentor_id, {"is_verified": new_value})
    return result[0] if result else {"is_verified": new_value}


@router.patch("/{mentor_id}/toggle-active")

async def toggle_active_mentor(
    request: Request,
    mentor_id: UUID,
    admin: dict = Depends(get_current_admin),
):
    """Basculer l'etat actif d'un mentor."""
    db = get_supabase_client()
    mentor = db.fetch_one(table="mentors", id_column="id", id_value=str(mentor_id))
    if not mentor:
        raise NotFoundError("Mentor", str(mentor_id))

    new_value = not mentor.get("is_active", True)
    result = db.update(
        table="mentors", id_column="id", id_value=str(mentor_id),
        data={"is_active": new_value},
    )
    _log_audit(admin, "toggle_active", "mentor", mentor_id, {"is_active": new_value})
    return result[0] if result else {"is_active": new_value}
