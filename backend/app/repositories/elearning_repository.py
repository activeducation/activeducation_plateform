"""
Repository pour le module E-Learning.

Gere les interactions avec Supabase pour:
- Catalogue de cours (avec progression optionnelle)
- Detail cours / modules / lecons
- Contenu de lecon
- Inscriptions utilisateurs
- Progression par lecon
- Attribution de points
"""

import logging
from datetime import datetime, timezone
from typing import Any, Optional

from app.db.supabase_client import SupabaseClient, get_supabase_client

logger = logging.getLogger(__name__)


class ElearningRepository:
    """Repository pour les operations e-learning."""

    def __init__(self, db: SupabaseClient) -> None:
        self._db = db

    # =========================================================================
    # COURS
    # =========================================================================

    async def get_published_courses(self, user_id: Optional[str] = None) -> list[dict[str, Any]]:
        """
        Retourne tous les cours publies, ordonnes par display_order.

        Si user_id est fourni, enrichit chaque cours avec progress_pct et is_enrolled.
        """
        try:
            result = (
                self._db.client.table("elearning_courses")
                .select("*")
                .eq("is_published", True)
                .order("display_order")
                .execute()
            )
            courses = result.data or []

            if not user_id or not courses:
                for course in courses:
                    course["progress_pct"] = None
                    course["is_enrolled"] = False
                return courses

            # Recuperer les inscriptions de l'utilisateur en une seule requete
            course_ids = [c["id"] for c in courses]
            enrollments_result = (
                self._db.client.table("elearning_enrollments")
                .select("course_id, progress_pct")
                .eq("user_id", user_id)
                .in_("course_id", course_ids)
                .execute()
            )
            enrollment_map: dict[str, dict] = {
                e["course_id"]: e for e in (enrollments_result.data or [])
            }

            for course in courses:
                enrollment = enrollment_map.get(course["id"])
                if enrollment:
                    course["is_enrolled"] = True
                    course["progress_pct"] = enrollment["progress_pct"]
                else:
                    course["is_enrolled"] = False
                    course["progress_pct"] = None

            return courses

        except Exception as e:
            logger.error(f"Error fetching published courses: {e}")
            raise

    async def get_course_detail(
        self, course_id: str, user_id: Optional[str] = None
    ) -> Optional[dict[str, Any]]:
        """
        Retourne un cours avec tous ses modules et lecons (batch loading, sans N+1).

        Si user_id est fourni, enrichit avec progress_pct, is_enrolled et le statut
        de chaque lecon.
        """
        try:
            # 1. Recuperer le cours
            course_result = (
                self._db.client.table("elearning_courses")
                .select("*")
                .eq("id", course_id)
                .limit(1)
                .execute()
            )
            if not course_result.data:
                return None
            course = course_result.data[0]

            # 2. Recuperer tous les modules du cours
            modules_result = (
                self._db.client.table("elearning_modules")
                .select("*")
                .eq("course_id", course_id)
                .order("display_order")
                .execute()
            )
            modules = modules_result.data or []

            if not modules:
                course["modules"] = []
                course["progress_pct"] = None
                course["is_enrolled"] = False
                return course

            module_ids = [m["id"] for m in modules]

            # 3. Recuperer toutes les lecons de tous les modules en une seule requete
            lessons_result = (
                self._db.client.table("elearning_lessons")
                .select("*")
                .in_("module_id", module_ids)
                .order("display_order")
                .execute()
            )
            all_lessons = lessons_result.data or []

            # 4. Si utilisateur connecte, recuperer son statut sur toutes les lecons
            lesson_status_map: dict[str, str] = {}
            if user_id and all_lessons:
                lesson_ids = [l["id"] for l in all_lessons]
                progress_result = (
                    self._db.client.table("elearning_user_progress")
                    .select("lesson_id, status")
                    .eq("user_id", user_id)
                    .in_("lesson_id", lesson_ids)
                    .execute()
                )
                lesson_status_map = {
                    p["lesson_id"]: p["status"] for p in (progress_result.data or [])
                }

            # 5. Grouper les lecons par module
            lessons_by_module: dict[str, list[dict]] = {}
            for lesson in all_lessons:
                mid = lesson["module_id"]
                if mid not in lessons_by_module:
                    lessons_by_module[mid] = []
                lesson["status"] = lesson_status_map.get(lesson["id"])
                lessons_by_module[mid].append(lesson)

            for module in modules:
                module["lessons"] = lessons_by_module.get(module["id"], [])

            course["modules"] = modules

            # 6. Enrichir avec les donnees d'inscription si utilisateur connecte
            if user_id:
                enrollment_result = (
                    self._db.client.table("elearning_enrollments")
                    .select("progress_pct")
                    .eq("user_id", user_id)
                    .eq("course_id", course_id)
                    .limit(1)
                    .execute()
                )
                if enrollment_result.data:
                    course["is_enrolled"] = True
                    course["progress_pct"] = enrollment_result.data[0]["progress_pct"]
                else:
                    course["is_enrolled"] = False
                    course["progress_pct"] = None
            else:
                course["is_enrolled"] = False
                course["progress_pct"] = None

            return course

        except Exception as e:
            logger.error(f"Error fetching course detail for {course_id}: {e}")
            raise

    # =========================================================================
    # LECONS
    # =========================================================================

    async def get_lesson_detail(
        self, lesson_id: str, user_id: Optional[str] = None
    ) -> Optional[dict[str, Any]]:
        """
        Retourne une lecon avec son contenu.

        Si user_id est fourni, ajoute le statut de progression.
        """
        try:
            # 1. Recuperer la lecon
            lesson_result = (
                self._db.client.table("elearning_lessons")
                .select("*")
                .eq("id", lesson_id)
                .limit(1)
                .execute()
            )
            if not lesson_result.data:
                return None
            lesson = lesson_result.data[0]

            # 2. Recuperer le contenu de la lecon
            content_result = (
                self._db.client.table("elearning_lesson_content")
                .select("content_data")
                .eq("lesson_id", lesson_id)
                .limit(1)
                .execute()
            )
            if content_result.data:
                lesson["content"] = {
                    "lesson_type": lesson["lesson_type"],
                    "data": content_result.data[0]["content_data"],
                }
            else:
                lesson["content"] = None

            # 3. Ajouter le statut de progression si utilisateur connecte
            lesson["status"] = None
            if user_id:
                progress_result = (
                    self._db.client.table("elearning_user_progress")
                    .select("status")
                    .eq("user_id", user_id)
                    .eq("lesson_id", lesson_id)
                    .limit(1)
                    .execute()
                )
                if progress_result.data:
                    lesson["status"] = progress_result.data[0]["status"]

            return lesson

        except Exception as e:
            logger.error(f"Error fetching lesson detail for {lesson_id}: {e}")
            raise

    # =========================================================================
    # INSCRIPTIONS
    # =========================================================================

    async def enroll_user(self, user_id: str, course_id: str) -> dict[str, Any]:
        """
        Inscrit un utilisateur a un cours.

        Verifie d'abord si l'inscription existe deja et retourne l'existante
        si c'est le cas (upsert semantique).

        Returns:
            Donnees de l'inscription (nouvelle ou existante).

        Raises:
            ValueError: Si l'utilisateur est deja inscrit (pour que l'endpoint
                        puisse retourner un 409).
        """
        try:
            # Verifier si l'inscription existe deja
            existing_result = (
                self._db.client.table("elearning_enrollments")
                .select("*")
                .eq("user_id", user_id)
                .eq("course_id", course_id)
                .limit(1)
                .execute()
            )
            if existing_result.data:
                raise ValueError("already_enrolled")

            # Creer l'inscription
            now = datetime.now(timezone.utc).isoformat()
            enrollment_data = {
                "user_id": user_id,
                "course_id": course_id,
                "enrolled_at": now,
                "progress_pct": 0,
            }
            result = (
                self._db.client.table("elearning_enrollments")
                .insert(enrollment_data)
                .execute()
            )
            logger.info(f"User {user_id} enrolled in course {course_id}")
            return result.data[0] if result.data else enrollment_data

        except ValueError:
            raise
        except Exception as e:
            logger.error(f"Error enrolling user {user_id} in course {course_id}: {e}")
            raise

    async def get_user_enrollments(self, user_id: str) -> list[dict[str, Any]]:
        """
        Retourne toutes les inscriptions d'un utilisateur avec les donnees du cours.

        Effectue un batch loading pour eviter le N+1.
        """
        try:
            # 1. Recuperer toutes les inscriptions
            enrollments_result = (
                self._db.client.table("elearning_enrollments")
                .select("*")
                .eq("user_id", user_id)
                .order("enrolled_at", desc=True)
                .execute()
            )
            enrollments = enrollments_result.data or []

            if not enrollments:
                return []

            # 2. Charger tous les cours en une seule requete
            course_ids = [e["course_id"] for e in enrollments]
            courses_result = (
                self._db.client.table("elearning_courses")
                .select("*")
                .in_("id", course_ids)
                .execute()
            )
            course_map: dict[str, dict] = {
                c["id"]: c for c in (courses_result.data or [])
            }

            # 3. Determiner la derniere lecon consultee pour chaque cours
            # (la lecon la plus recente avec statut in_progress ou completed)
            last_lessons_result = (
                self._db.client.table("elearning_user_progress")
                .select("lesson_id, elearning_lessons(module_id)")
                .eq("user_id", user_id)
                .in_("status", ["in_progress", "completed"])
                .order("started_at", desc=True)
                .execute()
            )
            # Construire un map course_id -> last_lesson_id via les modules
            last_lesson_by_course: dict[str, str] = {}
            if last_lessons_result.data:
                # Recuperer les module_ids pour mapper vers les cours
                lesson_ids_with_modules = last_lessons_result.data
                module_ids_needed = [
                    p["elearning_lessons"]["module_id"]
                    for p in lesson_ids_with_modules
                    if p.get("elearning_lessons")
                ]
                if module_ids_needed:
                    modules_result = (
                        self._db.client.table("elearning_modules")
                        .select("id, course_id")
                        .in_("id", module_ids_needed)
                        .execute()
                    )
                    module_to_course = {
                        m["id"]: m["course_id"] for m in (modules_result.data or [])
                    }
                    for progress_row in lesson_ids_with_modules:
                        lesson_info = progress_row.get("elearning_lessons")
                        if not lesson_info:
                            continue
                        module_id = lesson_info["module_id"]
                        course_id = module_to_course.get(module_id)
                        if course_id and course_id not in last_lesson_by_course:
                            last_lesson_by_course[course_id] = progress_row["lesson_id"]

            # 4. Assembler la reponse
            result = []
            for enrollment in enrollments:
                cid = enrollment["course_id"]
                course = course_map.get(cid)
                if not course:
                    continue

                # Enrichir le cours avec les donnees d'inscription
                course_with_enrollment = {
                    **course,
                    "progress_pct": enrollment["progress_pct"],
                    "is_enrolled": True,
                }

                result.append({
                    "course": course_with_enrollment,
                    "progress_pct": enrollment["progress_pct"],
                    "last_lesson_id": last_lesson_by_course.get(cid),
                    "enrolled_at": enrollment["enrolled_at"],
                })

            return result

        except Exception as e:
            logger.error(f"Error fetching enrollments for user {user_id}: {e}")
            raise

    # =========================================================================
    # PROGRESSION
    # =========================================================================

    async def mark_lesson_complete(
        self,
        user_id: str,
        lesson_id: str,
        score: Optional[int] = None,
        answers: Optional[dict] = None,
    ) -> dict[str, Any]:
        """
        Marque une lecon comme completee pour un utilisateur.

        Etapes:
        1. Upsert elearning_user_progress (status=completed)
        2. Recuperer la lecon (module_id, points_reward)
        3. Recalculer progress_pct du cours
        4. Mettre a jour elearning_enrollments.progress_pct
        5. Attribuer les points (upsert user_points)

        Returns:
            {lesson_id, status, points_earned, course_progress_pct}
        """
        try:
            now = datetime.now(timezone.utc).isoformat()

            # 1. Upsert de la progression
            progress_data: dict[str, Any] = {
                "user_id": user_id,
                "lesson_id": lesson_id,
                "status": "completed",
                "completed_at": now,
            }
            if score is not None:
                progress_data["score"] = score
            if answers is not None:
                progress_data["quiz_answers"] = answers

            # Verifier si une entree existe deja
            existing_progress = (
                self._db.client.table("elearning_user_progress")
                .select("id, started_at")
                .eq("user_id", user_id)
                .eq("lesson_id", lesson_id)
                .limit(1)
                .execute()
            )
            if existing_progress.data:
                # Mettre a jour l'entree existante
                (
                    self._db.client.table("elearning_user_progress")
                    .update(progress_data)
                    .eq("user_id", user_id)
                    .eq("lesson_id", lesson_id)
                    .execute()
                )
            else:
                # Inserer une nouvelle entree
                progress_data["started_at"] = now
                (
                    self._db.client.table("elearning_user_progress")
                    .insert(progress_data)
                    .execute()
                )

            # 2. Recuperer les details de la lecon
            lesson_result = (
                self._db.client.table("elearning_lessons")
                .select("module_id, points_reward")
                .eq("id", lesson_id)
                .limit(1)
                .execute()
            )
            if not lesson_result.data:
                logger.warning(f"Lesson {lesson_id} not found after marking complete")
                return {
                    "lesson_id": lesson_id,
                    "status": "completed",
                    "points_earned": 0,
                    "course_progress_pct": None,
                }
            lesson = lesson_result.data[0]
            points_reward = lesson["points_reward"] or 0
            module_id = lesson["module_id"]

            # 3. Recuperer le course_id via le module
            module_result = (
                self._db.client.table("elearning_modules")
                .select("course_id")
                .eq("id", module_id)
                .limit(1)
                .execute()
            )
            course_id: Optional[str] = None
            course_progress_pct: Optional[int] = None

            if module_result.data:
                course_id = module_result.data[0]["course_id"]

                # 4. Calculer la progression du cours
                # Total des lecons dans le cours
                all_modules_result = (
                    self._db.client.table("elearning_modules")
                    .select("id")
                    .eq("course_id", course_id)
                    .execute()
                )
                all_module_ids = [m["id"] for m in (all_modules_result.data or [])]

                total_lessons = 0
                completed_lessons = 0

                if all_module_ids:
                    total_lessons_result = (
                        self._db.client.table("elearning_lessons")
                        .select("id")
                        .in_("module_id", all_module_ids)
                        .execute()
                    )
                    all_lesson_ids = [l["id"] for l in (total_lessons_result.data or [])]
                    total_lessons = len(all_lesson_ids)

                    if all_lesson_ids:
                        completed_result = (
                            self._db.client.table("elearning_user_progress")
                            .select("id")
                            .eq("user_id", user_id)
                            .eq("status", "completed")
                            .in_("lesson_id", all_lesson_ids)
                            .execute()
                        )
                        completed_lessons = len(completed_result.data or [])

                if total_lessons > 0:
                    course_progress_pct = int((completed_lessons / total_lessons) * 100)
                else:
                    course_progress_pct = 0

                # 5. Mettre a jour l'inscription avec le nouveau pourcentage
                update_data: dict[str, Any] = {"progress_pct": course_progress_pct}
                if course_progress_pct == 100:
                    update_data["completed_at"] = now

                (
                    self._db.client.table("elearning_enrollments")
                    .update(update_data)
                    .eq("user_id", user_id)
                    .eq("course_id", course_id)
                    .execute()
                )

            # 6. Attribuer les points a l'utilisateur
            if points_reward > 0:
                try:
                    existing_points = (
                        self._db.client.table("user_points")
                        .select("id, points_balance, total_earned")
                        .eq("user_id", user_id)
                        .limit(1)
                        .execute()
                    )
                    if existing_points.data:
                        current = existing_points.data[0]
                        (
                            self._db.client.table("user_points")
                            .update({
                                "points_balance": current["points_balance"] + points_reward,
                                "total_earned": current["total_earned"] + points_reward,
                            })
                            .eq("user_id", user_id)
                            .execute()
                        )
                    else:
                        (
                            self._db.client.table("user_points")
                            .insert({
                                "user_id": user_id,
                                "points_balance": points_reward,
                                "total_earned": points_reward,
                            })
                            .execute()
                        )
                except Exception as points_error:
                    # L'attribution de points ne doit pas bloquer la completion
                    logger.warning(
                        f"Could not award points to user {user_id}: {points_error}"
                    )

            logger.info(
                f"User {user_id} completed lesson {lesson_id} "
                f"(+{points_reward} pts, course progress: {course_progress_pct}%)"
            )

            return {
                "lesson_id": lesson_id,
                "status": "completed",
                "points_earned": points_reward,
                "course_progress_pct": course_progress_pct,
            }

        except Exception as e:
            logger.error(
                f"Error marking lesson {lesson_id} complete for user {user_id}: {e}"
            )
            raise


# Singleton
elearning_repository = ElearningRepository(db=get_supabase_client())
