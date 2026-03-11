"""Endpoints publics pour les ecoles."""

from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Query

from app.repositories.schools_repository import get_schools_public_repository
from app.schemas.schools import SchoolListPublicResponse, SchoolPublicDetail
from app.core.cache import get_cache, TTL_LISTS, TTL_DETAIL

router = APIRouter()


@router.get("", response_model=SchoolListPublicResponse)
async def list_schools(
    search: Optional[str] = Query(None, description="Recherche par nom, ville ou description"),
    city: Optional[str] = Query(None, description="Filtrer par ville"),
    type: Optional[str] = Query(None, alias="type", description="Filtrer par type"),
    page: int = Query(1, ge=1, description="Numero de page"),
    per_page: int = Query(20, ge=1, le=100, description="Resultats par page"),
):
    """Liste paginee des ecoles actives, avec filtres optionnels."""
    # Cache uniquement pour les requetes sans recherche textuelle
    cache_key = None
    if not search:
        city_part = city or "all"
        type_part = type or "all"
        cache_key = f"schools:list:p{page}:pp{per_page}:c{city_part}:t{type_part}"

        cached = get_cache().get(cache_key)
        if cached is not None:
            return cached

    repo = get_schools_public_repository()
    result = await repo.list_schools(
        page=page,
        per_page=per_page,
        search=search,
        city=city,
        school_type=type,
    )

    if cache_key:
        get_cache().set(cache_key, result, ttl=TTL_LISTS)

    return result


@router.get("/{school_id}", response_model=SchoolPublicDetail)
async def get_school_detail(school_id: UUID):
    """Detail complet d'une ecole avec ses programmes et images."""
    cache_key = f"schools:detail:{school_id}"
    cached = get_cache().get(cache_key)
    if cached is not None:
        return cached

    repo = get_schools_public_repository()
    result = await repo.get_school_detail(school_id)

    get_cache().set(cache_key, result, ttl=TTL_DETAIL)
    return result
