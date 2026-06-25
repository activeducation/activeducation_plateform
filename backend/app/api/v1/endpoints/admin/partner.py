"""Admin endpoints pour la gestion des organisations partenaires."""

from uuid import UUID

from fastapi import APIRouter, Depends

from app.core.logging import get_logger
from app.core.security import get_current_admin
from app.schemas.partner import OrganizationResponse
from app.services.partner_service import PartnerService, get_partner_service

logger = get_logger("api.admin.partner")

router = APIRouter()


@router.post(
    "/partner/organizations/{org_id}/approve",
    response_model=OrganizationResponse,
)
async def approve_organization(
    org_id: UUID,
    admin: dict = Depends(get_current_admin),
    service: PartnerService = Depends(get_partner_service),
):
    """Approuve une organisation partenaire (admin uniquement)."""
    admin_id = (
        admin["user_id"] if isinstance(admin["user_id"], UUID) else UUID(str(admin["user_id"]))
    )
    return await service.approve_organization(org_id, admin_id)
