"""
Repository pour les operations utilisateurs.

Gere les interactions avec Supabase pour:
- CRUD utilisateurs
- Authentification
- Profils
"""

from datetime import datetime, timedelta, timezone
import hashlib
from typing import Any, Optional
from uuid import UUID

from app.db.supabase_client import get_supabase_client, SupabaseClient
from app.core.logging import get_logger
from app.core.exceptions import (
    NotFoundError,
    QueryError,
    AlreadyExistsError,
)

logger = get_logger("repositories.users")


class UsersRepository:
    """Repository pour les operations utilisateurs."""

    def __init__(self):
        self._db: SupabaseClient = get_supabase_client()

    # =========================================================================
    # READ OPERATIONS
    # =========================================================================

    async def get_by_id(self, user_id: UUID) -> Optional[dict[str, Any]]:
        """
        Recupere un utilisateur par son ID.

        Args:
            user_id: UUID de l'utilisateur

        Returns:
            Donnees utilisateur ou None
        """
        try:
            user = self._db.fetch_one(
                table="user_profiles",
                id_column="id",
                id_value=str(user_id),
            )
            return user

        except Exception as e:
            logger.error(f"Error fetching user {user_id}: {e}")
            raise QueryError(f"Erreur lors de la recuperation de l'utilisateur: {str(e)}")

    async def get_by_email(self, email: str) -> Optional[dict[str, Any]]:
        """
        Recupere un utilisateur par son email.

        Args:
            email: Email de l'utilisateur

        Returns:
            Donnees utilisateur ou None
        """
        try:
            users = self._db.fetch_all(
                table="user_profiles",
                filters={"email": email.lower()},
                limit=1,
            )
            return users[0] if users else None

        except Exception as e:
            logger.error(f"Error fetching user by email: {e}")
            raise QueryError(f"Erreur lors de la recherche de l'utilisateur: {str(e)}")

    # =========================================================================
    # CREATE / UPDATE OPERATIONS
    # =========================================================================

    async def create(
        self,
        email: str,
        password_hash: str,
        first_name: Optional[str] = None,
        last_name: Optional[str] = None,
        phone_number: Optional[str] = None,
    ) -> dict[str, Any]:
        """
        Cree un nouvel utilisateur.

        Note: Dans une implementation complete avec Supabase Auth,
        on utiliserait supabase.auth.sign_up() puis on creerait le profil.

        Args:
            email: Email de l'utilisateur
            password_hash: Hash du mot de passe
            first_name: Prenom
            last_name: Nom
            phone_number: Numero de telephone

        Returns:
            Donnees de l'utilisateur cree
        """
        try:
            # Generer un UUID pour le nouvel utilisateur
            # Note: En production avec Supabase Auth, l'ID viendrait de auth.users
            import uuid
            user_id = str(uuid.uuid4())

            data = {
                "id": user_id,
                "email": email.lower(),
                "password_hash": password_hash,
                "first_name": first_name,
                "last_name": last_name,
                "phone_number": phone_number,
                "display_name": f"{first_name} {last_name}".strip() if first_name else None,
                "preferred_language": "fr",
                "created_at": datetime.utcnow().isoformat(),
            }

            result = self._db.insert(table="user_profiles", data=data)

            logger.info(f"Created new user: {email}")
            return result[0] if result else data

        except Exception as e:
            if "duplicate" in str(e).lower() or "unique" in str(e).lower():
                raise AlreadyExistsError("Utilisateur", "email", email)
            logger.error(f"Error creating user: {e}")
            raise QueryError(f"Erreur lors de la creation de l'utilisateur: {str(e)}")

    async def update_profile(
        self,
        user_id: UUID,
        data: dict[str, Any],
    ) -> dict[str, Any]:
        """
        Met a jour le profil d'un utilisateur.

        Args:
            user_id: UUID de l'utilisateur
            data: Donnees a mettre a jour

        Returns:
            Profil mis a jour
        """
        try:
            # Ajouter updated_at
            data["updated_at"] = datetime.utcnow().isoformat()

            result = self._db.update(
                table="user_profiles",
                id_column="id",
                id_value=str(user_id),
                data=data,
            )

            if not result:
                raise NotFoundError("Utilisateur", str(user_id))

            return result[0]

        except NotFoundError:
            raise
        except Exception as e:
            logger.error(f"Error updating user profile: {e}")
            raise QueryError(f"Erreur lors de la mise a jour du profil: {str(e)}")

    async def update_password(
        self,
        user_id: UUID,
        password_hash: str,
    ) -> bool:
        """
        Met a jour le mot de passe d'un utilisateur.

        Args:
            user_id: UUID de l'utilisateur
            password_hash: Nouveau hash du mot de passe

        Returns:
            True si succes
        """
        try:
            result = self._db.update(
                table="user_profiles",
                id_column="id",
                id_value=str(user_id),
                data={
                    "password_hash": password_hash,
                    "updated_at": datetime.utcnow().isoformat(),
                },
            )

            return len(result) > 0

        except Exception as e:
            logger.error(f"Error updating password: {e}")
            raise QueryError(f"Erreur lors de la mise a jour du mot de passe: {str(e)}")

    async def update_last_login(self, user_id: UUID) -> bool:
        """
        Met a jour la date de derniere connexion.

        Args:
            user_id: UUID de l'utilisateur

        Returns:
            True si succes
        """
        try:
            self._db.update(
                table="user_profiles",
                id_column="id",
                id_value=str(user_id),
                data={"last_login_at": datetime.utcnow().isoformat()},
            )
            return True

        except Exception as e:
            # Ne pas echouer si la mise a jour de last_login echoue
            logger.warning(f"Could not update last_login for user {user_id}: {e}")
            return False

    async def update_avatar(
        self,
        user_id: UUID,
        avatar_url: str,
    ) -> dict[str, Any]:
        """
        Met a jour l'avatar d'un utilisateur.

        Args:
            user_id: UUID de l'utilisateur
            avatar_url: URL du nouvel avatar

        Returns:
            Profil mis a jour
        """
        return await self.update_profile(user_id, {"avatar_url": avatar_url})

    # =========================================================================
    # PASSWORD RESET
    # =========================================================================

    async def save_reset_token(
        self,
        user_id: UUID,
        token: str,
    ) -> bool:
        """
        Sauvegarde un token de reset de mot de passe.

        Args:
            user_id: UUID de l'utilisateur
            token: Token de reset

        Returns:
            True si succes
        """
        try:
            expires_at = datetime.now(timezone.utc) + timedelta(hours=1)
            self._db.update(
                table="user_profiles",
                id_column="id",
                id_value=str(user_id),
                data={
                    "reset_token": token,
                    "reset_token_expires": expires_at.isoformat(),
                },
            )
            return True

        except Exception as e:
            logger.error(f"Error saving reset token: {e}")
            return False

    async def get_by_valid_reset_token(self, token: str) -> Optional[dict[str, Any]]:
        """
        Recupere un utilisateur avec un token de reset valide et non expire.

        Args:
            token: Token de reset

        Returns:
            Donnees utilisateur ou None si token invalide/expire
        """
        try:
            now_iso = datetime.now(timezone.utc).isoformat()
            result = (
                self._db.client.table("user_profiles")
                .select("*")
                .eq("reset_token", token)
                .gt("reset_token_expires", now_iso)
                .limit(1)
                .execute()
            )
            return result.data[0] if result.data else None
        except Exception as e:
            logger.error(f"Error fetching user by reset token: {e}")
            return None

    async def invalidate_reset_token(self, user_id: UUID) -> bool:
        """
        Invalide le token de reset d'un utilisateur.

        Args:
            user_id: UUID de l'utilisateur

        Returns:
            True si succes
        """
        try:
            self._db.update(
                table="user_profiles",
                id_column="id",
                id_value=str(user_id),
                data={
                    "reset_token": None,
                    "reset_token_expires": None,
                },
            )
            return True

        except Exception as e:
            logger.warning(f"Could not invalidate reset token: {e}")
            return False

    # =========================================================================
    # REFRESH TOKENS
    # =========================================================================

    @staticmethod
    def _hash_token(token: str) -> str:
        """Hash SHA-256 d'un token pour stockage en base."""
        return hashlib.sha256(token.encode("utf-8")).hexdigest()

    async def save_refresh_token(
        self,
        user_id: UUID,
        refresh_token: str,
        expires_at: datetime,
    ) -> bool:
        """
        Sauvegarde un refresh token actif.
        """
        try:
            self._db.insert(
                table="auth_refresh_tokens",
                data={
                    "user_id": str(user_id),
                    "token_hash": self._hash_token(refresh_token),
                    "expires_at": expires_at.astimezone(timezone.utc).isoformat(),
                    "revoked_at": None,
                },
            )
            return True
        except Exception as e:
            logger.error(f"Error saving refresh token: {e}")
            return False

    async def is_refresh_token_active(self, user_id: UUID, refresh_token: str) -> bool:
        """
        Verifie qu'un refresh token est actif (non revoke et non expire).
        """
        try:
            now_iso = datetime.now(timezone.utc).isoformat()
            token_hash = self._hash_token(refresh_token)
            result = (
                self._db.client.table("auth_refresh_tokens")
                .select("id")
                .eq("user_id", str(user_id))
                .eq("token_hash", token_hash)
                .is_("revoked_at", "null")
                .gt("expires_at", now_iso)
                .limit(1)
                .execute()
            )
            return bool(result.data)
        except Exception as e:
            logger.error(f"Error validating refresh token: {e}")
            return False

    async def revoke_refresh_token(self, refresh_token: str) -> bool:
        """
        Revoque un refresh token specifique.
        """
        try:
            token_hash = self._hash_token(refresh_token)
            self._db.client.table("auth_refresh_tokens").update(
                {"revoked_at": datetime.now(timezone.utc).isoformat()}
            ).eq("token_hash", token_hash).is_("revoked_at", "null").execute()
            return True
        except Exception as e:
            logger.warning(f"Could not revoke refresh token: {e}")
            return False

    async def revoke_all_refresh_tokens(self, user_id: UUID) -> bool:
        """
        Revoque tous les refresh tokens actifs d'un utilisateur.
        """
        try:
            self._db.client.table("auth_refresh_tokens").update(
                {"revoked_at": datetime.now(timezone.utc).isoformat()}
            ).eq("user_id", str(user_id)).is_("revoked_at", "null").execute()
            return True
        except Exception as e:
            logger.warning(f"Could not revoke refresh tokens for user {user_id}: {e}")
            return False

    # =========================================================================
    # DELETE
    # =========================================================================

    async def delete(self, user_id: UUID) -> bool:
        """
        Supprime un utilisateur.

        Args:
            user_id: UUID de l'utilisateur

        Returns:
            True si succes
        """
        try:
            result = self._db.delete(
                table="user_profiles",
                id_column="id",
                id_value=str(user_id),
            )
            return len(result) > 0

        except Exception as e:
            logger.error(f"Error deleting user: {e}")
            raise QueryError(f"Erreur lors de la suppression de l'utilisateur: {str(e)}")

    # =========================================================================
    # SEARCH
    # =========================================================================

    async def search(
        self,
        query: str,
        limit: int = 10,
    ) -> list[dict[str, Any]]:
        """
        Recherche des utilisateurs par nom ou email.

        Args:
            query: Texte de recherche
            limit: Nombre max de resultats

        Returns:
            Liste des utilisateurs correspondants
        """
        try:
            # Utiliser le client brut pour une recherche ILIKE
            client = self._db.client
            result = (
                client.table("user_profiles")
                .select("id, email, first_name, last_name, display_name, avatar_url")
                .or_(f"email.ilike.%{query}%,first_name.ilike.%{query}%,last_name.ilike.%{query}%")
                .limit(limit)
                .execute()
            )

            return result.data

        except Exception as e:
            logger.error(f"Error searching users: {e}")
            return []


# Instance singleton
users_repo = UsersRepository()


def get_users_repository() -> UsersRepository:
    """Retourne l'instance du repository utilisateurs."""
    return users_repo
