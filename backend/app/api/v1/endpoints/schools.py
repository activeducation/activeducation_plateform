"""Endpoints publics pour les ecoles."""

from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Query

from app.repositories.schools_repository import get_schools_public_repository
from app.schemas.schools import SchoolListPublicResponse, SchoolPublicDetail
from app.core.cache import get_cache, TTL_LISTS, TTL_DETAIL
from app.core.config import get_settings

router = APIRouter()


@router.get("", response_model=SchoolListPublicResponse)
async def list_schools(
    search: Optional[str] = Query(None, description="Recherche par nom, ville ou description"),
    city: Optional[str] = Query(None, description="Filtrer par ville"),
    type: Optional[str] = Query(None, alias="type", description="Filtrer par type"),
    accredited_only: Optional[bool] = Query(
        None,
        description=(
            "Restreindre aux etablissements agreees par l'Etat. "
            "Non renseigne : valeur par defaut de la configuration "
            "(SCHOOLS_ACCREDITED_ONLY). false : renvoie aussi les non agreees."
        ),
    ),
    page: int = Query(1, ge=1, description="Numero de page"),
    per_page: int = Query(20, ge=1, le=100, description="Resultats par page"),
):
    """Liste paginee des ecoles actives, avec filtres optionnels."""
    # Cache uniquement pour les requetes sans recherche textuelle
    cache_key = None
    if not search:
        city_part = city or "all"
        type_part = type or "all"
        # Valeur effective (et non "default") : si la configuration bascule,
        # la cle change aussitot au lieu de servir des resultats perimes.
        effective_accredited = (
            get_settings().SCHOOLS_ACCREDITED_ONLY
            if accredited_only is None
            else accredited_only
        )
        acc_part = str(effective_accredited).lower()
        cache_key = (
            f"schools:list:p{page}:pp{per_page}:c{city_part}:t{type_part}:a{acc_part}"
        )

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
        accredited_only=accredited_only,
    )

    if cache_key:
        # model_dump(mode="json") et non le modele : CacheClient.set fait
        # json.dumps(..., default=str), qui transformerait silencieusement le
        # modele en sa repr. Au rechargement, json.loads rendrait une chaine
        # et la validation du response_model echouerait en 500.
        get_cache().set(cache_key, result.model_dump(mode="json"), ttl=TTL_LISTS)

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

    # Idem liste : serialiser avant de cacher (voir commentaire ci-dessus).
    get_cache().set(cache_key, result.model_dump(mode="json"), ttl=TTL_DETAIL)
    return result
