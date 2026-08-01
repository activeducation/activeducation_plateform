"""Admin : gestion des demandes de contact etudiant → mentor."""

from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, Query

from app.core.exceptions import NotFoundError
from app.core.logging import get_logger
from app.core.security import get_current_admin
from app.db.supabase_client import get_admin_supabase_client

logger = get_logger("api.admin.mentor_contacts")

router = APIRouter()


@router.get("/mentor-contact-requests")
async def list_contact_requests(
    status: Optional[str] = Query(None, description="pending | read | archived"),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    admin: dict = Depends(get_current_admin),
):
    """Liste paginee des demandes de contact etudiant → mentor."""
    db = get_admin_supabase_client()

    query = (
        db.client.table("mentor_contact_requests")
        .select(
            "id,mentor_id,student_id,message,status,created_at,updated_at,"
            "mentors!inner(full_name,specialty)",
            count="exact",
        )
        .order("created_at", desc=True)
    )

    if status:
        query = query.eq("status", status)

    total_res = query.execute()
    total = total_res.count if hasattr(total_res, "count") else len(total_res.data or [])

    result = (
        query.range((page - 1) * per_page, page * per_page - 1).execute()
    )

    # Batch-fetch user profiles for all student_ids
    student_ids = list({r["student_id"] for r in (result.data or []) if r.get("student_id")})
    profiles_map: dict[str, dict] = {}
    if student_ids:
        profiles = (
            db.client.table("user_profiles")
            .select("id,display_name,email")
            .in_("id", student_ids)
            .execute()
        )
        for p in profiles.data or []:
            profiles_map[p["id"]] = p

    items = []
    for r in result.data or []:
        mentor = r.get("mentors") or {}
        student = profiles_map.get(r["student_id"], {})
        items.append({
            "id": r["id"],
            "mentor_id": r["mentor_id"],
            "student_id": r["student_id"],
            "message": r["message"],
            "status": r["status"],
            "created_at": r["created_at"],
            "updated_at": r.get("updated_at"),
            "mentor_name": mentor.get("full_name"),
            "mentor_specialty": mentor.get("specialty"),
            "student_name": student.get("display_name"),
            "student_email": student.get("email"),
        })

    total_pages = max(1, (total + per_page - 1) // per_page)
    return {
        "items": items,
        "total": total,
        "page": page,
        "per_page": per_page,
        "total_pages": total_pages,
    }


@router.patch("/mentor-contact-requests/{request_id}/read")
async def mark_contact_request_read(
    request_id: UUID,
    admin: dict = Depends(get_current_admin),
):
    """Marquer une demande de contact comme lue."""
    db = get_admin_supabase_client()

    result = (
        db.client.table("mentor_contact_requests")
        .update({"status": "read", "updated_at": "now()"})
        .eq("id", str(request_id))
        .execute()
    )

    if not result.data:
        raise NotFoundError("Demande de contact", str(request_id))

    return result.data[0]


@router.delete("/mentor-contact-requests/{request_id}", status_code=204)
async def delete_contact_request(
    request_id: UUID,
    admin: dict = Depends(get_current_admin),
):
    """Supprimer une demande de contact."""
    db = get_admin_supabase_client()

    db.client.table("mentor_contact_requests").delete().eq("id", str(request_id)).execute()
