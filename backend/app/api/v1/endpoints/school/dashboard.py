"""School admin dashboard endpoint."""

from fastapi import APIRouter, Depends

from app.core.security import get_current_school_admin
from app.repositories.school_admin_repository import get_school_admin_repository

router = APIRouter()


@router.get("/stats")
async def get_dashboard_stats(admin: dict = Depends(get_current_school_admin)):
    """Retourne les statistiques du dashboard ecole."""
    repo = get_school_admin_repository()
    stats = repo.get_dashboard_stats(admin["school_id"])
    return stats
