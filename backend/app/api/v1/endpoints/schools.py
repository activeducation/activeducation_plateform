"""Endpoints publics pour les ecoles."""

from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Query

from app.repositories.schools_repository import get_schools_public_repository
from app.schemas.schools import SchoolListPublicResponse, SchoolPublicDetail

router = APIRouter()


@router.get("", response_model=SchoolListPublicResponse)
async def list_schools(
    search: Optional[str] = Query(None, description="Recherche par nom, ville ou description"),
    city: Optional[str] = Query(None, description="Filtrer par ville"),
    type: Optional[str] = Query(None, alias="type", description="Filtrer par type (university, grande_ecole, institut, centre_formation)"),
    page: int = Query(1, ge=1, description="Numero de page"),
    per_page: int = Query(20, ge=1, le=100, description="Resultats par page"),
):
    """Liste paginee des ecoles actives, avec filtres optionnels."""
    repo = get_schools_public_repository()
    return await repo.list_schools(
        page=page,
        per_page=per_page,
        search=search,
        city=city,
        school_type=type,
    )


@router.get("/{school_id}", response_model=SchoolPublicDetail)
async def get_school_detail(school_id: UUID):
    """Detail complet d'une ecole avec ses programmes et images."""
    repo = get_schools_public_repository()
    return await repo.get_school_detail(school_id)
