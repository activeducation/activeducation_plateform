"""Endpoints TutorAI — quiz, maîtrise, recommandation.

POST /tutor/quiz/generate           → génère un quiz (AssessorAgent)
POST /tutor/skills/{skill_id}/answer → enregistre une réponse (BKT)
GET  /tutor/mastery                  → maîtrise de l'élève
GET  /tutor/next-step                → recommandation (PlannerAgent)

Réservés aux utilisateurs authentifiés et gardés derrière le flag
TUTOR_MASTERY_ENABLED (404 si la fonctionnalité n'est pas activée).
"""

from typing import Any, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from app.core.config import settings
from app.core.security import get_current_user_id
from app.core.exceptions import ExternalServiceError
from app.services.tutor.agents import AssessorAgent, PlannerAgent
from app.services.tutor.mastery.service import get_mastery_service

router = APIRouter()

_assessor = AssessorAgent()
_planner = PlannerAgent()


def _require_enabled() -> None:
    """Garde : 404 si le module tuteur (maîtrise) n'est pas activé."""
    if not settings.TUTOR_MASTERY_ENABLED:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Fonctionnalité tuteur non activée.",
        )


# ---------------------------------------------------------------------------
# Schémas
# ---------------------------------------------------------------------------


class QuizRequest(BaseModel):
    topic: str = Field(..., min_length=2, max_length=300)
    num_questions: int = Field(default=3, ge=1, le=10)
    context: Optional[str] = Field(default=None, max_length=5000)


class AnswerRequest(BaseModel):
    correct: bool


class QuizSubmitRequest(BaseModel):
    skill_id: UUID
    answers: list[bool] = Field(..., min_length=1, max_length=50)


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------


@router.post("/quiz/generate", summary="Générer un quiz (TutorAI)")
async def generate_quiz(
    request: QuizRequest,
    user_id: UUID = Depends(get_current_user_id),
    _: None = Depends(_require_enabled),
) -> dict[str, Any]:
    try:
        return await _assessor.generate_quiz(
            topic=request.topic,
            num_questions=request.num_questions,
            context=request.context,
        )
    except ExternalServiceError as exc:
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail=exc.message)


@router.post("/skills/{skill_id}/answer", summary="Enregistrer une réponse (maîtrise BKT)")
async def record_answer(
    skill_id: UUID,
    request: AnswerRequest,
    user_id: UUID = Depends(get_current_user_id),
    _: None = Depends(_require_enabled),
) -> dict[str, Any]:
    result = await get_mastery_service().record_answer(
        user_id=user_id, skill_id=skill_id, correct=request.correct,
    )
    return {
        "skill_id": str(skill_id),
        "p_mastery": result.get("p_mastery"),
        "attempts": result.get("attempts"),
        "correct": result.get("correct"),
    }


@router.post("/quiz/submit", summary="Enregistrer les réponses d'un quiz (maîtrise BKT)")
async def submit_quiz(
    request: QuizSubmitRequest,
    user_id: UUID = Depends(get_current_user_id),
    _: None = Depends(_require_enabled),
) -> dict[str, Any]:
    result = await get_mastery_service().record_answers(
        user_id=user_id, skill_id=request.skill_id, answers=request.answers,
    )
    return {
        "skill_id": str(request.skill_id),
        "answers_recorded": len(request.answers),
        "p_mastery": result.get("p_mastery"),
        "attempts": result.get("attempts"),
        "correct": result.get("correct"),
    }


@router.get("/mastery", summary="Maîtrise de l'élève par compétence")
async def get_mastery(
    user_id: UUID = Depends(get_current_user_id),
    _: None = Depends(_require_enabled),
) -> dict[str, Any]:
    rows = await get_mastery_service().get_mastery(user_id)
    return {"mastery": rows}


@router.get("/next-step", summary="Prochaine compétence à travailler (PlannerAgent)")
async def next_step(
    user_id: UUID = Depends(get_current_user_id),
    _: None = Depends(_require_enabled),
) -> dict[str, Any]:
    return await _planner.recommend(user_id)
