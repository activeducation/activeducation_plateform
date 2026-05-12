"""Repository public pour les ecoles."""

from typing import Optional
from uuid import UUID

from app.db.supabase_client import get_supabase_client, SupabaseClient
from app.core.logging import get_logger
from app.core.exceptions import NotFoundError
from app.schemas.schools import (
    SchoolListPublicResponse,
    SchoolPublicSummary,
    SchoolPublicDetail,
    SchoolProgramPublic,
    SchoolImagePublic,
)

logger = get_logger("repositories.schools")


class SchoolsPublicRepository:
    def __init__(self):
        self._db: SupabaseClient = get_supabase_client()

    async def list_schools(
        self,
        page: int = 1,
        per_page: int = 20,
        search: Optional[str] = None,
        city: Optional[str] = None,
        school_type: Optional[str] = None,
    ) -> SchoolListPublicResponse:
        offset = (page - 1) * per_page

        query = self._db.client.table("schools").select("*", count="exact")

        # Filtre : uniquement les ecoles actives
        query = query.eq("is_active", True)

        if city:
            query = query.eq("city", city)
        if school_type:
            query = query.eq("type", school_type)
        if search:
            query = query.or_(f"name.ilike.%{search}%,city.ilike.%{search}%,description.ilike.%{search}%")

        result = query.order("name").range(offset, offset + per_page - 1).execute()
        schools_data = result.data or []

        # Récupérer les counts de programmes en une seule requête (évite N+1)
        programs_count_by_school = {}
        if schools_data:
            school_ids = [s["id"] for s in schools_data]
            try:
                programs_result = (
                    self._db.client.table("school_programs")
                    .select("school_id")
                    .in_("school_id", school_ids)
                    .eq("is_active", True)
                    .execute()
                )
                # Compter par school_id
                for p in (programs_result.data or []):
                    sid = p["school_id"]
                    programs_count_by_school[sid] = programs_count_by_school.get(sid, 0) + 1
            except Exception:
                pass

        items = []
        for s in schools_data:
            programs_count = programs_count_by_school.get(s["id"], 0)

            items.append(SchoolPublicSummary(
                id=s["id"],
                name=s["name"],
                type=s["type"],
                city=s["city"],
                is_public=s.get("is_public", True),
                logo_url=s.get("logo_url"),
                description=s.get("description"),
                programs_offered=s.get("programs_offered", []),
                accreditations=s.get("accreditations", []),
                tuition_range=s.get("tuition_range"),
                student_count=s.get("student_count"),
                founding_year=s.get("founding_year"),
                programs_count=programs_count,
            ))

        return SchoolListPublicResponse(
            items=items,
            total=result.count or len(items),
            page=page,
            per_page=per_page,
        )

    async def get_school_detail(self, school_id: UUID) -> SchoolPublicDetail:
        school = self._db.fetch_one(
            table="schools", id_column="id", id_value=str(school_id)
        )
        if not school or not school.get("is_active", True):
            raise NotFoundError("Ecole", str(school_id))

        # Programmes actifs
        programs_data = self._db.fetch_all(
            table="school_programs",
            filters={"school_id": str(school_id)},
            order_by="display_order.asc",
        )
        programs = [
            SchoolProgramPublic(**p)
            for p in programs_data
            if p.get("is_active", True)
        ]

        # Images
        images_data = self._db.fetch_all(
            table="school_images",
            filters={"school_id": str(school_id)},
            order_by="display_order.asc",
        )
        images = [SchoolImagePublic(**i) for i in images_data]

        return SchoolPublicDetail(
            id=school["id"],
            name=school["name"],
            type=school["type"],
            city=school["city"],
            address=school.get("address"),
            phone=school.get("phone"),
            email=school.get("email"),
            website=school.get("website"),
            description=school.get("description"),
            programs_offered=school.get("programs_offered", []),
            is_public=school.get("is_public", True),
            logo_url=school.get("logo_url"),
            cover_image_url=school.get("cover_image_url"),
            tuition_range=school.get("tuition_range"),
            admission_requirements=school.get("admission_requirements"),
            accreditations=school.get("accreditations", []),
            founding_year=school.get("founding_year"),
            student_count=school.get("student_count"),
            programs=programs,
            images=images,
        )


_schools_public_repo = SchoolsPublicRepository()


def get_schools_public_repository() -> SchoolsPublicRepository:
    return _schools_public_repo
