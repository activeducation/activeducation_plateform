"""Repository pour la gestion admin des carrieres."""

from typing import Any, Optional
from uuid import UUID

from app.db.supabase_client import get_supabase_client, SupabaseClient
from app.core.logging import get_logger
from app.core.exceptions import NotFoundError
from app.schemas.admin.careers import (
    CareerListResponse,
    CareerSummary,
    CareerDetail,
    CareerCreate,
    CareerUpdate,
    SectorCreate,
    SectorUpdate,
    SectorResponse,
)

logger = get_logger("repositories.admin.careers")


class CareersAdminRepository:
    def __init__(self):
        self._db: SupabaseClient = get_supabase_client()

    # Sectors
    async def list_sectors(self) -> list[dict]:
        return self._db.fetch_all(table="career_sectors", order_by="display_order.asc")

    async def create_sector(self, data: SectorCreate) -> dict:
        result = self._db.insert(table="career_sectors", data=data.model_dump())
        return result[0] if result else {}

    async def update_sector(self, sector_id: UUID, data: SectorUpdate) -> dict:
        update_data = data.model_dump(exclude_unset=True)
        result = self._db.update(
            table="career_sectors", id_column="id",
            id_value=str(sector_id), data=update_data,
        )
        if not result:
            raise NotFoundError("Secteur", str(sector_id))
        return result[0]

    async def delete_sector(self, sector_id: UUID):
        self._db.delete(table="career_sectors", id_column="id", id_value=str(sector_id))

    # Careers
    async def list_careers(
        self,
        page: int = 1,
        per_page: int = 20,
        search: Optional[str] = None,
        sector: Optional[str] = None,
        demand: Optional[str] = None,
        trend: Optional[str] = None,
    ) -> CareerListResponse:
        offset = (page - 1) * per_page

        query = self._db.client.table("careers").select("*", count="exact")

        if sector:
            query = query.eq("sector_name", sector)
        if demand:
            query = query.eq("job_demand", demand)
        if trend:
            query = query.eq("growth_trend", trend)
        if search:
            query = query.or_(f"name.ilike.%{search}%,description.ilike.%{search}%")

        result = query.order("created_at", desc=True).range(offset, offset + per_page - 1).execute()

        items = [CareerSummary(**c) for c in (result.data or [])]

        return CareerListResponse(
            items=items,
            total=result.count or len(items),
            page=page,
            per_page=per_page,
        )

    async def get_career_detail(self, career_id: UUID) -> CareerDetail:
        career = self._db.fetch_one(
            table="careers", id_column="id", id_value=str(career_id)
        )
        if not career:
            raise NotFoundError("Carriere", str(career_id))
        return CareerDetail(**career)

    async def create_career(self, data: CareerCreate) -> CareerDetail:
        result = self._db.insert(table="careers", data=data.model_dump())
        career = result[0] if result else {}
        return CareerDetail(**career)

    async def update_career(self, career_id: UUID, data: CareerUpdate) -> CareerDetail:
        update_data = data.model_dump(exclude_unset=True)
        if update_data:
            result = self._db.update(
                table="careers", id_column="id",
                id_value=str(career_id), data=update_data,
            )
            if not result:
                raise NotFoundError("Carriere", str(career_id))
        return await self.get_career_detail(career_id)

    async def delete_career(self, career_id: UUID):
        result = self._db.delete(table="careers", id_column="id", id_value=str(career_id))
        if not result:
            raise NotFoundError("Carriere", str(career_id))


_careers_admin_repo = CareersAdminRepository()


def get_careers_admin_repository() -> CareersAdminRepository:
    return _careers_admin_repo
