"""Espace mentorat : demander un mentor, suivre la relation, planifier des seances.

Conception
----------
Aucun mentor n'a de compte utilisateur (verifie en production). Un espace ou le
mentor se connecte pour accepter serait donc construit pour un cote qui ne peut
pas se connecter. Le mentor agit ici par un LIEN SIGNE recu par email : il ouvre
la demande, accepte ou decline, sans inscription. Le jeton est un HMAC de
l'identifiant de relation avec SECRET_KEY — il ne se devine pas et n'a pas
besoin d'etre stocke.

Le backend est la frontiere de securite : il n'envoie jamais le JWT de l'eleve a
Supabase, donc `auth.uid()` y est toujours NULL et RLS ne peut rien filtrer. Les
verifications d'appartenance sont donc explicites a chaque endpoint.
"""

from __future__ import annotations

import hashlib
import hmac
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, Request

from app.core import email as email_service
from app.core.config import get_settings
from app.core.exceptions import NotFoundError, ValidationError
from app.core.logging import get_logger
from app.core.security import get_current_user_id
from app.middleware.rate_limiter import strict_limit
from app.repositories.mentorship_repository import (
    MAX_PENDING_PER_MENTEE,
    get_mentorship_repository,
)
from app.repositories.orientation_profile_repository import (
    get_orientation_profile_repository,
)
from app.schemas.mentor import (
    MentorshipDecision,
    MentorshipRequestCreate,
    MentorshipResponse,
    SessionCreate,
    SessionResponse,
    SessionUpdate,
)

logger = get_logger("api.mentorship")

router = APIRouter()


# ============================================================================
# JETON D'INVITATION DU MENTOR
# ============================================================================

def invitation_token(relationship_id) -> str:
    """Jeton non devinable liant le mentor a UNE demande precise.

    Derive de SECRET_KEY, donc rien a stocker ni a faire expirer cote base :
    le jeton cesse d'etre valable si la cle tourne, et il ne vaut que pour
    cette relation.
    """
    secret = get_settings().SECRET_KEY.encode()
    message = f"mentorship-invitation:{relationship_id}".encode()
    return hmac.new(secret, message, hashlib.sha256).hexdigest()[:40]


def _check_token(relationship_id, token: str) -> None:
    # compare_digest et non `==` : une comparaison naive laisse fuiter le jeton
    # caractere par caractere via le temps de reponse.
    if not hmac.compare_digest(invitation_token(relationship_id), token or ""):
        raise HTTPException(status_code=403, detail="Lien d'invitation invalide.")


# ============================================================================
# COTE ELEVE
# ============================================================================

@router.post("/mentors/{mentor_id}/request", status_code=201)
@strict_limit("10/hour")
async def request_mentorship(
    request: Request,
    mentor_id: UUID,
    body: MentorshipRequestCreate,
    user_id: UUID = Depends(get_current_user_id),
):
    """Envoie une demande de mentorat a un mentor."""
    repo = get_mentorship_repository()

    mentor = repo.get_mentor(mentor_id)
    if not mentor or not mentor.get("is_active") or not mentor.get("is_verified"):
        raise NotFoundError("Mentor", str(mentor_id))

    existing = repo.find_relationship(mentor_id, user_id)
    if existing:
        # La contrainte UNIQUE(mentor_id, mentee_id) l'interdirait de toute
        # facon ; on renvoie un message lisible plutot qu'une erreur de base.
        raise ValidationError(
            "Vous avez déjà une demande auprès de ce mentor "
            f"(statut : {existing.get('status')})."
        )

    if repo.count_pending(user_id) >= MAX_PENDING_PER_MENTEE:
        raise ValidationError(
            f"Vous avez déjà {MAX_PENDING_PER_MENTEE} demandes en attente. "
            "Attendez une réponse avant d'en envoyer une autre."
        )

    places = (mentor.get("max_mentees") or 0) - (mentor.get("current_mentees") or 0)
    if places <= 0:
        raise ValidationError(
            "Ce mentor accompagne déjà le nombre maximum d'élèves. "
            "Essayez un autre mentor."
        )

    created = repo.create_request(mentor_id, user_id, body.model_dump(exclude_none=True))

    # Le mentor n'a pas de compte : on lui envoie le lien signe. Best-effort,
    # l'echec de l'email ne doit pas perdre la demande de l'eleve.
    if mentor.get("email"):
        try:
            link = _invitation_link(request, created["id"])
            await email_service.send_email_async(
                to_email=mentor["email"],
                subject="Un élève souhaite votre accompagnement — ActivEducation",
                html_body=_mentor_invitation_html(mentor, body, link),
            )
        except Exception as exc:  # noqa: BLE001
            logger.warning("Email d'invitation mentor echoue: %s", exc)

    return created


@router.get("/mentor-relationships", response_model=list[MentorshipResponse])
async def my_mentorships(user_id: UUID = Depends(get_current_user_id)):
    """Mes mentorats : demandes, relations actives et seances."""
    return get_mentorship_repository().list_for_mentee(user_id)


@router.get("/mentorship/suggestions")
async def suggested_mentors(
    limit: int = Query(10, ge=1, le=50),
    user_id: UUID = Depends(get_current_user_id),
):
    """Mentors classes selon le profil d'orientation de l'eleve.

    C'est le lien que les plateformes generalistes n'ont pas : ActivEducation
    connait deja les interets, les matieres preferees et le projet declares
    pendant le test d'orientation. Chaque suggestion est accompagnee des termes
    qui l'expliquent, plutot que d'un score opaque.
    """
    profile = None
    try:
        profile = await get_orientation_profile_repository().get_profile(user_id)
    except Exception as exc:  # noqa: BLE001
        # Sans profil on classe par note : une suggestion degradee vaut mieux
        # qu'une page en erreur.
        logger.warning("Profil d'orientation illisible pour les suggestions: %s", exc)

    items = get_mentorship_repository().suggest(profile, limit)
    return {
        "items": items,
        "personalized": bool(profile) and any(m["match_score"] for m in items),
    }


@router.post("/mentor-relationships/{relationship_id}/sessions",
             response_model=SessionResponse, status_code=201)
async def propose_session(
    relationship_id: UUID,
    body: SessionCreate,
    user_id: UUID = Depends(get_current_user_id),
):
    """Propose une seance dans une relation active."""
    repo = get_mentorship_repository()
    rel = _owned_relationship(repo, relationship_id, user_id)
    if rel.get("status") != "active":
        raise ValidationError(
            "Les séances ne sont possibles qu'une fois le mentorat accepté."
        )
    return repo.create_session(relationship_id, body.model_dump(exclude_none=True), "mentee")


@router.patch("/mentor-relationships/{relationship_id}/sessions/{session_id}",
              response_model=SessionResponse)
async def update_session(
    relationship_id: UUID,
    session_id: UUID,
    body: SessionUpdate,
    user_id: UUID = Depends(get_current_user_id),
):
    """Confirme, annule ou annote une seance."""
    repo = get_mentorship_repository()
    _owned_relationship(repo, relationship_id, user_id)

    session = repo.get_session(session_id)
    # On verifie que la seance appartient bien a CETTE relation : sans cela,
    # connaitre un identifiant de seance suffirait a la modifier.
    if not session or str(session.get("relationship_id")) != str(relationship_id):
        raise NotFoundError("Séance", str(session_id))

    changes = body.model_dump(exclude_none=True)
    if not changes:
        raise ValidationError("Aucune modification fournie.")
    return repo.update_session(session_id, changes)


def _owned_relationship(repo, relationship_id: UUID, user_id: UUID) -> dict:
    """Charge la relation en verifiant qu'elle appartient a l'appelant."""
    rel = repo.get_relationship(relationship_id)
    if not rel or str(rel.get("mentee_id")) != str(user_id):
        # Meme reponse qu'une relation inexistante : distinguer les deux cas
        # revelerait quelles relations existent.
        raise NotFoundError("Mentorat", str(relationship_id))
    return rel


# ============================================================================
# COTE MENTOR : lien signe, sans compte
# ============================================================================

@router.get("/mentorship/invitation/{relationship_id}")
@strict_limit("20/hour")
async def read_invitation(
    request: Request,
    relationship_id: UUID,
    token: str = Query(..., description="Jeton recu par email"),
):
    """Ouvre une demande de mentorat depuis le lien envoye au mentor."""
    _check_token(relationship_id, token)
    repo = get_mentorship_repository()
    rel = repo.get_relationship(relationship_id)
    if not rel:
        raise NotFoundError("Mentorat", str(relationship_id))
    mentor = repo.get_mentor(rel["mentor_id"]) or {}
    return {
        "id": rel["id"],
        "status": rel["status"],
        "goal": rel.get("goal"),
        "message": rel.get("message"),
        "preferred_channel": rel.get("preferred_channel"),
        "created_at": rel.get("created_at"),
        "mentor_name": mentor.get("full_name"),
        # Le nom de l'eleve n'est pas expose ici : le mentor decide sur
        # l'objectif, pas sur l'identite. Il le recevra si la relation demarre.
    }


@router.post("/mentorship/invitation/{relationship_id}")
@strict_limit("20/hour")
async def decide_invitation(
    request: Request,
    relationship_id: UUID,
    body: MentorshipDecision,
    token: str = Query(..., description="Jeton recu par email"),
):
    """Le mentor accepte ou decline, sans avoir de compte."""
    _check_token(relationship_id, token)
    repo = get_mentorship_repository()

    rel = repo.get_relationship(relationship_id)
    if not rel:
        raise NotFoundError("Mentorat", str(relationship_id))
    if rel.get("status") != "pending":
        # Idempotent : recliquer sur le lien ne doit pas changer une decision
        # deja prise ni renvoyer une erreur incomprehensible.
        return rel

    if body.accept:
        mentor = repo.get_mentor(rel["mentor_id"]) or {}
        places = (mentor.get("max_mentees") or 0) - (mentor.get("current_mentees") or 0)
        if places <= 0:
            raise ValidationError(
                "Vous accompagnez déjà le nombre maximum d'élèves."
            )

    updated = repo.decide(relationship_id, body.accept, body.reason)
    repo.refresh_mentee_count(rel["mentor_id"])
    return updated


def _invitation_link(request: Request, relationship_id) -> str:
    """Lien absolu construit depuis l'hote reellement servi.

    On ne stocke pas d'URL de base en configuration : elle divergerait du
    deploiement. `request.base_url` est l'adresse par laquelle l'API vient
    d'etre appelee.
    """
    base = str(request.base_url).rstrip("/")
    return (f"{base}/api/v1/mentorship/invitation/{relationship_id}"
            f"?token={invitation_token(relationship_id)}")


def _mentor_invitation_html(mentor: dict, body: MentorshipRequestCreate, link: str) -> str:
    return f"""
    <h2>Bonjour {mentor.get('full_name') or ''},</h2>
    <p>Un élève d'<b>ActivEducation</b> souhaite être accompagné par vous.</p>
    <p><b>Son objectif</b><br>{body.goal}</p>
    {f'<p><b>Son message</b><br>{body.message}</p>' if body.message else ''}
    <p>Vous n'avez pas besoin de compte : ouvrez le lien ci-dessous pour
    accepter ou décliner.</p>
    <p><a href="{link}">Répondre à la demande</a></p>
    <p>Ce lien vous est personnel. Merci de ne pas le transférer.</p>
    <p>L'équipe ActivEducation</p>
    """
