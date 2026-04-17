"""
Schemas Pydantic pour le School Dashboard.

Definit les structures pour:
- Authentification school_admin
- CRUD cours / modules / lecons
- Stats du dashboard
- Profil ecole
"""

from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


# =============================================================================
# AUTH
# =============================================================================


class SchoolAdminLoginResponse(BaseModel):
    """Reponse login pour un school_admin."""

    user: dict
    tokens: dict
    school: dict


# =============================================================================
# COURSES
# =============================================================================


class SchoolCourseCreate(BaseModel):
    """Creation d'un cours par une ecole."""

    title: str = Field(..., min_length=3, max_length=200)
    description: Optional[str] = Field(None, max_length=2000)
    difficulty: Optional[str] = Field(None, pattern="^(beginner|intermediate|advanced)$")
    category: Optional[str] = Field(None, max_length=100)
    duration_minutes: Optional[int] = Field(None, ge=1)
    points_reward: int = Field(0, ge=0)
    thumbnail_url: Optional[str] = None


class SchoolCourseUpdate(BaseModel):
    """Mise a jour d'un cours."""

    title: Optional[str] = Field(None, min_length=3, max_length=200)
    description: Optional[str] = Field(None, max_length=2000)
    difficulty: Optional[str] = Field(None, pattern="^(beginner|intermediate|advanced)$")
    category: Optional[str] = Field(None, max_length=100)
    duration_minutes: Optional[int] = Field(None, ge=1)
    points_reward: Optional[int] = Field(None, ge=0)
    thumbnail_url: Optional[str] = None


class SchoolCourseResponse(BaseModel):
    """Reponse cours avec school_id."""

    id: UUID
    title: str
    description: Optional[str] = None
    difficulty: Optional[str] = None
    category: Optional[str] = None
    duration_minutes: Optional[int] = None
    points_reward: int = 0
    thumbnail_url: Optional[str] = None
    is_published: bool = False
    display_order: int = 0
    school_id: Optional[UUID] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


class PublishRequest(BaseModel):
    """Toggle publication d'un cours."""

    is_published: bool


# =============================================================================
# MODULES
# =============================================================================


class SchoolModuleCreate(BaseModel):
    """Creation d'un module."""

    title: str = Field(..., min_length=2, max_length=200)
    description: Optional[str] = Field(None, max_length=1000)
    display_order: int = Field(0, ge=0)


class SchoolModuleUpdate(BaseModel):
    """Mise a jour d'un module."""

    title: Optional[str] = Field(None, min_length=2, max_length=200)
    description: Optional[str] = Field(None, max_length=1000)
    display_order: Optional[int] = Field(None, ge=0)


class ReorderRequest(BaseModel):
    """Reordonner des modules."""

    ordered_ids: list[UUID]


# =============================================================================
# LESSONS
# =============================================================================


class SchoolLessonCreate(BaseModel):
    """Creation d'une lecon."""

    title: str = Field(..., min_length=2, max_length=200)
    lesson_type: str = Field(..., pattern="^(video|text|quiz|pdf)$")
    duration_minutes: Optional[int] = Field(None, ge=1)
    points_reward: int = Field(0, ge=0)
    is_free: bool = False
    display_order: int = Field(0, ge=0)
    content_data: Optional[dict] = None


class SchoolLessonUpdate(BaseModel):
    """Mise a jour d'une lecon."""

    title: Optional[str] = Field(None, min_length=2, max_length=200)
    lesson_type: Optional[str] = Field(None, pattern="^(video|text|quiz|pdf)$")
    duration_minutes: Optional[int] = Field(None, ge=1)
    points_reward: Optional[int] = Field(None, ge=0)
    is_free: Optional[bool] = None
    display_order: Optional[int] = Field(None, ge=0)
    content_data: Optional[dict] = None


# =============================================================================
# DASHBOARD
# =============================================================================


class SchoolDashboardStats(BaseModel):
    """Statistiques du dashboard ecole."""

    total_courses: int = 0
    published_courses: int = 0
    total_enrollments: int = 0
    avg_progress: float = 0.0


# =============================================================================
# SCHOOL PROFILE
# =============================================================================


class SchoolProfileUpdate(BaseModel):
    """Mise a jour du profil ecole."""

    description: Optional[str] = Field(None, max_length=2000)
    logo_url: Optional[str] = None
    cover_image_url: Optional[str] = None
    phone: Optional[str] = Field(None, max_length=30)
    email: Optional[str] = Field(None, max_length=150)
    website: Optional[str] = Field(None, max_length=300)
