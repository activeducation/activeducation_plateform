"""
Service pour la gestion des organisations partenaires et beneficaires.

Gere la logique metier pour:
- Creation et gestion des organisations (CDEJ, ONG, etc.)
- Creation et gestion des dossiers beneficiaires
"""

from datetime import datetime
from typing import Optional
from uuid import UUID

from functools import lru_cache

from app.core.logging import get_logger
from app.core.cache import get_cache
from app.core.exceptions import (
    NotFoundError,
    AuthorizationError,
)
from app.schemas.partner import (
    OrganizationCreate,
    OrganizationUpdate,
    OrganizationResponse,
    OrganizationListResponse,
    BeneficiaryCreate,
    BeneficiaryUpdate,
    BeneficiaryResponse,
    BeneficiaryListResponse,
    BeneficiarySummary,
    OrganizationWithStats,
)
from app.repositories.partner_repository import (
    get_partner_repository,
    PartnerRepository,
)
import asyncio

from app.db.supabase_client import get_supabase_client
from app.repositories.users_repository import (
    get_users_repository,
    UsersRepository,
)

logger = get_logger("services.partner")


class PartnerService:
    """Service pour la gestion des partenaires et beneficiaires."""

    def __init__(self):
        self._partner_repo: PartnerRepository = get_partner_repository()
        self._users_repo: UsersRepository = get_users_repository()
        self._cache = get_cache()

    # =========================================================================
    # ORGANIZATION OPERATIONS
    # =========================================================================

    async def create_organization(
        self,
        data: OrganizationCreate,
        created_by: UUID,
    ) -> OrganizationResponse:
        """
        Cree une nouvelle organisation partenaire.

        L'utilisateur createur sera associe a l'organisation.
        """
        org_data = data.model_dump()

        org = await self._partner_repo.create_organization(
            data=org_data,
            created_by=created_by,
        )

        self._cache.delete_pattern("partner:organizations:*")

        logger.info(f"Organization created (pending approval): {org['id']} by {created_by}")
        return self._to_organization_response(org)

    async def get_organization(
        self,
        org_id: UUID,
        user_id: Optional[UUID] = None,
    ) -> OrganizationResponse:
        """Recupere une organisation par son ID.

        Si user_id est fourni, on filtre les non-approuvées (sauf pour admin/super_admin/
        partner_admin de l'org). Ainsi un étudiant ne peut pas voir une org pending.
        """
        org = await self._partner_repo.get_organization_by_id(org_id)
        if not org:
            raise NotFoundError("Organisation", str(org_id))

        # Si on a un user_id et que l'org n'est pas approuvée+active,
        # exiger un rôle admin / partner_admin de l'org
        if user_id is not None and not (org.get("is_approved") and org.get("is_active")):
            await self._assert_org_access(org_id, user_id)

        return self._to_organization_response(org)

    async def get_my_organization(self, user_id: UUID) -> OrganizationResponse:
        """Recupere l'organisation de l'utilisateur courant (celle qu'il a creee)."""
        org = await self._partner_repo.get_organization_by_creator(user_id)
        if not org:
            raise NotFoundError("Organisation", "créée par l'utilisateur")
        return self._to_organization_response(org)

    async def get_organization_by_code(
        self,
        code: str,
    ) -> OrganizationResponse:
        """Recupere une organisation par son code."""
        org = await self._partner_repo.get_organization_by_code(code)
        if not org:
            raise NotFoundError("Organisation", f"code: {code}")
        return self._to_organization_response(org)

    async def update_organization(
        self,
        org_id: UUID,
        data: OrganizationUpdate,
        user_id: UUID,
    ) -> OrganizationResponse:
        """Met a jour une organisation."""
        await self._assert_org_access(org_id, user_id)

        org = await self._partner_repo.get_organization_by_id(org_id)
        if not org:
            raise NotFoundError("Organisation", str(org_id))

        update_data = data.model_dump(exclude_unset=True)
        updated_org = await self._partner_repo.update_organization(org_id, update_data)

        self._cache.delete_pattern("partner:organizations:*")

        logger.info(f"Organization updated: {org_id}")
        return self._to_organization_response(updated_org)

    async def approve_organization(
        self,
        org_id: UUID,
        approved_by: UUID,
    ) -> OrganizationResponse:
        """Approuve une organisation (atomique via RPC PostgreSQL)."""
        db = get_supabase_client()
        try:
            result = await asyncio.to_thread(
                db.rpc,
                "approve_partner_organization",
                {"p_org_id": str(org_id), "p_approved_by": str(approved_by)},
            )
        except Exception as e:
            logger.error(f"Organization approval transaction failed: {e}", exc_info=True)
            raise

        if not result:
            raise NotFoundError("Organisation", str(org_id))

        self._cache.delete_pattern("partner:organizations:*")

        logger.info(f"Organization approved: {org_id}")
        return self._to_organization_response(result)

    async def list_organizations(
        self,
        page: int = 1,
        page_size: int = 20,
        is_active: Optional[bool] = None,
        is_approved: Optional[bool] = None,
        org_type: Optional[str] = None,
    ) -> OrganizationListResponse:
        """Liste les organisations avec pagination."""
        organizations, total = await self._partner_repo.list_organizations(
            page=page,
            page_size=page_size,
            is_active=is_active,
            is_approved=is_approved,
            org_type=org_type,
        )

        return OrganizationListResponse(
            organizations=[self._to_organization_response(org) for org in organizations],
            total=total,
            page=page,
            page_size=page_size,
        )

    async def get_organization_with_stats(
        self,
        org_id: UUID,
        user_id: UUID,
    ) -> OrganizationWithStats:
        """Recupere une organisation avec des statistiques (vérification d'accès)."""
        org = await self._partner_repo.get_organization_by_id(org_id)
        if not org:
            raise NotFoundError("Organisation", str(org_id))
        await self._assert_org_access(org_id, user_id)

        total = await self._partner_repo.count_beneficiaries(org_id)
        active = await self._partner_repo.count_beneficiaries(org_id, status="active")
        completed = await self._partner_repo.count_beneficiaries(org_id, status="completed")

        return OrganizationWithStats(
            organization=self._to_organization_response(org),
            total_beneficiaries=total,
            active_beneficiaries=active,
            completed_beneficiaries=completed,
        )

    # =========================================================================
    # BENEFICIARY OPERATIONS
    # =========================================================================

    async def create_beneficiary(
        self,
        organization_id: UUID,
        data: BeneficiaryCreate,
        referred_by: UUID,
    ) -> BeneficiaryResponse:
        """Cree un nouveau dossier de beneficiaire."""
        org = await self._partner_repo.get_organization_by_id(organization_id)
        if not org:
            raise NotFoundError("Organisation", str(organization_id))

        beneficiary_data = data.model_dump()
        beneficiary = await self._partner_repo.create_beneficiary(
            organization_id=organization_id,
            data=beneficiary_data,
            referred_by=referred_by,
        )

        self._cache.delete_pattern("partner:organizations:*")

        logger.info(f"Beneficiary dossier created: {beneficiary['dossier_number']}")
        return self._to_beneficiary_response(beneficiary)

    async def get_beneficiary(
        self,
        beneficiary_id: UUID,
        user_id: UUID,
    ) -> BeneficiaryResponse:
        """Recupere un beneficiaire par son ID (avec vérification d'accès)."""
        beneficiary = await self._partner_repo.get_beneficiary_by_id(beneficiary_id)
        if not beneficiary:
            raise NotFoundError("Beneficiaire", str(beneficiary_id))
        await self._assert_org_access(UUID(beneficiary["organization_id"]), user_id)
        return self._to_beneficiary_response(beneficiary)

    async def update_beneficiary(
        self,
        beneficiary_id: UUID,
        data: BeneficiaryUpdate,
        user_id: UUID,
    ) -> BeneficiaryResponse:
        """Met a jour un beneficiaire."""
        beneficiary = await self._partner_repo.get_beneficiary_by_id(beneficiary_id)
        if not beneficiary:
            raise NotFoundError("Beneficiaire", str(beneficiary_id))

        await self._assert_org_access(UUID(beneficiary["organization_id"]), user_id)

        update_data = data.model_dump(exclude_unset=True)
        updated_beneficiary = await self._partner_repo.update_beneficiary(
            beneficiary_id, update_data
        )

        self._cache.delete_pattern("partner:organizations:*")

        logger.info(f"Beneficiary updated: {beneficiary_id}")
        return self._to_beneficiary_response(updated_beneficiary)

    async def list_beneficiaries(
        self,
        organization_id: UUID,
        user_id: UUID,
        page: int = 1,
        page_size: int = 20,
        status: Optional[str] = None,
    ) -> BeneficiaryListResponse:
        """Liste les beneficiaires d'une organisation (avec vérification d'accès)."""
        org = await self._partner_repo.get_organization_by_id(organization_id)
        if not org:
            raise NotFoundError("Organisation", str(organization_id))
        await self._assert_org_access(organization_id, user_id)

        beneficiaries, total = await self._partner_repo.list_beneficiaries(
            organization_id=organization_id,
            page=page,
            page_size=page_size,
            status=status,
        )

        return BeneficiaryListResponse(
            beneficiaries=[self._to_beneficiary_summary(b) for b in beneficiaries],
            total=total,
            page=page,
            page_size=page_size,
        )

    async def delete_beneficiary(
        self,
        beneficiary_id: UUID,
        user_id: UUID,
    ) -> bool:
        """Desactive un beneficiaire."""
        beneficiary = await self._partner_repo.get_beneficiary_by_id(beneficiary_id)
        if not beneficiary:
            raise NotFoundError("Beneficiaire", str(beneficiary_id))

        await self._assert_org_access(UUID(beneficiary["organization_id"]), user_id)

        await self._partner_repo.delete_beneficiary(beneficiary_id)

        self._cache.delete_pattern("partner:organizations:*")
        logger.info(f"Beneficiary deactivated: {beneficiary_id}")
        return True

    # =========================================================================
    # AUTHORIZATION HELPERS
    # =========================================================================

    async def _assert_org_access(self, org_id: UUID, user_id: UUID) -> None:
        """Verifie que l'utilisateur a accès à l'organisation.

        En cas de refus, émet un événement Sentry tagué `security.idor_attempt`
        pour alerter en production.
        """
        user = await self._users_repo.get_by_id(user_id)
        if not user:
            self._report_security_event(
                "rbac_user_not_found", user_id=user_id, org_id=org_id, role=None,
            )
            raise AuthorizationError("Utilisateur introuvable")

        role = user.get("role", "student")

        # Admin rôle : accès complet (admin plateforme, super_admin)
        if role in ("admin", "super_admin"):
            return

        # Partner admin : seulement sa propre organisation
        user_org_id = user.get("organization_id")
        if role == "partner_admin" and user_org_id == str(org_id):
            return

        # Refus : trace pour monitoring sécurité
        self._report_security_event(
            "idor_attempt", user_id=user_id, org_id=org_id, role=role,
            user_org_id=user_org_id,
        )
        raise AuthorizationError(
            "Vous n'avez pas accès à cette organisation"
        )

    @staticmethod
    def _report_security_event(event_type: str, **context) -> None:
        """Émet un événement de sécurité vers Sentry + logs structurés.

        Pas de PII, juste IDs + role pour corrélation.
        """
        logger.warning(
            f"SECURITY: {event_type}",
            extra={"security_event": event_type, **{k: str(v) for k, v in context.items()}},
        )
        try:
            import sentry_sdk
            sentry_sdk.set_tag("security_event", event_type)
            sentry_sdk.set_context("security", {k: str(v) for k, v in context.items()})
            sentry_sdk.capture_message(
                f"Security event: {event_type}",
                level="warning",
            )
        except ImportError:
            pass  # sentry non installé — silencieux

    # =========================================================================
    # HELPERS
    # =========================================================================

    def _to_organization_response(self, org: dict) -> OrganizationResponse:
        """Convertit les donnees en OrganizationResponse."""
        return OrganizationResponse(
            id=UUID(org["id"]),
            name=org.get("name", ""),
            type=org.get("type", "cdej"),
            partner_code=org.get("partner_code"),
            description=org.get("description"),
            contact_email=org.get("contact_email"),
            contact_phone=org.get("contact_phone"),
            contact_person=org.get("contact_person"),
            address=org.get("address"),
            city=org.get("city"),
            country=org.get("country", "TOGO"),
            is_active=org.get("is_active", True),
            is_approved=org.get("is_approved", False),
            approved_at=org.get("approved_at"),
            created_at=org.get("created_at", datetime.now()),
            updated_at=org.get("updated_at"),
        )

    def _to_beneficiary_response(self, beneficiary: dict) -> BeneficiaryResponse:
        """Convertit les donnees en BeneficiaryResponse."""
        return BeneficiaryResponse(
            id=UUID(beneficiary["id"]),
            organization_id=UUID(beneficiary["organization_id"]),
            dossier_number=beneficiary.get("dossier_number"),
            first_name=beneficiary.get("first_name", ""),
            last_name=beneficiary.get("last_name", ""),
            date_of_birth=beneficiary.get("date_of_birth"),
            gender=beneficiary.get("gender"),
            place_of_birth=beneficiary.get("place_of_birth"),
            father_name=beneficiary.get("father_name"),
            mother_name=beneficiary.get("mother_name"),
            guardian_name=beneficiary.get("guardian_name"),
            guardian_phone=beneficiary.get("guardian_phone"),
            guardian_relationship=beneficiary.get("guardian_relationship"),
            address=beneficiary.get("address"),
            city=beneficiary.get("city"),
            country=beneficiary.get("country", "TOGO"),
            photo_url=beneficiary.get("photo_url"),
            notes=beneficiary.get("notes"),
            status=beneficiary.get("status", "active"),
            referred_at=beneficiary.get("referred_at", datetime.now()),
            created_at=beneficiary.get("created_at", datetime.now()),
            updated_at=beneficiary.get("updated_at"),
        )

    def _to_beneficiary_summary(self, beneficiary: dict) -> "BeneficiarySummary":
        """Convertit en BeneficiarySummary — exclut la PII sensible pour listings."""
        return BeneficiarySummary(
            id=UUID(beneficiary["id"]),
            organization_id=UUID(beneficiary["organization_id"]),
            dossier_number=beneficiary.get("dossier_number"),
            first_name=beneficiary.get("first_name", ""),
            last_name=beneficiary.get("last_name", ""),
            city=beneficiary.get("city"),
            status=beneficiary.get("status", "active"),
            referred_at=beneficiary.get("referred_at", datetime.now()),
            created_at=beneficiary.get("created_at", datetime.now()),
        )


@lru_cache(maxsize=1)
def get_partner_service() -> PartnerService:
    """Retourne l'instance (unique) du service partenaire."""
    return PartnerService()