"""
Repository pour les operations utilisateurs.

Gere les interactions avec Supabase pour:
- CRUD profils (user_profiles)
- Pas de gestion de mots de passe (deleguee a Supabase Auth)
"""

from datetime import datetime, timezone
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
    """Repository pour les operations sur les profils utilisateurs."""

    def __init__(self):
        self._db: SupabaseClient = get_supabase_client()

    # =========================================================================
    # READ OPERATIONS
    # =========================================================================

    async def get_by_id(self, user_id: UUID) -> Optional[dict[str, Any]]:
        """
        Recupere un profil utilisateur par son ID.

        Args:
            user_id: UUID de l'utilisateur (same que auth.users.id)

        Returns:
            Donnees profil ou None
        """
        try:
            return self._db.fetch_one(
                table="user_profiles",
                id_column="id",
                id_value=str(user_id),
            )
        except Exception as e:
            logger.error(f"Error fetching user {user_id}: {e}")
            raise QueryError(f"Erreur lors de la recuperation de l'utilisateur: {str(e)}")

    async def get_by_email(self, email: str) -> Optional[dict[str, Any]]:
        """
        Recupere un profil utilisateur par son email.

        Args:
            email: Email de l'utilisateur

        Returns:
            Donnees profil ou None
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

    async def create_profile(
        self,
        user_id: UUID,
        email: str,
        first_name: Optional[str] = None,
        last_name: Optional[str] = None,
        phone_number: Optional[str] = None,
    ) -> dict[str, Any]:
        """
        Cree le profil d'un utilisateur apres inscription via Supabase Auth.

        L'ID doit correspondre a l'ID genere par Supabase Auth (auth.users.id).

        Args:
            user_id: UUID de l'utilisateur (fourni par Supabase Auth)
            email: Email de l'utilisateur
            first_name: Prenom (optionnel)
            last_name: Nom (optionnel)
            phone_number: Numero de telephone (optionnel)

        Returns:
            Donnees du profil cree
        """
        try:
            data = {
                "id": str(user_id),
                "email": email.lower(),
                "first_name": first_name,
                "last_name": last_name,
                "phone_number": phone_number,
                "display_name": f"{first_name} {last_name}".strip() if first_name else None,
                "preferred_language": "fr",
                "created_at": datetime.now(timezone.utc).isoformat(),
            }

            # Retirer les valeurs None pour eviter les erreurs de schema
            data = {k: v for k, v in data.items() if v is not None or k in ("id", "email")}

            result = self._db.insert(table="user_profiles", data=data)
            logger.info(f"Created profile for user: {user_id}")
            return result[0] if result else data

        except Exception as e:
            if "duplicate" in str(e).lower() or "unique" in str(e).lower():
                raise AlreadyExistsError("Utilisateur", "email", email)
            logger.error(f"Error creating profile: {e}")
            raise QueryError(f"Erreur lors de la creation du profil: {str(e)}")

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
            data["updated_at"] = datetime.now(timezone.utc).isoformat()

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

    async def update_last_login(self, user_id: UUID) -> bool:
        """Met a jour la date de derniere connexion."""
        try:
            self._db.update(
                table="user_profiles",
                id_column="id",
                id_value=str(user_id),
                data={"last_login_at": datetime.now(timezone.utc).isoformat()},
            )
            return True
        except Exception as e:
            logger.warning(f"Could not update last_login for user {user_id}: {e}")
            return False

    async def update_avatar(self, user_id: UUID, avatar_url: str) -> dict[str, Any]:
        """Met a jour l'avatar d'un utilisateur."""
        return await self.update_profile(user_id, {"avatar_url": avatar_url})

    # =========================================================================
    # DELETE
    # =========================================================================

    async def delete(self, user_id: UUID) -> bool:
        """
        Supprime le profil d'un utilisateur.
        Note: Cela ne supprime pas l'utilisateur de Supabase Auth.
        Utiliser l'admin API Supabase pour supprimer completement.
        """
        try:
            result = self._db.delete(
                table="user_profiles",
                id_column="id",
                id_value=str(user_id),
            )
            return len(result) > 0
        except Exception as e:
            logger.error(f"Error deleting user profile: {e}")
            raise QueryError(f"Erreur lors de la suppression du profil: {str(e)}")

    # =========================================================================
    # SEARCH
    # =========================================================================

    async def search(self, query: str, limit: int = 10) -> list[dict[str, Any]]:
        """Recherche des utilisateurs par nom ou email."""
        try:
            result = (
                self._db.client.table("user_profiles")
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
