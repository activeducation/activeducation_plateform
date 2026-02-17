"""Admin gamification management endpoints."""

from uuid import UUID
from typing import Optional

from fastapi import APIRouter, Depends, Query, Request

from app.core.logging import get_logger
from app.core.security import get_current_admin
from app.db.supabase_client import get_supabase_client
from app.core.exceptions import NotFoundError


logger = get_logger("api.admin.gamification")

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


# =========================================================================
# ACHIEVEMENTS
# =========================================================================

@router.get("/achievements")

async def list_achievements(
    request: Request,
    admin: dict = Depends(get_current_admin),
):
    """Liste des achievements."""
    db = get_supabase_client()
    return db.fetch_all(table="achievements", order_by="category.asc")


@router.post("/achievements")

async def create_achievement(
    request: Request,
    body: dict,
    admin: dict = Depends(get_current_admin),
):
    """Creer un achievement."""
    db = get_supabase_client()
    result = db.insert(table="achievements", data=body)
    _log_audit(admin, "create", "achievement", result[0].get("id") if result else None, body)
    return result[0] if result else body


@router.put("/achievements/{achievement_id}")

async def update_achievement(
    request: Request,
    achievement_id: UUID,
    body: dict,
    admin: dict = Depends(get_current_admin),
):
    """Modifier un achievement."""
    db = get_supabase_client()
    result = db.update(table="achievements", id_column="id", id_value=str(achievement_id), data=body)
    if not result:
        raise NotFoundError("Achievement", str(achievement_id))
    _log_audit(admin, "update", "achievement", achievement_id, body)
    return result[0]


@router.delete("/achievements/{achievement_id}")

async def delete_achievement(
    request: Request,
    achievement_id: UUID,
    admin: dict = Depends(get_current_admin),
):
    """Supprimer un achievement."""
    db = get_supabase_client()
    db.delete(table="achievements", id_column="id", id_value=str(achievement_id))
    _log_audit(admin, "delete", "achievement", achievement_id)
    return {"success": True, "message": "Achievement supprime"}


# =========================================================================
# CHALLENGES
# =========================================================================

@router.get("/challenges")

async def list_challenges(
    request: Request,
    admin: dict = Depends(get_current_admin),
):
    """Liste des challenges."""
    db = get_supabase_client()
    return db.fetch_all(table="challenges", order_by="created_at.desc")


@router.post("/challenges")

async def create_challenge(
    request: Request,
    body: dict,
    admin: dict = Depends(get_current_admin),
):
    """Creer un challenge."""
    db = get_supabase_client()
    result = db.insert(table="challenges", data=body)
    _log_audit(admin, "create", "challenge", result[0].get("id") if result else None, body)
    return result[0] if result else body


@router.put("/challenges/{challenge_id}")

async def update_challenge(
    request: Request,
    challenge_id: UUID,
    body: dict,
    admin: dict = Depends(get_current_admin),
):
    """Modifier un challenge."""
    db = get_supabase_client()
    result = db.update(table="challenges", id_column="id", id_value=str(challenge_id), data=body)
    if not result:
        raise NotFoundError("Challenge", str(challenge_id))
    _log_audit(admin, "update", "challenge", challenge_id, body)
    return result[0]


@router.delete("/challenges/{challenge_id}")

async def delete_challenge(
    request: Request,
    challenge_id: UUID,
    admin: dict = Depends(get_current_admin),
):
    """Supprimer un challenge."""
    db = get_supabase_client()
    db.delete(table="challenges", id_column="id", id_value=str(challenge_id))
    _log_audit(admin, "delete", "challenge", challenge_id)
    return {"success": True, "message": "Challenge supprime"}
