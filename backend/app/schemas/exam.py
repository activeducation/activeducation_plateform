"""Schemas Pydantic pour les examens des cours."""

from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Any, Optional
from uuid import UUID

from pydantic import BaseModel, Field, field_validator

# ── Types de questions ───────────────────────────────────────────────────────


class QuestionType(str, Enum):
    SINGLE_CHOICE = "single_choice"
    MULTIPLE_CHOICE = "multiple_choice"
    TEXT_INPUT = "text_input"
    ORDERING = "ordering"


# ── Options & questions ──────────────────────────────────────────────────────


class ExamOption(BaseModel):
    text: str = Field(..., min_length=1, max_length=500)
    is_correct: bool = False


class ExamQuestionCreate(BaseModel):
    question: str = Field(..., min_length=1, max_length=1000)
    question_type: QuestionType = QuestionType.SINGLE_CHOICE
    options: list[ExamOption] = Field(default_factory=list, min_length=0, max_length=8)
    points: int = Field(1, ge=1, le=10)

    @field_validator("options")
    @classmethod
    def _validate_options(cls, v: list[ExamOption], info) -> list[ExamOption]:
        qtype = info.data.get("question_type", QuestionType.SINGLE_CHOICE)
        if qtype in (QuestionType.SINGLE_CHOICE, QuestionType.MULTIPLE_CHOICE):
            if len(v) < 2:
                raise ValueError("Au moins 2 options requises pour ce type de question.")
            if qtype == QuestionType.SINGLE_CHOICE and sum(1 for o in v if o.is_correct) != 1:
                raise ValueError("Une seule option doit être correcte (single_choice).")
            if qtype == QuestionType.MULTIPLE_CHOICE and not any(o.is_correct for o in v):
                raise ValueError("Au moins une option correcte requise (multiple_choice).")
        if qtype == QuestionType.TEXT_INPUT and not any(o.is_correct for o in v):
            raise ValueError("Au moins une réponse acceptée requise (text_input).")
        if qtype == QuestionType.ORDERING and len(v) < 2:
            raise ValueError("Au moins 2 éléments requis pour une question d'ordonnancement.")
        return v


class ExamQuestionResponse(BaseModel):
    id: UUID
    question: str
    question_type: QuestionType = QuestionType.SINGLE_CHOICE
    options: list[dict]
    points: int
    display_order: int


# ── Examen (admin) ───────────────────────────────────────────────────────────


class ExamUpsert(BaseModel):
    """Cree/met a jour l'examen d'un cours (avec ses questions)."""

    title: str = Field("Examen final", max_length=200)
    description: Optional[str] = Field(None, max_length=1000)
    passing_score: int = Field(80, ge=0, le=100)
    xp_reward: int = Field(100, ge=0, le=10000)
    badge_title: Optional[str] = Field(None, max_length=120)
    badge_icon: Optional[str] = Field(None, max_length=300)
    is_active: bool = True
    questions: list[ExamQuestionCreate] = Field(default_factory=list)


class ExamResponse(BaseModel):
    id: UUID
    course_id: UUID
    title: str
    description: Optional[str] = None
    passing_score: int
    xp_reward: int
    badge_title: Optional[str] = None
    badge_icon: Optional[str] = None
    is_active: bool
    questions: list[ExamQuestionResponse] = Field(default_factory=list)


# ── Examen cote etudiant (sans les bonnes reponses) ──────────────────────────


class ExamPublicOption(BaseModel):
    text: str


class ExamPublicQuestion(BaseModel):
    id: UUID
    question: str
    question_type: QuestionType = QuestionType.SINGLE_CHOICE
    options: list[ExamPublicOption]


class ExamPublic(BaseModel):
    """Vue etudiant : pas de is_correct expose."""

    id: UUID
    course_id: UUID
    title: str
    description: Optional[str] = None
    passing_score: int
    badge_title: Optional[str] = None
    badge_icon: Optional[str] = None
    questions: list[ExamPublicQuestion] = Field(default_factory=list)


# ── Soumission ───────────────────────────────────────────────────────────────


class ExamSubmission(BaseModel):
    """
    Reponses de l'etudiant.
    La valeur varie selon le type de question :
    - single_choice : int (index de l'option)
    - multiple_choice : list[int] (indices selectionnes)
    - text_input : str (reponse libre)
    - ordering : list[int] (indices dans l'ordre choisi)
    """
    answers: dict[str, Any]


class ExamResult(BaseModel):
    score: int  # pourcentage 0..100
    passed: bool
    passing_score: int
    correct_count: int
    total_questions: int
    xp_awarded: int = 0
    badge_earned: bool = False
    badge_title: Optional[str] = None
    badge_icon: Optional[str] = None
    attempt_at: Optional[datetime] = None
    details: Optional[list[dict]] = None  # reponse par question pour le feedback
