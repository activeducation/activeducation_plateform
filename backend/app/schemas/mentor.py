"""Schemas Pydantic pour les candidatures mentor et les taches mentor."""

from __future__ import annotations

from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

# ============================================================================
# PORTFOLIO MENTOR (sous-modeles)
# ============================================================================


class PortfolioFormation(BaseModel):
    ecole: str = Field(..., min_length=1, max_length=200)
    diplome: str = Field(..., min_length=1, max_length=200)
    domaine: Optional[str] = Field(None, max_length=200)
    annee_debut: Optional[int] = Field(None, ge=1950, le=2100)
    annee_fin: Optional[int] = Field(None, ge=1950, le=2100)


class PortfolioExperience(BaseModel):
    poste: str = Field(..., min_length=1, max_length=200)
    entreprise: str = Field(..., min_length=1, max_length=200)
    debut: str = Field(..., description="Date au format YYYY-MM")
    fin: Optional[str] = Field(None, description="Date au format YYYY-MM ou null si en cours")
    en_cours: bool = False
    description: Optional[str] = Field(None, max_length=5000)


def _normalize_url(v: Optional[str]) -> Optional[str]:
    if not v:
        return v
    v = v.strip()
    if not v.startswith('http://') and not v.startswith('https://') and not v.startswith('//'):
        return f'https://{v}'
    return v


class PortfolioCertification(BaseModel):
    nom: str = Field(..., min_length=1, max_length=200)
    organisme: str = Field(..., min_length=1, max_length=200)
    annee: Optional[int] = Field(None, ge=1950, le=2100)
    lien: Optional[str] = Field(None, max_length=500)

    @field_validator("lien")
    @classmethod
    def _normalize_lien(cls, v: Optional[str]) -> Optional[str]:
        return _normalize_url(v)


class PortfolioProjet(BaseModel):
    nom: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=5000)
    lien: Optional[str] = Field(None, max_length=500)
    technologies: Optional[list[str]] = None

    @field_validator("lien")
    @classmethod
    def _normalize_lien(cls, v: Optional[str]) -> Optional[str]:
        return _normalize_url(v)


class PortfolioLangue(BaseModel):
    langue: str = Field(..., min_length=1, max_length=100)
    niveau: str = Field(..., description="Niveau: Débutant, Intermédiaire, Avancé, Courant, Natif")


class PortfolioLien(BaseModel):
    type: str = Field(..., description="github, website, twitter, etc.")
    url: str = Field(..., max_length=500)

    @field_validator("url")
    @classmethod
    def _normalize_url(cls, v: str) -> str:
        return _normalize_url(v) or v


class MentorPortfolio(BaseModel):
    """Structure complete du portfolio d'un mentor."""

    formations: list[PortfolioFormation] = []
    experiences: list[PortfolioExperience] = []
    certifications: list[PortfolioCertification] = []
    projets: list[PortfolioProjet] = []
    langues: list[PortfolioLangue] = []
    liens: list[PortfolioLien] = []


# ============================================================================
# CANDIDATURES MENTOR
# ============================================================================


class MentorApplicationCreate(BaseModel):
    """Candidature envoyee depuis l'app etudiant."""

    full_name: str = Field(..., min_length=2, max_length=120)
    email: EmailStr
    phone: Optional[str] = Field(None, max_length=40)
    specialty: str = Field(..., min_length=2, max_length=120)
    bio: Optional[str] = Field(None, max_length=5000)
    years_experience: Optional[int] = Field(None, ge=0, le=80)
    expertise_areas: Optional[list[str]] = None
    linkedin_url: Optional[str] = Field(None, max_length=300)
    motivation: Optional[str] = Field(None, max_length=5000)
    portfolio: Optional[MentorPortfolio] = None

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

    @field_validator("linkedin_url")
    @classmethod
    def _normalize_linkedin(cls, v: Optional[str]) -> Optional[str]:
        return _normalize_url(v)


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
    portfolio: Optional[MentorPortfolio] = None
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
    profession: Optional[str] = Field(None, max_length=120)
    specialty: str = Field(..., min_length=2, max_length=120)
    email: Optional[EmailStr] = None
    phone: Optional[str] = Field(None, max_length=40)
    bio: Optional[str] = Field(None, max_length=5000)
    years_experience: Optional[int] = Field(None, ge=0, le=80)
    expertise_areas: Optional[list[str]] = None
    linkedin_url: Optional[str] = Field(None, max_length=300)
    is_verified: bool = False
    portfolio: Optional[MentorPortfolio] = None

    @field_validator("linkedin_url")
    @classmethod
    def _normalize_linkedin(cls, v: Optional[str]) -> Optional[str]:
        return _normalize_url(v)


# ============================================================================
# MISE A JOUR DU PORTFOLIO (par le mentor lui-meme)
# ============================================================================


class MentorPortfolioUpdate(BaseModel):
    """Mise a jour partielle ou complete du portfolio."""

    portfolio: MentorPortfolio


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
# DEMANDES DE CONTACT (etudiant → mentor)
# ============================================================================


class MentorContactCreate(BaseModel):
    """Body pour qu'un etudiant contacte un mentor."""

    message: str = Field(..., min_length=1, max_length=2000)


class MentorContactRequest(BaseModel):
    """Demande de contact retournee par l'API."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    mentor_id: UUID
    student_id: UUID
    message: str
    status: str
    created_at: datetime
    updated_at: Optional[datetime] = None
    # Champs enrichis pour l'admin
    mentor_name: Optional[str] = None
    mentor_specialty: Optional[str] = None
    student_name: Optional[str] = None
    student_email: Optional[str] = None
