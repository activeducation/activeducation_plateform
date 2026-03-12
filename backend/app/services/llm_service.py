"""
LLMService — Façade du service AÏDA.

Orchestre :
- SessionManager  : historique des conversations
- PromptBuilder   : construction des prompts système
- SafetyFilter    : détection d'injections et contenu hors-domaine
- GroqProvider    : appels Groq (principal) + Ollama (fallback)
"""

import uuid
import logging
from typing import AsyncGenerator, Optional

from app.services.llm.session_manager import SessionManager
from app.services.llm.prompt_builder import PromptBuilder
from app.services.llm.safety_filter import SafetyFilter
from app.services.llm.groq_provider import GroqProvider
from app.repositories.knowledge_base_repository import knowledge_base_repository

logger = logging.getLogger(__name__)

MAX_HISTORY = 10


class LLMService:
    """Service conversationnel AÏDA — Groq (principal) + Ollama (fallback)."""

    def __init__(self) -> None:
        self._sessions = SessionManager()
        self._prompt_builder = PromptBuilder(knowledge_base_repository)
        self._safety = SafetyFilter()
        self._provider = GroqProvider()

    async def chat(
        self,
        message: str,
        session_id: str,
        orientation_context: Optional[dict] = None,
        client_history: Optional[list[dict]] = None,
    ) -> dict:
        """Envoie un message et retourne la réponse complète."""
        message = self._safety.sanitize(message)

        if self._safety.is_injection_attempt(message):
            return {"reply": self._safety.get_rejection_message(), "session_id": session_id}

        history = self._sessions.get_history(session_id)
        if not history and client_history:
            history = self._sessions.seed_from_client(session_id, client_history)

        system_prompt = self._prompt_builder.build(orientation_context)
        messages = [{"role": "system", "content": system_prompt}]
        messages.extend(history[-MAX_HISTORY:])
        messages.append({"role": "user", "content": message})

        reply = await self._provider.complete(messages)

        if reply is None:
            return {
                "reply": (
                    "Je suis AÏDA, votre conseillère d'orientation. "
                    "Le service est temporairement indisponible. "
                    "Réessaie dans quelques instants !"
                ),
                "session_id": session_id,
            }

        self._sessions.append(session_id, message, reply)
        return {"reply": reply, "session_id": session_id}

    async def chat_stream(
        self,
        message: str,
        session_id: str,
        orientation_context: Optional[dict] = None,
        client_history: Optional[list[dict]] = None,
    ) -> AsyncGenerator[dict, None]:
        """Envoie un message et stream la réponse chunk par chunk."""
        message = self._safety.sanitize(message)

        if self._safety.is_injection_attempt(message):
            yield {"chunk": self._safety.get_rejection_message()}
            yield {"done": True}
            return

        history = self._sessions.get_history(session_id)
        if not history and client_history:
            history = self._sessions.seed_from_client(session_id, client_history)

        system_prompt = self._prompt_builder.build(orientation_context)
        messages = [{"role": "system", "content": system_prompt}]
        messages.extend(history[-MAX_HISTORY:])
        messages.append({"role": "user", "content": message})

        full_reply_parts: list[str] = []

        async for chunk in self._provider.stream(messages):
            full_reply_parts.append(chunk)
            yield {"chunk": chunk}

        full_reply = "".join(full_reply_parts)
        if full_reply:
            self._sessions.append(session_id, message, full_reply)

        yield {"done": True}

    def clear_session(self, session_id: str) -> None:
        self._sessions.clear(session_id)

    def get_history(self, session_id: str) -> list[dict]:
        return self._sessions.get_history(session_id)

    @staticmethod
    def new_session_id() -> str:
        return str(uuid.uuid4())


# Singleton partagé
llm_service = LLMService()
