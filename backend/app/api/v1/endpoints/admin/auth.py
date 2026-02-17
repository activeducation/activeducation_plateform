"""Admin authentication endpoint."""

from datetime import datetime
from uuid import UUID

from fastapi import APIRouter, Request

from app.core.logging import get_logger
from app.core.security import (
    verify_password,
    create_token_pair,
)
from app.core.exceptions import AuthenticationError, AuthorizationError
from app.schemas.auth import LoginRequest
from app.repositories.users_repository import get_users_repository


logger = get_logger("api.admin.auth")

router = APIRouter()


@router.post("/login")
async def admin_login(request: Request, body: LoginRequest):
    """
    Login admin - refuse les utilisateurs sans role admin/super_admin.
    Retourne user (avec role) + tokens.
    """
    repo = get_users_repository()
    user = await repo.get_by_email(body.email)

    if not user:
        raise AuthenticationError("Email ou mot de passe incorrect")

    if not verify_password(body.password, user.get("password_hash", "")):
        raise AuthenticationError("Email ou mot de passe incorrect")

    role = user.get("role", "student")
    if role not in ("admin", "super_admin"):
        raise AuthorizationError("Acces reserve aux administrateurs")

    if not user.get("is_active", True):
        raise AuthenticationError("Compte desactive")

    tokens = create_token_pair(user["id"], body.email)

    # Update last login
    try:
        repo._db.update(
            table="user_profiles",
            id_column="id",
            id_value=str(user["id"]),
            data={"last_login_at": datetime.utcnow().isoformat()},
        )
    except Exception:
        pass  # Ne pas bloquer le login si last_login echoue

    return {
        "user": {
            "id": user["id"],
            "email": user["email"],
            "first_name": user.get("first_name"),
            "last_name": user.get("last_name"),
            "display_name": user.get("display_name"),
            "role": role,
        },
        "tokens": {
            "access_token": tokens.access_token,
            "refresh_token": tokens.refresh_token,
            "expires_in": tokens.expires_in,
        },
    }
