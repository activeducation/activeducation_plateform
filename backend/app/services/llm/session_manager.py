"""
SessionManager — Gestion de l'historique des conversations AÏDA.

Stocke les sessions en mémoire avec éviction LRU quand la limite est atteinte.
"""

import logging
from typing import Optional

logger = logging.getLogger(__name__)

MAX_SESSIONS = 1000
MAX_HISTORY = 10  # Messages conservés par session (5 échanges)


class SessionManager:
    """Gère les sessions de conversation en mémoire."""

    def __init__(self) -> None:
        self._sessions: dict[str, list[dict]] = {}

    def get_history(self, session_id: str) -> list[dict]:
        """Retourne l'historique d'une session (liste vide si inconnue)."""
        return list(self._sessions.get(session_id, []))

    def seed_from_client(
        self,
        session_id: str,
        client_history: list[dict],
    ) -> list[dict]:
        """
        Reconstruit le contexte depuis l'historique client si la session
        est inconnue du serveur (après redémarrage).
        """
        if session_id in self._sessions:
            return self.get_history(session_id)

        history = [
            {"role": m["role"], "content": m["content"]}
            for m in client_history
            if m.get("role") in ("user", "assistant") and m.get("content")
        ][-MAX_HISTORY:]

        if history:
            logger.info(
                "Session %s restaurée depuis l'historique client (%d messages)",
                session_id, len(history),
            )

        return history

    def append(self, session_id: str, user_message: str, assistant_reply: str) -> None:
        """Ajoute un échange à l'historique de la session."""
        history = list(self._sessions.get(session_id, []))
        history.append({"role": "user", "content": user_message})
        history.append({"role": "assistant", "content": assistant_reply})

        # Éviction LRU si limite atteinte
        if len(self._sessions) >= MAX_SESSIONS and session_id not in self._sessions:
            oldest = next(iter(self._sessions))
            del self._sessions[oldest]
            logger.debug("Session évincée (LRU): %s", oldest)

        self._sessions[session_id] = history

    def clear(self, session_id: str) -> None:
        """Efface l'historique d'une session."""
        self._sessions.pop(session_id, None)
