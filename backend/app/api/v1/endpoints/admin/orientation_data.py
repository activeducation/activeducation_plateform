"""Admin — donnees alimentant le moteur d'orientation multi-criteres.

PATCH /admin/orientation-data/careers/{id}  → matieres cles d'un metier
PATCH /admin/orientation-data/programs/{id} → cout annuel d'une formation

Ces deux champs conditionnent respectivement le critere "notes" et le critere
"budget" : sans eux, ces criteres sont simplement ignores par le moteur.
"""

from typing import Any, Optional
from uuid import UUID

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from app.core.security import get_current_admin
from app.repositories.orientation_profile_repository import (
    get_orientation_profile_repository,
)

router = APIRouter()


class CareerSubjectsRequest(BaseModel):
    key_subjects: list[str] = Field(
        default_factory=list,
        max_length=15,
        description="Matières scolaires clés du métier. Ex: ['Mathématiques', 'Physique']",
    )


class ProgramCostRequest(BaseModel):
    tuition_annual_fcfa: Optional[int] = Field(default=None, ge=0)
    is_public: Optional[bool] = None


@router.patch(
    "/careers/{career_id}",
    summary="Définir les matières clés d'un métier (critère notes)",
)
async def set_career_key_subjects(
    career_id: UUID,
    request: CareerSubjectsRequest,
    admin=Depends(get_current_admin),
) -> dict[str, Any]:
    career = await get_orientation_profile_repository().set_career_key_subjects(
        career_id, request.key_subjects,
    )
    return {"career": career}


@router.patch(
    "/programs/{program_id}",
    summary="Définir le coût annuel d'une formation (critère budget)",
)
async def set_program_cost(
    program_id: UUID,
    request: ProgramCostRequest,
    admin=Depends(get_current_admin),
) -> dict[str, Any]:
    program = await get_orientation_profile_repository().set_program_cost(
        program_id,
        tuition_annual_fcfa=request.tuition_annual_fcfa,
        is_public=request.is_public,
    )
    return {"program": program}
