"""Ingestion RAG du contenu e-learning existant.

Extrait le texte d'une leçon (titre + description + contenu JSONB polymorphe)
et l'indexe dans content_chunks (source_type='lesson'). Permet :
- l'auto-ré-indexation à la sauvegarde d'une leçon (best-effort),
- un backfill de tout le catalogue.

L'extraction est générique (parcours récursif du JSONB), donc robuste aux
différents types de leçon (article, vidéo, quiz, pdf, challenge).
"""

from __future__ import annotations

from typing import Any, Optional
from uuid import UUID

from app.core.logging import get_logger
from app.db.supabase_client import get_admin_supabase_client, SupabaseClient
from app.repositories.elearning_repository import (
    ElearningRepository,
    get_elearning_repository,
)
from app.services.rag.ingestion import IngestionService

logger = get_logger("services.rag.lesson_ingestion")

# Champs texte de premier niveau d'une leçon à indexer.
_LESSON_TEXT_FIELDS = ("title", "description", "summary")


def _harvest_strings(node: Any) -> list[str]:
    """Collecte récursivement les chaînes de texte utiles d'un JSONB.

    Ignore les URLs et les chaînes très courtes (clés techniques, ids...).
    """
    out: list[str] = []
    if isinstance(node, str):
        s = node.strip()
        if len(s) >= 3 and not s.startswith(("http://", "https://")):
            out.append(s)
    elif isinstance(node, dict):
        for value in node.values():
            out.extend(_harvest_strings(value))
    elif isinstance(node, list):
        for item in node:
            out.extend(_harvest_strings(item))
    return out


def extract_lesson_text(lesson: dict[str, Any]) -> str:
    """Assemble le texte indexable d'une leçon (titre + description + contenu)."""
    parts: list[str] = []
    for field in _LESSON_TEXT_FIELDS:
        value = lesson.get(field)
        if isinstance(value, str) and value.strip():
            parts.append(value.strip())

    content = lesson.get("content")
    if isinstance(content, dict):
        parts.extend(_harvest_strings(content.get("data")))

    # Dédoublonne en préservant l'ordre.
    seen: set[str] = set()
    unique = [p for p in parts if not (p in seen or seen.add(p))]
    return "\n".join(unique)


class LessonIngestionService:
    """Indexe les leçons e-learning dans le RAG."""

    def __init__(
        self,
        elearning: Optional[ElearningRepository] = None,
        ingestion: Optional[IngestionService] = None,
        db: Optional[SupabaseClient] = None,
    ) -> None:
        self._elearning = elearning
        self._ingestion = ingestion
        self._db = db

    def _get_elearning(self) -> ElearningRepository:
        if self._elearning is None:
            self._elearning = get_elearning_repository()
        return self._elearning

    def _get_ingestion(self) -> IngestionService:
        if self._ingestion is None:
            self._ingestion = IngestionService()
        return self._ingestion

    def _get_db(self) -> SupabaseClient:
        if self._db is None:
            self._db = get_admin_supabase_client()
        return self._db

    async def ingest_lesson(self, lesson_id: UUID) -> int:
        """Indexe une leçon. Retourne le nombre de chunks insérés (0 si vide)."""
        lesson = await self._get_elearning().get_lesson_detail(str(lesson_id))
        if not lesson:
            logger.info("Ingestion leçon %s : introuvable", lesson_id)
            return 0

        text = extract_lesson_text(lesson)
        subject = lesson.get("subject") or lesson.get("category")
        title = lesson.get("title")

        # replace=True nettoie les anciens chunks même si le texte est vide.
        return await self._get_ingestion().ingest(
            source_type="lesson",
            text=text,
            source_id=lesson_id,
            subject=subject,
            title=title,
            replace=True,
        )

    async def ingest_all_lessons(self) -> dict[str, int]:
        """Backfill : indexe toutes les leçons du catalogue."""
        result = (
            self._get_db().client.table("elearning_lessons")
            .select("id")
            .execute()
        )
        lesson_ids = [row["id"] for row in (result.data or [])]

        lessons_processed = 0
        chunks_inserted = 0
        for lid in lesson_ids:
            try:
                chunks_inserted += await self.ingest_lesson(UUID(str(lid)))
                lessons_processed += 1
            except Exception as e:  # une leçon en échec ne bloque pas le lot
                logger.warning("Ingestion leçon %s échouée: %s", lid, e)

        logger.info(
            "Backfill RAG : %d leçons, %d chunks", lessons_processed, chunks_inserted
        )
        return {
            "lessons_processed": lessons_processed,
            "chunks_inserted": chunks_inserted,
        }


_lesson_ingestion_service: Optional[LessonIngestionService] = None


def get_lesson_ingestion_service() -> LessonIngestionService:
    """Retourne l'instance (unique) du service d'ingestion de leçons."""
    global _lesson_ingestion_service
    if _lesson_ingestion_service is None:
        _lesson_ingestion_service = LessonIngestionService()
    return _lesson_ingestion_service
