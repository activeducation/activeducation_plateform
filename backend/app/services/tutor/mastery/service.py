"""MasteryService — enregistre les reponses et suit la maitrise (BKT).

A chaque reponse a un exercice ciblant une competence :
1. lit la maitrise actuelle (ou p_init si jamais evaluee),
2. la met a jour par BKT,
3. persiste (p_mastery, compteurs).

Expose aussi la lecture de la maitrise et la detection des competences
faibles (utilisee par le PlannerAgent en slice 2).
"""

from __future__ import annotations

from typing import Any, Optional
from uuid import UUID

from app.core.config import settings
from app.core.logging import get_logger
from app.repositories.mastery_repository import (
    MasteryRepository,
    get_mastery_repository,
)
from app.services.tutor.mastery.bkt import BktParams, bkt_update

logger = get_logger("services.tutor.mastery")


class MasteryService:
    """Suivi de la maitrise par competence."""

    def __init__(
        self,
        repository: Optional[MasteryRepository] = None,
        params: Optional[BktParams] = None,
    ) -> None:
        self._repo = repository
        self._params = params

    def _get_repo(self) -> MasteryRepository:
        if self._repo is None:
            self._repo = get_mastery_repository()
        return self._repo

    def _get_params(self) -> BktParams:
        if self._params is None:
            self._params = BktParams.from_settings()
        return self._params

    async def record_answer(
        self,
        user_id: UUID,
        skill_id: UUID,
        correct: bool,
    ) -> dict[str, Any]:
        """Enregistre une reponse et met a jour la maitrise BKT."""
        params = self._get_params()
        current = await self._get_repo().get(user_id, skill_id)

        prior = current["p_mastery"] if current else params.p_init
        attempts = (current["attempts"] if current else 0) + 1
        correct_count = (current["correct"] if current else 0) + (1 if correct else 0)

        new_p = bkt_update(prior, correct, params)
        result = await self._get_repo().upsert(
            user_id, skill_id, new_p, attempts, correct_count,
        )
        logger.debug(
            "Maitrise %s/%s : %.3f -> %.3f (correct=%s)",
            user_id, skill_id, prior, new_p, correct,
        )
        return result

    async def record_answers(
        self,
        user_id: UUID,
        skill_id: UUID,
        answers: list[bool],
    ) -> dict[str, Any]:
        """Enregistre plusieurs réponses (un quiz) pour une compétence.

        Applique le BKT séquentiellement et retourne l'état de maîtrise final.
        """
        result: dict[str, Any] = {}
        for correct in answers:
            result = await self.record_answer(user_id, skill_id, correct)
        return result

    async def get_mastery(self, user_id: UUID) -> list[dict[str, Any]]:
        """Retourne toute la maitrise d'un utilisateur (faible d'abord)."""
        return await self._get_repo().list_for_user(user_id)

    async def weak_skills(
        self,
        user_id: UUID,
        threshold: Optional[float] = None,
        limit: int = 10,
    ) -> list[dict[str, Any]]:
        """Competences sous le seuil de maitrise (a renforcer en priorite)."""
        threshold = threshold if threshold is not None else settings.MASTERY_THRESHOLD
        return await self._get_repo().list_weak(user_id, threshold, limit)


_mastery_service: Optional[MasteryService] = None


def get_mastery_service() -> MasteryService:
    """Retourne l'instance (unique) du service de maitrise."""
    global _mastery_service
    if _mastery_service is None:
        _mastery_service = MasteryService()
    return _mastery_service
