"""
Service d'authentification via Supabase Auth.

Toute la gestion des mots de passe et tokens est deleguee a Supabase Auth.
Le backend se charge uniquement de la logique metier supplementaire
(creation du profil utilisateur, mise a jour du profil, etc.)
"""

from datetime import datetime
from typing import Optional
from uuid import UUID

from app.core.logging import get_logger
from app.core.exceptions import (
    AuthenticationError,
    AlreadyExistsError,
    NotFoundError,
    ValidationError,
    InvalidTokenError,
)
from app.schemas.auth import (
    LoginRequest,
    RegisterRequest,
    UserResponse,
    UserProfile,
    AuthResponse,
    TokenResponse,
    UpdateProfileRequest,
)
from app.repositories.users_repository import (
    get_users_repository,
    UsersRepository,
)
from app.db.supabase_client import get_supabase_client

logger = get_logger("services.auth")


class AuthService:
    """Service pour les operations d'authentification via Supabase Auth."""

    def __init__(self):
        self._users_repo: UsersRepository = get_users_repository()
        self._db = get_supabase_client()

    # =========================================================================
    # LOGIN / REGISTER
    # =========================================================================

    async def login(self, request: LoginRequest) -> AuthResponse:
        """
        Authentifie un utilisateur via Supabase Auth.

        Returns:
            AuthResponse avec user et tokens Supabase

        Raises:
            AuthenticationError: Si credentials invalides
        """
        try:
            response = self._db.client.auth.sign_in_with_password({
                "email": request.email.lower(),
                "password": request.password,
            })

            if not response.user or not response.session:
                raise AuthenticationError("Email ou mot de passe incorrect")

        except AuthenticationError:
            raise
        except Exception as e:
            error_msg = str(e).lower()
            if any(k in error_msg for k in ("invalid", "incorrect", "credentials", "not found")):
                logger.warning(f"Failed login attempt for: {request.email}")
                raise AuthenticationError("Email ou mot de passe incorrect")
            logger.error(f"Login error for {request.email}: {e}")
            raise AuthenticationError("Erreur lors de la connexion")

        user_id = UUID(response.user.id)
        session = response.session

        # Recuperer ou creer le profil dans user_profiles
        profile = await self._users_repo.get_by_id(user_id)
        if not profile:
            profile = await self._users_repo.create_profile(
                user_id=user_id,
                email=response.user.email,
            )

        await self._users_repo.update_last_login(user_id)

        logger.info(f"User logged in: {request.email}")

        return AuthResponse(
            user=self._to_user_response(profile, response.user.email),
            tokens=TokenResponse(
                access_token=session.access_token,
                refresh_token=session.refresh_token,
                expires_in=session.expires_in or 1800,
            ),
        )

    async def register(self, request: RegisterRequest) -> AuthResponse:
        """
        Inscrit un nouvel utilisateur via Supabase Auth.

        Raises:
            AlreadyExistsError: Si l'email existe deja
        """
        try:
            response = self._db.client.auth.sign_up({
                "email": request.email.lower(),
                "password": request.password,
                "options": {
                    "data": {
                        "first_name": request.first_name,
                        "last_name": request.last_name,
                    }
                }
            })

            if not response.user:
                raise AuthenticationError("Erreur lors de l'inscription")

        except AuthenticationError:
            raise
        except Exception as e:
            error_msg = str(e).lower()
            if any(k in error_msg for k in ("already", "exists", "duplicate")):
                raise AlreadyExistsError("Utilisateur", "email", request.email)
            logger.error(f"Register error for {request.email}: {e}")
            raise AuthenticationError("Erreur lors de l'inscription")

        user_id = UUID(response.user.id)
        session = response.session

        # Creer le profil dans user_profiles
        profile = await self._users_repo.create_profile(
            user_id=user_id,
            email=request.email.lower(),
            first_name=request.first_name,
            last_name=request.last_name,
            phone_number=request.phone_number,
        )

        logger.info(f"New user registered: {request.email}")

        # Supabase peut envoyer un email de confirmation (session peut etre None)
        access_token = session.access_token if session else ""
        refresh_token = session.refresh_token if session else ""
        expires_in = session.expires_in if session else 1800

        return AuthResponse(
            user=self._to_user_response(profile, request.email),
            tokens=TokenResponse(
                access_token=access_token,
                refresh_token=refresh_token,
                expires_in=expires_in,
            ),
        )

    async def logout(self, user_id: UUID) -> bool:
        """
        Deconnecte un utilisateur (invalide la session Supabase).
        """
        try:
            if hasattr(self._db.client.auth, 'admin'):
                self._db.client.auth.admin.sign_out(str(user_id))
        except Exception as e:
            logger.warning(f"Could not invalidate Supabase session for {user_id}: {e}")

        logger.info(f"User logged out: {user_id}")
        return True

    # =========================================================================
    # TOKEN REFRESH
    # =========================================================================

    async def refresh_tokens(self, refresh_token: str) -> TokenResponse:
        """
        Rafraichit les tokens via Supabase Auth.

        Raises:
            InvalidTokenError: Si le token est invalide
        """
        try:
            response = self._db.client.auth.refresh_session(refresh_token)

            if not response.session:
                raise InvalidTokenError("Refresh token invalide ou revoque")

            session = response.session
            logger.info("Tokens refreshed")

            return TokenResponse(
                access_token=session.access_token,
                refresh_token=session.refresh_token,
                expires_in=session.expires_in or 1800,
            )

        except InvalidTokenError:
            raise
        except Exception as e:
            error_msg = str(e).lower()
            if any(k in error_msg for k in ("expired", "invalid")):
                raise InvalidTokenError("Refresh token invalide ou expire")
            logger.error(f"Token refresh error: {e}")
            raise InvalidTokenError("Erreur lors du rafraichissement du token")

    # =========================================================================
    # PASSWORD RESET
    # =========================================================================

    async def request_password_reset(self, email: str) -> bool:
        """
        Demande une reinitialisation de mot de passe.
        Supabase envoie automatiquement l'email de reset.
        Retourne toujours True pour ne pas reveler si l'email existe.
        """
        try:
            self._db.client.auth.reset_password_for_email(
                email.lower(),
                options={"redirect_to": "https://activeduhub.com/reset-password"},
            )
            logger.info(f"Password reset email sent for: {email}")
        except Exception as e:
            logger.warning(f"Password reset request failed for {email}: {e}")

        return True

    async def reset_password(self, token: str, new_password: str) -> bool:
        """
        Reinitialise le mot de passe via le token du lien email.

        Args:
            token: Access token Supabase du lien de reset
            new_password: Nouveau mot de passe

        Raises:
            InvalidTokenError: Si le token est invalide
        """
        try:
            response = self._db.client.auth.get_user(token)
            if not response or not response.user:
                raise InvalidTokenError("Token de reinitialisation invalide")

            self._db.client.auth.admin.update_user_by_id(
                response.user.id,
                {"password": new_password},
            )

            logger.info(f"Password reset successful for: {response.user.email}")
            return True

        except InvalidTokenError:
            raise
        except Exception as e:
            logger.error(f"Password reset error: {e}")
            raise InvalidTokenError("Erreur lors de la reinitialisation du mot de passe")

    async def change_password(
        self,
        user_id: UUID,
        current_password: str,
        new_password: str,
    ) -> bool:
        """
        Change le mot de passe d'un utilisateur connecte.
        Verifie l'ancien mot de passe via re-authentification.

        Raises:
            AuthenticationError: Si le mot de passe actuel est incorrect
        """
        user = await self._users_repo.get_by_id(user_id)
        if not user:
            raise NotFoundError("Utilisateur", str(user_id))

        # Verifier l'ancien mot de passe via re-authentification Supabase
        try:
            self._db.client.auth.sign_in_with_password({
                "email": user["email"],
                "password": current_password,
            })
        except Exception:
            raise AuthenticationError("Mot de passe actuel incorrect")

        # Mettre a jour le mot de passe via admin API
        try:
            self._db.client.auth.admin.update_user_by_id(
                str(user_id),
                {"password": new_password},
            )
            logger.info(f"Password changed for user: {user_id}")
            return True
        except Exception as e:
            logger.error(f"Error changing password for {user_id}: {e}")
            raise AuthenticationError("Erreur lors du changement de mot de passe")

    # =========================================================================
    # PROFILE MANAGEMENT
    # =========================================================================

    async def get_profile(self, user_id: UUID) -> UserProfile:
        """Recupere le profil d'un utilisateur."""
        user = await self._users_repo.get_by_id(user_id)
        if not user:
            raise NotFoundError("Utilisateur", str(user_id))
        return self._to_user_profile(user)

    async def update_profile(
        self,
        user_id: UUID,
        request: UpdateProfileRequest,
    ) -> UserProfile:
        """Met a jour le profil d'un utilisateur."""
        update_data = request.model_dump(exclude_unset=True)

        if not update_data:
            raise ValidationError("Aucune donnee a mettre a jour")

        user = await self._users_repo.update_profile(user_id, update_data)

        logger.info(
            f"Profile updated for user: {user_id}",
            extra={"fields": list(update_data.keys())},
        )

        return self._to_user_profile(user)

    # =========================================================================
    # HELPERS
    # =========================================================================

    def _to_user_response(self, profile: dict, email: Optional[str] = None) -> UserResponse:
        """Convertit les donnees DB en UserResponse."""
        return UserResponse(
            id=UUID(profile["id"]),
            email=profile.get("email") or email or "",
            first_name=profile.get("first_name"),
            last_name=profile.get("last_name"),
            display_name=profile.get("display_name"),
            phone_number=profile.get("phone_number"),
            avatar_url=profile.get("avatar_url"),
            created_at=profile.get("created_at", datetime.now()),
        )

    def _to_user_profile(self, user: dict) -> UserProfile:
        """Convertit les donnees DB en UserProfile."""
        return UserProfile(
            id=UUID(user["id"]),
            email=user.get("email", ""),
            first_name=user.get("first_name"),
            last_name=user.get("last_name"),
            display_name=user.get("display_name"),
            phone_number=user.get("phone_number"),
            avatar_url=user.get("avatar_url"),
            date_of_birth=user.get("date_of_birth"),
            school_name=user.get("school_name"),
            class_level=user.get("class_level"),
            preferred_language=user.get("preferred_language", "fr"),
            created_at=user.get("created_at", datetime.now()),
            updated_at=user.get("updated_at"),
        )


# Instance singleton
auth_service = AuthService()


def get_auth_service() -> AuthService:
    """Retourne l'instance du service d'authentification."""
    return auth_service
