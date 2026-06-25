"""Repository for admin opportunities management."""

from datetime import datetime
from functools import lru_cache
from typing import Optional
from uuid import UUID

from app.core.exceptions import NotFoundError
from app.core.logging import get_logger
from app.db.supabase_client import SupabaseClient, get_admin_supabase_client
from app.schemas.admin.opportunities import (
    OpportunityCreate,
    OpportunityDetail,
    OpportunityListResponse,
    OpportunitySummary,
    OpportunityType,
    OpportunityUpdate,
)

logger = get_logger("repositories.admin.opportunities")


class OpportunitiesAdminRepository:
    def __init__(self):
        self._db: SupabaseClient = get_admin_supabase_client()

    def list_opportunities(
        self,
        page: int = 1,
        per_page: int = 20,
        search: Optional[str] = None,
        opportunity_type: Optional[OpportunityType] = None,
        is_published: Optional[bool] = None,
        school_id: Optional[UUID] = None,
    ) -> OpportunityListResponse:
        offset = (page - 1) * per_page

        query = self._db.client.table("opportunities").select("*", count="exact")

        if opportunity_type:
            query = query.eq("opportunity_type", opportunity_type.value)
        if is_published is not None:
            query = query.eq("is_published", is_published)
        if school_id:
            query = query.eq("school_id", str(school_id))
        if search:
            query = query.or_(f"title.ilike.%{search}%,organization_name.ilike.%{search}%")

        result = query.order("created_at", desc=True).range(offset, offset + per_page - 1).execute()

        items = [OpportunitySummary(**self._flatten_opportunity(o)) for o in (result.data or [])]
        total = result.count or 0
        total_pages = (total + per_page - 1) // per_page

        return OpportunityListResponse(
            items=items,
            total=total,
            page=page,
            per_page=per_page,
            total_pages=total_pages,
        )

    def get_opportunity(self, opportunity_id: UUID) -> OpportunityDetail:
        result = (
            self._db.client.table("opportunities")
            .select("*")
            .eq("id", str(opportunity_id))
            .execute()
        )

        if not result.data:
            raise NotFoundError("Opportunité", str(opportunity_id))

        return OpportunityDetail(**self._flatten_opportunity(result.data[0]))

    def create_opportunity(
        self,
        data: OpportunityCreate,
        user_id: UUID,
    ) -> OpportunityDetail:
        now = datetime.utcnow()
        payload = {
            "title": data.title,
            "description": data.description,
            "opportunity_type": data.opportunity_type.value,
            "organization_name": data.organization_name,
            "organization_logo": data.organization_logo,
            "location": data.location,
            "remote_type": data.remote_type.value if data.remote_type else None,
            "duration": data.duration,
            "requirements": data.requirements,
            "benefits": data.benefits,
            "salary_min": data.salary_min,
            "salary_max": data.salary_max,
            "salary_currency": data.salary_currency,
            "application_url": data.application_url,
            "application_deadline": data.application_deadline,
            "school_id": str(data.school_id) if data.school_id else None,
            "created_by": str(user_id),
            "created_at": now.isoformat(),
            "updated_at": now.isoformat(),
        }

        result = self._db.client.table("opportunities").insert(payload).execute()

        if not result.data:
            raise Exception("Failed to create opportunity")

        logger.info(f"Opportunity created by user {user_id}: {result.data[0]['id']}")
        return OpportunityDetail(**self._flatten_opportunity(result.data[0]))

    def update_opportunity(
        self,
        opportunity_id: UUID,
        data: OpportunityUpdate,
    ) -> OpportunityDetail:
        payload = data.model_dump(exclude_unset=True)

        if payload.get("opportunity_type"):
            payload["opportunity_type"] = payload["opportunity_type"].value
        if payload.get("remote_type"):
            payload["remote_type"] = payload["remote_type"].value

        payload["updated_at"] = datetime.utcnow().isoformat()

        result = (
            self._db.client.table("opportunities")
            .update(payload)
            .eq("id", str(opportunity_id))
            .execute()
        )

        if not result.data:
            raise NotFoundError("Opportunité", str(opportunity_id))

        logger.info(f"Opportunity updated: {opportunity_id}")
        return OpportunityDetail(**self._flatten_opportunity(result.data[0]))

    def delete_opportunity(self, opportunity_id: UUID) -> None:
        result = (
            self._db.client.table("opportunities").delete().eq("id", str(opportunity_id)).execute()
        )

        if not result.data:
            raise NotFoundError("Opportunité", str(opportunity_id))

        logger.info(f"Opportunity deleted: {opportunity_id}")

    def toggle_publish(self, opportunity_id: UUID, is_published: bool) -> OpportunityDetail:
        payload = {
            "is_published": is_published,
            "updated_at": datetime.utcnow().isoformat(),
        }
        result = (
            self._db.client.table("opportunities")
            .update(payload)
            .eq("id", str(opportunity_id))
            .execute()
        )

        if not result.data:
            raise NotFoundError("Opportunité", str(opportunity_id))

        return OpportunityDetail(**self._flatten_opportunity(result.data[0]))

    def toggle_featured(self, opportunity_id: UUID, is_featured: bool) -> OpportunityDetail:
        payload = {
            "is_featured": is_featured,
            "updated_at": datetime.utcnow().isoformat(),
        }
        result = (
            self._db.client.table("opportunities")
            .update(payload)
            .eq("id", str(opportunity_id))
            .execute()
        )

        if not result.data:
            raise NotFoundError("Opportunité", str(opportunity_id))

        return OpportunityDetail(**self._flatten_opportunity(result.data[0]))

    @staticmethod
    def _flatten_opportunity(data: dict) -> dict:
        return {
            "id": data.get("id"),
            "title": data.get("title"),
            "description": data.get("description"),
            "opportunity_type": data.get("opportunity_type"),
            "organization_name": data.get("organization_name"),
            "organization_logo": data.get("organization_logo"),
            "location": data.get("location"),
            "remote_type": data.get("remote_type"),
            "duration": data.get("duration"),
            "requirements": data.get("requirements"),
            "benefits": data.get("benefits"),
            "salary_min": data.get("salary_min"),
            "salary_max": data.get("salary_max"),
            "salary_currency": data.get("salary_currency", "EUR"),
            "application_url": data.get("application_url"),
            "application_deadline": data.get("application_deadline"),
            "is_published": data.get("is_published", False),
            "is_featured": data.get("is_featured", False),
            "school_id": data.get("school_id"),
            "created_by": data.get("created_by"),
            "created_at": data.get("created_at"),
            "updated_at": data.get("updated_at"),
        }


@lru_cache(maxsize=1)
def get_opportunities_admin_repository() -> "OpportunitiesAdminRepository":
    """Retourne l'instance (unique) du repository admin opportunités."""
    return OpportunitiesAdminRepository()
