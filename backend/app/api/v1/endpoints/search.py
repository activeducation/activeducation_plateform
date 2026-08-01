"""Recherche unifiee : ecoles + metiers/carrieres + cours e-learning.

Un seul endpoint GET /search?q=... renvoie des resultats types, chacun avec
un `type`, un titre, un sous-titre, une image et une `route` (chemin de la
page de detail cote app). Lecture publique, cache court.
"""

import asyncio
from functools import lru_cache
from typing import Any

from fastapi import APIRouter, Query

from app.core.cache import CacheClient, get_cache
from app.core.logging import get_logger
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


def _search_schools(db, term: str, limit: int) -> list[dict[str, Any]]:
    try:
        res = (
            db.client.table("schools")
            .select("id, name, city, logo_url, cover_image_url, type")
            .or_(f"name.ilike.%{term}%,city.ilike.%{term}%,description.ilike.%{term}%")
            .order("name")
            .limit(limit)
            .execute()
        )
        return [
            {
                "type": "school",
                "id": s["id"],
                "title": s.get("name", ""),
                "subtitle": s.get("city") or s.get("type") or "École",
                "image": s.get("logo_url") or s.get("cover_image_url"),
                "route": "/schools",
            }
            for s in res.data or []
        ]
    except Exception as e:
        logger.warning(f"search schools error: {e}")
        return []


def _search_careers(db, term: str, limit: int) -> list[dict[str, Any]]:
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
        return [
            {
                "type": "career",
                "id": c["id"],
                "title": c.get("name", ""),
                "subtitle": c.get("sector_name") or "Métier",
                "image": c.get("image_url"),
                "route": f"/orientation/career?id={c['id']}",
            }
            for c in res.data or []
        ]
    except Exception as e:
        logger.warning(f"search careers error: {e}")
        return []


def _search_courses(db, term: str, limit: int) -> list[dict[str, Any]]:
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
        return [
            {
                "type": "course",
                "id": c["id"],
                "title": c.get("title", ""),
                "subtitle": c.get("category") or "Cours",
                "image": c.get("thumbnail_url"),
                "route": f"/elearning/course/{c['id']}",
            }
            for c in res.data or []
        ]
    except Exception as e:
        logger.warning(f"search courses error: {e}")
        return []


@router.get("")
async def unified_search(
    q: str = Query(..., min_length=1, max_length=120, description="Terme de recherche"),
    limit: int = Query(8, ge=1, le=20, description="Max de resultats par categorie"),
):
    """Recherche ecoles, metiers et cours en parallele."""
    term = _esc(q)
    if not term:
        return {"query": q, "schools": [], "careers": [], "courses": [], "total": 0}

    cache_key = f"search:{term.lower()}:l{limit}"
    cached = _cache().get(cache_key)
    if cached is not None:
        return cached

    db = get_supabase_client()

    schools_fut, careers_fut, courses_fut = await asyncio.gather(
        asyncio.to_thread(_search_schools, db, term, limit),
        asyncio.to_thread(_search_careers, db, term, limit),
        asyncio.to_thread(_search_courses, db, term, limit),
    )

    result = {
        "query": q,
        "schools": schools_fut,
        "careers": careers_fut,
        "courses": courses_fut,
        "total": len(schools_fut) + len(careers_fut) + len(courses_fut),
    }
    _cache().set(cache_key, result, ttl=_SEARCH_TTL)
    return result
