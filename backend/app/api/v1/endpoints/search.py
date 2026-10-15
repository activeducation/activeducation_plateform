"""Recherche unifiee : ecoles + metiers/carrieres + cours e-learning.

Un seul endpoint GET /search?q=... renvoie des resultats types, chacun avec
un `type`, un titre, un sous-titre, une image et une `route` (chemin de la
page de detail cote app). Lecture publique, cache court.
"""

from typing import Any

from fastapi import APIRouter, Query
from functools import lru_cache

from app.core.logging import get_logger
from app.core.cache import get_cache, CacheClient
from app.core.config import get_settings
from app.db.supabase_client import get_supabase_client

logger = get_logger("api.search")

router = APIRouter()

_SEARCH_TTL = 120  # 2 min


@lru_cache(maxsize=1)
def _cache() -> CacheClient:
    return get_cache()


def _esc(q: str) -> str:
    """Echappe les caracteres PostgREST sensibles dans un terme ilike."""
    return q.replace("%", "").replace(",", " ").replace("(", " ").replace(")", " ").strip()


@router.get("")
async def unified_search(
    q: str = Query(..., min_length=1, max_length=120, description="Terme de recherche"),
    limit: int = Query(8, ge=1, le=20, description="Max de resultats par categorie"),
):
    """Recherche ecoles, metiers et cours en une requete."""
    term = _esc(q)
    if not term:
        return {"query": q, "schools": [], "careers": [], "courses": [], "total": 0}

    acc = "1" if get_settings().SCHOOLS_ACCREDITED_ONLY else "0"
    cache_key = f"search:{term.lower()}:l{limit}:a{acc}"
    cached = _cache().get(cache_key)
    if cached is not None:
        return cached

    db = get_supabase_client()
    schools: list[dict[str, Any]] = []
    careers: list[dict[str, Any]] = []
    courses: list[dict[str, Any]] = []

    # --- Ecoles ---
    try:
        settings = get_settings()
        schools_query = (
            db.client.table("schools")
            .select("id, name, city, logo_url, cover_image_url, type")
            .eq("is_active", True)
        )
        # Meme perimetre que l'annuaire : la recherche ne doit pas remonter
        # des etablissements que la liste masque.
        if settings.SCHOOLS_ACCREDITED_ONLY:
            schools_query = schools_query.contains(
                "accreditations", [settings.SCHOOLS_ACCREDITATION_LABEL]
            )
        res = (
            schools_query
            .or_(f"name.ilike.%{term}%,city.ilike.%{term}%,description.ilike.%{term}%")
            .order("name")
            .limit(limit)
            .execute()
        )
        for s in res.data or []:
            schools.append({
                "type": "school",
                "id": s["id"],
                "title": s.get("name", ""),
                "subtitle": s.get("city") or s.get("type") or "École",
                "image": s.get("logo_url") or s.get("cover_image_url"),
                "route": "/schools",  # l'annuaire (detail ecole = sheet interne)
            })
    except Exception as e:
        logger.warning(f"search schools error: {e}")

    # --- Metiers / carrieres ---
    try:
        res = (
            db.client.table("careers")
            .select("id, name, sector_name, image_url")
            .eq("is_active", True)
            .or_(f"name.ilike.%{term}%,sector_name.ilike.%{term}%")
            .order("name")
            .limit(limit)
            .execute()
        )
        for c in res.data or []:
            careers.append({
                "type": "career",
                "id": c["id"],
                "title": c.get("name", ""),
                "subtitle": c.get("sector_name") or "Métier",
                "image": c.get("image_url"),
                "route": f"/orientation/career?id={c['id']}",
            })
    except Exception as e:
        logger.warning(f"search careers error: {e}")

    # --- Cours ---
    try:
        res = (
            db.client.table("elearning_courses")
            .select("id, title, category, thumbnail_url")
            .eq("is_published", True)
            .or_(f"title.ilike.%{term}%,description.ilike.%{term}%,category.ilike.%{term}%")
            .order("display_order")
            .limit(limit)
            .execute()
        )
        for c in res.data or []:
            courses.append({
                "type": "course",
                "id": c["id"],
                "title": c.get("title", ""),
                "subtitle": c.get("category") or "Cours",
                "image": c.get("thumbnail_url"),
                "route": f"/elearning/course/{c['id']}",
            })
    except Exception as e:
        logger.warning(f"search courses error: {e}")

    result = {
        "query": q,
        "schools": schools,
        "careers": careers,
        "courses": courses,
        "total": len(schools) + len(careers) + len(courses),
    }
    _cache().set(cache_key, result, ttl=_SEARCH_TTL)
    return result
