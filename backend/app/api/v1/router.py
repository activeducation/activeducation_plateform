from fastapi import APIRouter

from app.api.v1.endpoints import (
    announcements,
    auth,
    chat,
    elearning,
    gamification,
    mentors,
    opportunities,
    orientation,
    schools,
    search,
    settings,
)
from app.api.v1.endpoints.admin import auth as admin_auth
from app.api.v1.endpoints.admin import careers as admin_careers
from app.api.v1.endpoints.admin import dashboard as admin_dashboard
from app.api.v1.endpoints.admin import elearning as admin_elearning
from app.api.v1.endpoints.admin import gamification as admin_gamification
from app.api.v1.endpoints.admin import knowledge_base as admin_knowledge_base
from app.api.v1.endpoints.admin import mentor_applications as admin_mentor_applications
from app.api.v1.endpoints.admin import mentor_contacts as admin_mentor_contacts
from app.api.v1.endpoints.admin import mentors as admin_mentors
from app.api.v1.endpoints.admin import opportunities as admin_opportunities
from app.api.v1.endpoints.admin import orientation as admin_orientation
from app.api.v1.endpoints.admin import partner as admin_partner
from app.api.v1.endpoints.admin import schools as admin_schools
from app.api.v1.endpoints.admin import settings as admin_settings
from app.api.v1.endpoints.admin import upload as admin_upload
from app.api.v1.endpoints.admin import users as admin_users
from app.api.v1.endpoints.partner import organizations as partner_organizations
from app.api.v1.endpoints.school import auth as school_auth
from app.api.v1.endpoints.school import courses as school_courses
from app.api.v1.endpoints.school import dashboard as school_dashboard
from app.api.v1.endpoints.school import lessons as school_lessons
from app.api.v1.endpoints.school import modules as school_modules
from app.api.v1.endpoints.school import profile as school_profile

api_router = APIRouter()

# Authentication endpoints
api_router.include_router(auth.router, prefix="/auth", tags=["authentication"])

# Orientation endpoints
api_router.include_router(orientation.router, prefix="/orientation", tags=["orientation"])

# Schools public endpoints
api_router.include_router(schools.router, prefix="/schools", tags=["schools"])

# Chat IA — AÏDA (Groq, gratuit)
api_router.include_router(chat.router, prefix="/chat", tags=["chat-ia"])

# E-Learning — cours, modules, lecons, progression
api_router.include_router(elearning.router, prefix="/elearning", tags=["elearning"])

# Gamification — XP, badges, challenges, leaderboard
api_router.include_router(gamification.router, prefix="/gamification", tags=["gamification"])

# Mentors — liste et detail des mentors
api_router.include_router(mentors.router, prefix="/mentors", tags=["mentors"])

# Opportunities — stages, jobs, bourses
api_router.include_router(opportunities.router, prefix="/opportunities", tags=["opportunities"])

# Announcements — annonces actives (publiques)
api_router.include_router(announcements.router, prefix="/announcements", tags=["announcements"])

# Settings — parametres publics
api_router.include_router(settings.router, prefix="/settings", tags=["settings"])
api_router.include_router(search.router, prefix="/search", tags=["search"])

# Partner (CDEJ, ONG) — organisations et beneficiaires
api_router.include_router(partner_organizations.router, prefix="", tags=["partner"])

# =============================================================================
# ADMIN ENDPOINTS
# =============================================================================
api_router.include_router(admin_auth.router, prefix="/admin/auth", tags=["admin-auth"])
api_router.include_router(admin_upload.router, prefix="/admin/upload", tags=["admin-upload"])
api_router.include_router(
    admin_dashboard.router, prefix="/admin/dashboard", tags=["admin-dashboard"]
)
api_router.include_router(admin_users.router, prefix="/admin/users", tags=["admin-users"])
api_router.include_router(admin_schools.router, prefix="/admin/schools", tags=["admin-schools"])
api_router.include_router(admin_careers.router, prefix="/admin/careers", tags=["admin-careers"])
api_router.include_router(admin_orientation.router, prefix="/admin/tests", tags=["admin-tests"])
api_router.include_router(
    admin_gamification.router, prefix="/admin/gamification", tags=["admin-gamification"]
)
api_router.include_router(admin_mentors.router, prefix="/admin/mentors", tags=["admin-mentors"])
api_router.include_router(admin_settings.router, prefix="/admin", tags=["admin-settings"])
api_router.include_router(
    admin_knowledge_base.router, prefix="/admin/knowledge-base", tags=["admin-knowledge-base"]
)
api_router.include_router(
    admin_opportunities.router, prefix="/admin/opportunities", tags=["admin-opportunities"]
)
api_router.include_router(
    admin_elearning.router, prefix="/admin/elearning", tags=["admin-elearning"]
)
api_router.include_router(admin_partner.router, prefix="/admin", tags=["admin-partner"])
api_router.include_router(
    admin_mentor_applications.router, prefix="/admin", tags=["admin-mentor-applications"]
)
api_router.include_router(
    admin_mentor_contacts.router, prefix="/admin", tags=["admin-mentor-contacts"]
)

# =============================================================================
# SCHOOL ADMIN ENDPOINTS
# =============================================================================
api_router.include_router(school_auth.router, prefix="/school/auth", tags=["school-auth"])
api_router.include_router(school_courses.router, prefix="/school", tags=["school-courses"])
api_router.include_router(school_modules.router, prefix="/school", tags=["school-modules"])
api_router.include_router(school_lessons.router, prefix="/school", tags=["school-lessons"])
api_router.include_router(
    school_dashboard.router, prefix="/school/dashboard", tags=["school-dashboard"]
)
api_router.include_router(school_profile.router, prefix="/school", tags=["school-profile"])
