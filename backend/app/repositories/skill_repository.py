"""Repository du referentiel de competences (skills, lesson_skills).

Contenu pedagogique partage (non lie a un utilisateur), acces service_role.
"""

from datetime import datetime, timezone
from functools import lru_cache
from typing import Any, Optional
from uuid import UUID

from app.core.logging import get_logger
from app.core.exceptions import QueryError
from app.db.supabase_client import get_admin_supabase_client, SupabaseClient

logger = get_logger("repositories.skill")

_SKILLS = "skills"
_LESSON_SKILLS = "lesson_skills"


class SkillRepository:
    """CRUD des competences et de leur lien aux lecons."""

    def __init__(self) -> None:
        self._db: SupabaseClient = get_admin_supabase_client()

    async def create_skill(
        self,
        subject: str,
        code: str,
        title: str,
        description: Optional[str] = None,
        prerequisite_skill_ids: Optional[list[UUID]] = None,
    ) -> dict[str, Any]:
        """Cree une competence (unique par subject+code)."""
        try:
            now = datetime.now(timezone.utc).isoformat()
            data = {
                "subject": subject,
                "code": code,
                "title": title,
                "description": description,
                "prerequisite_skill_ids": [str(s) for s in (prerequisite_skill_ids or [])],
                "created_at": now,
                "updated_at": now,
            }
            result = self._db.insert(table=_SKILLS, data=data)
            return result[0] if result else data
        except Exception as e:
            logger.error("Erreur creation competence: %s", e, exc_info=True)
            raise QueryError(f"Erreur lors de la creation de la competence: {str(e)}")

    async def get_skill(self, skill_id: UUID) -> Optional[dict[str, Any]]:
        try:
            return self._db.fetch_one(table=_SKILLS, id_column="id", id_value=str(skill_id))
        except Exception as e:
            logger.error("Erreur lecture competence: %s", e, exc_info=True)
            raise QueryError(f"Erreur lors de la lecture de la competence: {str(e)}")

    async def list_by_subject(self, subject: str) -> list[dict[str, Any]]:
        try:
            return self._db.fetch_all(table=_SKILLS, filters={"subject": subject})
        except Exception as e:
            logger.error("Erreur liste competences: %s", e, exc_info=True)
            raise QueryError(f"Erreur lors de la liste des competences: {str(e)}")

    async def link_lesson(
        self,
        lesson_id: UUID,
        skill_id: UUID,
        weight: float = 1.0,
    ) -> dict[str, Any]:
        """Lie une lecon a une competence (upsert sur lesson_id+skill_id)."""
        try:
            data = {
                "lesson_id": str(lesson_id),
                "skill_id": str(skill_id),
                "weight": weight,
            }
            result = (
                self._db.client.table(_LESSON_SKILLS)
                .upsert(data, on_conflict="lesson_id,skill_id")
                .execute()
            )
            return result.data[0] if result.data else data
        except Exception as e:
            logger.error("Erreur lien lecon-competence: %s", e, exc_info=True)
            raise QueryError(f"Erreur lors du lien lecon-competence: {str(e)}")

    async def get_skills_for_lesson(self, lesson_id: UUID) -> list[dict[str, Any]]:
        """Competences couvertes par une lecon (skill_id + weight)."""
        try:
            result = (
                self._db.client.table(_LESSON_SKILLS)
                .select("skill_id, weight")
                .eq("lesson_id", str(lesson_id))
                .execute()
            )
            return result.data or []
        except Exception as e:
            logger.error("Erreur competences de lecon: %s", e, exc_info=True)
            raise QueryError(f"Erreur lors de la lecture des competences: {str(e)}")


@lru_cache(maxsize=1)
def get_skill_repository() -> SkillRepository:
    """Retourne l'instance (unique) du repository de competences."""
    return SkillRepository()
