"""
Endpoints API pour l'authentification.

Gere:
- Login / Register
- Token refresh
- Password reset
- Profile management
"""

from uuid import UUID

from fastapi import APIRouter, Depends, Request

from app.core.logging import get_logger
from app.core.security import get_current_user_id
from app.schemas.auth import (
    LoginRequest,
    RegisterRequest,
    TokenResponse,
    RefreshTokenRequest,
    ForgotPasswordRequest,
    ResetPasswordRequest,
    ChangePasswordRequest,
    AuthResponse,
    UserProfile,
    UpdateProfileRequest,
    MessageResponse,
    LogoutResponse,
)
from app.services.auth_service import get_auth_service, AuthService
from app.middleware.rate_limiter import strict_limit, standard_limit

logger = get_logger("api.auth")

router = APIRouter()


# =============================================================================
# DEPENDENCY
# =============================================================================


def get_service() -> AuthService:
    """Dependency pour obtenir le service auth."""
    return get_auth_service()


# =============================================================================
# LOGIN / REGISTER
# =============================================================================


@router.post("/login", response_model=AuthResponse)
@strict_limit("10/minute")
async def login(
    request: Request,
    body: LoginRequest,
    service: AuthService = Depends(get_service),
):
    """
    Authentifie un utilisateur.

    Retourne les tokens d'acces et de rafraichissement.
    """
    result = await service.login(body)

    logger.info(
        "User logged in",
        extra={"email": body.email},
    )

    return result


@router.post("/register", response_model=AuthResponse)
@strict_limit("5/minute")
async def register(
    request: Request,
    body: RegisterRequest,
    service: AuthService = Depends(get_service),
):
    """
    Inscrit un nouvel utilisateur.

    Retourne les tokens d'acces et de rafraichissement.
    """
    result = await service.register(body)

    logger.info(
        "New user registered",
        extra={"email": body.email},
    )

    return result


@router.post("/logout", response_model=LogoutResponse)
@standard_limit()
async def logout(
    request: Request,
    user_id: UUID = Depends(get_current_user_id),
    service: AuthService = Depends(get_service),
):
    """
    Deconnecte l'utilisateur courant.

    Invalide le refresh token.
    """
    await service.logout(user_id)

    return LogoutResponse(
        success=True,
        message="Deconnexion reussie",
    )


# =============================================================================
# TOKEN REFRESH
# =============================================================================


@router.post("/refresh", response_model=TokenResponse)
@strict_limit("20/minute")
async def refresh_token(
    request: Request,
    body: RefreshTokenRequest,
    service: AuthService = Depends(get_service),
):
    """
    Rafraichit les tokens avec un refresh token.

    Retourne une nouvelle paire de tokens.
    """
    result = await service.refresh_tokens(body.refresh_token)

    return result


# =============================================================================
# PASSWORD RESET
# =============================================================================


@router.post("/forgot-password", response_model=MessageResponse)
@strict_limit("3/minute")
async def forgot_password(
    request: Request,
    body: ForgotPasswordRequest,
    service: AuthService = Depends(get_service),
):
    """
    Demande une reinitialisation de mot de passe.

    Envoie un email avec un lien de reinitialisation.
    """
    await service.request_password_reset(body.email)

    # Toujours retourner succes pour ne pas reveler si l'email existe
    return MessageResponse(
        success=True,
        message="Si cet email existe, un lien de reinitialisation a ete envoye.",
    )


@router.post("/reset-password", response_model=MessageResponse)
@strict_limit("5/minute")
async def reset_password(
    request: Request,
    body: ResetPasswordRequest,
    service: AuthService = Depends(get_service),
):
    """
    Reinitialise le mot de passe avec un token.
    """
    await service.reset_password(body.token, body.new_password)

    return MessageResponse(
        success=True,
        message="Mot de passe reinitialise avec succes.",
    )


@router.post("/change-password", response_model=MessageResponse)
@strict_limit("5/minute")
async def change_password(
    request: Request,
    body: ChangePasswordRequest,
    user_id: UUID = Depends(get_current_user_id),
    service: AuthService = Depends(get_service),
):
    """
    Change le mot de passe de l'utilisateur connecte.
    """
    await service.change_password(
        user_id,
        body.current_password,
        body.new_password,
    )

    return MessageResponse(
        success=True,
        message="Mot de passe change avec succes.",
    )


# =============================================================================
# PROFILE
# =============================================================================


@router.get("/me", response_model=UserProfile)
@standard_limit()
async def get_current_user_profile(
    request: Request,
    user_id: UUID = Depends(get_current_user_id),
    service: AuthService = Depends(get_service),
):
    """
    Recupere le profil de l'utilisateur connecte.
    """
    return await service.get_profile(user_id)


@router.patch("/me", response_model=UserProfile)
@standard_limit()
async def update_current_user_profile(
    request: Request,
    body: UpdateProfileRequest,
    user_id: UUID = Depends(get_current_user_id),
    service: AuthService = Depends(get_service),
):
    """
    Met a jour le profil de l'utilisateur connecte.
    """
    return await service.update_profile(user_id, body)
