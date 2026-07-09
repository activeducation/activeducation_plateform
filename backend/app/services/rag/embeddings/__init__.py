"""Abstraction provider d'embeddings pour le RAG TutorAI."""

from app.services.rag.embeddings.base import (
    EmbeddingProvider,
    get_embedding_provider,
    register_embedding_provider,
)

__all__ = [
    "EmbeddingProvider",
    "get_embedding_provider",
    "register_embedding_provider",
]
