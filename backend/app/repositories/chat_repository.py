"""Repository des conversations TutorAI (chat_sessions / chat_messages).

Remplace le stockage memoire de `SessionManager` par une persistance
durable, multi-worker safe.

SECURITE — ownership applicatif : le backend utilise le service_role, qui
CONTOURNE la RLS Postgres. L'appartenance d'une session/message a son
proprietaire doit donc etre imposee ici, sur CHAQUE requete, via un filtre
`user_id`. Aucune methode n'expose une session sans verifier le user_id.
"""

from datetime import datetime, timezone
from functools import lru_cache
from typing import Any, Optional
from uuid import UUID, uuid4

from app.core.logging import get_logger
from app.core.exceptions import QueryError
from app.db.supabase_client import get_admin_supabase_client, SupabaseClient

logger = get_logger("repositories.chat")

_SESSIONS = "chat_sessions"
_MESSAGES = "chat_messages"
_ALLOWED_ROLES = ("user", "assistant", "system")


class ChatRepository:
    """CRUD des conversations, avec ownership impose sur chaque acces."""

    def __init__(self) -> None:
        self._db: SupabaseClient = get_admin_supabase_client()

    # =========================================================================
    # SESSIONS
    # =========================================================================

    async def create_session(
        self,
        user_id: UUID,
        session_id: Optional[UUID] = None,
        subject_context: Optional[dict[str, Any]] = None,
        provider: Optional[str] = None,
        title: Optional[str] = None,
    ) -> dict[str, Any]:
        """Cree une session de conversation pour un utilisateur."""
        try:
            now = datetime.now(timezone.utc).isoformat()
            data = {
                "id": str(session_id or uuid4()),
                "user_id": str(user_id),
                "subject_context": subject_context or {},
                "provider": provider,
                "title": title,
                "message_count": 0,
                "last_active_at": now,
                "created_at": now,
                "updated_at": now,
            }
            result = self._db.insert(table=_SESSIONS, data=data)
            logger.info("Session chat creee %s (user %s)", data["id"], user_id)
            return result[0] if result else data
        except Exception as e:
            logger.error("Erreur creation session chat: %s", e, exc_info=True)
            raise QueryError(f"Erreur lors de la creation de la session: {str(e)}")

    async def get_session(
        self,
        session_id: UUID,
        user_id: UUID,
    ) -> Optional[dict[str, Any]]:
        """Recupere une session SI elle appartient a l'utilisateur, sinon None."""
        try:
            result = (
                self._db.client.table(_SESSIONS)
                .select("*")
                .eq("id", str(session_id))
                .eq("user_id", str(user_id))  # ownership
                .limit(1)
                .execute()
            )
            return result.data[0] if result.data else None
        except Exception as e:
            logger.error("Erreur lecture session %s: %s", session_id, e, exc_info=True)
            raise QueryError(f"Erreur lors de la lecture de la session: {str(e)}")

    async def list_sessions(
        self,
        user_id: UUID,
        limit: int = 20,
    ) -> list[dict[str, Any]]:
        """Liste les sessions d'un utilisateur, les plus recentes d'abord."""
        try:
            result = (
                self._db.client.table(_SESSIONS)
                .select("id, title, subject_context, message_count, last_active_at, created_at")
                .eq("user_id", str(user_id))
                .order("last_active_at", desc=True)
                .limit(limit)
                .execute()
            )
            return result.data or []
        except Exception as e:
            logger.error("Erreur liste sessions user %s: %s", user_id, e, exc_info=True)
            raise QueryError(f"Erreur lors de la liste des sessions: {str(e)}")

    async def clear_session(self, session_id: UUID, user_id: UUID) -> bool:
        """Supprime une session (et ses messages en cascade) si proprietaire.

        Retourne False si la session n'existe pas ou n'appartient pas a
        l'utilisateur — jamais d'erreur silencieuse d'ownership.
        """
        try:
            result = (
                self._db.client.table(_SESSIONS)
                .delete()
                .eq("id", str(session_id))
                .eq("user_id", str(user_id))  # ownership
                .execute()
            )
            deleted = bool(result.data)
            if deleted:
                logger.info("Session chat %s effacee (user %s)", session_id, user_id)
            return deleted
        except Exception as e:
            logger.error("Erreur suppression session %s: %s", session_id, e, exc_info=True)
            raise QueryError(f"Erreur lors de la suppression de la session: {str(e)}")

    # =========================================================================
    # MESSAGES
    # =========================================================================

    async def append_message(
        self,
        session_id: UUID,
        user_id: UUID,
        role: str,
        content: str,
        token_count: Optional[int] = None,
        metadata: Optional[dict[str, Any]] = None,
    ) -> dict[str, Any]:
        """Ajoute un message a une session et met a jour les compteurs.

        L'appelant DOIT avoir verifie l'ownership de la session au prealable
        (via get_session ou create_session) ; le user_id denormalise garantit
        que meme un session_id errone ne fuite pas vers un autre proprietaire.
        """
        if role not in _ALLOWED_ROLES:
            raise QueryError(f"Role de message invalide: {role!r}")
        try:
            data = {
                "session_id": str(session_id),
                "user_id": str(user_id),
                "role": role,
                "content": content,
                "token_count": token_count,
                "metadata": metadata or {},
                "created_at": datetime.now(timezone.utc).isoformat(),
            }
            result = self._db.insert(table=_MESSAGES, data=data)
            await self._touch_session(session_id, user_id)
            return result[0] if result else data
        except QueryError:
            raise
        except Exception as e:
            logger.error("Erreur ajout message session %s: %s", session_id, e, exc_info=True)
            raise QueryError(f"Erreur lors de l'ajout du message: {str(e)}")

    async def get_history(
        self,
        session_id: UUID,
        user_id: UUID,
        limit: int = 20,
    ) -> list[dict[str, str]]:
        """Retourne les derniers messages {role, content}, ordre chronologique.

        Filtre par user_id : une session d'un autre proprietaire renvoie [].
        """
        try:
            result = (
                self._db.client.table(_MESSAGES)
                .select("role, content, created_at")
                .eq("session_id", str(session_id))
                .eq("user_id", str(user_id))  # ownership
                .order("created_at", desc=True)
                .limit(limit)
                .execute()
            )
            rows = result.data or []
            rows.reverse()  # remettre en ordre chronologique
            return [{"role": r["role"], "content": r["content"]} for r in rows]
        except Exception as e:
            logger.error("Erreur historique session %s: %s", session_id, e, exc_info=True)
            raise QueryError(f"Erreur lors de la lecture de l'historique: {str(e)}")

    # =========================================================================
    # INTERNE
    # =========================================================================

    async def _touch_session(self, session_id: UUID, user_id: UUID) -> None:
        """Met a jour last_active_at (best-effort, non bloquant).

        message_count n'est PAS incremente ici pour eviter un read-modify-write
        sujet aux races entre workers ; il sera maintenu par un trigger SQL ou
        un RPC d'increment atomique dans une phase ulterieure.
        """
        try:
            now = datetime.now(timezone.utc).isoformat()
            self._db.client.table(_SESSIONS).update({
                "last_active_at": now,
                "updated_at": now,
            }).eq("id", str(session_id)).eq("user_id", str(user_id)).execute()
        except Exception as e:
            logger.warning("touch_session %s echoue (non bloquant): %s", session_id, e)


@lru_cache(maxsize=1)
def get_chat_repository() -> ChatRepository:
    """Retourne l'instance (unique) du repository de conversations."""
    return ChatRepository()
