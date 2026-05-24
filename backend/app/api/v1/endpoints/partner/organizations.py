"""
Endpoints API pour les organisations partenaires et beneficaires.

Gere:
- Creation et gestion des organisations (CDEJ, ONG)
- Creation et gestion des dossiers beneficiaires
"""

from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, Request, Query

from app.core.logging import get_logger
from app.core.security import get_current_user_id, get_current_user_role
from app.schemas.partner import (
    OrganizationCreate,
    OrganizationUpdate,
    OrganizationResponse,
    OrganizationListResponse,
    BeneficiaryCreate,
    BeneficiaryUpdate,
    BeneficiaryResponse,
    BeneficiaryListResponse,
    OrganizationWithStats,
)
from app.services.partner_service import get_partner_service, PartnerService
from app.middleware.rate_limiter import standard_limit

logger = get_logger("api.partner")

router = APIRouter(prefix="/partner", tags=["partner"])


def get_service() -> PartnerService:
    """Dependency pour obtenir le service partenaire."""
    return get_partner_service()


# =============================================================================
# ORGANIZATIONS
# =============================================================================


@router.post("/organizations", response_model=OrganizationResponse, status_code=201)
@standard_limit()
async def create_organization(
    request: Request,
    body: OrganizationCreate,
    user_id: UUID = Depends(get_current_user_id),
    service: PartnerService = Depends(get_service),
):
    """
    Cree une nouvelle organisation partenaire.

    L'utilisateur courant devient l'administrateur de l'organisation.
    """
    return await service.create_organization(body, user_id)


@router.get("/organizations", response_model=OrganizationListResponse)
@standard_limit()
async def list_organizations(
    request: Request,
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page"),
    is_active: Optional[bool] = Query(None, description="Filter by active status"),
    is_approved: Optional[bool] = Query(None, description="Filter by approved status"),
    org_type: Optional[str] = Query(None, description="Filter by organization type"),
    user_id: UUID = Depends(get_current_user_id),
    user_role: str = Depends(get_current_user_role),
    service: PartnerService = Depends(get_service),
):
    """Liste les organisations avec pagination."""
    # Restriction RBAC : les non-admins ne voient que les organisations approuvées et actives
    admin_roles = ("admin", "super_admin", "partner_admin")
    if user_role not in admin_roles:
        is_approved = True
        is_active = True

    return await service.list_organizations(
        page=page,
        page_size=page_size,
        is_active=is_active,
        is_approved=is_approved,
        org_type=org_type,
    )


@router.get("/organizations/{org_id}", response_model=OrganizationResponse)
@standard_limit()
async def get_organization(
    request: Request,
    org_id: UUID,
    user_id: UUID = Depends(get_current_user_id),
    service: PartnerService = Depends(get_service),
):
    """Recupere une organisation par son ID."""
    return await service.get_organization(org_id, user_id=user_id)


@router.get("/organizations/{org_id}/stats", response_model=OrganizationWithStats)
@standard_limit()
async def get_organization_stats(
    request: Request,
    org_id: UUID,
    user_id: UUID = Depends(get_current_user_id),
    service: PartnerService = Depends(get_service),
):
    """Recupere une organisation avec ses statistiques."""
    return await service.get_organization_with_stats(org_id, user_id)


@router.patch("/organizations/{org_id}", response_model=OrganizationResponse)
@standard_limit()
async def update_organization(
    request: Request,
    org_id: UUID,
    body: OrganizationUpdate,
    user_id: UUID = Depends(get_current_user_id),
    service: PartnerService = Depends(get_service),
):
    """Met a jour une organisation."""
    return await service.update_organization(org_id, body, user_id)


# =============================================================================
# BENEFICIARIES
# =============================================================================


@router.post(
    "/organizations/{org_id}/beneficiaries",
    response_model=BeneficiaryResponse,
    status_code=201,
)
@standard_limit()
async def create_beneficiary(
    request: Request,
    org_id: UUID,
    body: BeneficiaryCreate,
    user_id: UUID = Depends(get_current_user_id),
    service: PartnerService = Depends(get_service),
):
    """Cree un nouveau dossier de beneficiaire pour une organisation."""
    return await service.create_beneficiary(org_id, body, user_id)


@router.get("/organizations/{org_id}/beneficiaries", response_model=BeneficiaryListResponse)
@standard_limit()
async def list_beneficiaries(
    request: Request,
    org_id: UUID,
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page"),
    status: Optional[str] = Query(None, description="Filter by status"),
    user_id: UUID = Depends(get_current_user_id),
    service: PartnerService = Depends(get_service),
):
    """Liste les beneficiaires d'une organisation."""
    return await service.list_beneficiaries(
        organization_id=org_id,
        user_id=user_id,
        page=page,
        page_size=page_size,
        status=status,
    )


@router.get("/beneficiaries/{beneficiary_id}", response_model=BeneficiaryResponse)
@standard_limit()
async def get_beneficiary(
    request: Request,
    beneficiary_id: UUID,
    user_id: UUID = Depends(get_current_user_id),
    service: PartnerService = Depends(get_service),
):
    """Recupere un beneficiaire par son ID."""
    return await service.get_beneficiary(beneficiary_id, user_id)


@router.patch("/beneficiaries/{beneficiary_id}", response_model=BeneficiaryResponse)
@standard_limit()
async def update_beneficiary(
    request: Request,
    beneficiary_id: UUID,
    body: BeneficiaryUpdate,
    user_id: UUID = Depends(get_current_user_id),
    service: PartnerService = Depends(get_service),
):
    """Met a jour un beneficiaire."""
    return await service.update_beneficiary(beneficiary_id, body, user_id)


@router.delete("/beneficiaries/{beneficiary_id}")
@standard_limit()
async def delete_beneficiary(
    request: Request,
    beneficiary_id: UUID,
    user_id: UUID = Depends(get_current_user_id),
    service: PartnerService = Depends(get_service),
):
    """Desactive un beneficiaire."""
    await service.delete_beneficiary(beneficiary_id, user_id)
    return {"success": True, "message": "Beneficiaire desactive"}