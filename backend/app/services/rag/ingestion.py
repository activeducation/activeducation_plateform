"""IngestionService — indexation de contenu pour le RAG.

Prend un texte source (leçon, entrée KB…), le découpe en chunks, calcule les
embeddings, et persiste le tout. Ré-ingestion propre : les anciens chunks de
la même source sont supprimés avant réinsertion.

Contrairement au retrieval dans le chat, l'ingestion propage ses erreurs :
l'admin qui déclenche une ingestion doit savoir si elle a échoué.
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
from app.services.rag.chunking import chunk_text
from app.services.rag.embeddings import EmbeddingProvider, get_embedding_provider

logger = get_logger("services.rag.ingestion")


class IngestionService:
    """Découpe + embed + persiste du contenu indexable."""

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

    async def ingest(
        self,
        source_type: str,
        text: str,
        source_id: Optional[UUID] = None,
        subject: Optional[str] = None,
        title: Optional[str] = None,
        metadata: Optional[dict[str, Any]] = None,
        replace: bool = True,
    ) -> int:
        """Indexe un contenu. Retourne le nombre de chunks insérés.

        Args:
            source_type: 'lesson' | 'knowledge_base' | ...
            text: contenu brut à indexer.
            source_id: id de la source (pour la ré-ingestion / suppression).
            subject: matière (filtre de recherche).
            title: titre affichable (citation).
            replace: si True et source_id fourni, supprime les chunks existants
                de cette source avant réinsertion.
        """
        chunks = chunk_text(text, settings.RAG_CHUNK_SIZE, settings.RAG_CHUNK_OVERLAP)
        if not chunks:
            logger.info("Ingestion %s : aucun contenu à indexer", source_type)
            # Ré-ingestion d'un contenu vidé : on nettoie quand même l'ancien.
            if replace and source_id is not None:
                await self._get_repo().delete_by_source(source_type, source_id)
            return 0

        embeddings = await self._get_embedder().embed(chunks)

        if replace and source_id is not None:
            await self._get_repo().delete_by_source(source_type, source_id)

        rows = [
            {
                "source_type": source_type,
                "source_id": source_id,
                "subject": subject,
                "title": title,
                "chunk_index": i,
                "chunk_text": chunk,
                "embedding": embedding,
                "metadata": metadata or {},
            }
            for i, (chunk, embedding) in enumerate(zip(chunks, embeddings))
        ]
        inserted = await self._get_repo().insert_chunks(rows)
        logger.info(
            "Ingestion %s (%s) : %d chunks indexés",
            source_type, source_id, inserted,
        )
        return inserted
