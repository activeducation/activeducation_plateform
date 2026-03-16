"""
Schemas Pydantic pour le module E-Learning.

Ces schemas definissent les structures de donnees pour:
- Cours (catalogue, detail)
- Modules et lecons
- Contenu de lecon (polymorphique via JSONB)
- Progression utilisateur
- Inscriptions aux cours
"""

from enum import Enum
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict


# =============================================================================
# ENUMS
# =============================================================================


class LessonType(str, Enum):
    """Types de lecons disponibles."""

    VIDEO = "video"
    ARTICLE = "article"
    QUIZ = "quiz"
    PDF = "pdf"
    CHALLENGE = "challenge"


class CourseDifficulty(str, Enum):
    """Niveaux de difficulte des cours."""

    DEBUTANT = "debutant"
    INTERMEDIAIRE = "intermediaire"
    AVANCE = "avance"


class LessonStatus(str, Enum):
    """Etat de progression d'une lecon pour l'utilisateur."""

    NOT_STARTED = "not_started"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"


# =============================================================================
# COURS
# =============================================================================


class CourseListItem(BaseModel):
    """Element de liste de cours — catalogue public."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    title: str
    description: Optional[str] = None
    thumbnail_url: Optional[str] = None
    category: Optional[str] = None
    difficulty: CourseDifficulty
    duration_minutes: int
    points_reward: int
    is_published: bool
    display_order: int
    # Champs enrichis si l'utilisateur est connecte
    progress_pct: Optional[int] = None
    is_enrolled: Optional[bool] = False


# =============================================================================
# LECONS
# =============================================================================


class LessonSummary(BaseModel):
    """Resume d'une lecon dans la liste d'un module."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    title: str
    lesson_type: LessonType
    duration_minutes: int
    points_reward: int
    is_free: bool
    # Etat de progression pour l'utilisateur connecte
    status: Optional[LessonStatus] = None


# =============================================================================
# MODULES
# =============================================================================


class ModuleDetail(BaseModel):
    """Module d'un cours avec toutes ses lecons."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    title: str
    description: Optional[str] = None
    display_order: int
    is_locked: bool
    lessons: list[LessonSummary]


# =============================================================================
# DETAIL COURS
# =============================================================================


class CourseDetail(CourseListItem):
    """Detail complet d'un cours avec ses modules et lecons."""

    modules: list[ModuleDetail]


# =============================================================================
# CONTENU DE LECON
# =============================================================================


class LessonContent(BaseModel):
    """
    Contenu polymorphique d'une lecon.

    Le champ `data` contient des structures differentes selon lesson_type:
    - video:     {"url": "...", "provider": "youtube|vimeo", "duration_seconds": 300}
    - article:   {"body": "...", "format": "markdown|html"}
    - quiz:      {"questions": [...]}
    - pdf:       {"url": "...", "filename": "..."}
    - challenge: {"instructions": "...", "starter_code": "...", "language": "python"}
    """

    lesson_type: LessonType
    data: dict


class LessonDetail(LessonSummary):
    """Detail complet d'une lecon avec son contenu."""

    content: Optional[LessonContent] = None


# =============================================================================
# INSCRIPTIONS
# =============================================================================


class EnrollmentResponse(BaseModel):
    """Reponse apres inscription a un cours."""

    course_id: UUID
    enrolled_at: str
    progress_pct: int


# =============================================================================
# PROGRESSION
# =============================================================================


class CompleteLessonRequest(BaseModel):
    """Corps de la requete pour marquer une lecon comme terminee."""

    score: Optional[int] = None
    answers: Optional[dict] = None


class CompleteLessonResponse(BaseModel):
    """Reponse apres completion d'une lecon."""

    lesson_id: UUID
    status: str
    points_earned: int
    course_progress_pct: Optional[int] = None


# =============================================================================
# MES COURS
# =============================================================================


class MyCourse(BaseModel):
    """Un cours inscrit par l'utilisateur avec sa progression."""

    model_config = ConfigDict(from_attributes=True)

    course: CourseListItem
    progress_pct: int
    last_lesson_id: Optional[UUID] = None
    enrolled_at: str


class MyCoursesResponse(BaseModel):
    """Reponse de la liste des cours de l'utilisateur."""

    courses: list[MyCourse]
