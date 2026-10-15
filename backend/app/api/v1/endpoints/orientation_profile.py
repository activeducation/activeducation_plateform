"""Endpoints du moteur d'orientation multi-criteres (eleve).

GET  /orientation/profile                     → profil d'orientation
PUT  /orientation/profile                     → enregistrer/mettre a jour
GET  /orientation/recommendations/multi-factor → metiers classes tous criteres

Complete les tests existants (RIASEC/MBTI) par les notes, matieres preferees,
centres d'interet, budget et projet professionnel.
"""

from typing import Any, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field, field_validator

from app.core.security import get_current_user_id
from app.repositories.orientation_profile_repository import (
    get_orientation_profile_repository,
)
from app.services.orientation_recommendation_service import (
    get_orientation_recommendation_service,
)

router = APIRouter()


# ---------------------------------------------------------------------------
# Schémas
# ---------------------------------------------------------------------------


class OrientationProfileRequest(BaseModel):
    """Profil d'orientation saisi par l'élève."""

    grades: dict[str, float] = Field(
        default_factory=dict,
        description="Notes par matière, sur 20. Ex: {\"Mathématiques\": 14.5}",
    )
    favorite_subjects: list[str] = Field(default_factory=list, max_length=20)
    interests: list[str] = Field(default_factory=list, max_length=30)
    budget_annual_fcfa: Optional[int] = Field(
        default=None, ge=0,
        description="Budget annuel maximum pour les études (FCFA)",
    )
    career_project: Optional[str] = Field(default=None, max_length=2000)

    @field_validator("grades")
    @classmethod
    def validate_grades(cls, v: dict[str, float]) -> dict[str, float]:
        if len(v) > 30:
            raise ValueError("30 matières maximum")
        for subject, grade in v.items():
            if not 0 <= grade <= 20:
                raise ValueError(f"Note invalide pour '{subject}' : attendue entre 0 et 20")
        return v


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------


@router.get("/profile", summary="Profil d'orientation de l'élève")
async def get_orientation_profile(
    user_id: UUID = Depends(get_current_user_id),
) -> dict[str, Any]:
    profile = await get_orientation_profile_repository().get_profile(user_id)
    return {"profile": profile}


@router.put("/profile", summary="Enregistrer le profil d'orientation")
async def upsert_orientation_profile(
    request: OrientationProfileRequest,
    user_id: UUID = Depends(get_current_user_id),
) -> dict[str, Any]:
    profile = await get_orientation_profile_repository().upsert_profile(
        user_id=user_id,
        grades=request.grades,
        favorite_subjects=request.favorite_subjects,
        interests=request.interests,
        budget_annual_fcfa=request.budget_annual_fcfa,
        career_project=request.career_project,
    )
    return {"profile": profile}


@router.get(
    "/recommendations/multi-factor",
    summary="Recommandations d'orientation (tests + notes + intérêts + budget + projet)",
    description=(
        "Classe les métiers en combinant tous les critères disponibles. "
        "Un critère non renseigné est exclu du calcul (et non pénalisé) : "
        "`profile_completeness` indique ce qu'il reste à renseigner pour affiner."
    ),
)
async def get_multi_factor_recommendations(
    limit: int = Query(default=10, ge=1, le=50),
    user_id: UUID = Depends(get_current_user_id),
) -> dict[str, Any]:
    return await get_orientation_recommendation_service().recommend(
        user_id=user_id, limit=limit,
    )
