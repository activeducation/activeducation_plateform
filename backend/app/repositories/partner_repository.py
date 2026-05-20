"""
Repository pour les operations sur les organisations partenaires et beneficaires.

Gere les interactions avec Supabase pour:
- CRUD organisations partenaires (partner_organizations)
- CRUD dossiers beneficiaires (beneficiary_dossiers)
"""

import secrets
import string
from datetime import datetime, timezone
from typing import Any, Optional
from uuid import UUID

from app.db.supabase_client import get_admin_supabase_client, SupabaseClient
from app.core.logging import get_logger
from app.schemas.partner import OrganizationType
from app.core.exceptions import (
    NotFoundError,
    QueryError,
    AlreadyExistsError,
    ValidationError,
)

logger = get_logger("repositories.partner")


def generate_partner_code() -> str:
    """Generate a unique partner code."""
    chars = string.ascii_uppercase + string.digits
    return "CDEJ-" + "".join(secrets.choice(chars) for _ in range(6))


def generate_dossier_number() -> str:
    """Generate a unique dossier number."""
    chars = string.ascii_uppercase + string.digits
    return "DOS-" + "".join(secrets.choice(chars) for _ in range(8))


class PartnerRepository:
    """Repository pour les operations sur les partenaires et beneficiaires."""

    def __init__(self):
        self._db: SupabaseClient = get_admin_supabase_client()

    # =========================================================================
    # ORGANIZATIONS
    # =========================================================================

    async def get_organization_by_id(self, org_id: UUID) -> Optional[dict[str, Any]]:
        """Recupere une organisation par son ID."""
        try:
            return self._db.fetch_one(
                table="partner_organizations",
                id_column="id",
                id_value=str(org_id),
            )
        except Exception as e:
            logger.error(f"Error fetching organization {org_id}: {e}", exc_info=True)
            raise QueryError(f"Erreur lors de la recuperation de l'organisation: {str(e)}")

    async def get_organization_by_code(self, code: str) -> Optional[dict[str, Any]]:
        """Recupere une organisation par son code partenaire."""
        try:
            return self._db.fetch_one(
                table="partner_organizations",
                id_column="partner_code",
                id_value=code,
            )
        except Exception as e:
            logger.error(f"Error fetching organization by code {code}: {e}", exc_info=True)
            raise QueryError(f"Erreur lors de la recuperation de l'organisation: {str(e)}")

    async def create_organization(
        self,
        data: dict[str, Any],
        created_by: Optional[UUID] = None,
    ) -> dict[str, Any]:
        """Cree une nouvelle organisation partenaire."""
        try:
            data["partner_code"] = generate_partner_code()
            data["created_at"] = datetime.now(timezone.utc).isoformat()
            data["updated_at"] = datetime.now(timezone.utc).isoformat()
            if created_by:
                data["created_by"] = str(created_by)

            result = self._db.insert(table="partner_organizations", data=data)
            logger.info(f"Created organization: {data['partner_code']}")
            return result[0] if result else data
        except Exception as e:
            logger.error(f"Error creating organization: {e}", exc_info=True)
            raise QueryError(f"Erreur lors de la creation de l'organisation: {str(e)}")

    async def update_organization(
        self,
        org_id: UUID,
        data: dict[str, Any],
    ) -> dict[str, Any]:
        """Met a jour une organisation."""
        try:
            data["updated_at"] = datetime.now(timezone.utc).isoformat()

            result = self._db.update(
                table="partner_organizations",
                id_column="id",
                id_value=str(org_id),
                data=data,
            )

            if not result:
                raise NotFoundError("Organisation", str(org_id))

            return result[0]
        except NotFoundError:
            raise
        except Exception as e:
            logger.error(f"Error updating organization: {e}", exc_info=True)
            raise QueryError(f"Erreur lors de la mise a jour de l'organisation: {str(e)}")

    async def approve_organization(
        self,
        org_id: UUID,
        approved_by: UUID,
    ) -> dict[str, Any]:
        """Approuve une organisation."""
        return await self.update_organization(
            org_id,
            {
                "is_approved": True,
                "approved_by": str(approved_by),
                "approved_at": datetime.now(timezone.utc).isoformat(),
            },
        )

    async def list_organizations(
        self,
        page: int = 1,
        page_size: int = 20,
        is_active: Optional[bool] = None,
        is_approved: Optional[bool] = None,
        org_type: Optional[str] = None,
    ) -> tuple[list[dict[str, Any]], int]:
        """Liste les organisations avec pagination."""
        try:
            offset = (page - 1) * page_size

            query = self._db.client.table("partner_organizations").select(
                "*", count="exact"
            )

            if is_active is not None:
                query = query.eq("is_active", is_active)
            if is_approved is not None:
                query = query.eq("is_approved", is_approved)
            if org_type is not None:
                valid_types = list(OrganizationType)
                if org_type not in valid_types:
                    raise ValidationError(
                        f"org_type invalide. Valeurs: {', '.join(valid_types)}"
                    )
                query = query.eq("type", org_type)

            response = query.order("created_at", desc=True).range(
                offset, offset + page_size - 1
            ).execute()

            total = response.count or 0

            return response.data or [], total

        except ValidationError:
            raise
        except Exception as e:
            logger.error(f"Error listing organizations: {e}", exc_info=True)
            raise QueryError(f"Erreur lors de la liste des organisations: {str(e)}")

    async def delete_organization(self, org_id: UUID) -> bool:
        """Supprime une organisation (desactive)."""
        try:
            result = self._db.update(
                table="partner_organizations",
                id_column="id",
                id_value=str(org_id),
                data={"is_active": False, "updated_at": datetime.now(timezone.utc).isoformat()},
            )
            return len(result) > 0
        except Exception as e:
            logger.error(f"Error deleting organization: {e}", exc_info=True)
            raise QueryError(f"Erreur lors de la suppression de l'organisation: {str(e)}")

    # =========================================================================
    # BENEFICIARIES
    # =========================================================================

    async def get_beneficiary_by_id(self, beneficiary_id: UUID) -> Optional[dict[str, Any]]:
        """Recupere un beneficiaire par son ID."""
        try:
            return self._db.fetch_one(
                table="beneficiary_dossiers",
                id_column="id",
                id_value=str(beneficiary_id),
            )
        except Exception as e:
            logger.error(f"Error fetching beneficiary {beneficiary_id}: {e}", exc_info=True)
            raise QueryError(f"Erreur lors de la recuperation du beneficiaire: {str(e)}")

    async def get_beneficiary_by_number(self, dossier_number: str) -> Optional[dict[str, Any]]:
        """Recupere un beneficiaire par son numero de dossier."""
        try:
            return self._db.fetch_one(
                table="beneficiary_dossiers",
                id_column="dossier_number",
                id_value=dossier_number,
            )
        except Exception as e:
            logger.error(f"Error fetching beneficiary by number {dossier_number}: {e}", exc_info=True)
            raise QueryError(f"Erreur lors de la recuperation du beneficiaire: {str(e)}")

    async def create_beneficiary(
        self,
        organization_id: UUID,
        data: dict[str, Any],
        referred_by: Optional[UUID] = None,
    ) -> dict[str, Any]:
        """Cree un nouveau dossier de beneficiaire."""
        try:
            data["organization_id"] = str(organization_id)
            data["dossier_number"] = generate_dossier_number()
            data["referred_at"] = datetime.now(timezone.utc).isoformat()
            data["created_at"] = datetime.now(timezone.utc).isoformat()
            data["updated_at"] = datetime.now(timezone.utc).isoformat()
            if referred_by:
                data["referred_by"] = str(referred_by)

            result = self._db.insert(table="beneficiary_dossiers", data=data)
            logger.info(f"Created beneficiary dossier: {data['dossier_number']}")
            return result[0] if result else data
        except Exception as e:
            logger.error(f"Error creating beneficiary: {e}", exc_info=True)
            raise QueryError(f"Erreur lors de la creation du beneficiaire: {str(e)}")

    async def update_beneficiary(
        self,
        beneficiary_id: UUID,
        data: dict[str, Any],
    ) -> dict[str, Any]:
        """Met a jour un beneficiaire."""
        try:
            data["updated_at"] = datetime.now(timezone.utc).isoformat()

            result = self._db.update(
                table="beneficiary_dossiers",
                id_column="id",
                id_value=str(beneficiary_id),
                data=data,
            )

            if not result:
                raise NotFoundError("Beneficiaire", str(beneficiary_id))

            return result[0]
        except NotFoundError:
            raise
        except Exception as e:
            logger.error(f"Error updating beneficiary: {e}", exc_info=True)
            raise QueryError(f"Erreur lors de la mise a jour du beneficiaire: {str(e)}")

    async def list_beneficiaries(
        self,
        organization_id: UUID,
        page: int = 1,
        page_size: int = 20,
        status: Optional[str] = None,
    ) -> tuple[list[dict[str, Any]], int]:
        """Liste les beneficiaires d'une organisation avec pagination."""
        try:
            offset = (page - 1) * page_size

            query = self._db.client.table("beneficiary_dossiers").select(
                "*", count="exact"
            ).eq("organization_id", str(organization_id))

            if status:
                query = query.eq("status", status)

            response = query.order("created_at", desc=True).range(
                offset, offset + page_size - 1
            ).execute()

            total = response.count or 0

            return response.data or [], total

        except Exception as e:
            logger.error(f"Error listing beneficiaries: {e}", exc_info=True)
            raise QueryError(f"Erreur lors de la liste des beneficiaires: {str(e)}")

    async def count_beneficiaries(
        self,
        organization_id: UUID,
        status: Optional[str] = None,
    ) -> int:
        """Compte les beneficiaires d'une organisation."""
        try:
            query = self._db.client.table("beneficiary_dossiers").select(
                "*", count="exact"
            ).eq("organization_id", str(organization_id))

            if status:
                query = query.eq("status", status)

            response = query.execute()
            return response.count or 0

        except Exception as e:
            logger.error(f"Error counting beneficiaries: {e}", exc_info=True)
            return 0

    async def delete_beneficiary(self, beneficiary_id: UUID) -> bool:
        """Supprime un beneficiaire (desactive)."""
        try:
            result = self._db.update(
                table="beneficiary_dossiers",
                id_column="id",
                id_value=str(beneficiary_id),
                data={"status": "inactive", "updated_at": datetime.now(timezone.utc).isoformat()},
            )
            return len(result) > 0
        except Exception as e:
            logger.error(f"Error deleting beneficiary: {e}", exc_info=True)
            raise QueryError(f"Erreur lors de la suppression du beneficiaire: {str(e)}")

    async def get_user_role(self, user_id: str) -> Optional[str]:
        """Recupere le role d'un utilisateur depuis user_profiles."""
        try:
            response = self._db.fetch_one(
                table="user_profiles",
                id_column="id",
                id_value=user_id,
            )
            return response.get("role") if response else None
        except Exception as e:
            logger.error(f"Error getting user role: {e}", exc_info=True)
            return None


partner_repo = PartnerRepository()


def get_partner_repository() -> PartnerRepository:
    """Retourne l'instance du repository partenaire."""
    return partner_repo