"""Admin careers management endpoints."""

from uuid import UUID
from typing import Optional

from fastapi import APIRouter, Depends, Query, Request

from app.core.logging import get_logger
from app.core.security import get_current_admin, get_current_super_admin
from app.repositories.admin.careers_repository import get_careers_admin_repository
from app.schemas.admin.careers import (
    CareerListResponse,
    CareerDetail,
    CareerCreate,
    CareerUpdate,
    SectorCreate,
    SectorUpdate,
    SectorResponse,
)


logger = get_logger("api.admin.careers")

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
# SECTORS
# =========================================================================

@router.get("/sectors", response_model=list[SectorResponse])

async def list_sectors(
    request: Request,
    admin: dict = Depends(get_current_admin),
):
    """Liste des secteurs."""
    repo = get_careers_admin_repository()
    return await repo.list_sectors()


@router.post("/sectors", response_model=SectorResponse)

async def create_sector(
    request: Request,
    body: SectorCreate,
    admin: dict = Depends(get_current_admin),
):
    """Creer un secteur."""
    repo = get_careers_admin_repository()
    result = await repo.create_sector(body)
    _log_audit(admin, "create", "sector", result.get("id"), body.model_dump())
    return result


@router.put("/sectors/{sector_id}", response_model=SectorResponse)

async def update_sector(
    request: Request,
    sector_id: UUID,
    body: SectorUpdate,
    admin: dict = Depends(get_current_admin),
):
    """Modifier un secteur."""
    repo = get_careers_admin_repository()
    result = await repo.update_sector(sector_id, body)
    _log_audit(admin, "update", "sector", sector_id, body.model_dump(exclude_unset=True))
    return result


@router.delete("/sectors/{sector_id}")

async def delete_sector(
    request: Request,
    sector_id: UUID,
    admin: dict = Depends(get_current_super_admin),
):
    """Supprimer un secteur (super_admin)."""
    repo = get_careers_admin_repository()
    await repo.delete_sector(sector_id)
    _log_audit(admin, "delete", "sector", sector_id)
    return {"success": True, "message": "Secteur supprime"}


# =========================================================================
# CAREERS
# =========================================================================

@router.get("", response_model=CareerListResponse)

async def list_careers(
    request: Request,
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    search: Optional[str] = Query(None),
    sector: Optional[str] = Query(None),
    demand: Optional[str] = Query(None),
    trend: Optional[str] = Query(None),
    admin: dict = Depends(get_current_admin),
):
    """Liste paginee des carrieres."""
    repo = get_careers_admin_repository()
    return await repo.list_careers(
        page=page, per_page=per_page, search=search,
        sector=sector, demand=demand, trend=trend,
    )


@router.get("/{career_id}", response_model=CareerDetail)

async def get_career(
    request: Request,
    career_id: UUID,
    admin: dict = Depends(get_current_admin),
):
    """Detail d'une carriere."""
    repo = get_careers_admin_repository()
    return await repo.get_career_detail(career_id)


@router.post("", response_model=CareerDetail)

async def create_career(
    request: Request,
    body: CareerCreate,
    admin: dict = Depends(get_current_admin),
):
    """Creer une carriere."""
    repo = get_careers_admin_repository()
    result = await repo.create_career(body)
    _log_audit(admin, "create", "career", result.id, body.model_dump())
    return result


@router.put("/{career_id}", response_model=CareerDetail)

async def update_career(
    request: Request,
    career_id: UUID,
    body: CareerUpdate,
    admin: dict = Depends(get_current_admin),
):
    """Modifier une carriere."""
    repo = get_careers_admin_repository()
    result = await repo.update_career(career_id, body)
    _log_audit(admin, "update", "career", career_id, body.model_dump(exclude_unset=True))
    return result


@router.delete("/{career_id}")

async def delete_career(
    request: Request,
    career_id: UUID,
    admin: dict = Depends(get_current_super_admin),
):
    """Supprimer une carriere (super_admin)."""
    repo = get_careers_admin_repository()
    await repo.delete_career(career_id)
    _log_audit(admin, "delete", "career", career_id)
    return {"success": True, "message": "Carriere supprimee"}
