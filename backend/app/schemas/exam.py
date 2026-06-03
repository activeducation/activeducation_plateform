"""Schemas Pydantic pour les examens QCM des cours."""

from __future__ import annotations

from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field, field_validator


# ── Options & questions ──────────────────────────────────────────────────────

class ExamOption(BaseModel):
    text: str = Field(..., min_length=1, max_length=500)
    is_correct: bool = False


class ExamQuestionCreate(BaseModel):
    question: str = Field(..., min_length=1, max_length=1000)
    options: list[ExamOption] = Field(..., min_length=2, max_length=8)
    points: int = Field(1, ge=1, le=10)

    @field_validator("options")
    @classmethod
    def _at_least_one_correct(cls, v: list[ExamOption]) -> list[ExamOption]:
        if not any(o.is_correct for o in v):
            raise ValueError("Au moins une option doit être correcte.")
        return v


class ExamQuestionResponse(BaseModel):
    id: UUID
    question: str
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
    # {question_id (str): index de l'option choisie (int)}
    answers: dict[str, int]


class ExamResult(BaseModel):
    score: int               # pourcentage 0..100
    passed: bool
    passing_score: int
    correct_count: int
    total_questions: int
    xp_awarded: int = 0
    badge_earned: bool = False
    badge_title: Optional[str] = None
    badge_icon: Optional[str] = None
    attempt_at: Optional[datetime] = None
