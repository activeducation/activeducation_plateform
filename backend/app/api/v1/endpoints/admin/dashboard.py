"""Admin dashboard stats endpoint."""

from fastapi import APIRouter, Depends, Request

from app.core.logging import get_logger
from app.core.security import get_current_admin
from app.repositories.admin.stats_repository import get_stats_repository
from app.schemas.admin.dashboard import DashboardStats


logger = get_logger("api.admin.dashboard")

router = APIRouter()


@router.get("/stats", response_model=DashboardStats)
async def get_dashboard_stats(
    request: Request,
    admin: dict = Depends(get_current_admin),
):
    """Retourne les statistiques agregees du dashboard."""
    repo = get_stats_repository()
    return await repo.get_dashboard_stats()
