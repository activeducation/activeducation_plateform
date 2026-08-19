"""Admin — Ingestion de contenu pour le RAG TutorAI.

POST /admin/rag/ingest → découpe + embed + indexe un contenu (leçon, KB…).

Réservé aux admins. L'ingestion propage ses erreurs (contrairement au
retrieval best-effort du chat) : l'admin doit savoir si l'indexation a
échoué (ex. Ollama injoignable).
"""

from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from app.core.security import get_current_admin
from app.core.exceptions import ExternalServiceError
from app.services.rag.ingestion import IngestionService
from app.services.rag.lesson_ingestion import get_lesson_ingestion_service
from app.repositories.skill_repository import get_skill_repository

router = APIRouter()

_ingestion = IngestionService()


class IngestRequest(BaseModel):
    """Corps d'une requête d'ingestion."""

    source_type: str = Field(..., min_length=1, max_length=50,
                             description="'lesson' | 'knowledge_base' | ...")
    text: str = Field(..., min_length=1, description="Contenu brut à indexer")
    source_id: Optional[UUID] = Field(
        default=None,
        description="ID de la source (permet la ré-ingestion propre)",
    )
    subject: Optional[str] = Field(default=None, max_length=100)
    title: Optional[str] = Field(default=None, max_length=200)
    replace: bool = Field(
        default=True,
        description="Supprime les chunks existants de la source avant réinsertion",
    )


class IngestResponse(BaseModel):
    chunks_inserted: int
    source_type: str


class LessonSkillsRequest(BaseModel):
    skill_ids: list[UUID] = Field(default_factory=list, max_length=20)


@router.post(
    "/ingest",
    response_model=IngestResponse,
    summary="Indexer un contenu pour le RAG (TutorAI)",
    description=(
        "Découpe le texte en chunks, calcule les embeddings et les persiste. "
        "Nécessite la migration 019 (pgvector) appliquée et Ollama disponible "
        "avec le modèle d'embeddings configuré."
    ),
)
async def ingest_content(
    request: IngestRequest,
    admin=Depends(get_current_admin),
) -> IngestResponse:
    try:
        inserted = await _ingestion.ingest(
            source_type=request.source_type,
            text=request.text,
            source_id=request.source_id,
            subject=request.subject,
            title=request.title,
            replace=request.replace,
        )
    except ExternalServiceError as exc:
        # Ollama injoignable / dimension inattendue → 502.
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=exc.message,
        )
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de l'ingestion du contenu.",
        )

    return IngestResponse(
        chunks_inserted=inserted,
        source_type=request.source_type,
    )


@router.post(
    "/lessons/{lesson_id}/ingest",
    summary="Indexer une leçon e-learning pour le RAG",
)
async def ingest_lesson(
    lesson_id: UUID,
    admin=Depends(get_current_admin),
) -> dict:
    try:
        inserted = await get_lesson_ingestion_service().ingest_lesson(lesson_id)
    except ExternalServiceError as exc:
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail=exc.message)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de l'indexation de la leçon.",
        )
    return {"lesson_id": str(lesson_id), "chunks_inserted": inserted}


@router.post(
    "/lessons/ingest-all",
    summary="Backfill : indexer toutes les leçons du catalogue",
)
async def ingest_all_lessons(admin=Depends(get_current_admin)) -> dict:
    try:
        return await get_lesson_ingestion_service().ingest_all_lessons()
    except ExternalServiceError as exc:
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail=exc.message)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors du backfill des leçons.",
        )


@router.put(
    "/lessons/{lesson_id}/skills",
    summary="Lier une leçon à des compétences (lesson_skills)",
)
async def set_lesson_skills(
    lesson_id: UUID,
    request: LessonSkillsRequest,
    admin=Depends(get_current_admin),
) -> dict:
    linked = await get_skill_repository().set_lesson_skills(
        lesson_id, request.skill_ids,
    )
    return {"lesson_id": str(lesson_id), "skills_linked": linked}
