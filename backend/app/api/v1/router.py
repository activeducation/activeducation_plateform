from fastapi import APIRouter
from app.api.v1.endpoints import orientation, auth, schools
from app.api.v1.endpoints.admin import (
    auth as admin_auth,
    upload as admin_upload,
    dashboard as admin_dashboard,
    users as admin_users,
    schools as admin_schools,
    careers as admin_careers,
    orientation as admin_orientation,
    gamification as admin_gamification,
    mentors as admin_mentors,
    settings as admin_settings,
)

api_router = APIRouter()

# Authentication endpoints
api_router.include_router(auth.router, prefix="/auth", tags=["authentication"])

# Orientation endpoints
api_router.include_router(orientation.router, prefix="/orientation", tags=["orientation"])

# Schools public endpoints
api_router.include_router(schools.router, prefix="/schools", tags=["schools"])

# =============================================================================
# ADMIN ENDPOINTS
# =============================================================================
api_router.include_router(admin_auth.router, prefix="/admin/auth", tags=["admin-auth"])
api_router.include_router(admin_upload.router, prefix="/admin/upload", tags=["admin-upload"])
api_router.include_router(admin_dashboard.router, prefix="/admin/dashboard", tags=["admin-dashboard"])
api_router.include_router(admin_users.router, prefix="/admin/users", tags=["admin-users"])
api_router.include_router(admin_schools.router, prefix="/admin/schools", tags=["admin-schools"])
api_router.include_router(admin_careers.router, prefix="/admin/careers", tags=["admin-careers"])
api_router.include_router(admin_orientation.router, prefix="/admin/tests", tags=["admin-tests"])
api_router.include_router(admin_gamification.router, prefix="/admin/gamification", tags=["admin-gamification"])
api_router.include_router(admin_mentors.router, prefix="/admin/mentors", tags=["admin-mentors"])
api_router.include_router(admin_settings.router, prefix="/admin", tags=["admin-settings"])
