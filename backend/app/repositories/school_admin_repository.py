"""
Repository pour le School Admin Dashboard.

Gere les interactions avec Supabase pour:
- Liaison school_admin <-> school
- CRUD cours / modules / lecons scopes a une ecole
- Statistiques du dashboard
- Profil ecole
"""

import logging
from datetime import datetime, timezone
from typing import Any, Optional

from app.db.supabase_client import SupabaseClient, get_admin_supabase_client

logger = logging.getLogger(__name__)


class SchoolAdminRepository:
    """Repository pour les operations school-admin."""

    def __init__(self, db: SupabaseClient) -> None:
        self._db = db

    # =========================================================================
    # SCHOOL ADMIN PROFILE
    # =========================================================================

    def get_school_for_admin(self, user_id: str) -> Optional[dict[str, Any]]:
        """Retourne la ligne school_admin_profiles pour cet user_id."""
        result = (
            self._db.client.table("school_admin_profiles")
            .select("*")
            .eq("user_id", user_id)
            .eq("is_active", True)
            .limit(1)
            .execute()
        )
        return result.data[0] if result.data else None

    # =========================================================================
    # COURSES
    # =========================================================================

    def get_courses(self, school_id: str) -> list[dict[str, Any]]:
        """Tous les cours d'une ecole."""
        result = (
            self._db.client.table("elearning_courses")
            .select("*")
            .eq("school_id", school_id)
            .order("display_order")
            .execute()
        )
        return result.data or []

    def get_course(self, course_id: str, school_id: str) -> Optional[dict[str, Any]]:
        """Un cours avec verification d'appartenance a l'ecole."""
        result = (
            self._db.client.table("elearning_courses")
            .select("*")
            .eq("id", course_id)
            .eq("school_id", school_id)
            .limit(1)
            .execute()
        )
        if not result.data:
            return None

        course = result.data[0]

        # Charger les modules + lecons
        modules_result = (
            self._db.client.table("elearning_modules")
            .select("*")
            .eq("course_id", course_id)
            .order("display_order")
            .execute()
        )
        modules = modules_result.data or []

        if modules:
            module_ids = [m["id"] for m in modules]
            lessons_result = (
                self._db.client.table("elearning_lessons")
                .select("*")
                .in_("module_id", module_ids)
                .order("display_order")
                .execute()
            )
            lessons_by_module: dict[str, list] = {}
            for lesson in (lessons_result.data or []):
                mid = lesson["module_id"]
                lessons_by_module.setdefault(mid, []).append(lesson)
            for mod in modules:
                mod["lessons"] = lessons_by_module.get(mod["id"], [])

        course["modules"] = modules
        return course

    def create_course(self, school_id: str, data: dict[str, Any]) -> dict[str, Any]:
        """Cree un cours pour cette ecole."""
        now = datetime.now(timezone.utc).isoformat()
        payload = {
            **data,
            "school_id": school_id,
            "is_published": False,
            "created_at": now,
            "updated_at": now,
        }
        result = self._db.client.table("elearning_courses").insert(payload).execute()
        return result.data[0] if result.data else payload

    def update_course(
        self, course_id: str, school_id: str, data: dict[str, Any]
    ) -> Optional[dict[str, Any]]:
        """Met a jour un cours (verifie l'appartenance)."""
        data["updated_at"] = datetime.now(timezone.utc).isoformat()
        result = (
            self._db.client.table("elearning_courses")
            .update(data)
            .eq("id", course_id)
            .eq("school_id", school_id)
            .execute()
        )
        return result.data[0] if result.data else None

    def delete_course(self, course_id: str, school_id: str) -> bool:
        """Supprime un cours (verifie l'appartenance)."""
        result = (
            self._db.client.table("elearning_courses")
            .delete()
            .eq("id", course_id)
            .eq("school_id", school_id)
            .execute()
        )
        return bool(result.data)

    def publish_course(
        self, course_id: str, school_id: str, is_published: bool
    ) -> Optional[dict[str, Any]]:
        """Toggle la publication d'un cours."""
        result = (
            self._db.client.table("elearning_courses")
            .update({
                "is_published": is_published,
                "updated_at": datetime.now(timezone.utc).isoformat(),
            })
            .eq("id", course_id)
            .eq("school_id", school_id)
            .execute()
        )
        return result.data[0] if result.data else None

    # =========================================================================
    # MODULES
    # =========================================================================

    def _verify_course_ownership(self, course_id: str, school_id: str) -> bool:
        """Verifie que le cours appartient a l'ecole."""
        result = (
            self._db.client.table("elearning_courses")
            .select("id")
            .eq("id", course_id)
            .eq("school_id", school_id)
            .limit(1)
            .execute()
        )
        return bool(result.data)

    def get_modules(self, course_id: str, school_id: str) -> list[dict[str, Any]]:
        """Modules d'un cours de l'ecole."""
        if not self._verify_course_ownership(course_id, school_id):
            return []
        result = (
            self._db.client.table("elearning_modules")
            .select("*")
            .eq("course_id", course_id)
            .order("display_order")
            .execute()
        )
        return result.data or []

    def create_module(
        self, course_id: str, school_id: str, data: dict[str, Any]
    ) -> Optional[dict[str, Any]]:
        """Cree un module pour un cours de l'ecole."""
        if not self._verify_course_ownership(course_id, school_id):
            return None
        now = datetime.now(timezone.utc).isoformat()
        payload = {
            **data,
            "course_id": course_id,
            "created_at": now,
            "updated_at": now,
        }
        result = self._db.client.table("elearning_modules").insert(payload).execute()
        return result.data[0] if result.data else payload

    def update_module(
        self, module_id: str, school_id: str, data: dict[str, Any]
    ) -> Optional[dict[str, Any]]:
        """Met a jour un module (verifie l'appartenance via le cours)."""
        module = self._db.client.table("elearning_modules").select("course_id").eq("id", module_id).limit(1).execute()
        if not module.data:
            return None
        if not self._verify_course_ownership(module.data[0]["course_id"], school_id):
            return None
        data["updated_at"] = datetime.now(timezone.utc).isoformat()
        result = (
            self._db.client.table("elearning_modules")
            .update(data)
            .eq("id", module_id)
            .execute()
        )
        return result.data[0] if result.data else None

    def delete_module(self, module_id: str, school_id: str) -> bool:
        """Supprime un module (verifie l'appartenance)."""
        module = self._db.client.table("elearning_modules").select("course_id").eq("id", module_id).limit(1).execute()
        if not module.data:
            return False
        if not self._verify_course_ownership(module.data[0]["course_id"], school_id):
            return False
        result = self._db.client.table("elearning_modules").delete().eq("id", module_id).execute()
        return bool(result.data)

    def reorder_modules(self, school_id: str, ordered_ids: list[str]) -> bool:
        """Reordonne les modules par la liste d'IDs."""
        for idx, module_id in enumerate(ordered_ids):
            self._db.client.table("elearning_modules").update({"display_order": idx}).eq("id", module_id).execute()
        return True

    # =========================================================================
    # LESSONS
    # =========================================================================

    def _verify_module_ownership(self, module_id: str, school_id: str) -> bool:
        """Verifie que le module appartient a un cours de l'ecole."""
        module = self._db.client.table("elearning_modules").select("course_id").eq("id", module_id).limit(1).execute()
        if not module.data:
            return False
        return self._verify_course_ownership(module.data[0]["course_id"], school_id)

    def get_lessons(self, module_id: str, school_id: str) -> list[dict[str, Any]]:
        """Lecons d'un module de l'ecole."""
        if not self._verify_module_ownership(module_id, school_id):
            return []
        result = (
            self._db.client.table("elearning_lessons")
            .select("*")
            .eq("module_id", module_id)
            .order("display_order")
            .execute()
        )
        return result.data or []

    def create_lesson(
        self, module_id: str, school_id: str, data: dict[str, Any]
    ) -> Optional[dict[str, Any]]:
        """Cree une lecon pour un module de l'ecole."""
        if not self._verify_module_ownership(module_id, school_id):
            return None

        content_data = data.pop("content_data", None)
        now = datetime.now(timezone.utc).isoformat()
        payload = {
            **data,
            "module_id": module_id,
            "created_at": now,
            "updated_at": now,
        }
        result = self._db.client.table("elearning_lessons").insert(payload).execute()
        lesson = result.data[0] if result.data else payload

        # Inserer le contenu si fourni
        if content_data and lesson.get("id"):
            self._db.client.table("elearning_lesson_content").insert({
                "lesson_id": lesson["id"],
                "content_data": content_data,
            }).execute()

        return lesson

    def update_lesson(
        self, lesson_id: str, school_id: str, data: dict[str, Any]
    ) -> Optional[dict[str, Any]]:
        """Met a jour une lecon (verifie l'appartenance)."""
        lesson = self._db.client.table("elearning_lessons").select("module_id").eq("id", lesson_id).limit(1).execute()
        if not lesson.data:
            return None
        if not self._verify_module_ownership(lesson.data[0]["module_id"], school_id):
            return None

        content_data = data.pop("content_data", None)
        data["updated_at"] = datetime.now(timezone.utc).isoformat()
        result = (
            self._db.client.table("elearning_lessons")
            .update(data)
            .eq("id", lesson_id)
            .execute()
        )

        # Mettre a jour le contenu si fourni
        if content_data is not None:
            existing = self._db.client.table("elearning_lesson_content").select("id").eq("lesson_id", lesson_id).limit(1).execute()
            if existing.data:
                self._db.client.table("elearning_lesson_content").update({"content_data": content_data}).eq("lesson_id", lesson_id).execute()
            else:
                self._db.client.table("elearning_lesson_content").insert({"lesson_id": lesson_id, "content_data": content_data}).execute()

        return result.data[0] if result.data else None

    def delete_lesson(self, lesson_id: str, school_id: str) -> bool:
        """Supprime une lecon (verifie l'appartenance)."""
        lesson = self._db.client.table("elearning_lessons").select("module_id").eq("id", lesson_id).limit(1).execute()
        if not lesson.data:
            return False
        if not self._verify_module_ownership(lesson.data[0]["module_id"], school_id):
            return False
        result = self._db.client.table("elearning_lessons").delete().eq("id", lesson_id).execute()
        return bool(result.data)

    # =========================================================================
    # DASHBOARD STATS
    # =========================================================================

    def get_dashboard_stats(self, school_id: str) -> dict[str, Any]:
        """Statistiques agregees pour le dashboard."""
        # Total des cours
        courses = (
            self._db.client.table("elearning_courses")
            .select("id, is_published")
            .eq("school_id", school_id)
            .execute()
        )
        course_list = courses.data or []
        total_courses = len(course_list)
        published_courses = sum(1 for c in course_list if c.get("is_published"))

        # Enrollments
        total_enrollments = 0
        avg_progress = 0.0
        if course_list:
            course_ids = [c["id"] for c in course_list]
            enrollments = (
                self._db.client.table("elearning_enrollments")
                .select("progress_pct")
                .in_("course_id", course_ids)
                .execute()
            )
            enrollment_list = enrollments.data or []
            total_enrollments = len(enrollment_list)
            if total_enrollments > 0:
                avg_progress = sum(e.get("progress_pct", 0) for e in enrollment_list) / total_enrollments

        return {
            "total_courses": total_courses,
            "published_courses": published_courses,
            "total_enrollments": total_enrollments,
            "avg_progress": round(avg_progress, 1),
        }

    # =========================================================================
    # SCHOOL PROFILE
    # =========================================================================

    def get_school_profile(self, school_id: str) -> Optional[dict[str, Any]]:
        """Retourne le profil de l'ecole."""
        result = (
            self._db.client.table("schools")
            .select("*")
            .eq("id", school_id)
            .limit(1)
            .execute()
        )
        return result.data[0] if result.data else None

    def update_school_profile(
        self, school_id: str, data: dict[str, Any]
    ) -> Optional[dict[str, Any]]:
        """Met a jour le profil de l'ecole."""
        data["updated_at"] = datetime.now(timezone.utc).isoformat()
        result = (
            self._db.client.table("schools")
            .update(data)
            .eq("id", school_id)
            .execute()
        )
        return result.data[0] if result.data else None


# Singleton
school_admin_repository = SchoolAdminRepository(db=get_admin_supabase_client())


def get_school_admin_repository() -> SchoolAdminRepository:
    return school_admin_repository
