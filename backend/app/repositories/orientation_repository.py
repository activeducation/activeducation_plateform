"""
Repository pour les operations d'orientation.

Gere les interactions avec la base de donnees Supabase pour:
- Tests d'orientation
- Sessions de test
- Resultats
- Carrieres
"""

from datetime import datetime
from typing import Any, Optional
from uuid import UUID

from app.db.supabase_client import get_supabase_client, SupabaseClient
from app.core.logging import get_logger
from app.core.exceptions import (
    TestNotFoundError,
    CareerNotFoundError,
    NotFoundError,
    QueryError,
)
from app.schemas.orientation import TestResult

logger = get_logger("repositories.orientation")


class OrientationRepository:
    """Repository pour les operations liees a l'orientation."""

    def __init__(self):
        self._db: SupabaseClient = get_supabase_client()

    # =========================================================================
    # TESTS D'ORIENTATION
    # =========================================================================

    async def get_all_tests(self, active_only: bool = True) -> list[dict[str, Any]]:
        """
        Recupere tous les tests d'orientation disponibles.
        Utilise des requetes batch pour eviter le N+1.

        Args:
            active_only: Si True, ne retourne que les tests actifs

        Returns:
            Liste des tests avec leurs questions
        """
        try:
            filters = {"is_active": True} if active_only else None
            tests = self._db.fetch_all(
                table="orientation_tests",
                filters=filters,
                order_by="display_order.asc",
            )

            if not tests:
                return tests

            # --- Batch: charger TOUTES les questions en une seule requete ---
            test_ids = [t["id"] for t in tests]
            client = self._db.client
            all_questions_result = (
                client.table("test_questions")
                .select("*")
                .in_("test_id", test_ids)
                .order("display_order", desc=False)
                .execute()
            )
            all_questions = all_questions_result.data

            # --- Batch: charger TOUTES les options en une seule requete ---
            question_ids = [q["id"] for q in all_questions]
            all_options: list[dict] = []
            if question_ids:
                all_options_result = (
                    client.table("question_options")
                    .select("*")
                    .in_("question_id", question_ids)
                    .order("display_order", desc=False)
                    .execute()
                )
                all_options = all_options_result.data

            # --- Assembler: options -> questions -> tests ---
            options_by_question: dict[str, list[dict]] = {}
            for opt in all_options:
                qid = opt["question_id"]
                options_by_question.setdefault(qid, []).append(opt)

            questions_by_test: dict[str, list[dict]] = {}
            for q in all_questions:
                q["options"] = options_by_question.get(q["id"], [])
                tid = q["test_id"]
                questions_by_test.setdefault(tid, []).append(q)

            for test in tests:
                test["questions"] = questions_by_test.get(test["id"], [])

            logger.info(f"Retrieved {len(tests)} orientation tests (batch)")
            return tests

        except Exception as e:
            logger.error(f"Error fetching orientation tests: {e}")
            raise QueryError(f"Erreur lors de la recuperation des tests: {str(e)}")

    async def get_test_by_id(self, test_id: UUID) -> dict[str, Any]:
        """
        Recupere un test specifique par son ID.

        Args:
            test_id: UUID du test

        Returns:
            Le test avec ses questions

        Raises:
            TestNotFoundError: Si le test n'existe pas
        """
        try:
            test = self._db.fetch_one(
                table="orientation_tests",
                id_column="id",
                id_value=str(test_id),
            )

            if not test:
                raise TestNotFoundError(str(test_id))

            # Charger les questions
            test["questions"] = await self._get_test_questions(test["id"])

            return test

        except TestNotFoundError:
            raise
        except Exception as e:
            logger.error(f"Error fetching test {test_id}: {e}")
            raise QueryError(f"Erreur lors de la recuperation du test: {str(e)}")

    async def _get_test_questions(self, test_id: str) -> list[dict[str, Any]]:
        """Recupere les questions d'un test avec leurs options."""
        questions = self._db.fetch_all(
            table="test_questions",
            filters={"test_id": test_id},
            order_by="display_order.asc",
        )

        if not questions:
            return questions

        # Batch: charger toutes les options en une requete
        question_ids = [q["id"] for q in questions]
        client = self._db.client
        all_options_result = (
            client.table("question_options")
            .select("*")
            .in_("question_id", question_ids)
            .order("display_order", desc=False)
            .execute()
        )

        options_by_question: dict[str, list[dict]] = {}
        for opt in all_options_result.data:
            qid = opt["question_id"]
            options_by_question.setdefault(qid, []).append(opt)

        for question in questions:
            question["options"] = options_by_question.get(question["id"], [])

        return questions

    # =========================================================================
    # SESSIONS DE TEST
    # =========================================================================

    async def create_test_session(
        self,
        user_id: UUID,
        test_id: UUID,
    ) -> dict[str, Any]:
        """
        Cree une nouvelle session de test.

        Args:
            user_id: UUID de l'utilisateur
            test_id: UUID du test

        Returns:
            La session creee
        """
        try:
            data = {
                "user_id": str(user_id),
                "test_id": str(test_id),
                "status": "in_progress",
                "started_at": datetime.utcnow().isoformat(),
            }

            result = self._db.insert(table="user_test_sessions", data=data)

            logger.info(
                f"Created test session for user {user_id}",
                extra={"test_id": str(test_id), "session_id": result[0]["id"]},
            )
            return result[0]

        except Exception as e:
            logger.error(f"Error creating test session: {e}")
            raise QueryError(f"Erreur lors de la creation de la session: {str(e)}")

    async def save_test_responses(
        self,
        session_id: UUID,
        responses: dict[str, str],
    ) -> dict[str, Any]:
        """
        Sauvegarde les reponses d'une session de test.

        Args:
            session_id: UUID de la session
            responses: Dictionnaire {question_id: option_id}

        Returns:
            La session mise a jour
        """
        try:
            result = self._db.update(
                table="user_test_sessions",
                id_column="id",
                id_value=str(session_id),
                data={"responses": responses},
            )

            if not result:
                raise NotFoundError("Session de test", str(session_id))

            return result[0]

        except NotFoundError:
            raise
        except Exception as e:
            logger.error(f"Error saving test responses: {e}")
            raise QueryError(f"Erreur lors de la sauvegarde des reponses: {str(e)}")

    async def complete_test_session(
        self,
        session_id: UUID,
        user_id: UUID,
        test_id: UUID,
        responses: dict[str, str],
        result: TestResult,
    ) -> dict[str, Any]:
        """
        Complete une session de test et sauvegarde les resultats.

        Args:
            session_id: UUID de la session
            user_id: UUID de l'utilisateur
            test_id: UUID du test
            responses: Reponses de l'utilisateur
            result: Resultats calcules

        Returns:
            Les resultats sauvegardes
        """
        try:
            # Mettre a jour la session
            self._db.update(
                table="user_test_sessions",
                id_column="id",
                id_value=str(session_id),
                data={
                    "responses": responses,
                    "status": "completed",
                    "completed_at": datetime.utcnow().isoformat(),
                },
            )

            # Sauvegarder les resultats
            result_data = {
                "session_id": str(session_id),
                "user_id": str(user_id),
                "test_id": str(test_id),
                "scores": result.scores,
                "dominant_traits": result.dominant_traits,
                "recommendations": [str(r) for r in (result.recommendations or [])],
            }

            saved_result = self._db.insert(table="test_results", data=result_data)

            logger.info(
                f"Completed test session {session_id}",
                extra={
                    "user_id": str(user_id),
                    "dominant_traits": result.dominant_traits,
                },
            )

            return saved_result[0]

        except Exception as e:
            logger.error(f"Error completing test session: {e}")
            raise QueryError(f"Erreur lors de la completion du test: {str(e)}")

    async def get_user_sessions(
        self,
        user_id: UUID,
        status: Optional[str] = None,
    ) -> list[dict[str, Any]]:
        """
        Recupere les sessions de test d'un utilisateur.

        Args:
            user_id: UUID de l'utilisateur
            status: Filtrer par statut (optionnel)

        Returns:
            Liste des sessions
        """
        try:
            filters = {"user_id": str(user_id)}
            if status:
                filters["status"] = status

            sessions = self._db.fetch_all(
                table="user_test_sessions",
                filters=filters,
                order_by="created_at.desc",
            )

            return sessions

        except Exception as e:
            logger.error(f"Error fetching user sessions: {e}")
            raise QueryError(f"Erreur lors de la recuperation des sessions: {str(e)}")

    async def get_user_results(self, user_id: UUID) -> list[dict[str, Any]]:
        """
        Recupere tous les resultats de test d'un utilisateur.

        Args:
            user_id: UUID de l'utilisateur

        Returns:
            Liste des resultats
        """
        try:
            results = self._db.fetch_all(
                table="test_results",
                filters={"user_id": str(user_id)},
                order_by="calculated_at.desc",
            )

            return results

        except Exception as e:
            logger.error(f"Error fetching user results: {e}")
            raise QueryError(f"Erreur lors de la recuperation des resultats: {str(e)}")

    # =========================================================================
    # CARRIERES
    # =========================================================================

    async def get_all_careers(
        self,
        sector: Optional[str] = None,
        limit: Optional[int] = None,
    ) -> list[dict[str, Any]]:
        """
        Recupere toutes les carrieres.

        Args:
            sector: Filtrer par secteur (optionnel)
            limit: Nombre max de resultats (optionnel)

        Returns:
            Liste des carrieres
        """
        try:
            filters = {"is_active": True}
            if sector:
                filters["sector_name"] = sector

            careers = self._db.fetch_all(
                table="careers",
                filters=filters,
                order_by="name.asc",
                limit=limit,
            )

            return careers

        except Exception as e:
            logger.error(f"Error fetching careers: {e}")
            raise QueryError(f"Erreur lors de la recuperation des carrieres: {str(e)}")

    async def get_career_by_id(self, career_id: UUID) -> dict[str, Any]:
        """
        Recupere une carriere par son ID.

        Args:
            career_id: UUID de la carriere

        Returns:
            La carriere

        Raises:
            CareerNotFoundError: Si la carriere n'existe pas
        """
        try:
            career = self._db.fetch_one(
                table="careers",
                id_column="id",
                id_value=str(career_id),
            )

            if not career:
                raise CareerNotFoundError(str(career_id))

            return career

        except CareerNotFoundError:
            raise
        except Exception as e:
            logger.error(f"Error fetching career {career_id}: {e}")
            raise QueryError(f"Erreur lors de la recuperation de la carriere: {str(e)}")

    async def get_careers_by_traits(
        self,
        traits: list[str],
        limit: int = 10,
    ) -> list[dict[str, Any]]:
        """
        Recupere les carrieres correspondant aux traits RIASEC.

        Cherche en utilisant les traits en francais ET anglais pour compatibilite.
        """
        try:
            # Mapping francais (accentue) -> anglais + non-accentue pour compatibilite
            fr_to_en = {
                "Réaliste": "Realistic", "Investigateur": "Investigative",
                "Artistique": "Artistic", "Social": "Social",
                "Entrepreneur": "Enterprising", "Conventionnel": "Conventional",
            }
            # Variantes sans accents (comme dans le seed SQL)
            fr_accent_to_no_accent = {
                "Réaliste": "Realiste",
            }
            en_to_fr = {v: k for k, v in fr_to_en.items()}

            # Construire une liste etendue avec toutes les variantes
            search_traits = list(traits)
            for t in traits:
                if t in fr_to_en:
                    search_traits.append(fr_to_en[t])
                if t in fr_accent_to_no_accent:
                    search_traits.append(fr_accent_to_no_accent[t])
                if t in en_to_fr:
                    search_traits.append(en_to_fr[t])

            client = self._db.client
            query = (
                client.table("careers")
                .select("*")
                .overlaps("related_traits", search_traits)
                .eq("is_active", True)
                .limit(limit)
            )
            result = query.execute()

            return result.data

        except Exception as e:
            logger.error(f"Error fetching careers by traits: {e}")
            raise QueryError(f"Erreur lors de la recherche de carrieres: {str(e)}")

    async def get_matching_school_programs(
        self,
        sector_names: list[str],
        limit: int = 10,
    ) -> list[dict[str, Any]]:
        """
        Recupere les programmes scolaires des ecoles correspondant aux secteurs recommandes.
        Retourne les programmes avec le nom de l'ecole.
        """
        try:
            client = self._db.client

            # Recuperer les ecoles actives
            schools_result = (
                client.table("schools")
                .select("id, name, city, logo_url, type")
                .eq("is_active", True)
                .execute()
            )

            if not schools_result.data:
                return []

            school_ids = [s["id"] for s in schools_result.data]
            schools_map = {s["id"]: s for s in schools_result.data}

            # Recuperer les programmes de ces ecoles
            programs_result = (
                client.table("school_programs")
                .select("*")
                .in_("school_id", school_ids)
                .eq("is_active", True)
                .limit(limit * 3)  # fetcher plus pour filtrer ensuite
                .execute()
            )

            if not programs_result.data:
                return []

            # Enrichir avec les infos de l'ecole
            enriched = []
            for p in programs_result.data:
                school = schools_map.get(p["school_id"], {})
                enriched.append({
                    "program_id": p["id"],
                    "program_name": p["name"],
                    "program_level": p.get("level", ""),
                    "program_duration": p.get("duration_years"),
                    "school_id": p["school_id"],
                    "school_name": school.get("name", ""),
                    "school_city": school.get("city", ""),
                    "school_logo_url": school.get("logo_url"),
                    "school_type": school.get("type", ""),
                })

            return enriched[:limit]

        except Exception as e:
            logger.error(f"Error fetching matching school programs: {e}")
            return []

    # =========================================================================
    # FAVORIS
    # =========================================================================

    async def add_favorite_career(
        self,
        user_id: UUID,
        career_id: UUID,
    ) -> dict[str, Any]:
        """Ajoute une carriere aux favoris d'un utilisateur."""
        try:
            data = {
                "user_id": str(user_id),
                "career_id": str(career_id),
            }
            result = self._db.insert(table="user_favorite_careers", data=data)
            return result[0]

        except Exception as e:
            # Ignorer les erreurs de doublon (deja en favori)
            if "duplicate" in str(e).lower():
                logger.info(f"Career {career_id} already in favorites for user {user_id}")
                return {"already_exists": True}
            raise QueryError(f"Erreur lors de l'ajout aux favoris: {str(e)}")

    async def remove_favorite_career(
        self,
        user_id: UUID,
        career_id: UUID,
    ) -> bool:
        """Retire une carriere des favoris d'un utilisateur."""
        try:
            # Utiliser le client brut pour la suppression avec 2 conditions
            client = self._db.client
            result = (
                client.table("user_favorite_careers")
                .delete()
                .eq("user_id", str(user_id))
                .eq("career_id", str(career_id))
                .execute()
            )
            return len(result.data) > 0

        except Exception as e:
            logger.error(f"Error removing favorite career: {e}")
            raise QueryError(f"Erreur lors du retrait des favoris: {str(e)}")

    async def get_user_favorites(self, user_id: UUID) -> list[dict[str, Any]]:
        """Recupere les carrieres favorites d'un utilisateur."""
        try:
            # Jointure pour recuperer les details des carrieres
            client = self._db.client
            result = (
                client.table("user_favorite_careers")
                .select("*, careers(*)")
                .eq("user_id", str(user_id))
                .execute()
            )

            # Extraire les carrieres des resultats
            favorites = [item["careers"] for item in result.data if item.get("careers")]
            return favorites

        except Exception as e:
            logger.error(f"Error fetching user favorites: {e}")
            raise QueryError(f"Erreur lors de la recuperation des favoris: {str(e)}")


# Instance singleton
orientation_repo = OrientationRepository()


def get_orientation_repository() -> OrientationRepository:
    """Retourne l'instance du repository d'orientation."""
    return orientation_repo
