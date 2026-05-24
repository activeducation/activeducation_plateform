"""
Endpoints API publics pour les mentors.
"""

from uuid import UUID

from fastapi import APIRouter, Query

from functools import lru_cache

from app.core.logging import get_logger
from app.core.cache import get_cache, CacheClient, TTL_MENTORS
from app.db.supabase_client import get_supabase_client

logger = get_logger("api.mentors")

router = APIRouter()


@lru_cache(maxsize=1)
def _cache() -> CacheClient:
    """Retourne l'instance (unique) du cache."""
    return get_cache()


@router.get("")
async def list_mentors(
    specialty: str = Query(None, description="Filtrer par specialite"),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
):
    """
    Liste des mentors verifies et actifs pour les etudiants.
    """
    # Cache uniquement sans filtre specialty (requête la plus commune)
    cache_key = None
    if not specialty:
        cache_key = f"mentors:list:l{limit}:o{offset}"
        cached = _cache().get(cache_key)
        if cached is not None:
            return cached

    db = get_supabase_client()

    # NB : on tri par rating_avg (colonne de schema.sql) — l'ancienne colonne
    # "rating" n'existe pas dans la table mentors actuelle.
    query = db.client.table("mentors").select(
        "id,full_name,specialty,bio,avatar_url,years_experience,is_verified,hourly_rate,available_slots,rating_avg"
    ).eq("is_active", True).eq("is_verified", True).order("rating_avg", desc=True).range(offset, offset + limit - 1)

    if specialty:
        query = query.ilike("specialty", f"%{specialty}%")

    result = query.execute()

    data = [
        {
            "id": m.get("id"),
            "full_name": m.get("full_name"),
            "specialty": m.get("specialty"),
            "bio": m.get("bio"),
            "avatar_url": m.get("avatar_url"),
            "years_experience": m.get("years_experience"),
            "is_verified": m.get("is_verified"),
            "hourly_rate": m.get("hourly_rate"),
            "available_slots": m.get("available_slots"),
        }
        for m in (result.data or [])
    ]

    if cache_key:
        _cache().set(cache_key, data, ttl=TTL_MENTORS)

    return data


@router.get("/{mentor_id}")
async def get_mentor(mentor_id: UUID):
    """
    Detail d'un mentor specifique.
    """
    cache_key = f"mentors:detail:{mentor_id}"
    cached = _cache().get(cache_key)
    if cached is not None:
        return cached

    db = get_supabase_client()

    result = db.client.table("mentors").select(
        "id,full_name,specialty,bio,avatar_url,years_experience,is_verified,hourly_rate,available_slots,location,linkedin_url"
    ).eq("id", str(mentor_id)).eq("is_active", True).limit(1).execute()

    if not result.data:
        from app.core.exceptions import NotFoundError
        raise NotFoundError("Mentor", str(mentor_id))

    m = result.data[0]
    data = {
        "id": m.get("id"),
        "full_name": m.get("full_name"),
        "specialty": m.get("specialty"),
        "bio": m.get("bio"),
        "avatar_url": m.get("avatar_url"),
        "years_experience": m.get("years_experience"),
        "is_verified": m.get("is_verified"),
        "hourly_rate": m.get("hourly_rate"),
        "available_slots": m.get("available_slots"),
        "location": m.get("location"),
        "linkedin_url": m.get("linkedin_url"),
    }

    _cache().set(cache_key, data, ttl=TTL_MENTORS)
    return data


@router.get("/{mentor_id}/reviews")
async def get_mentor_reviews(
    mentor_id: UUID,
    limit: int = Query(10, ge=1, le=50),
):
    """
    Avis sur un mentor.

    Expose le display_name et avatar_url, pas le user_id.
    """
    db = get_supabase_client()

    result = db.client.table("mentor_reviews").select(
        "id,rating,comment,created_at,user_profiles(display_name,avatar_url)"
    ).eq("mentor_id", str(mentor_id)).order("created_at.desc").limit(limit).execute()

    return [
        {
            "id": r.get("id"),
            "rating": r.get("rating"),
            "comment": r.get("comment"),
            "created_at": r.get("created_at"),
            "reviewer_name": (r.get("user_profiles") or {}).get("display_name", "Anonyme"),
            "reviewer_avatar": (r.get("user_profiles") or {}).get("avatar_url"),
        }
        for r in (result.data or [])
    ]