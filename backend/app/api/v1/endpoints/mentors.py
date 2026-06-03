"""
Endpoints API publics pour les mentors.
"""

from uuid import UUID
from typing import Optional

from fastapi import APIRouter, Query, Depends

from functools import lru_cache

from app.core.logging import get_logger
from app.core.cache import get_cache, CacheClient, TTL_MENTORS
from app.db.supabase_client import get_supabase_client
from app.core.security import get_current_user_id_optional
from app.core import email as email_service
from app.schemas.mentor import MentorApplicationCreate, MentorApplicationResponse
from app.repositories.mentor_repository import get_mentor_repository

logger = get_logger("api.mentors")

router = APIRouter()


@lru_cache(maxsize=1)
def _cache() -> CacheClient:
    """Retourne l'instance (unique) du cache."""
    return get_cache()


@router.post("/apply", response_model=MentorApplicationResponse, status_code=201)
async def apply_as_mentor(
    application: MentorApplicationCreate,
    user_id: Optional[UUID] = Depends(get_current_user_id_optional),
):
    """Candidature pour devenir mentor (publique, depuis l'app).

    - Enregistre la candidature (status=pending).
    - Notifie l'equipe par email (best-effort, adresse configurable a chaud).
    - Envoie un accuse de reception au candidat (best-effort).
    """
    repo = get_mentor_repository()
    data = application.model_dump(exclude_none=True)
    if user_id is not None:
        data["user_id"] = str(user_id)

    created = repo.create_application(data)

    # Notification interne (best-effort, ne bloque jamais la candidature)
    try:
        await email_service.notify_internal(
            subject=f"Nouvelle candidature mentor — {application.full_name}",
            html_body=_internal_application_html(application),
        )
    except Exception as e:
        logger.warning(f"Notification interne candidature mentor echouee: {e}")

    # Accuse de reception au candidat (best-effort)
    try:
        await email_service.send_email_async(
            to_email=str(application.email),
            subject="Votre candidature mentor — ActivEducation",
            html_body=_applicant_ack_html(application),
        )
    except Exception as e:
        logger.warning(f"Accuse reception candidat echoue: {e}")

    logger.info("Mentor application received: %s", application.email)
    return created


def _internal_application_html(a: MentorApplicationCreate) -> str:
    areas = ", ".join(a.expertise_areas or []) or "—"
    return f"""
    <h2>Nouvelle candidature mentor</h2>
    <ul>
      <li><b>Nom</b> : {a.full_name}</li>
      <li><b>Email</b> : {a.email}</li>
      <li><b>Téléphone</b> : {a.phone or '—'}</li>
      <li><b>Spécialité</b> : {a.specialty}</li>
      <li><b>Expérience</b> : {a.years_experience if a.years_experience is not None else '—'} ans</li>
      <li><b>Domaines</b> : {areas}</li>
      <li><b>LinkedIn</b> : {a.linkedin_url or '—'}</li>
    </ul>
    <p><b>Bio</b><br>{a.bio or '—'}</p>
    <p><b>Motivation</b><br>{a.motivation or '—'}</p>
    <hr><p>Traitez cette candidature dans le dashboard admin → Mentors → Candidatures.</p>
    """


def _applicant_ack_html(a: MentorApplicationCreate) -> str:
    return f"""
    <h2>Merci pour votre candidature, {a.full_name} !</h2>
    <p>Nous avons bien reçu votre candidature pour devenir mentor sur
    <b>ActivEducation</b> (spécialité : {a.specialty}).</p>
    <p>Notre équipe l'examinera et reviendra vers vous prochainement.</p>
    <p>À bientôt,<br>L'équipe ActivEducation</p>
    """


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