"""Admin opportunities management endpoints."""

from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, Query

from app.core.logging import get_logger
from app.core.security import get_current_admin
from app.schemas.admin.opportunities import (
    OpportunityCreate,
    OpportunityDetail,
    OpportunityListResponse,
    OpportunityType,
    OpportunityUpdate,
)

logger = get_logger("api.admin.opportunities")

router = APIRouter()


def _get_repo():
    from app.repositories.admin.opportunities_repository import get_opportunities_admin_repository

    return get_opportunities_admin_repository()


def _log_audit(admin, action, entity_type, entity_id, changes=None):
    try:
        from app.db.supabase_client import get_admin_supabase_client

        db = get_admin_supabase_client()
        db.client.table("admin_audit_log").insert(
            {
                "admin_id": str(admin["user_id"]),
                "action": action,
                "entity_type": entity_type,
                "entity_id": str(entity_id) if entity_id else None,
                "changes": changes,
            }
        ).execute()
    except Exception:
        logger.error("Audit log failed, blocking action", exc_info=True)
        raise


@router.get("", response_model=OpportunityListResponse)
async def list_opportunities(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    search: Optional[str] = None,
    opportunity_type: Optional[OpportunityType] = None,
    is_published: Optional[bool] = None,
    admin: dict = Depends(get_current_admin),
):
    """Liste des opportunités avec pagination."""
    repo = _get_repo()
    return repo.list_opportunities(
        page=page,
        per_page=per_page,
        search=search,
        opportunity_type=opportunity_type,
        is_published=is_published,
    )


@router.get("/{opportunity_id}", response_model=OpportunityDetail)
async def get_opportunity(
    opportunity_id: UUID,
    admin: dict = Depends(get_current_admin),
):
    """Détail d'une opportunité."""
    repo = _get_repo()
    return repo.get_opportunity(opportunity_id)


@router.post("", response_model=OpportunityDetail, status_code=201)
async def create_opportunity(
    data: OpportunityCreate,
    admin: dict = Depends(get_current_admin),
):
    """Créer une nouvelle opportunité."""
    repo = _get_repo()
    opportunity = repo.create_opportunity(data, admin["user_id"])
    _log_audit(admin, "create", "opportunity", opportunity.id)
    return opportunity


@router.put("/{opportunity_id}", response_model=OpportunityDetail)
async def update_opportunity(
    opportunity_id: UUID,
    data: OpportunityUpdate,
    admin: dict = Depends(get_current_admin),
):
    """Mettre à jour une opportunité."""
    repo = _get_repo()
    opportunity = repo.update_opportunity(opportunity_id, data)
    _log_audit(admin, "update", "opportunity", opportunity_id, data.model_dump(exclude_unset=True))
    return opportunity


@router.delete("/{opportunity_id}")
async def delete_opportunity(
    opportunity_id: UUID,
    admin: dict = Depends(get_current_admin),
):
    """Supprimer une opportunité."""
    repo = _get_repo()
    repo.delete_opportunity(opportunity_id)
    _log_audit(admin, "delete", "opportunity", opportunity_id)
    return {"success": True, "message": "Opportunité supprimée"}


@router.patch("/{opportunity_id}/publish")
async def toggle_publish(
    opportunity_id: UUID,
    is_published: bool,
    admin: dict = Depends(get_current_admin),
):
    """Publier ou masquer une opportunité."""
    repo = _get_repo()
    opportunity = repo.toggle_publish(opportunity_id, is_published)
    action = "publish" if is_published else "unpublish"
    _log_audit(admin, action, "opportunity", opportunity_id)
    status = "publiée" if is_published else "masquée"
    return {"success": True, "message": f"Opportunité {status}", "opportunity": opportunity}


@router.patch("/{opportunity_id}/featured")
async def toggle_featured(
    opportunity_id: UUID,
    is_featured: bool,
    admin: dict = Depends(get_current_admin),
):
    """Mettre ou retirer une opportunité en featured."""
    repo = _get_repo()
    opportunity = repo.toggle_featured(opportunity_id, is_featured)
    action = "feature" if is_featured else "unfeature"
    _log_audit(admin, action, "opportunity", opportunity_id)
    status = "envedette" if is_featured else "retirée des vedettes"
    return {"success": True, "message": f"Opportunité {status}", "opportunity": opportunity}
