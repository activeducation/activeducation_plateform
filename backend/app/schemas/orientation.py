"""
Schemas Pydantic pour le module Orientation.

Ces schemas definissent les structures de donnees pour:
- Tests d'orientation
- Questions et options
- Sessions de test
- Resultats
- Carrieres
"""

from datetime import datetime
from enum import Enum
from typing import Any, Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


# =============================================================================
# ENUMS
# =============================================================================


class TestType(str, Enum):
    """Types de tests d'orientation disponibles."""

    RIASEC = "riasec"
    PERSONALITY = "personality"
    SKILLS = "skills"
    INTERESTS = "interests"
    APTITUDE = "aptitude"


class QuestionType(str, Enum):
    """Types de questions."""

    LIKERT_SCALE = "likert"
    MULTIPLE_CHOICE = "multipleChoice"
    BOOLEAN = "boolean"
    SCENARIO = "scenario"
    THIS_OR_THAT = "thisOrThat"
    RANKING = "ranking"
    SLIDER = "slider"


class SessionStatus(str, Enum):
    """Statuts possibles d'une session de test."""

    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    ABANDONED = "abandoned"


class JobDemand(str, Enum):
    """Niveau de demande pour un metier."""

    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"


class GrowthTrend(str, Enum):
    """Tendance de croissance d'un metier."""

    GROWING = "growing"
    STABLE = "stable"
    DECLINING = "declining"


# =============================================================================
# SCHEMAS DE BASE (pour creation/update)
# =============================================================================


class OptionBase(BaseModel):
    """Option de reponse pour une question."""

    model_config = ConfigDict(populate_by_name=True)

    id: str
    text: str = Field(alias="option_text")
    value: Any = Field(alias="option_value")
    icon: Optional[str] = None
    emoji: Optional[str] = None


class QuestionBase(BaseModel):
    """Question d'un test."""

    model_config = ConfigDict(populate_by_name=True)

    id: str
    text: str = Field(alias="question_text")
    type: QuestionType = Field(alias="question_type")
    category: Optional[str] = None
    options: list[OptionBase] = []
    image_asset: Optional[str] = Field(None, alias="imageAsset")
    section_title: Optional[str] = Field(None, alias="sectionTitle")
    slider_left_label: Optional[str] = Field(None, alias="sliderLeftLabel")
    slider_right_label: Optional[str] = Field(None, alias="sliderRightLabel")


class TestBase(BaseModel):
    """Test d'orientation de base."""

    name: str
    description: str
    type: TestType
    duration_minutes: int = 15
    image_url: Optional[str] = None


# =============================================================================
# SCHEMAS DE CARRIERES (Deplaces avant TestResult pour usage direct)
# =============================================================================


class EducationPath(BaseModel):
    """Parcours educatif pour une carriere."""

    minimum_level: str = "BAC"
    recommended_formations: list[str] = []
    schools_in_togo: list[str] = []
    duration_years: int = 3
    certifications: Optional[str] = None


class SalaryInfo(BaseModel):
    """Informations salariales."""

    model_config = ConfigDict(populate_by_name=True)

    min_fcfa: int = Field(alias="salary_min_fcfa")
    max_fcfa: int = Field(alias="salary_max_fcfa")
    avg_fcfa: int = Field(alias="salary_avg_fcfa")
    note: Optional[str] = Field(None, alias="salary_note")


class Career(BaseModel):
    """Carriere/Metier complet."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    description: str
    sector_name: str
    image_url: Optional[str] = None

    # Competences et traits
    required_skills: list[str] = []
    related_traits: list[str] = []

    # Education
    education_path: EducationPath

    # Salaires
    salary_min_fcfa: Optional[int] = None
    salary_max_fcfa: Optional[int] = None
    salary_avg_fcfa: Optional[int] = None
    salary_note: Optional[str] = None

    # Perspectives
    job_demand: Optional[JobDemand] = None
    growth_trend: Optional[GrowthTrend] = None
    outlook_description: Optional[str] = None
    top_employers: list[str] = []
    entrepreneurship_potential: bool = False


class CareerSummary(BaseModel):
    """Resume d'une carriere avec score de correspondance."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    description: str = ""
    sector_name: str
    job_demand: Optional[JobDemand] = None
    salary_avg_fcfa: Optional[int] = None
    image_url: Optional[str] = None
    # Champs de matching (remplis lors des recommandations)
    match_score: float = Field(default=0.0, ge=0, le=100, description="Score de correspondance avec le profil (0-100)")
    matching_traits: list[str] = Field(default=[], description="Traits en commun avec le profil utilisateur")
    # Champs enrichis pour le mobile
    required_skills: list[str] = []
    related_traits: list[str] = []
    education_minimum_level: Optional[str] = None
    salary_min_fcfa: Optional[int] = None
    salary_max_fcfa: Optional[int] = None


class CareerRecommendation(BaseModel):
    """Recommandation de carriere basee sur les resultats de test."""

    career: CareerSummary
    match_score: float = Field(..., ge=0, le=100)
    matching_traits: list[str] = []


# =============================================================================
# SCHEMAS COMPLETS (avec ID et timestamps)
# =============================================================================


class Option(OptionBase):
    """Option complete avec ID."""

    pass


class Question(QuestionBase):
    """Question complete avec options."""

    options: list[Option] = []


class OrientationTest(TestBase):
    """Test d'orientation complet."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    questions: list[Question] = []
    is_active: bool = True
    display_order: int = 0


class OrientationTestSummary(BaseModel):
    """Resume d'un test (sans les questions)."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    description: str
    type: TestType
    duration_minutes: int
    image_url: Optional[str] = None
    is_active: bool = True


# =============================================================================
# SCHEMAS MOBILE-FRIENDLY (camelCase)
# =============================================================================


class MobileOption(BaseModel):
    """Option au format mobile (camelCase)."""

    id: str
    text: str
    value: Any
    icon: Optional[str] = None
    emoji: Optional[str] = None


class MobileQuestion(BaseModel):
    """Question au format mobile (camelCase)."""

    model_config = ConfigDict(populate_by_name=True)

    id: str
    text: str
    type: str
    category: Optional[str] = None
    options: list[MobileOption] = []
    imageAsset: Optional[str] = None
    sectionTitle: Optional[str] = None
    sliderLeftLabel: Optional[str] = None
    sliderRightLabel: Optional[str] = None


class MobileOrientationTest(BaseModel):
    """Test au format mobile (camelCase pour Flutter json_serializable)."""

    id: str
    name: str
    description: str
    type: str
    durationMinutes: int
    questions: list[MobileQuestion] = []
    imageUrl: Optional[str] = None


# =============================================================================
# SCHEMAS DE SESSION
# =============================================================================


class TestSessionCreate(BaseModel):
    """Donnees pour creer une session de test."""

    test_id: UUID


class TestSessionResponse(BaseModel):
    """Reponse apres creation d'une session."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    test_id: UUID
    user_id: UUID
    status: SessionStatus
    started_at: datetime


class TestSubmission(BaseModel):
    """Donnees pour soumettre un test."""

    responses: dict[str, str] = Field(
        ...,
        description="Dictionnaire {question_id: option_id}",
        examples=[{"Q1": "opt_3", "Q2": "opt_1"}],
    )


# =============================================================================
# SCHEMAS DE RESULTATS
# =============================================================================


class TestResult(BaseModel):
    """Resultats d'un test d'orientation avec interpretation structuree."""

    test_id: UUID
    scores: dict[str, float] = Field(
        ...,
        description="Scores par categorie (en francais, normalises 0-100%)",
        examples=[{"Réaliste": 85.0, "Investigateur": 40.0}],
    )
    dominant_traits: list[str] = Field(
        ...,
        description="Top 3 des traits dominants (en francais)",
        examples=[["Réaliste", "Investigateur", "Artistique"]],
    )
    recommendations: list[CareerSummary] = Field(
        default=[],
        description="Liste de carrieres recommandees avec score de correspondance",
    )
    interpretation: dict = Field(
        default={},
        description="Interpretation structuree du profil: profile_summary, strengths, work_style, advice, recommended_sectors",
    )
    matching_programs: list[dict] = Field(
        default=[],
        description="Programmes scolaires correspondant au profil",
    )

    model_config = ConfigDict(from_attributes=True)


class TestResultWithDetails(TestResult):
    """Resultats avec details supplementaires."""

    session_id: UUID
    user_id: UUID
    calculated_at: datetime


class UserTestHistory(BaseModel):
    """Historique des tests d'un utilisateur."""

    session_id: UUID
    test_id: UUID
    test_name: str
    status: SessionStatus
    started_at: datetime
    completed_at: Optional[datetime] = None
    result: Optional[TestResult] = None


# =============================================================================
# SCHEMAS MOBILE CARRIERES (camelCase pour Flutter)
# =============================================================================


class MobileEducationPath(BaseModel):
    """Parcours educatif au format mobile."""

    minimumLevel: str = "BAC"
    recommendedFormations: list[str] = []
    schoolsInTogo: list[str] = []
    durationYears: int = 3
    certifications: Optional[str] = None


class MobileSalaryInfo(BaseModel):
    """Informations salariales au format mobile."""

    minMonthlyFCFA: int
    maxMonthlyFCFA: int
    averageMonthlyFCFA: int
    experienceNote: str = ""


class MobileJobOutlook(BaseModel):
    """Perspectives d'emploi au format mobile."""

    demand: str  # high, medium, low
    trend: str  # growing, stable, declining
    description: str
    topEmployers: list[str] = []
    entrepreneurshipPotential: bool = False


class MobileCareer(BaseModel):
    """Carriere au format mobile (camelCase pour Flutter)."""

    id: str
    name: str
    description: str
    sector: str
    requiredSkills: list[str] = []
    relatedTraits: list[str] = []
    educationPath: MobileEducationPath
    salaryInfo: MobileSalaryInfo
    outlook: MobileJobOutlook
    imageUrl: Optional[str] = None


# =============================================================================
# SCHEMAS DE FAVORIS
# =============================================================================


class FavoriteCareerRequest(BaseModel):
    """Requete pour ajouter/retirer un favori."""

    career_id: UUID


class FavoriteCareerResponse(BaseModel):
    """Reponse apres action sur favori."""

    success: bool
    message: str
    career_id: UUID
