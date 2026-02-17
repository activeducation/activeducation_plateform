"""Admin settings and announcements endpoints."""

from uuid import UUID
from typing import Optional

from fastapi import APIRouter, Depends, Query, Request

from app.core.logging import get_logger
from app.core.security import get_current_admin, get_current_super_admin
from app.db.supabase_client import get_supabase_client
from app.core.exceptions import NotFoundError


logger = get_logger("api.admin.settings")

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
# APP SETTINGS
# =========================================================================

@router.get("/settings")

async def list_settings(
    request: Request,
    admin: dict = Depends(get_current_super_admin),
):
    """Liste des parametres (super_admin)."""
    db = get_supabase_client()
    return db.fetch_all(table="app_settings", order_by="key.asc")


@router.put("/settings/{key}")

async def update_setting(
    request: Request,
    key: str,
    body: dict,
    admin: dict = Depends(get_current_super_admin),
):
    """Modifier un parametre (super_admin)."""
    db = get_supabase_client()
    import json

    existing = db.client.table("app_settings").select("*").eq("key", key).limit(1).execute()
    if not existing.data:
        # Create if not exists
        result = db.insert(table="app_settings", data={
            "key": key,
            "value": json.dumps(body.get("value")),
            "description": body.get("description", ""),
            "updated_by": str(admin["user_id"]),
        })
    else:
        result = db.client.table("app_settings").update({
            "value": json.dumps(body.get("value")),
            "updated_by": str(admin["user_id"]),
        }).eq("key", key).execute()
        result = result.data

    _log_audit(admin, "update", "setting", key, body)
    return result[0] if result else body


# =========================================================================
# ANNOUNCEMENTS
# =========================================================================

@router.get("/announcements")

async def list_announcements(
    request: Request,
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    is_active: Optional[bool] = Query(None),
    admin: dict = Depends(get_current_admin),
):
    """Liste paginee des annonces."""
    db = get_supabase_client()
    offset = (page - 1) * per_page

    query = db.client.table("announcements").select("*", count="exact")
    if is_active is not None:
        query = query.eq("is_active", is_active)

    result = query.order("created_at", desc=True).range(offset, offset + per_page - 1).execute()

    return {
        "items": result.data,
        "total": result.count or len(result.data),
        "page": page,
        "per_page": per_page,
    }


@router.post("/announcements")

async def create_announcement(
    request: Request,
    body: dict,
    admin: dict = Depends(get_current_admin),
):
    """Creer une annonce."""
    db = get_supabase_client()
    body["created_by"] = str(admin["user_id"])
    result = db.insert(table="announcements", data=body)
    _log_audit(admin, "create", "announcement", result[0].get("id") if result else None, body)
    return result[0] if result else body


@router.put("/announcements/{announcement_id}")

async def update_announcement(
    request: Request,
    announcement_id: UUID,
    body: dict,
    admin: dict = Depends(get_current_admin),
):
    """Modifier une annonce."""
    db = get_supabase_client()
    result = db.update(
        table="announcements", id_column="id",
        id_value=str(announcement_id), data=body,
    )
    if not result:
        raise NotFoundError("Annonce", str(announcement_id))
    _log_audit(admin, "update", "announcement", announcement_id, body)
    return result[0]


@router.delete("/announcements/{announcement_id}")

async def delete_announcement(
    request: Request,
    announcement_id: UUID,
    admin: dict = Depends(get_current_admin),
):
    """Supprimer une annonce."""
    db = get_supabase_client()
    db.delete(table="announcements", id_column="id", id_value=str(announcement_id))
    _log_audit(admin, "delete", "announcement", announcement_id)
    return {"success": True, "message": "Annonce supprimee"}


# =========================================================================
# AUDIT LOG
# =========================================================================

@router.get("/audit-log")

async def list_audit_log(
    request: Request,
    page: int = Query(1, ge=1),
    per_page: int = Query(50, ge=1, le=200),
    entity_type: Optional[str] = Query(None),
    admin: dict = Depends(get_current_super_admin),
):
    """Journal d'audit (super_admin uniquement)."""
    db = get_supabase_client()
    offset = (page - 1) * per_page

    query = db.client.table("admin_audit_log").select(
        "*, user_profiles(email, first_name, last_name)", count="exact"
    )
    if entity_type:
        query = query.eq("entity_type", entity_type)

    result = query.order("created_at", desc=True).range(offset, offset + per_page - 1).execute()

    return {
        "items": result.data,
        "total": result.count or len(result.data),
        "page": page,
        "per_page": per_page,
    }
