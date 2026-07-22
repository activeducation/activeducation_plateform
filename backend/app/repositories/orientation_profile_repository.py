"""Repository du profil d'orientation eleve + donnees de matching.

Regroupe les lectures necessaires au moteur multi-criteres :
- profil eleve (notes, matieres, interets, budget, projet),
- dernier resultat de test (RIASEC/MBTI),
- carrieres actives (avec key_subjects),
- formations avec cout, groupees par carriere.

SECURITE : le profil est une donnee personnelle. Le service_role contournant
la RLS, chaque acces filtre explicitement par user_id.
"""

from datetime import datetime, timezone
from functools import lru_cache
from typing import Any, Optional
from uuid import UUID

from app.core.logging import get_logger
from app.core.exceptions import QueryError
from app.db.supabase_client import get_admin_supabase_client, SupabaseClient

logger = get_logger("repositories.orientation_profile")

_PROFILE = "student_orientation_profile"
_SESSIONS = "user_test_sessions"
_CAREERS = "careers"
_PROGRAMS = "school_programs"


class OrientationProfileRepository:
    """Profil d'orientation + donnees de matching."""

    def __init__(self) -> None:
        self._db: SupabaseClient = get_admin_supabase_client()

    # =========================================================================
    # PROFIL ELEVE
    # =========================================================================

    async def get_profile(self, user_id: UUID) -> Optional[dict[str, Any]]:
        """Profil d'orientation de l'eleve, ou None s'il n'a rien saisi."""
        try:
            result = (
                self._db.client.table(_PROFILE)
                .select("*")
                .eq("user_id", str(user_id))  # ownership
                .limit(1)
                .execute()
            )
            return result.data[0] if result.data else None
        except Exception as e:
            logger.error("Erreur lecture profil orientation: %s", e, exc_info=True)
            raise QueryError(f"Erreur lors de la lecture du profil: {str(e)}")

    async def upsert_profile(
        self,
        user_id: UUID,
        grades: Optional[dict[str, Any]] = None,
        favorite_subjects: Optional[list[str]] = None,
        interests: Optional[list[str]] = None,
        budget_annual_fcfa: Optional[int] = None,
        career_project: Optional[str] = None,
    ) -> dict[str, Any]:
        """Cree ou met a jour le profil d'orientation (conflit sur user_id)."""
        try:
            now = datetime.now(timezone.utc).isoformat()
            data = {
                "user_id": str(user_id),
                "grades": grades or {},
                "favorite_subjects": favorite_subjects or [],
                "interests": interests or [],
                "budget_annual_fcfa": budget_annual_fcfa,
                "career_project": career_project,
                "updated_at": now,
            }
            result = (
                self._db.client.table(_PROFILE)
                .upsert(data, on_conflict="user_id")
                .execute()
            )
            return result.data[0] if result.data else data
        except Exception as e:
            logger.error("Erreur upsert profil orientation: %s", e, exc_info=True)
            raise QueryError(f"Erreur lors de l'enregistrement du profil: {str(e)}")

    # =========================================================================
    # DONNEES DE MATCHING
    # =========================================================================

    async def get_latest_test_result(self, user_id: UUID) -> Optional[dict[str, Any]]:
        """Resultat du dernier test complete (scores + dominant_traits)."""
        try:
            result = (
                self._db.client.table(_SESSIONS)
                .select("result, completed_at")
                .eq("user_id", str(user_id))  # ownership
                .eq("status", "completed")
                .order("completed_at", desc=True)
                .limit(1)
                .execute()
            )
            if not result.data:
                return None
            return result.data[0].get("result") or None
        except Exception as e:
            logger.error("Erreur lecture dernier test: %s", e, exc_info=True)
            return None  # best-effort : l'absence de test n'est pas bloquante

    async def list_active_careers(self, limit: int = 200) -> list[dict[str, Any]]:
        """Carrieres actives (avec riasec_codes et key_subjects)."""
        try:
            result = (
                self._db.client.table(_CAREERS)
                .select("*")
                .eq("is_active", True)
                .limit(limit)
                .execute()
            )
            return result.data or []
        except Exception as e:
            logger.error("Erreur liste carrieres: %s", e, exc_info=True)
            raise QueryError(f"Erreur lors de la lecture des carrieres: {str(e)}")

    async def list_programs_grouped_by_career(self) -> dict[str, list[dict[str, Any]]]:
        """Formations (avec cout) regroupees par carriere.

        Une seule requete puis regroupement en memoire : evite N requetes
        (une par carriere) lors du calcul des recommandations.
        """
        try:
            result = (
                self._db.client.table(_PROGRAMS)
                .select("id, name, degree_level, career_ids, tuition_annual_fcfa, is_public")
                .execute()
            )
            grouped: dict[str, list[dict[str, Any]]] = {}
            for program in result.data or []:
                for career_id in (program.get("career_ids") or []):
                    grouped.setdefault(str(career_id), []).append(program)
            return grouped
        except Exception as e:
            logger.error("Erreur liste formations: %s", e, exc_info=True)
            return {}  # best-effort : sans cout, le critere budget est ignore


    # =========================================================================
    # ECRITURES ADMIN (donnees de matching)
    # =========================================================================

    async def set_career_key_subjects(
        self,
        career_id: UUID,
        key_subjects: list[str],
    ) -> dict[str, Any]:
        """Definit les matieres cles d'un metier (exploite les notes de l'eleve)."""
        try:
            result = self._db.update(
                table=_CAREERS,
                id_column="id",
                id_value=str(career_id),
                data={"key_subjects": key_subjects},
            )
            return result[0] if result else {"id": str(career_id), "key_subjects": key_subjects}
        except Exception as e:
            logger.error("Erreur maj key_subjects: %s", e, exc_info=True)
            raise QueryError(f"Erreur lors de la mise a jour des matieres cles: {str(e)}")

    async def set_program_cost(
        self,
        program_id: UUID,
        tuition_annual_fcfa: Optional[int] = None,
        is_public: Optional[bool] = None,
    ) -> dict[str, Any]:
        """Definit le cout annuel d'une formation (rend le budget exploitable)."""
        try:
            data: dict[str, Any] = {}
            if tuition_annual_fcfa is not None:
                data["tuition_annual_fcfa"] = tuition_annual_fcfa
            if is_public is not None:
                data["is_public"] = is_public
            if not data:
                return {"id": str(program_id)}
            result = self._db.update(
                table=_PROGRAMS,
                id_column="id",
                id_value=str(program_id),
                data=data,
            )
            return result[0] if result else {"id": str(program_id), **data}
        except Exception as e:
            logger.error("Erreur maj cout formation: %s", e, exc_info=True)
            raise QueryError(f"Erreur lors de la mise a jour du cout: {str(e)}")


@lru_cache(maxsize=1)
def get_orientation_profile_repository() -> OrientationProfileRepository:
    """Retourne l'instance (unique) du repository de profil d'orientation."""
    return OrientationProfileRepository()
