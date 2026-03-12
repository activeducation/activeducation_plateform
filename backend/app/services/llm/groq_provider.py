"""
GroqProvider — Appels à l'API Groq avec streaming et fallback Ollama.

Gère :
- Appels Groq (principal, gratuit, 14 400 req/jour)
- Appels Ollama (fallback local, auto-hébergé)
- Streaming SSE via générateurs asynchrones
"""

import logging
import os
from typing import AsyncGenerator, Optional

import httpx

logger = logging.getLogger(__name__)

GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"
GROQ_MODEL = "llama-3.1-8b-instant"
GROQ_TIMEOUT = 30.0

OLLAMA_BASE_URL = os.environ.get("OLLAMA_BASE_URL", "http://localhost:11434").rstrip("/")
OLLAMA_MODEL = os.environ.get("OLLAMA_MODEL", "llama3.1:8b")
OLLAMA_TIMEOUT = 90.0

MAX_TOKENS = 800
TEMPERATURE = 0.7

_UNAVAILABLE_REPLY = (
    "Je suis AÏDA, votre conseillère d'orientation. "
    "Le service est temporairement indisponible. "
    "Réessaie dans quelques instants !"
)


class GroqProvider:
    """Provider LLM : Groq (principal) + Ollama (fallback)."""

    def __init__(self) -> None:
        from app.core.config import settings
        self._groq_api_key = (settings.GROQ_API_KEY or "").strip()
        self._groq_enabled = bool(self._groq_api_key)
        self._ollama_available: Optional[bool] = None

        provider_info = f"Groq ({GROQ_MODEL})" if self._groq_enabled else f"Ollama ({OLLAMA_MODEL})"
        logger.info("GroqProvider initialisé — provider principal: %s", provider_info)

    # ------------------------------------------------------------------
    # API publique — non-streaming
    # ------------------------------------------------------------------

    async def complete(self, messages: list[dict]) -> Optional[str]:
        """Génère une réponse complète (non-streaming)."""
        if self._groq_enabled:
            reply = await self._call_groq(messages)
            if reply:
                return reply

        return await self._call_ollama(messages)

    # ------------------------------------------------------------------
    # API publique — streaming
    # ------------------------------------------------------------------

    async def stream(self, messages: list[dict]) -> AsyncGenerator[str, None]:
        """
        Génère la réponse en streaming.
        Yield des chunks de texte au fur et à mesure.
        """
        if self._groq_enabled:
            async for chunk in self._stream_groq(messages):
                yield chunk
            return

        # Fallback Ollama : pas de vrai streaming, on simule mot par mot
        reply = await self._call_ollama(messages)
        if reply:
            words = reply.split(" ")
            for i, word in enumerate(words):
                yield word + ("" if i == len(words) - 1 else " ")
        else:
            yield _UNAVAILABLE_REPLY

    # ------------------------------------------------------------------
    # Groq — non-streaming
    # ------------------------------------------------------------------

    async def _call_groq(self, messages: list[dict]) -> Optional[str]:
        try:
            async with httpx.AsyncClient(timeout=GROQ_TIMEOUT) as client:
                resp = await client.post(
                    GROQ_API_URL,
                    headers={
                        "Authorization": f"Bearer {self._groq_api_key}",
                        "Content-Type": "application/json",
                    },
                    json={
                        "model": GROQ_MODEL,
                        "messages": messages,
                        "max_tokens": MAX_TOKENS,
                        "temperature": TEMPERATURE,
                    },
                )
                resp.raise_for_status()

            data = resp.json()
            reply = data["choices"][0]["message"]["content"].strip()
            logger.debug("Groq → %d caractères", len(reply))
            return reply

        except httpx.HTTPStatusError as exc:
            code = exc.response.status_code
            logger.warning("Groq erreur %s — fallback Ollama: %s", code, exc.response.text[:200])
            if code == 401:
                logger.error("GROQ_API_KEY invalide ou expirée")
            return None
        except (httpx.TimeoutException, httpx.ConnectError):
            logger.warning("Groq timeout/connect error — fallback Ollama")
            return None
        except Exception as exc:
            logger.warning("Groq erreur inattendue — fallback Ollama: %s", exc)
            return None

    # ------------------------------------------------------------------
    # Groq — streaming
    # ------------------------------------------------------------------

    async def _stream_groq(self, messages: list[dict]) -> AsyncGenerator[str, None]:
        """Stream la réponse Groq chunk par chunk."""
        try:
            async with httpx.AsyncClient(timeout=GROQ_TIMEOUT) as client:
                async with client.stream(
                    "POST",
                    GROQ_API_URL,
                    headers={
                        "Authorization": f"Bearer {self._groq_api_key}",
                        "Content-Type": "application/json",
                    },
                    json={
                        "model": GROQ_MODEL,
                        "messages": messages,
                        "max_tokens": MAX_TOKENS,
                        "temperature": TEMPERATURE,
                        "stream": True,
                    },
                ) as resp:
                    resp.raise_for_status()
                    async for line in resp.aiter_lines():
                        if not line.startswith("data: "):
                            continue
                        data_str = line[6:]
                        if data_str.strip() == "[DONE]":
                            return
                        try:
                            import json
                            data = json.loads(data_str)
                            delta = data["choices"][0].get("delta", {})
                            content = delta.get("content")
                            if content:
                                yield content
                        except Exception:
                            continue

        except Exception as exc:
            logger.warning("Groq streaming erreur — fallback: %s", exc)
            # Fallback non-streaming
            reply = await self._call_ollama(messages)
            if reply:
                yield reply
            else:
                yield _UNAVAILABLE_REPLY

    # ------------------------------------------------------------------
    # Ollama — fallback
    # ------------------------------------------------------------------

    async def _call_ollama(self, messages: list[dict]) -> Optional[str]:
        if self._ollama_available is None:
            self._ollama_available = await self._check_ollama()

        if not self._ollama_available:
            return None

        try:
            async with httpx.AsyncClient(timeout=OLLAMA_TIMEOUT) as client:
                resp = await client.post(
                    f"{OLLAMA_BASE_URL}/api/chat",
                    json={
                        "model": OLLAMA_MODEL,
                        "messages": messages,
                        "stream": False,
                        "options": {"num_predict": MAX_TOKENS, "temperature": TEMPERATURE},
                    },
                )
                resp.raise_for_status()

            reply = resp.json().get("message", {}).get("content", "").strip()
            if not reply:
                logger.warning("Ollama réponse vide")
                return None
            logger.debug("Ollama → %d caractères", len(reply))
            return reply

        except (httpx.ConnectError, httpx.TimeoutException):
            logger.warning("Ollama indisponible (%s)", OLLAMA_BASE_URL)
            self._ollama_available = False
            return None
        except Exception as exc:
            logger.warning("Ollama erreur: %s", exc)
            return None

    async def _check_ollama(self) -> bool:
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                resp = await client.get(f"{OLLAMA_BASE_URL}/api/tags")
                resp.raise_for_status()
                models = [m.get("name", "") for m in resp.json().get("models", [])]
                found = any(
                    OLLAMA_MODEL in name or name.startswith(OLLAMA_MODEL.split(":")[0])
                    for name in models
                )
                if found:
                    logger.info("Ollama disponible — modèle '%s' trouvé", OLLAMA_MODEL)
                else:
                    logger.warning("Ollama joignable mais modèle '%s' absent", OLLAMA_MODEL)
                return True
        except (httpx.ConnectError, httpx.TimeoutException):
            logger.info("Ollama non joignable sur %s", OLLAMA_BASE_URL)
            return False
        except Exception as exc:
            logger.info("Erreur vérification Ollama: %s", exc)
            return False
