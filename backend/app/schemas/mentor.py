"""Schemas Pydantic pour les candidatures mentor et les taches mentor."""

from __future__ import annotations

from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field, field_validator

# ============================================================================
# CANDIDATURES MENTOR
# ============================================================================


class MentorApplicationCreate(BaseModel):
    """Candidature envoyee depuis l'app etudiant."""

    full_name: str = Field(..., min_length=2, max_length=120)
    email: EmailStr
    phone: Optional[str] = Field(None, max_length=40)
    specialty: str = Field(..., min_length=2, max_length=120)
    bio: Optional[str] = Field(None, max_length=2000)
    years_experience: Optional[int] = Field(None, ge=0, le=80)
    expertise_areas: Optional[list[str]] = None
    linkedin_url: Optional[str] = Field(None, max_length=300)
    motivation: Optional[str] = Field(None, max_length=2000)

    @field_validator("full_name", "specialty")
    @classmethod
    def _strip(cls, v: str) -> str:
        return v.strip()

    @field_validator("expertise_areas")
    @classmethod
    def _clean_areas(cls, v: Optional[list[str]]) -> Optional[list[str]]:
        if not v:
            return v
        return [a.strip() for a in v if a and a.strip()][:15]


class MentorApplicationResponse(BaseModel):
    id: UUID
    full_name: str
    email: str
    phone: Optional[str] = None
    specialty: str
    bio: Optional[str] = None
    years_experience: Optional[int] = None
    expertise_areas: Optional[list[str]] = None
    linkedin_url: Optional[str] = None
    motivation: Optional[str] = None
    status: str
    review_note: Optional[str] = None
    created_mentor_id: Optional[UUID] = None
    created_at: Optional[datetime] = None


class MentorApplicationReview(BaseModel):
    """Decision admin sur une candidature."""

    note: Optional[str] = Field(None, max_length=1000)


# ============================================================================
# CREATION DIRECTE D'UN MENTOR (admin)
# ============================================================================


class MentorCreate(BaseModel):
    full_name: str = Field(..., min_length=2, max_length=120)
    specialty: str = Field(..., min_length=2, max_length=120)
    email: Optional[EmailStr] = None
    phone: Optional[str] = Field(None, max_length=40)
    bio: Optional[str] = Field(None, max_length=2000)
    years_experience: Optional[int] = Field(None, ge=0, le=80)
    expertise_areas: Optional[list[str]] = None
    linkedin_url: Optional[str] = Field(None, max_length=300)
    is_verified: bool = False


# ============================================================================
# TACHES ASSIGNEES AUX MENTORS
# ============================================================================

_TASK_STATUSES = {"todo", "in_progress", "done", "cancelled"}
_TASK_PRIORITIES = {"low", "normal", "high"}


class MentorTaskCreate(BaseModel):
    title: str = Field(..., min_length=2, max_length=200)
    description: Optional[str] = Field(None, max_length=2000)
    priority: str = "normal"
    due_date: Optional[datetime] = None

    @field_validator("priority")
    @classmethod
    def _valid_priority(cls, v: str) -> str:
        if v not in _TASK_PRIORITIES:
            raise ValueError(f"priority doit être parmi {sorted(_TASK_PRIORITIES)}")
        return v


class MentorTaskUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=2, max_length=200)
    description: Optional[str] = Field(None, max_length=2000)
    status: Optional[str] = None
    priority: Optional[str] = None
    due_date: Optional[datetime] = None

    @field_validator("status")
    @classmethod
    def _valid_status(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v not in _TASK_STATUSES:
            raise ValueError(f"status doit être parmi {sorted(_TASK_STATUSES)}")
        return v

    @field_validator("priority")
    @classmethod
    def _valid_priority(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v not in _TASK_PRIORITIES:
            raise ValueError(f"priority doit être parmi {sorted(_TASK_PRIORITIES)}")
        return v


class MentorTaskResponse(BaseModel):
    id: UUID
    mentor_id: UUID
    title: str
    description: Optional[str] = None
    status: str
    priority: str
    due_date: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    created_at: Optional[datetime] = None
