"""Contrat provider d'embeddings + fabrique.

Meme philosophie que l'abstraction LLM : le code metier (ingestion,
retrieval) ne depend jamais d'un fournisseur concret. Aujourd'hui : Ollama
nomic-embed-text (768d). Demain : autre modele/dimension, sans reecrire les
appelants — a condition d'aligner settings.EMBEDDING_DIM et la colonne
vector(N) en base.
"""

from __future__ import annotations

from functools import lru_cache
from typing import Callable, Optional, Protocol, runtime_checkable

from app.core.logging import get_logger

logger = get_logger("services.rag.embeddings")


@runtime_checkable
class EmbeddingProvider(Protocol):
    """Fournit des vecteurs d'embedding pour du texte."""

    @property
    def dim(self) -> int:
        """Dimension des vecteurs produits (doit matcher la colonne en base)."""
        ...

    async def embed(self, texts: list[str]) -> list[list[float]]:
        """Embed un lot de textes (ingestion)."""
        ...

    async def embed_query(self, text: str) -> list[float]:
        """Embed une requete unique (recherche)."""
        ...


_ProviderFactory = Callable[[], EmbeddingProvider]
_REGISTRY: dict[str, _ProviderFactory] = {}


def register_embedding_provider(name: str, factory: _ProviderFactory) -> None:
    """Enregistre une fabrique de provider d'embeddings (idempotent)."""
    _REGISTRY[name.lower()] = factory


def _default_registry() -> dict[str, _ProviderFactory]:
    def _ollama() -> EmbeddingProvider:
        from app.services.rag.embeddings.ollama_embedding_provider import (
            OllamaEmbeddingProvider,
        )
        return OllamaEmbeddingProvider()

    return {"ollama": _ollama}


@lru_cache(maxsize=4)
def get_embedding_provider(name: Optional[str] = None) -> EmbeddingProvider:
    """Retourne le provider d'embeddings actif (memoise)."""
    from app.core.config import settings

    resolved = (name or settings.EMBEDDING_PROVIDER or "ollama").lower()
    factory = _REGISTRY.get(resolved) or _default_registry().get(resolved)
    if factory is None:
        logger.warning("Provider d'embeddings inconnu '%s' — repli 'ollama'", resolved)
        factory = _default_registry()["ollama"]

    provider = factory()
    logger.info(
        "Provider d'embeddings actif : %s (%s, dim=%d)",
        resolved, type(provider).__name__, provider.dim,
    )
    return provider
