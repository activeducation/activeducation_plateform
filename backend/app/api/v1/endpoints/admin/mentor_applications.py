"""Admin : gestion des candidatures mentor (list / approve / reject)."""

from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, Query

from app.core import email as email_service
from app.core.exceptions import NotFoundError
from app.core.logging import get_logger
from app.core.security import get_current_admin
from app.db.supabase_client import get_admin_supabase_client, get_supabase_client
from app.repositories.mentor_repository import get_mentor_repository
from app.schemas.mentor import MentorApplicationReview
from ._helpers import log_audit_action

logger = get_logger("api.admin.mentor_applications")

router = APIRouter()


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

    # Creer le mentor a partir de la candidature
    mentor_data = {
        "full_name": app.get("full_name"),
        "profession": app.get("specialty"),
        "specialty": app.get("specialty"),
        "bio": app.get("bio") or app.get("motivation") or "Candidature mentor",
        "email": app.get("email"),
        "phone": app.get("phone"),
        "years_experience": app.get("years_experience"),
        "expertise_areas": app.get("expertise_areas"),
        "linkedin_url": app.get("linkedin_url"),
        "portfolio": app.get("portfolio") or {},
        "is_verified": True,
        "is_active": True,
        "source": "application",
    }
    mentor_data = {k: v for k, v in mentor_data.items() if v is not None}

    # Si le candidat a un compte, verifier si un mentor existe deja
    db = get_admin_supabase_client()
    existing_mentor = None
    if app.get("user_id"):
        existing = (
            db.client.table("mentors").select("id").eq("id", app["user_id"]).limit(1).execute()
        )
        if existing.data:
            existing_mentor = existing.data[0]
            db.client.table("mentors").update(mentor_data).eq("id", app["user_id"]).execute()
            mentor = existing_mentor
        else:
            mentor_data["id"] = app["user_id"]
            mentor = repo.create_mentor(mentor_data)
    else:
        mentor = repo.create_mentor(mentor_data)

    updated = repo.update_application(
        app_id,
        {
            "status": "approved",
            "review_note": (body.note if body else None),
            "reviewed_by": str(admin["user_id"]),
            "reviewed_at": _now_iso(),
            "created_mentor_id": mentor.get("id"),
        },
    )
    log_audit_action(admin, "approve", "mentor_application", app_id, {"mentor_id": mentor.get("id")})

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

    updated = repo.update_application(
        app_id,
        {
            "status": "rejected",
            "review_note": (body.note if body else None),
            "reviewed_by": str(admin["user_id"]),
            "reviewed_at": _now_iso(),
        },
    )
    log_audit_action(admin, "reject", "mentor_application", app_id, {"note": (body.note if body else None)})

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
