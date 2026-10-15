"""Repository de la maitrise par competence (user_skill_mastery).

Acces via service_role. La maitrise appartient a l'utilisateur : chaque
requete filtre par user_id (l'appelant passe le user_id authentifie).
"""

from datetime import datetime, timezone
from functools import lru_cache
from typing import Any, Optional
from uuid import UUID

from app.core.logging import get_logger
from app.core.exceptions import QueryError
from app.db.supabase_client import get_admin_supabase_client, SupabaseClient

logger = get_logger("repositories.mastery")

_TABLE = "user_skill_mastery"


class MasteryRepository:
    """CRUD de la maitrise (user_skill_mastery)."""

    def __init__(self) -> None:
        self._db: SupabaseClient = get_admin_supabase_client()

    async def get(self, user_id: UUID, skill_id: UUID) -> Optional[dict[str, Any]]:
        """Maitrise actuelle pour (user, skill), ou None si jamais evaluee."""
        try:
            result = (
                self._db.client.table(_TABLE)
                .select("*")
                .eq("user_id", str(user_id))
                .eq("skill_id", str(skill_id))
                .limit(1)
                .execute()
            )
            return result.data[0] if result.data else None
        except Exception as e:
            logger.error("Erreur lecture maitrise: %s", e, exc_info=True)
            raise QueryError(f"Erreur lors de la lecture de la maitrise: {str(e)}")

    async def upsert(
        self,
        user_id: UUID,
        skill_id: UUID,
        p_mastery: float,
        attempts: int,
        correct: int,
    ) -> dict[str, Any]:
        """Insere ou met a jour la maitrise (conflit sur user_id+skill_id)."""
        try:
            data = {
                "user_id": str(user_id),
                "skill_id": str(skill_id),
                "p_mastery": p_mastery,
                "attempts": attempts,
                "correct": correct,
                "last_updated": datetime.now(timezone.utc).isoformat(),
            }
            result = (
                self._db.client.table(_TABLE)
                .upsert(data, on_conflict="user_id,skill_id")
                .execute()
            )
            return result.data[0] if result.data else data
        except Exception as e:
            logger.error("Erreur upsert maitrise: %s", e, exc_info=True)
            raise QueryError(f"Erreur lors de la mise a jour de la maitrise: {str(e)}")

    async def list_for_user(self, user_id: UUID) -> list[dict[str, Any]]:
        """Toute la maitrise d'un utilisateur, la plus faible d'abord."""
        try:
            result = (
                self._db.client.table(_TABLE)
                .select("skill_id, p_mastery, attempts, correct, last_updated")
                .eq("user_id", str(user_id))
                .order("p_mastery", desc=False)
                .execute()
            )
            return result.data or []
        except Exception as e:
            logger.error("Erreur liste maitrise: %s", e, exc_info=True)
            raise QueryError(f"Erreur lors de la lecture de la maitrise: {str(e)}")

    async def list_weak(
        self,
        user_id: UUID,
        threshold: float,
        limit: int = 10,
    ) -> list[dict[str, Any]]:
        """Competences sous le seuil de maitrise, la plus faible d'abord."""
        try:
            result = (
                self._db.client.table(_TABLE)
                .select("skill_id, p_mastery, attempts, correct")
                .eq("user_id", str(user_id))
                .lt("p_mastery", threshold)
                .order("p_mastery", desc=False)
                .limit(limit)
                .execute()
            )
            return result.data or []
        except Exception as e:
            logger.error("Erreur liste competences faibles: %s", e, exc_info=True)
            raise QueryError(f"Erreur lors de la lecture des competences: {str(e)}")


@lru_cache(maxsize=1)
def get_mastery_repository() -> MasteryRepository:
    """Retourne l'instance (unique) du repository de maitrise."""
    return MasteryRepository()
