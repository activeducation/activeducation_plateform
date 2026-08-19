"""LLMService — Façade du service AÏDA / TutorAI.

Orchestre :
- SessionStore    : historique des conversations (mémoire ou DB selon flag)
- PromptBuilder   : construction des prompts système
- SafetyFilter    : détection d'injections et contenu hors-domaine
- LLMProvider     : appels LLM (Groq principal + Ollama fallback)

L'historique est gouverné par `SessionStore` : identique à l'existant tant
que TUTOR_PERSIST_SESSIONS est False (mémoire process), persisté en base
sinon. Le `user_id` (issu de l'auth) est requis pour l'ownership.
"""

import json
import uuid
from typing import AsyncGenerator, Optional
from uuid import UUID

from app.core.config import settings
from app.core.logging import get_logger
from app.services.llm.prompt_builder import PromptBuilder
from app.services.llm.safety_filter import SafetyFilter
from app.services.llm.providers import get_llm_provider
from app.services.tutor.session_store import SessionStore
from app.services.tutor.tools import get_tool_schemas, dispatch_tool
from app.services.rag.retrieval import RetrievalService
from app.repositories.knowledge_base_repository import knowledge_base_repository

logger = get_logger("services.llm")

# Nombre de messages d'historique injectés dans le prompt (fenêtre de contexte).
MAX_HISTORY = 10


class LLMService:
    """Service conversationnel AÏDA — provider abstrait + store d'historique."""

    def __init__(self) -> None:
        self._store = SessionStore()
        self._prompt_builder = PromptBuilder(knowledge_base_repository)
        self._safety = SafetyFilter()
        self._provider = get_llm_provider()
        self._retrieval = RetrievalService()

    async def _build_system_prompt(
        self,
        message: str,
        orientation_context: Optional[dict],
    ) -> str:
        """Construit le prompt système, enrichi du contexte RAG si activé.

        Flag off (défaut) → identique à PromptBuilder.build (aucun changement).
        Flag on → ajoute les extraits de cours pertinents, best-effort (un
        échec RAG n'empêche pas la réponse).
        """
        system_prompt = self._prompt_builder.build(orientation_context)
        if settings.TUTOR_RAG_ENABLED:
            context = await self._retrieval.retrieve_context(message)
            if context:
                system_prompt += (
                    "\n\n# Contenu de cours pertinent\n"
                    "Appuie-toi sur ces extraits pour répondre et cite-les "
                    "avec [n] quand tu t'en sers.\n"
                    f"{context}"
                )
        return system_prompt

    async def _run_with_tools(
        self,
        messages: list[dict],
        user_id: UUID,
    ) -> Optional[str]:
        """Boucle de function-calling.

        Le LLM peut appeler des outils (quiz, recommandation) avant de produire
        sa réponse finale. On exécute les outils, on réinjecte leurs résultats,
        et on reboucle jusqu'à obtenir une réponse texte (ou la limite d'itérations).
        """
        tools = get_tool_schemas()
        for _ in range(settings.TUTOR_TOOLS_MAX_ITERATIONS):
            result = await self._provider.complete_with_tools(messages, tools)
            tool_calls = result.get("tool_calls")
            if not tool_calls:
                return result.get("content")

            messages.append({
                "role": "assistant",
                "content": result.get("content") or "",
                "tool_calls": tool_calls,
            })
            for call in tool_calls:
                fn = call.get("function", {})
                try:
                    args = json.loads(fn.get("arguments") or "{}")
                except (json.JSONDecodeError, TypeError):
                    args = {}
                tool_result = await dispatch_tool(fn.get("name", ""), args, user_id)
                messages.append({
                    "role": "tool",
                    "tool_call_id": call.get("id"),
                    "content": tool_result,
                })

        # Limite atteinte : forcer une réponse finale sans outils.
        return await self._provider.complete(messages)

    async def chat(
        self,
        message: str,
        session_id: UUID,
        user_id: UUID,
        orientation_context: Optional[dict] = None,
        client_history: Optional[list[dict]] = None,
    ) -> dict:
        """Envoie un message et retourne la réponse complète."""
        message = self._safety.sanitize(message)

        if self._safety.is_injection_attempt(message):
            return {"reply": self._safety.get_rejection_message(), "session_id": str(session_id)}

        history = await self._store.get_history(session_id, user_id, limit=MAX_HISTORY)
        if not history and client_history:
            history = self._store.seed_from_client(client_history, MAX_HISTORY)

        system_prompt = await self._build_system_prompt(message, orientation_context)
        messages = [{"role": "system", "content": system_prompt}]
        messages.extend(history[-MAX_HISTORY:])
        messages.append({"role": "user", "content": message})

        if settings.TUTOR_TOOLS_ENABLED:
            reply = await self._run_with_tools(messages, user_id)
        else:
            reply = await self._provider.complete(messages)

        if reply is None:
            return {
                "reply": (
                    "Je suis AÏDA, votre conseillère d'orientation. "
                    "Le service est temporairement indisponible. "
                    "Réessaie dans quelques instants !"
                ),
                "session_id": str(session_id),
            }

        await self._store.append(session_id, user_id, message, reply)
        return {"reply": reply, "session_id": str(session_id)}

    async def chat_stream(
        self,
        message: str,
        session_id: UUID,
        user_id: UUID,
        orientation_context: Optional[dict] = None,
        client_history: Optional[list[dict]] = None,
    ) -> AsyncGenerator[dict, None]:
        """Envoie un message et stream la réponse chunk par chunk."""
        message = self._safety.sanitize(message)

        if self._safety.is_injection_attempt(message):
            yield {"chunk": self._safety.get_rejection_message()}
            yield {"done": True}
            return

        history = await self._store.get_history(session_id, user_id, limit=MAX_HISTORY)
        if not history and client_history:
            history = self._store.seed_from_client(client_history, MAX_HISTORY)

        system_prompt = await self._build_system_prompt(message, orientation_context)
        messages = [{"role": "system", "content": system_prompt}]
        messages.extend(history[-MAX_HISTORY:])
        messages.append({"role": "user", "content": message})

        full_reply_parts: list[str] = []

        if settings.TUTOR_TOOLS_ENABLED:
            # Le tool-calling nécessite des allers-retours non-streamables ; on
            # résout d'abord la réponse finale, puis on la stream mot par mot
            # pour préserver le contrat SSE côté app.
            reply = await self._run_with_tools(messages, user_id)
            if reply:
                words = reply.split(" ")
                for i, word in enumerate(words):
                    token = word + ("" if i == len(words) - 1 else " ")
                    full_reply_parts.append(token)
                    yield {"chunk": token}
        else:
            async for chunk in self._provider.stream(messages):
                full_reply_parts.append(chunk)
                yield {"chunk": chunk}

        full_reply = "".join(full_reply_parts)
        if full_reply:
            await self._store.append(session_id, user_id, message, full_reply)

        yield {"done": True}

    async def clear_session(self, session_id: UUID, user_id: UUID) -> bool:
        return await self._store.clear(session_id, user_id)

    @staticmethod
    def new_session_id() -> str:
        return str(uuid.uuid4())


# Singleton partagé
llm_service = LLMService()
