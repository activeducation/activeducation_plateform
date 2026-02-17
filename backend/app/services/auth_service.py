"""
Service d'authentification.

Gere la logique metier pour:
- Login/Register
- Token refresh
- Password reset
- Profile management
"""

from datetime import datetime, timedelta, timezone
from typing import Optional
from uuid import UUID

from app.core.logging import get_logger
from app.core.config import settings
from app.core.security import (
    hash_password,
    verify_password,
    create_token_pair,
    verify_refresh_token,
    create_password_reset_token,
    verify_password_reset_token,
    TokenPair,
)
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

logger = get_logger("services.auth")


class AuthService:
    """Service pour les operations d'authentification."""

    def __init__(self):
        self._users_repo: UsersRepository = get_users_repository()

    # =========================================================================
    # LOGIN / REGISTER
    # =========================================================================

    async def login(self, request: LoginRequest) -> AuthResponse:
        """
        Authentifie un utilisateur.

        Args:
            request: Email et mot de passe

        Returns:
            AuthResponse avec user et tokens

        Raises:
            AuthenticationError: Si credentials invalides
        """
        # Recuperer l'utilisateur par email
        user = await self._users_repo.get_by_email(request.email)

        if not user:
            logger.warning(f"Login attempt with unknown email: {request.email}")
            raise AuthenticationError("Email ou mot de passe incorrect")

        # Verifier le mot de passe
        if not verify_password(request.password, user.get("password_hash", "")):
            logger.warning(f"Invalid password for user: {request.email}")
            raise AuthenticationError("Email ou mot de passe incorrect")

        # Generer les tokens
        tokens = create_token_pair(user["id"], request.email)
        refresh_expires_at = datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
        await self._users_repo.save_refresh_token(
            UUID(user["id"]),
            tokens.refresh_token,
            refresh_expires_at,
        )

        # Mettre a jour la derniere connexion
        await self._users_repo.update_last_login(UUID(user["id"]))

        logger.info(f"User logged in: {request.email}")

        return AuthResponse(
            user=self._to_user_response(user),
            tokens=TokenResponse(
                access_token=tokens.access_token,
                refresh_token=tokens.refresh_token,
                expires_in=tokens.expires_in,
            ),
        )

    async def register(self, request: RegisterRequest) -> AuthResponse:
        """
        Inscrit un nouvel utilisateur.

        Args:
            request: Donnees d'inscription

        Returns:
            AuthResponse avec user et tokens

        Raises:
            AlreadyExistsError: Si l'email existe deja
        """
        # Verifier si l'email existe deja
        existing = await self._users_repo.get_by_email(request.email)
        if existing:
            raise AlreadyExistsError("Utilisateur", "email", request.email)

        # Hasher le mot de passe
        password_hash = hash_password(request.password)

        # Creer l'utilisateur
        user = await self._users_repo.create(
            email=request.email,
            password_hash=password_hash,
            first_name=request.first_name,
            last_name=request.last_name,
            phone_number=request.phone_number,
        )

        # Generer les tokens
        tokens = create_token_pair(user["id"], request.email)
        refresh_expires_at = datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
        await self._users_repo.save_refresh_token(
            UUID(user["id"]),
            tokens.refresh_token,
            refresh_expires_at,
        )

        logger.info(f"New user registered: {request.email}")

        return AuthResponse(
            user=self._to_user_response(user),
            tokens=TokenResponse(
                access_token=tokens.access_token,
                refresh_token=tokens.refresh_token,
                expires_in=tokens.expires_in,
            ),
        )

    async def logout(self, user_id: UUID) -> bool:
        """
        Deconnecte un utilisateur.

        Note: Dans une implementation complete, on invaliderait
        le refresh token en base de donnees.

        Args:
            user_id: ID de l'utilisateur

        Returns:
            True si succes
        """
        await self._users_repo.revoke_all_refresh_tokens(user_id)
        logger.info(f"User logged out: {user_id}")
        return True

    # =========================================================================
    # TOKEN REFRESH
    # =========================================================================

    async def refresh_tokens(self, refresh_token: str) -> TokenResponse:
        """
        Rafraichit les tokens avec un refresh token.

        Args:
            refresh_token: Token de rafraichissement

        Returns:
            Nouveaux tokens

        Raises:
            InvalidTokenError: Si le token est invalide
        """
        # Verifier le refresh token
        payload = verify_refresh_token(refresh_token)
        user_id = UUID(payload.sub)

        # Verifier que le refresh token est actif en base
        is_active = await self._users_repo.is_refresh_token_active(user_id, refresh_token)
        if not is_active:
            raise InvalidTokenError("Refresh token invalide ou revoque")

        # Verifier que l'utilisateur existe toujours
        user = await self._users_repo.get_by_id(user_id)
        if not user:
            raise InvalidTokenError("Utilisateur non trouve")

        # Generer de nouveaux tokens
        tokens = create_token_pair(payload.sub, user.get("email"))
        await self._users_repo.revoke_refresh_token(refresh_token)
        refresh_expires_at = datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
        await self._users_repo.save_refresh_token(
            user_id,
            tokens.refresh_token,
            refresh_expires_at,
        )

        logger.info(f"Tokens refreshed for user: {payload.sub}")

        return TokenResponse(
            access_token=tokens.access_token,
            refresh_token=tokens.refresh_token,
            expires_in=tokens.expires_in,
        )

    # =========================================================================
    # PASSWORD RESET
    # =========================================================================

    async def request_password_reset(self, email: str) -> bool:
        """
        Demande une reinitialisation de mot de passe.

        Args:
            email: Email de l'utilisateur

        Returns:
            True (meme si l'email n'existe pas, pour securite)
        """
        user = await self._users_repo.get_by_email(email)

        if user:
            # Generer le token de reset
            reset_token = create_password_reset_token(email)

            # TODO: Envoyer l'email avec le lien de reset
            logger.info(f"Password reset requested for: {email}")

            # Sauvegarder le token en DB (optionnel, pour invalidation)
            await self._users_repo.save_reset_token(UUID(user["id"]), reset_token)

        # Toujours retourner True pour ne pas reveler si l'email existe
        return True

    async def reset_password(self, token: str, new_password: str) -> bool:
        """
        Reinitialise le mot de passe avec un token.

        Args:
            token: Token de reinitialisation
            new_password: Nouveau mot de passe

        Returns:
            True si succes

        Raises:
            InvalidTokenError: Si le token est invalide
        """
        # Verifier le token
        email = verify_password_reset_token(token)

        # Recuperer l'utilisateur par token DB pour garantir l'invalidation serveur
        user = await self._users_repo.get_by_valid_reset_token(token)
        if not user:
            raise InvalidTokenError("Token de reinitialisation invalide ou expire")

        # Verifier la coherence entre token JWT et token stocke en DB
        if user.get("email", "").lower() != email.lower():
            raise InvalidTokenError("Token de reinitialisation invalide")

        # Hasher le nouveau mot de passe
        password_hash = hash_password(new_password)

        # Mettre a jour le mot de passe
        await self._users_repo.update_password(UUID(user["id"]), password_hash)

        # Invalider le token de reset
        await self._users_repo.invalidate_reset_token(UUID(user["id"]))

        logger.info(f"Password reset successful for: {email}")

        return True

    async def change_password(
        self,
        user_id: UUID,
        current_password: str,
        new_password: str,
    ) -> bool:
        """
        Change le mot de passe d'un utilisateur connecte.

        Args:
            user_id: ID de l'utilisateur
            current_password: Mot de passe actuel
            new_password: Nouveau mot de passe

        Returns:
            True si succes

        Raises:
            AuthenticationError: Si le mot de passe actuel est incorrect
        """
        user = await self._users_repo.get_by_id(user_id)
        if not user:
            raise NotFoundError("Utilisateur", str(user_id))

        # Verifier le mot de passe actuel
        if not verify_password(current_password, user.get("password_hash", "")):
            raise AuthenticationError("Mot de passe actuel incorrect")

        # Hasher et sauvegarder le nouveau mot de passe
        password_hash = hash_password(new_password)
        await self._users_repo.update_password(user_id, password_hash)

        logger.info(f"Password changed for user: {user_id}")

        return True

    # =========================================================================
    # PROFILE MANAGEMENT
    # =========================================================================

    async def get_profile(self, user_id: UUID) -> UserProfile:
        """
        Recupere le profil d'un utilisateur.

        Args:
            user_id: ID de l'utilisateur

        Returns:
            UserProfile

        Raises:
            NotFoundError: Si l'utilisateur n'existe pas
        """
        user = await self._users_repo.get_by_id(user_id)
        if not user:
            raise NotFoundError("Utilisateur", str(user_id))

        return self._to_user_profile(user)

    async def update_profile(
        self,
        user_id: UUID,
        request: UpdateProfileRequest,
    ) -> UserProfile:
        """
        Met a jour le profil d'un utilisateur.

        Args:
            user_id: ID de l'utilisateur
            request: Donnees a mettre a jour

        Returns:
            UserProfile mis a jour
        """
        # Filtrer les champs non-None
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

    def _to_user_response(self, user: dict) -> UserResponse:
        """Convertit les donnees DB en UserResponse."""
        return UserResponse(
            id=UUID(user["id"]),
            email=user["email"],
            first_name=user.get("first_name"),
            last_name=user.get("last_name"),
            display_name=user.get("display_name"),
            phone_number=user.get("phone_number"),
            avatar_url=user.get("avatar_url"),
            created_at=user.get("created_at", datetime.now()),
        )

    def _to_user_profile(self, user: dict) -> UserProfile:
        """Convertit les donnees DB en UserProfile."""
        return UserProfile(
            id=UUID(user["id"]),
            email=user["email"],
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
