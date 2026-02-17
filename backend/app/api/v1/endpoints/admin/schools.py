"""Admin schools management endpoints."""

from uuid import UUID
from typing import Optional

from fastapi import APIRouter, Depends, Query, Request

from app.core.logging import get_logger
from app.core.security import get_current_admin, get_current_super_admin
from app.repositories.admin.schools_repository import get_schools_admin_repository
from app.schemas.admin.schools import (
    SchoolListResponse,
    SchoolDetail,
    SchoolCreate,
    SchoolUpdate,
    ProgramCreate,
    ProgramUpdate,
    ImageCreate,
)


logger = get_logger("api.admin.schools")

router = APIRouter()


def _log_audit(admin, action, entity_type, entity_id, changes=None):
    try:
        from app.db.supabase_client import get_supabase_client
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
# SCHOOLS CRUD
# =========================================================================

@router.get("", response_model=SchoolListResponse)

async def list_schools(
    request: Request,
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    search: Optional[str] = Query(None),
    city: Optional[str] = Query(None),
    type: Optional[str] = Query(None),
    is_verified: Optional[bool] = Query(None),
    admin: dict = Depends(get_current_admin),
):
    """Liste paginee des ecoles."""
    repo = get_schools_admin_repository()
    return await repo.list_schools(
        page=page, per_page=per_page, search=search,
        city=city, school_type=type, is_verified=is_verified,
    )


@router.get("/{school_id}", response_model=SchoolDetail)

async def get_school(
    request: Request,
    school_id: UUID,
    admin: dict = Depends(get_current_admin),
):
    """Detail d'une ecole avec programmes et images."""
    repo = get_schools_admin_repository()
    return await repo.get_school_detail(school_id)


@router.post("", response_model=SchoolDetail)

async def create_school(
    request: Request,
    body: SchoolCreate,
    admin: dict = Depends(get_current_admin),
):
    """Creer une ecole."""
    repo = get_schools_admin_repository()
    result = await repo.create_school(body)
    _log_audit(admin, "create", "school", result.id, body.model_dump())
    return result


@router.put("/{school_id}", response_model=SchoolDetail)

async def update_school(
    request: Request,
    school_id: UUID,
    body: SchoolUpdate,
    admin: dict = Depends(get_current_admin),
):
    """Modifier une ecole."""
    repo = get_schools_admin_repository()
    result = await repo.update_school(school_id, body)
    _log_audit(admin, "update", "school", school_id, body.model_dump(exclude_unset=True))
    return result


@router.delete("/{school_id}")

async def delete_school(
    request: Request,
    school_id: UUID,
    admin: dict = Depends(get_current_super_admin),
):
    """Supprimer une ecole (super_admin)."""
    repo = get_schools_admin_repository()
    await repo.delete_school(school_id)
    _log_audit(admin, "delete", "school", school_id)
    return {"success": True, "message": "Ecole supprimee"}


@router.patch("/{school_id}/verify")

async def toggle_verify(
    request: Request,
    school_id: UUID,
    admin: dict = Depends(get_current_admin),
):
    """Basculer la verification d'une ecole."""
    repo = get_schools_admin_repository()
    result = await repo.toggle_verify(school_id)
    _log_audit(admin, "verify", "school", school_id, {"is_verified": result["is_verified"]})
    return result


@router.patch("/{school_id}/toggle-active")

async def toggle_active(
    request: Request,
    school_id: UUID,
    admin: dict = Depends(get_current_admin),
):
    """Basculer l'etat actif d'une ecole."""
    repo = get_schools_admin_repository()
    result = await repo.toggle_active(school_id)
    _log_audit(admin, "toggle_active", "school", school_id)
    return result


# =========================================================================
# PROGRAMS
# =========================================================================

@router.post("/{school_id}/programs")

async def add_program(
    request: Request,
    school_id: UUID,
    body: ProgramCreate,
    admin: dict = Depends(get_current_admin),
):
    """Ajouter une filiere a une ecole."""
    repo = get_schools_admin_repository()
    result = await repo.add_program(school_id, body)
    _log_audit(admin, "create", "school_program", result.get("id"), body.model_dump())
    return result


@router.put("/{school_id}/programs/{program_id}")

async def update_program(
    request: Request,
    school_id: UUID,
    program_id: UUID,
    body: ProgramUpdate,
    admin: dict = Depends(get_current_admin),
):
    """Modifier une filiere."""
    repo = get_schools_admin_repository()
    result = await repo.update_program(program_id, body)
    _log_audit(admin, "update", "school_program", program_id, body.model_dump(exclude_unset=True))
    return result


@router.delete("/{school_id}/programs/{program_id}")

async def delete_program(
    request: Request,
    school_id: UUID,
    program_id: UUID,
    admin: dict = Depends(get_current_admin),
):
    """Supprimer une filiere."""
    repo = get_schools_admin_repository()
    await repo.delete_program(program_id)
    _log_audit(admin, "delete", "school_program", program_id)
    return {"success": True, "message": "Filiere supprimee"}


# =========================================================================
# IMAGES
# =========================================================================

@router.post("/{school_id}/images")

async def add_image(
    request: Request,
    school_id: UUID,
    body: ImageCreate,
    admin: dict = Depends(get_current_admin),
):
    """Ajouter une image a une ecole."""
    repo = get_schools_admin_repository()
    result = await repo.add_image(school_id, body)
    _log_audit(admin, "create", "school_image", result.get("id"))
    return result


@router.delete("/{school_id}/images/{image_id}")

async def delete_image(
    request: Request,
    school_id: UUID,
    image_id: UUID,
    admin: dict = Depends(get_current_admin),
):
    """Supprimer une image d'une ecole."""
    repo = get_schools_admin_repository()
    await repo.delete_image(image_id)
    _log_audit(admin, "delete", "school_image", image_id)
    return {"success": True, "message": "Image supprimee"}
