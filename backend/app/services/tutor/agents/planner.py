"""PlannerAgent — recommande la prochaine compétence à travailler.

Lit la maîtrise de l'élève (via MasteryService.weak_skills), enrichit avec
les titres des compétences, et formule une recommandation. Point d'entrée du
tutorat adaptatif : cibler ce qui est réellement mal maîtrisé.
"""

from __future__ import annotations

from typing import Any, Optional
from uuid import UUID

from app.core.logging import get_logger
from app.repositories.skill_repository import SkillRepository, get_skill_repository
from app.services.tutor.mastery.service import MasteryService, get_mastery_service

logger = get_logger("services.tutor.agents.planner")


class PlannerAgent:
    """Recommande les compétences faibles à renforcer."""

    def __init__(
        self,
        mastery_service: Optional[MasteryService] = None,
        skill_repository: Optional[SkillRepository] = None,
    ) -> None:
        self._mastery = mastery_service
        self._skills = skill_repository

    def _get_mastery(self) -> MasteryService:
        if self._mastery is None:
            self._mastery = get_mastery_service()
        return self._mastery

    def _get_skills(self) -> SkillRepository:
        if self._skills is None:
            self._skills = get_skill_repository()
        return self._skills

    async def recommend(self, user_id: UUID, limit: int = 3) -> dict[str, Any]:
        """Retourne les compétences faibles + un message de recommandation."""
        weak = await self._get_mastery().weak_skills(user_id, limit=limit)

        enriched: list[dict[str, Any]] = []
        for row in weak:
            skill_id = row.get("skill_id")
            title = None
            if skill_id:
                try:
                    skill = await self._get_skills().get_skill(UUID(str(skill_id)))
                    title = skill.get("title") if skill else None
                except Exception as e:  # enrichissement best-effort
                    logger.debug("Titre compétence %s indisponible: %s", skill_id, e)
            enriched.append({
                "skill_id": skill_id,
                "title": title,
                "p_mastery": row.get("p_mastery"),
            })

        if not enriched:
            message = (
                "Aucune lacune détectée pour l'instant. Continue les exercices "
                "pour que je puisse cibler ce qui te ferait progresser !"
            )
        else:
            names = ", ".join(e["title"] or "une compétence" for e in enriched)
            message = f"Je te conseille de renforcer en priorité : {names}."

        return {
            "has_recommendation": bool(enriched),
            "weak_skills": enriched,
            "message": message,
        }
