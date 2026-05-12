"""
Endpoints API publics pour les opportunités (stages, jobs, bourses).
"""

from uuid import UUID
from typing import Optional

from fastapi import APIRouter, Query

from app.core.logging import get_logger
from app.core.cache import get_cache, TTL_OPPORTUNITIES
from app.db.supabase_client import get_supabase_client

logger = get_logger("api.opportunities")

router = APIRouter()
cache = get_cache()


@router.get("")
async def list_opportunities(
    opportunity_type: Optional[str] = Query(None, description="Type: internship, job, volunteer, scholarship"),
    location: Optional[str] = Query(None, description="Filtrer par localisation"),
    remote: Optional[str] = Query(None, description="Filtrer par type: onsite, remote, hybrid"),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
):
    """
    Liste des opportunités publiées pour les étudiants.
    """
    # Cache uniquement pour requêtes sans filtres (plus frequent)
    cache_key = None
    if not opportunity_type and not location and not remote:
        cache_key = f"opportunities:list:l{limit}:o{offset}"
        cached = cache.get(cache_key)
        if cached is not None:
            return cached

    db = get_supabase_client()

    query = db.client.table("opportunities").select(
        "id,title,opportunity_type,organization_name,organization_logo,location,remote_type,application_deadline,is_published,is_featured,created_at"
    ).eq("is_published", True).order("is_featured.desc").range(offset, offset + limit - 1)

    if opportunity_type:
        query = query.eq("opportunity_type", opportunity_type)

    if location:
        query = query.ilike("location", f"%{location}%")

    if remote:
        query = query.eq("remote_type", remote)

    result = query.execute()

    data = [
        {
            "id": o.get("id"),
            "title": o.get("title"),
            "opportunity_type": o.get("opportunity_type"),
            "organization_name": o.get("organization_name"),
            "organization_logo": o.get("organization_logo"),
            "location": o.get("location"),
            "remote_type": o.get("remote_type"),
            "application_deadline": o.get("application_deadline"),
            "is_featured": o.get("is_featured"),
            "created_at": o.get("created_at"),
        }
        for o in (result.data or [])
    ]

    if cache_key:
        cache.set(cache_key, data, ttl=TTL_OPPORTUNITIES)

    return data


@router.get("/{opportunity_id}")
async def get_opportunity(opportunity_id: UUID):
    """
    Détail d'une opportunité spécifique.
    """
    cache_key = f"opportunities:detail:{opportunity_id}"
    cached = cache.get(cache_key)
    if cached is not None:
        return cached

    db = get_supabase_client()

    result = db.client.table("opportunities").select(
        "id,title,opportunity_type,organization_name,organization_logo,location,remote_type,description,duration,requirements,benefits,salary_min,salary_max,salary_currency,application_url,application_deadline,is_published,is_featured,created_at,updated_at"
    ).eq("id", str(opportunity_id)).eq("is_published", True).limit(1).execute()

    if not result.data:
        from app.core.exceptions import NotFoundError
        raise NotFoundError("Opportunité", str(opportunity_id))

    o = result.data[0]
    data = {
        "id": o.get("id"),
        "title": o.get("title"),
        "opportunity_type": o.get("opportunity_type"),
        "organization_name": o.get("organization_name"),
        "organization_logo": o.get("organization_logo"),
        "location": o.get("location"),
        "remote_type": o.get("remote_type"),
        "description": o.get("description"),
        "duration": o.get("duration"),
        "requirements": o.get("requirements"),
        "benefits": o.get("benefits"),
        "salary_min": o.get("salary_min"),
        "salary_max": o.get("salary_max"),
        "salary_currency": o.get("salary_currency", "EUR"),
        "application_url": o.get("application_url"),
        "application_deadline": o.get("application_deadline"),
        "is_featured": o.get("is_featured"),
        "created_at": o.get("created_at"),
        "updated_at": o.get("updated_at"),
    }

    cache.set(cache_key, data, ttl=TTL_OPPORTUNITIES)
    return data