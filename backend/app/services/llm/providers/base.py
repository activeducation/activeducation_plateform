"""Contrat provider LLM + fabrique.

`LLMProvider` est un Protocol structurel : tout objet exposant `complete`
et `stream` avec les bonnes signatures le satisfait (le `GroqProvider`
existant s'y conforme deja, sans heritage a modifier).

La fabrique `get_llm_provider()` lit `settings.LLM_PROVIDER` et retourne
une instance memoisee. Enregistrer un nouveau provider = un appel a
`register_provider(nom, fabrique)`, sans toucher aux appelants.
"""

from __future__ import annotations

from functools import lru_cache
from typing import (
    AsyncGenerator,
    Callable,
    Optional,
    Protocol,
    TypedDict,
    runtime_checkable,
)

from app.core.logging import get_logger

logger = get_logger("services.llm.providers")


class LLMMessage(TypedDict):
    """Un message au format OpenAI/Groq (role + contenu)."""

    role: str      # "system" | "user" | "assistant"
    content: str


@runtime_checkable
class LLMProvider(Protocol):
    """Contrat minimal d'un fournisseur de completion conversationnelle."""

    async def complete(self, messages: list[LLMMessage]) -> Optional[str]:
        """Retourne la reponse complete, ou None si le provider a echoue."""
        ...

    def stream(self, messages: list[LLMMessage]) -> AsyncGenerator[str, None]:
        """Yield la reponse par morceaux (streaming)."""
        ...


# ---------------------------------------------------------------------------
# Registre de providers
# ---------------------------------------------------------------------------

_ProviderFactory = Callable[[], LLMProvider]
_REGISTRY: dict[str, _ProviderFactory] = {}


def register_provider(name: str, factory: _ProviderFactory) -> None:
    """Enregistre une fabrique de provider sous un nom (idempotent)."""
    _REGISTRY[name.lower()] = factory


def _default_registry() -> dict[str, _ProviderFactory]:
    """Fabriques par defaut, importees paresseusement (evite les cycles)."""

    def _groq() -> LLMProvider:
        from app.services.llm.groq_provider import GroqProvider
        return GroqProvider()

    return {"groq": _groq, "ollama": _groq}  # GroqProvider gere deja le fallback Ollama


@lru_cache(maxsize=4)
def get_llm_provider(name: Optional[str] = None) -> LLMProvider:
    """Retourne le provider LLM actif (memoise).

    Args:
        name: nom explicite ; par defaut `settings.LLM_PROVIDER`.

    Le provider par defaut ("groq") encapsule deja la bascule Groq -> Ollama,
    donc un deploiement sans GROQ_API_KEY bascule tout seul en local.
    """
    from app.core.config import settings

    resolved = (name or settings.LLM_PROVIDER or "groq").lower()

    factory = _REGISTRY.get(resolved) or _default_registry().get(resolved)
    if factory is None:
        logger.warning(
            "Provider LLM inconnu '%s' — repli sur 'groq'", resolved
        )
        factory = _default_registry()["groq"]

    provider = factory()
    logger.info("Provider LLM actif : %s (%s)", resolved, type(provider).__name__)
    return provider
