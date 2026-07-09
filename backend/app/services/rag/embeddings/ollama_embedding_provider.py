"""OllamaEmbeddingProvider — embeddings via Ollama (nomic-embed-text).

Appelle l'endpoint Ollama `/api/embeddings` (un texte a la fois, endpoint
stable). Gratuit, local, aucune cle API. Contrainte : Ollama doit tourner
avec le modele configure la ou le backend calcule les embeddings.

Leve ExternalServiceError si Ollama est injoignable : contrairement au chat
(qui a un repli gracieux), une ingestion/recherche sans embeddings n'a pas
de sens — l'appelant doit gerer l'echec explicitement.
"""

from __future__ import annotations

import httpx

from app.core.config import settings
from app.core.logging import get_logger
from app.core.exceptions import ExternalServiceError

logger = get_logger("services.rag.embeddings.ollama")


class OllamaEmbeddingProvider:
    """Embeddings Ollama (endpoint /api/embeddings)."""

    def __init__(self) -> None:
        self._base_url = settings.OLLAMA_BASE_URL.rstrip("/")
        self._model = settings.EMBEDDING_MODEL
        self._dim = settings.EMBEDDING_DIM
        self._timeout = settings.EMBEDDING_TIMEOUT_SECONDS

    @property
    def dim(self) -> int:
        return self._dim

    async def embed_query(self, text: str) -> list[float]:
        """Embed une requete unique."""
        return await self._embed_one(text)

    async def embed(self, texts: list[str]) -> list[list[float]]:
        """Embed un lot de textes (sequentiel : endpoint mono-prompt)."""
        vectors: list[list[float]] = []
        for text in texts:
            vectors.append(await self._embed_one(text))
        return vectors

    async def _embed_one(self, text: str) -> list[float]:
        try:
            async with httpx.AsyncClient(timeout=self._timeout) as client:
                resp = await client.post(
                    f"{self._base_url}/api/embeddings",
                    json={"model": self._model, "prompt": text},
                )
                resp.raise_for_status()
            embedding = resp.json().get("embedding")
            if not embedding:
                raise ExternalServiceError(
                    service="ollama",
                    message="Ollama a renvoye un embedding vide",
                )
            if len(embedding) != self._dim:
                # Desalignement modele/schema : erreur explicite plutot que
                # d'inserer un vecteur de mauvaise dimension.
                raise ExternalServiceError(
                    service="ollama",
                    message=(
                        f"Dimension d'embedding inattendue : {len(embedding)} "
                        f"(attendu {self._dim}). Verifiez EMBEDDING_MODEL/DIM."
                    ),
                )
            return embedding
        except ExternalServiceError:
            raise
        except (httpx.ConnectError, httpx.TimeoutException) as exc:
            logger.error("Ollama embeddings injoignable (%s): %s", self._base_url, exc)
            raise ExternalServiceError(
                service="ollama",
                message="Service d'embeddings (Ollama) indisponible",
            )
        except Exception as exc:
            logger.error("Erreur embeddings Ollama: %s", exc, exc_info=True)
            raise ExternalServiceError(
                service="ollama",
                message=f"Erreur lors du calcul de l'embedding: {exc}",
            )
