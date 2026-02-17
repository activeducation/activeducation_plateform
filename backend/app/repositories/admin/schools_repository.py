"""Repository pour la gestion admin des ecoles."""

from typing import Any, Optional
from uuid import UUID

from app.db.supabase_client import get_supabase_client, SupabaseClient
from app.core.logging import get_logger
from app.core.exceptions import NotFoundError
from app.schemas.admin.schools import (
    SchoolListResponse,
    SchoolSummary,
    SchoolDetail,
    SchoolCreate,
    SchoolUpdate,
    ProgramCreate,
    ProgramUpdate,
    ProgramSummary,
    ImageCreate,
    ImageSummary,
)

logger = get_logger("repositories.admin.schools")


class SchoolsAdminRepository:
    def __init__(self):
        self._db: SupabaseClient = get_supabase_client()

    async def list_schools(
        self,
        page: int = 1,
        per_page: int = 20,
        search: Optional[str] = None,
        city: Optional[str] = None,
        school_type: Optional[str] = None,
        is_verified: Optional[bool] = None,
    ) -> SchoolListResponse:
        offset = (page - 1) * per_page

        query = self._db.client.table("schools").select("*", count="exact")

        if city:
            query = query.eq("city", city)
        if school_type:
            query = query.eq("type", school_type)
        if is_verified is not None:
            query = query.eq("is_verified", is_verified)
        if search:
            query = query.or_(f"name.ilike.%{search}%,city.ilike.%{search}%")

        result = query.order("created_at", desc=True).range(offset, offset + per_page - 1).execute()

        items = []
        for s in (result.data or []):
            # Count programs
            programs_count = 0
            try:
                pc = self._db.client.table("school_programs").select(
                    "id", count="exact"
                ).eq("school_id", s["id"]).execute()
                programs_count = pc.count or 0
            except Exception:
                pass

            items.append(SchoolSummary(
                id=s["id"],
                name=s["name"],
                type=s["type"],
                city=s["city"],
                is_public=s.get("is_public", True),
                is_verified=s.get("is_verified", False),
                is_active=s.get("is_active", True),
                logo_url=s.get("logo_url"),
                description=s.get("description"),
                tuition_range=s.get("tuition_range"),
                accreditations=s.get("accreditations", []),
                student_count=s.get("student_count"),
                founding_year=s.get("founding_year"),
                programs_count=programs_count,
                created_at=s.get("created_at"),
            ))

        return SchoolListResponse(
            items=items,
            total=result.count or len(items),
            page=page,
            per_page=per_page,
        )

    async def get_school_detail(self, school_id: UUID) -> SchoolDetail:
        school = self._db.fetch_one(
            table="schools", id_column="id", id_value=str(school_id)
        )
        if not school:
            raise NotFoundError("Ecole", str(school_id))

        # Get programs
        programs_data = self._db.fetch_all(
            table="school_programs",
            filters={"school_id": str(school_id)},
            order_by="display_order.asc",
        )
        programs = [ProgramSummary(**p) for p in programs_data]

        # Get images
        images_data = self._db.fetch_all(
            table="school_images",
            filters={"school_id": str(school_id)},
            order_by="display_order.asc",
        )
        images = [ImageSummary(**i) for i in images_data]

        return SchoolDetail(
            **school,
            programs=programs,
            images=images,
        )

    async def create_school(self, data: SchoolCreate) -> SchoolDetail:
        result = self._db.insert(table="schools", data=data.model_dump())
        school = result[0] if result else {}
        return SchoolDetail(**school, programs=[], images=[])

    async def update_school(self, school_id: UUID, data: SchoolUpdate) -> SchoolDetail:
        update_data = data.model_dump(exclude_unset=True)
        if update_data:
            result = self._db.update(
                table="schools", id_column="id",
                id_value=str(school_id), data=update_data,
            )
            if not result:
                raise NotFoundError("Ecole", str(school_id))
        return await self.get_school_detail(school_id)

    async def delete_school(self, school_id: UUID):
        result = self._db.delete(table="schools", id_column="id", id_value=str(school_id))
        if not result:
            raise NotFoundError("Ecole", str(school_id))

    async def toggle_verify(self, school_id: UUID) -> dict:
        school = self._db.fetch_one(table="schools", id_column="id", id_value=str(school_id))
        if not school:
            raise NotFoundError("Ecole", str(school_id))
        new_val = not school.get("is_verified", False)
        result = self._db.update(
            table="schools", id_column="id",
            id_value=str(school_id), data={"is_verified": new_val},
        )
        return result[0] if result else {"is_verified": new_val}

    async def toggle_active(self, school_id: UUID) -> dict:
        school = self._db.fetch_one(table="schools", id_column="id", id_value=str(school_id))
        if not school:
            raise NotFoundError("Ecole", str(school_id))
        new_val = not school.get("is_active", True)
        result = self._db.update(
            table="schools", id_column="id",
            id_value=str(school_id), data={"is_active": new_val},
        )
        return result[0] if result else {"is_active": new_val}

    # Programs
    async def add_program(self, school_id: UUID, data: ProgramCreate) -> dict:
        program_data = data.model_dump()
        program_data["school_id"] = str(school_id)
        result = self._db.insert(table="school_programs", data=program_data)
        return result[0] if result else program_data

    async def update_program(self, program_id: UUID, data: ProgramUpdate) -> dict:
        update_data = data.model_dump(exclude_unset=True)
        result = self._db.update(
            table="school_programs", id_column="id",
            id_value=str(program_id), data=update_data,
        )
        if not result:
            raise NotFoundError("Programme", str(program_id))
        return result[0]

    async def delete_program(self, program_id: UUID):
        self._db.delete(table="school_programs", id_column="id", id_value=str(program_id))

    # Images
    async def add_image(self, school_id: UUID, data: ImageCreate) -> dict:
        image_data = data.model_dump()
        image_data["school_id"] = str(school_id)
        result = self._db.insert(table="school_images", data=image_data)
        return result[0] if result else image_data

    async def delete_image(self, image_id: UUID):
        self._db.delete(table="school_images", id_column="id", id_value=str(image_id))


_schools_admin_repo = SchoolsAdminRepository()


def get_schools_admin_repository() -> SchoolsAdminRepository:
    return _schools_admin_repo
