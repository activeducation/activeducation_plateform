"""Service de recommandation d'orientation multi-criteres.

Assemble les donnees (profil eleve, dernier test, carrieres, formations) et
delegue le scoring au moteur pur `OrientationMatchEngine`.

Expose aussi la completude du profil : plus l'eleve renseigne de criteres,
plus la recommandation est fiable — l'UI peut l'inciter a completer.
"""

from __future__ import annotations

from typing import Any, Optional
from uuid import UUID

from app.core.logging import get_logger
from app.repositories.orientation_profile_repository import (
    OrientationProfileRepository,
    get_orientation_profile_repository,
)
from app.services.orientation_match_engine import (
    OrientationMatchEngine,
    orientation_match_engine,
)

logger = get_logger("services.orientation_recommendation")

# Libelles des criteres, pour guider l'eleve vers ce qui manque.
_CRITERIA_LABELS = {
    "tests": "un test d'orientation",
    "grades": "vos notes",
    "interests": "vos centres d'intérêt",
    "budget": "votre budget",
    "project": "votre projet professionnel",
}


class OrientationRecommendationService:
    """Recommandations d'orientation combinant tous les criteres disponibles."""

    def __init__(
        self,
        repository: Optional[OrientationProfileRepository] = None,
        engine: Optional[OrientationMatchEngine] = None,
    ) -> None:
        self._repo = repository
        self._engine = engine or orientation_match_engine

    def _get_repo(self) -> OrientationProfileRepository:
        if self._repo is None:
            self._repo = get_orientation_profile_repository()
        return self._repo

    @staticmethod
    def profile_completeness(
        profile: dict[str, Any],
        has_test_result: bool,
    ) -> dict[str, Any]:
        """Part des criteres renseignes + liste de ce qui manque."""
        present = {
            "tests": has_test_result,
            "grades": bool(profile.get("grades")),
            "interests": bool(
                (profile.get("interests") or []) or (profile.get("favorite_subjects") or [])
            ),
            "budget": bool(profile.get("budget_annual_fcfa")),
            "project": bool((profile.get("career_project") or "").strip()),
        }
        filled = sum(1 for v in present.values() if v)
        return {
            "percent": round((filled / len(present)) * 100),
            "criteria": present,
            "missing": [_CRITERIA_LABELS[k] for k, v in present.items() if not v],
        }

    async def recommend(self, user_id: UUID, limit: int = 10) -> dict[str, Any]:
        """Classe les metiers les plus pertinents pour l'eleve."""
        repo = self._get_repo()

        profile = await repo.get_profile(user_id) or {}
        riasec = await repo.get_latest_test_result(user_id)
        careers = await repo.list_active_careers()
        programs_by_career = await repo.list_programs_grouped_by_career()

        recommendations = self._engine.rank_careers(
            profile,
            careers,
            riasec=riasec,
            programs_by_career=programs_by_career,
            limit=limit,
        )

        return {
            "recommendations": recommendations,
            "has_test_result": bool(riasec),
            "profile_completeness": self.profile_completeness(profile, bool(riasec)),
        }


_service: Optional[OrientationRecommendationService] = None


def get_orientation_recommendation_service() -> OrientationRecommendationService:
    """Retourne l'instance (unique) du service de recommandation."""
    global _service
    if _service is None:
        _service = OrientationRecommendationService()
    return _service
