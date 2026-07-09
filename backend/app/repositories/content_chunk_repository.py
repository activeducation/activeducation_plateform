"""Repository des chunks de contenu indexes (RAG).

Persistance vectorielle via pgvector. La recherche par similarite passe par
le RPC Postgres `match_content_chunks` (l'operateur `<=>` n'est pas
exprimable via le query builder Supabase).

Acces via service_role. Les chunks ne sont pas lies a un utilisateur (contenu
pedagogique partage), donc pas d'ownership par user_id ici.
"""

from datetime import datetime, timezone
from functools import lru_cache
from typing import Any, Optional
from uuid import UUID

from app.core.logging import get_logger
from app.core.exceptions import QueryError
from app.db.supabase_client import get_admin_supabase_client, SupabaseClient

logger = get_logger("repositories.content_chunk")

_TABLE = "content_chunks"
_MATCH_FN = "match_content_chunks"


class ContentChunkRepository:
    """CRUD + recherche semantique des fragments de contenu."""

    def __init__(self) -> None:
        self._db: SupabaseClient = get_admin_supabase_client()

    async def insert_chunks(self, chunks: list[dict[str, Any]]) -> int:
        """Insere un lot de chunks. Retourne le nombre insere."""
        if not chunks:
            return 0
        try:
            now = datetime.now(timezone.utc).isoformat()
            rows = []
            for c in chunks:
                rows.append({
                    "source_type": c["source_type"],
                    "source_id": str(c["source_id"]) if c.get("source_id") else None,
                    "subject": c.get("subject"),
                    "title": c.get("title"),
                    "chunk_index": c.get("chunk_index", 0),
                    "chunk_text": c["chunk_text"],
                    "embedding": c["embedding"],
                    "metadata": c.get("metadata") or {},
                    "created_at": now,
                })
            result = self._db.insert(table=_TABLE, data=rows)
            inserted = len(result) if result else len(rows)
            logger.info("Inseres %d chunks (%s)", inserted, rows[0]["source_type"])
            return inserted
        except Exception as e:
            logger.error("Erreur insertion chunks: %s", e, exc_info=True)
            raise QueryError(f"Erreur lors de l'insertion des chunks: {str(e)}")

    async def delete_by_source(
        self,
        source_type: str,
        source_id: UUID,
    ) -> int:
        """Supprime tous les chunks d'une source (avant re-ingestion)."""
        try:
            result = (
                self._db.client.table(_TABLE)
                .delete()
                .eq("source_type", source_type)
                .eq("source_id", str(source_id))
                .execute()
            )
            deleted = len(result.data) if result.data else 0
            logger.info("Supprimes %d chunks (%s/%s)", deleted, source_type, source_id)
            return deleted
        except Exception as e:
            logger.error("Erreur suppression chunks: %s", e, exc_info=True)
            raise QueryError(f"Erreur lors de la suppression des chunks: {str(e)}")

    async def search(
        self,
        query_embedding: list[float],
        top_k: int = 4,
        min_similarity: float = 0.3,
        subject: Optional[str] = None,
        source_id: Optional[UUID] = None,
    ) -> list[dict[str, Any]]:
        """Recherche les chunks les plus proches (similarite cosinus).

        Retourne une liste de dicts {id, source_type, source_id, subject,
        title, chunk_text, similarity}, tries du plus pertinent au moins.
        """
        try:
            params = {
                "query_embedding": query_embedding,
                "match_count": top_k,
                "min_similarity": min_similarity,
                "filter_subject": subject,
                "filter_source_id": str(source_id) if source_id else None,
            }
            data = self._db.rpc(_MATCH_FN, params)
            return data or []
        except Exception as e:
            logger.error("Erreur recherche semantique: %s", e, exc_info=True)
            raise QueryError(f"Erreur lors de la recherche semantique: {str(e)}")


@lru_cache(maxsize=1)
def get_content_chunk_repository() -> ContentChunkRepository:
    """Retourne l'instance (unique) du repository de chunks."""
    return ContentChunkRepository()
