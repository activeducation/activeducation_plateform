"""SessionStore — stockage d'historique de conversation, memoire ou DB.

Remplace a terme le `SessionManager` en memoire. Deux modes, choisis par
`settings.TUTOR_PERSIST_SESSIONS` :

- False (defaut) : delegue a un cache memoire process. Comportement
  identique a l'existant, zero dependance DB. C'est le mode actif en prod
  tant que la migration 018 n'est pas deployee.
- True : persiste via `ChatRepository` (multi-worker safe). En cas d'erreur
  DB, repli automatique sur la memoire pour ne jamais casser une reponse a
  l'utilisateur (resilience > exhaustivite du log).

Interface asynchrone, prete a etre cablee dans le service de chat en Phase 1
sans changer les appelants.
"""

from __future__ import annotations

from collections import OrderedDict
from typing import Any, Optional
from uuid import UUID

from app.core.config import settings
from app.core.logging import get_logger
from app.repositories.chat_repository import ChatRepository, get_chat_repository

logger = get_logger("services.tutor.session_store")

_MAX_MEMORY_SESSIONS = 1000


class _MemoryBackend:
    """Cache d'historique en memoire, avec eviction LRU."""

    def __init__(self) -> None:
        self._sessions: "OrderedDict[str, list[dict]]" = OrderedDict()

    def get_history(self, session_id: str, limit: int) -> list[dict]:
        history = self._sessions.get(session_id)
        if history is None:
            return []
        self._sessions.move_to_end(session_id)
        return list(history[-limit:])

    def append(self, session_id: str, role: str, content: str) -> None:
        history = self._sessions.get(session_id, [])
        history.append({"role": role, "content": content})
        self._sessions[session_id] = history
        self._sessions.move_to_end(session_id)
        while len(self._sessions) > _MAX_MEMORY_SESSIONS:
            evicted, _ = self._sessions.popitem(last=False)
            logger.debug("Session evincee (LRU): %s", evicted)

    def clear(self, session_id: str) -> None:
        self._sessions.pop(session_id, None)


class SessionStore:
    """Facade unique : DB si activee, memoire sinon (avec repli)."""

    def __init__(self, repository: Optional[ChatRepository] = None) -> None:
        self._memory = _MemoryBackend()
        self._repo = repository
        self._history_limit = settings.TUTOR_SESSION_HISTORY_LIMIT

    @property
    def _persist(self) -> bool:
        return settings.TUTOR_PERSIST_SESSIONS

    def _get_repo(self) -> ChatRepository:
        if self._repo is None:
            self._repo = get_chat_repository()
        return self._repo

    async def get_history(
        self,
        session_id: UUID,
        user_id: UUID,
        limit: Optional[int] = None,
    ) -> list[dict[str, str]]:
        """Retourne l'historique {role, content} en ordre chronologique."""
        limit = limit or self._history_limit
        if self._persist:
            try:
                return await self._get_repo().get_history(session_id, user_id, limit)
            except Exception as e:
                logger.warning("get_history DB echoue, repli memoire: %s", e)
        return self._memory.get_history(str(session_id), limit)

    async def append(
        self,
        session_id: UUID,
        user_id: UUID,
        user_message: str,
        assistant_reply: str,
        token_count: Optional[int] = None,
    ) -> None:
        """Ajoute un echange (message utilisateur + reponse assistant)."""
        if self._persist:
            try:
                repo = self._get_repo()
                await repo.append_message(session_id, user_id, "user", user_message)
                await repo.append_message(
                    session_id, user_id, "assistant", assistant_reply,
                    token_count=token_count,
                )
                return
            except Exception as e:
                logger.warning("append DB echoue, repli memoire: %s", e)
        self._memory.append(str(session_id), "user", user_message)
        self._memory.append(str(session_id), "assistant", assistant_reply)

    async def clear(self, session_id: UUID, user_id: UUID) -> bool:
        """Efface une session. Retourne True si quelque chose a ete supprime."""
        if self._persist:
            try:
                return await self._get_repo().clear_session(session_id, user_id)
            except Exception as e:
                logger.warning("clear DB echoue, repli memoire: %s", e)
        self._memory.clear(str(session_id))
        return True

    @staticmethod
    def seed_from_client(
        client_history: list[dict],
        limit: int,
    ) -> list[dict[str, str]]:
        """Filtre/tronque un historique fourni par le client (seeding contexte)."""
        return [
            {"role": m["role"], "content": m["content"]}
            for m in client_history
            if m.get("role") in ("user", "assistant") and m.get("content")
        ][-limit:]
