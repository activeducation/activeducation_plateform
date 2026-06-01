"""Public endpoints for announcements visible to students."""

from fastapi import APIRouter, Query
from datetime import datetime, timezone

from app.core.logging import get_logger
from app.db.supabase_client import get_supabase_client

logger = get_logger("api.announcements")

router = APIRouter()


@router.get("")
async def list_active_announcements(
    audience: str = Query("students", description="target_audience filter"),
    limit: int = Query(10, ge=1, le=50),
):
    """Liste des annonces actives destinées aux étudiants."""
    db = get_supabase_client()
    now = datetime.now(timezone.utc).isoformat()

    query = db.client.table("announcements").select(
        "id,title,content,type,image_url,created_at"
    ).eq("is_active", True)

    query = query.or_(
        f"target_audience.eq.all,target_audience.eq.{audience}"
    )

    query = query.or_(f"start_date.is.null,start_date.lte.{now}")
    query = query.or_(f"end_date.is.null,end_date.gte.{now}")

    result = query.order("created_at", desc=True).limit(limit).execute()

    return result.data or []
