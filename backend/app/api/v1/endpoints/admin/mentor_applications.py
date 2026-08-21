"""Admin : gestion des candidatures mentor (list / approve / reject)."""

from uuid import UUID
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query

from app.core.logging import get_logger
from app.core.security import get_current_admin
from app.core.exceptions import NotFoundError
from app.core import email as email_service
from app.db.supabase_client import get_supabase_client
from app.schemas.mentor import MentorApplicationReview
from app.repositories.mentor_repository import get_mentor_repository

logger = get_logger("api.admin.mentor_applications")

router = APIRouter()


# Colonnes NOT NULL et sans valeur par defaut de la table `mentors`.
# La table vient d'un schema.sql historique que les migrations ne declarent
# pas : ces contraintes ne sont visibles qu'en interrogeant la base.
MENTOR_REQUIRED_FIELDS = ("profession", "bio")


def build_mentor_data(app: dict) -> dict:
    """Construit la ligne `mentors` a partir d'une candidature approuvee.

    Deux pieges, chacun ayant deja casse l'approbation en production :

    - `profession` et `bio` sont NOT NULL sans defaut, alors que la
      candidature ne connait que `specialty` et une bio facultative. Le filtre
      final retirant les valeurs nulles, une bio absente disparaissait du
      payload et l'insertion echouait ;
    - l'identifiant du compte doit aller dans `user_id`, la colonne prevue
      pour ce lien, et non dans `id` qui est la cle primaire.
    """
    specialty = app.get("specialty")

    data = {
        "full_name": app.get("full_name"),
        "specialty": specialty,
        "profession": specialty or "Mentor",
        "bio": app.get("bio") or app.get("motivation") or "",
        # La photo jointe a la candidature devient l'avatar du mentor.
        "avatar_url": app.get("photo_url"),
        "email": app.get("email"),
        "phone": app.get("phone"),
        "years_experience": app.get("years_experience"),
        "expertise_areas": app.get("expertise_areas"),
        "linkedin_url": app.get("linkedin_url"),
        "is_verified": True,
        "is_active": True,
        "source": "application",
    }
    if app.get("user_id"):
        data["user_id"] = app["user_id"]

    return {k: v for k, v in data.items() if v is not None}


def _log_audit(admin, action, entity_id, changes=None):
    try:
        db = get_supabase_client()
        db.insert(table="admin_audit_log", data={
            "admin_id": str(admin["user_id"]),
            "action": action,
            "entity_type": "mentor_application",
            "entity_id": str(entity_id) if entity_id else None,
            "changes": changes,
        })
    except Exception:
        logger.warning("Audit log (mentor_application) failed", exc_info=True)


@router.get("/mentor-applications")
async def list_applications(
    status: Optional[str] = Query(None, description="pending | approved | rejected"),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    admin: dict = Depends(get_current_admin),
):
    """Liste paginee des candidatures mentor."""
    return get_mentor_repository().list_applications(status=status, page=page, per_page=per_page)


@router.patch("/mentor-applications/{app_id}/approve")
async def approve_application(
    app_id: UUID,
    body: MentorApplicationReview | None = None,
    admin: dict = Depends(get_current_admin),
):
    """Approuve une candidature et cree le mentor correspondant."""
    repo = get_mentor_repository()
    app = repo.get_application(app_id)
    if not app:
        raise NotFoundError("Candidature", str(app_id))
    if app.get("status") == "approved":
        return app  # idempotent

    mentor_data = build_mentor_data(app)

    try:
        mentor = repo.create_mentor(mentor_data)
    except Exception as exc:
        # La table mentors vient d'un schema.sql historique non suivi par
        # Alembic : elle peut porter des contraintes que le code ignore. Sans
        # ce garde-fou, l'erreur remonte en 500 opaque et il faut lire les logs
        # du serveur pour savoir quelle colonne pose probleme.
        logger.error("Creation du mentor echouee: %s", exc, exc_info=True)
        raise HTTPException(
            status_code=422,
            detail=f"Impossible de créer le mentor : {exc}",
        ) from exc

    updated = repo.update_application(app_id, {
        "status": "approved",
        "review_note": (body.note if body else None),
        "reviewed_by": str(admin["user_id"]),
        "reviewed_at": _now_iso(),
        "created_mentor_id": mentor.get("id"),
    })
    _log_audit(admin, "approve", app_id, {"mentor_id": mentor.get("id")})

    # Email de bienvenue (best-effort)
    try:
        await email_service.send_email_async(
            to_email=app.get("email"),
            subject="Bienvenue parmi les mentors ActivEducation 🎉",
            html_body=f"""
            <h2>Félicitations {app.get('full_name')} !</h2>
            <p>Votre candidature pour devenir mentor sur <b>ActivEducation</b> a été
            <b>acceptée</b>. Vous faites désormais partie de nos mentors.</p>
            <p>Notre équipe vous contactera pour la suite.</p>
            <p>L'équipe ActivEducation</p>
            """,
        )
    except Exception as e:
        logger.warning(f"Email d'approbation echoue: {e}")

    return updated or app


@router.patch("/mentor-applications/{app_id}/reject")
async def reject_application(
    app_id: UUID,
    body: MentorApplicationReview | None = None,
    admin: dict = Depends(get_current_admin),
):
    """Rejette une candidature mentor."""
    repo = get_mentor_repository()
    app = repo.get_application(app_id)
    if not app:
        raise NotFoundError("Candidature", str(app_id))

    updated = repo.update_application(app_id, {
        "status": "rejected",
        "review_note": (body.note if body else None),
        "reviewed_by": str(admin["user_id"]),
        "reviewed_at": _now_iso(),
    })
    _log_audit(admin, "reject", app_id, {"note": (body.note if body else None)})

    # Email de refus courtois (best-effort)
    try:
        await email_service.send_email_async(
            to_email=app.get("email"),
            subject="Votre candidature mentor — ActivEducation",
            html_body=f"""
            <h2>Bonjour {app.get('full_name')},</h2>
            <p>Merci pour l'intérêt porté à ActivEducation. Après étude, nous ne
            pouvons pas donner suite à votre candidature de mentor pour le moment.</p>
            <p>Nous vous encourageons à re-postuler plus tard.</p>
            <p>L'équipe ActivEducation</p>
            """,
        )
    except Exception as e:
        logger.warning(f"Email de refus echoue: {e}")

    return updated or app


def _now_iso() -> str:
    from datetime import datetime, timezone
    return datetime.now(timezone.utc).isoformat()
