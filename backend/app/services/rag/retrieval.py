"""RetrievalService — recherche de contenu pertinent pour le tuteur.

Embed la requete, cherche les chunks les plus proches, et les formate en
bloc de contexte avec citations `[n]` a injecter dans le prompt.

Dans le chat, le retrieval est *best-effort* : si les embeddings echouent
(Ollama injoignable), on renvoie un contexte vide plutot que de casser la
reponse. L'ingestion, elle, propage ses erreurs (voir IngestionService).
"""

from __future__ import annotations

from typing import Any, Optional
from uuid import UUID

from app.core.config import settings
from app.core.logging import get_logger
from app.repositories.content_chunk_repository import (
    ContentChunkRepository,
    get_content_chunk_repository,
)
from app.services.rag.embeddings import EmbeddingProvider, get_embedding_provider

logger = get_logger("services.rag.retrieval")


class RetrievalService:
    """Recherche semantique + formatage du contexte pour le prompt."""

    def __init__(
        self,
        repository: Optional[ContentChunkRepository] = None,
        embedder: Optional[EmbeddingProvider] = None,
    ) -> None:
        self._repo = repository
        self._embedder = embedder

    def _get_repo(self) -> ContentChunkRepository:
        if self._repo is None:
            self._repo = get_content_chunk_repository()
        return self._repo

    def _get_embedder(self) -> EmbeddingProvider:
        if self._embedder is None:
            self._embedder = get_embedding_provider()
        return self._embedder

    async def retrieve(
        self,
        query: str,
        subject: Optional[str] = None,
        source_id: Optional[UUID] = None,
        top_k: Optional[int] = None,
        min_similarity: Optional[float] = None,
    ) -> list[dict[str, Any]]:
        """Retourne les chunks les plus pertinents pour une requete."""
        query = (query or "").strip()
        if not query:
            return []
        embedding = await self._get_embedder().embed_query(query)
        return await self._get_repo().search(
            embedding,
            top_k=top_k or settings.RAG_TOP_K,
            min_similarity=min_similarity if min_similarity is not None else settings.RAG_MIN_SIMILARITY,
            subject=subject,
            source_id=source_id,
        )

    @staticmethod
    def format_context(chunks: list[dict[str, Any]]) -> str:
        """Formate les chunks en bloc de contexte cite pour le prompt."""
        if not chunks:
            return ""
        lines = []
        for i, c in enumerate(chunks, start=1):
            label = c.get("title") or c.get("subject") or "Source"
            text = (c.get("chunk_text") or "").strip()
            lines.append(f"[{i}] ({label}) {text}")
        return "\n\n".join(lines)

    async def retrieve_context(
        self,
        query: str,
        subject: Optional[str] = None,
    ) -> str:
        """Recherche + formatage, best-effort (ne leve jamais).

        Utilise dans le chat : un echec RAG ne doit pas casser la reponse du
        tuteur, il retombe simplement sur ses connaissances generales.
        """
        try:
            chunks = await self.retrieve(query, subject=subject)
            return self.format_context(chunks)
        except Exception as e:
            logger.warning("Retrieval RAG echoue (best-effort, ignore): %s", e)
            return ""
