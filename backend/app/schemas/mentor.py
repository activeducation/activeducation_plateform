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
    # URL renvoyee par POST /mentors/apply/photo. Reprise dans
    # mentors.avatar_url lors de l'approbation.
    photo_url: Optional[str] = Field(None, max_length=500)

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


# ============================================================================
# ESPACE MENTORAT : demande, relation, seances
# ============================================================================

# Canaux de seance. La visio n'est pas privilegiee : au Togo, WhatsApp et le
# telephone passent la ou la visio ne passe pas, et c'est deja la ou les
# echanges se font. Liste dupliquee dans la migration 030 (contrainte CHECK).
SESSION_CHANNELS = ("whatsapp", "telephone", "presentiel", "visio")

RELATIONSHIP_STATUSES = ("pending", "active", "completed", "cancelled")
SESSION_STATUSES = ("proposed", "confirmed", "done", "cancelled")


class MentorshipRequestCreate(BaseModel):
    """Demande de mentorat envoyee par un eleve."""

    # L'objectif est obligatoire : sans lui, le mentor ne peut pas decider, et
    # la recherche montre que les programmes qui marchent partent d'un but
    # explicite plutot que d'une mise en relation nue.
    goal: str = Field(..., min_length=10, max_length=500)
    message: Optional[str] = Field(None, max_length=2000)
    preferred_channel: Optional[str] = None

    @field_validator("goal", "message")
    @classmethod
    def _strip(cls, v: Optional[str]) -> Optional[str]:
        return v.strip() if v else v

    @field_validator("preferred_channel")
    @classmethod
    def _valid_channel(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v not in SESSION_CHANNELS:
            raise ValueError(f"preferred_channel doit être parmi {sorted(SESSION_CHANNELS)}")
        return v


class MentorshipDecision(BaseModel):
    """Reponse du mentor a une demande."""

    accept: bool
    reason: Optional[str] = Field(None, max_length=500)


class SessionCreate(BaseModel):
    """Proposition de seance."""

    scheduled_at: datetime
    duration_min: int = Field(45, ge=15, le=240)
    channel: str
    topic: Optional[str] = Field(None, max_length=200)

    @field_validator("channel")
    @classmethod
    def _valid_channel(cls, v: str) -> str:
        if v not in SESSION_CHANNELS:
            raise ValueError(f"channel doit être parmi {sorted(SESSION_CHANNELS)}")
        return v


class SessionUpdate(BaseModel):
    status: Optional[str] = None
    notes: Optional[str] = Field(None, max_length=2000)

    @field_validator("status")
    @classmethod
    def _valid_status(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v not in SESSION_STATUSES:
            raise ValueError(f"status doit être parmi {sorted(SESSION_STATUSES)}")
        return v


class SessionResponse(BaseModel):
    id: UUID
    relationship_id: UUID
    scheduled_at: datetime
    duration_min: int
    channel: str
    status: str
    proposed_by: str
    topic: Optional[str] = None
    notes: Optional[str] = None
    created_at: Optional[datetime] = None


class MentorshipResponse(BaseModel):
    """Une relation vue par l'eleve, mentor resume inclus."""

    id: UUID
    mentor_id: UUID
    status: str
    goal: Optional[str] = None
    message: Optional[str] = None
    preferred_channel: Optional[str] = None
    decline_reason: Optional[str] = None
    started_at: Optional[datetime] = None
    created_at: Optional[datetime] = None
    # Resume du mentor, pour eviter un aller-retour par relation.
    mentor_name: Optional[str] = None
    mentor_specialty: Optional[str] = None
    mentor_avatar_url: Optional[str] = None
    sessions: list[SessionResponse] = []
