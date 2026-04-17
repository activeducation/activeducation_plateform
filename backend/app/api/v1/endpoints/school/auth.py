"""School admin authentication endpoint."""

from fastapi import APIRouter, Request

from app.core.logging import get_logger
from app.core.exceptions import AuthenticationError, AuthorizationError
from app.schemas.auth import LoginRequest
from app.services.auth_service import get_auth_service
from app.repositories.users_repository import get_users_repository
from app.repositories.school_admin_repository import get_school_admin_repository

logger = get_logger("api.school.auth")

router = APIRouter()


@router.post("/login")
async def school_admin_login(request: Request, body: LoginRequest):
    """
    Login school_admin — refuse les utilisateurs sans role school_admin.
    Retourne user (avec role) + tokens + school info.
    """
    # Authenticate via Supabase Auth
    service = get_auth_service()
    auth_result = await service.login(body)

    # Check school_admin role in user_profiles
    repo = get_users_repository()
    user = await repo.get_by_id(auth_result.user.id)

    if not user:
        raise AuthenticationError("Utilisateur non trouve")

    role = user.get("role", "student")
    if role != "school_admin":
        raise AuthorizationError("Acces reserve aux administrateurs d'ecole")

    if not user.get("is_active", True):
        raise AuthenticationError("Compte desactive")

    # Get school info
    school_repo = get_school_admin_repository()
    admin_profile = school_repo.get_school_for_admin(str(auth_result.user.id))

    if not admin_profile:
        raise AuthorizationError("Profil school_admin non configure")

    school = school_repo.get_school_profile(admin_profile["school_id"])

    return {
        "user": {
            "id": str(auth_result.user.id),
            "email": auth_result.user.email,
            "first_name": auth_result.user.first_name,
            "last_name": auth_result.user.last_name,
            "display_name": auth_result.user.display_name,
            "role": role,
            "position": admin_profile.get("position"),
        },
        "tokens": {
            "access_token": auth_result.tokens.access_token,
            "refresh_token": auth_result.tokens.refresh_token,
            "expires_in": auth_result.tokens.expires_in,
        },
        "school": school or {},
    }
