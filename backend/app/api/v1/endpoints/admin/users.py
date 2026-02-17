"""Admin users management endpoints."""

from uuid import UUID
from typing import Optional

from fastapi import APIRouter, Depends, Query, Request

from app.core.logging import get_logger
from app.core.security import get_current_admin, get_current_super_admin
from app.core.exceptions import AuthorizationError
from app.repositories.admin.users_admin_repository import get_users_admin_repository
from app.schemas.admin.users import (
    AdminUserListResponse,
    AdminUserDetail,
    AdminUserUpdate,
    RoleUpdateRequest,
)


logger = get_logger("api.admin.users")

router = APIRouter()


@router.get("", response_model=AdminUserListResponse)

async def list_users(
    request: Request,
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    search: Optional[str] = Query(None),
    role: Optional[str] = Query(None),
    is_active: Optional[bool] = Query(None),
    admin: dict = Depends(get_current_admin),
):
    """Liste paginee des utilisateurs avec recherche et filtres."""
    repo = get_users_admin_repository()
    return await repo.list_users(
        page=page, per_page=per_page, search=search, role=role, is_active=is_active
    )


@router.get("/{user_id}", response_model=AdminUserDetail)

async def get_user(
    request: Request,
    user_id: UUID,
    admin: dict = Depends(get_current_admin),
):
    """Detail d'un utilisateur avec resume d'activite."""
    repo = get_users_admin_repository()
    return await repo.get_user_detail(user_id)


@router.patch("/{user_id}", response_model=AdminUserDetail)

async def update_user(
    request: Request,
    user_id: UUID,
    body: AdminUserUpdate,
    admin: dict = Depends(get_current_admin),
):
    """Met a jour un utilisateur."""
    repo = get_users_admin_repository()
    result = await repo.update_user(user_id, body)
    _log_audit(admin, "update", "user", user_id, body.model_dump(exclude_unset=True))
    return result


@router.patch("/{user_id}/role")

async def update_user_role(
    request: Request,
    user_id: UUID,
    body: RoleUpdateRequest,
    admin: dict = Depends(get_current_super_admin),
):
    """Change le role d'un utilisateur (super_admin uniquement)."""
    repo = get_users_admin_repository()
    result = await repo.update_role(user_id, body.role)
    _log_audit(admin, "update_role", "user", user_id, {"new_role": body.role})
    return result


@router.patch("/{user_id}/deactivate")

async def deactivate_user(
    request: Request,
    user_id: UUID,
    admin: dict = Depends(get_current_admin),
):
    """Desactive un utilisateur."""
    repo = get_users_admin_repository()
    result = await repo.toggle_active(user_id, False)
    _log_audit(admin, "deactivate", "user", user_id, {"is_active": False})
    return result


@router.patch("/{user_id}/activate")

async def activate_user(
    request: Request,
    user_id: UUID,
    admin: dict = Depends(get_current_admin),
):
    """Reactive un utilisateur."""
    repo = get_users_admin_repository()
    result = await repo.toggle_active(user_id, True)
    _log_audit(admin, "activate", "user", user_id, {"is_active": True})
    return result


def _log_audit(admin, action, entity_type, entity_id, changes):
    try:
        from app.db.supabase_client import get_supabase_client
        db = get_supabase_client()
        db.insert(table="admin_audit_log", data={
            "admin_id": str(admin["user_id"]),
            "action": action,
            "entity_type": entity_type,
            "entity_id": str(entity_id),
            "changes": changes,
        })
    except Exception as e:
        logger.warning(f"Audit log failed: {e}")
