"""Repository des examens de cours (CRUD admin + scoring + badge)."""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any, Optional
from uuid import UUID

from app.db.supabase_client import get_admin_supabase_client, SupabaseClient
from app.core.logging import get_logger

logger = get_logger("repositories.exam")


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


class ExamRepository:
    def __init__(self) -> None:
        self._db: SupabaseClient = get_admin_supabase_client()

    # ── Lecture ───────────────────────────────────────────────────────────────

    def get_exam_by_course(self, course_id: UUID) -> Optional[dict[str, Any]]:
        res = (
            self._db.client.table("course_exams")
            .select("*")
            .eq("course_id", str(course_id))
            .limit(1)
            .execute()
        )
        if not res.data:
            return None
        exam = res.data[0]
        exam["questions"] = self._get_questions(exam["id"])
        return exam

    def _get_questions(self, exam_id: str) -> list[dict[str, Any]]:
        res = (
            self._db.client.table("exam_questions")
            .select("*")
            .eq("exam_id", exam_id)
            .order("display_order")
            .execute()
        )
        return res.data or []

    # ── Upsert (admin) ────────────────────────────────────────────────────────

    def upsert_exam(self, course_id: UUID, data: dict[str, Any], questions: list[dict]) -> dict[str, Any]:
        """Cree ou met a jour l'examen d'un cours + remplace ses questions."""
        existing = self.get_exam_by_course(course_id)
        exam_fields = {
            "course_id": str(course_id),
            "title": data.get("title", "Examen final"),
            "description": data.get("description"),
            "passing_score": data.get("passing_score", 80),
            "xp_reward": data.get("xp_reward", 100),
            "badge_title": data.get("badge_title"),
            "badge_icon": data.get("badge_icon"),
            "is_active": data.get("is_active", True),
            "updated_at": _now(),
        }

        if existing:
            exam_id = existing["id"]
            self._db.client.table("course_exams").update(exam_fields).eq("id", exam_id).execute()
            # Remplacer les questions
            self._db.client.table("exam_questions").delete().eq("exam_id", exam_id).execute()
        else:
            exam_fields["created_at"] = _now()
            res = self._db.client.table("course_exams").insert(exam_fields).execute()
            exam_id = res.data[0]["id"]

        # (Re)inserer les questions
        if questions:
            rows = []
            for i, q in enumerate(questions):
                rows.append({
                    "exam_id": exam_id,
                    "question": q["question"],
                    "options": q["options"],   # liste de {text, is_correct}
                    "points": q.get("points", 1),
                    "display_order": i,
                })
            self._db.client.table("exam_questions").insert(rows).execute()

        return self.get_exam_by_course(course_id)

    def delete_exam(self, course_id: UUID) -> bool:
        self._db.client.table("course_exams").delete().eq("course_id", str(course_id)).execute()
        return True

    # ── Tentatives ────────────────────────────────────────────────────────────

    def record_attempt(
        self, user_id: UUID, exam_id: str, course_id: Optional[str],
        score: int, passed: bool, answers: dict,
    ) -> dict[str, Any]:
        row = {
            "user_id": str(user_id),
            "exam_id": exam_id,
            "course_id": course_id,
            "score": score,
            "passed": passed,
            "answers": answers,
            "created_at": _now(),
        }
        res = self._db.client.table("user_exam_attempts").insert(row).execute()
        return res.data[0] if res.data else row

    def has_passed_before(self, user_id: UUID, exam_id: str) -> bool:
        res = (
            self._db.client.table("user_exam_attempts")
            .select("id", count="exact")
            .eq("user_id", str(user_id))
            .eq("exam_id", exam_id)
            .eq("passed", True)
            .limit(1)
            .execute()
        )
        return (res.count or 0) > 0

    def grant_badge(self, user_id: UUID, course_id: str, badge_title: str, badge_icon: Optional[str]) -> None:
        """Insere un user_achievement de type course_badge (idempotent best-effort)."""
        achievement_type = f"course_badge:{course_id}"
        try:
            # Eviter le doublon
            existing = (
                self._db.client.table("user_achievements")
                .select("id")
                .eq("user_id", str(user_id))
                .eq("achievement_type", achievement_type)
                .limit(1)
                .execute()
            )
            if existing.data:
                return
            self._db.client.table("user_achievements").insert({
                "user_id": str(user_id),
                "achievement_type": achievement_type,
                "achievement_data": {
                    "title": badge_title,
                    "icon": badge_icon,
                    "course_id": course_id,
                },
            }).execute()
        except Exception as e:
            logger.warning(f"grant_badge failed for user {user_id}: {e}")


_repo: Optional[ExamRepository] = None


def get_exam_repository() -> ExamRepository:
    global _repo
    if _repo is None:
        _repo = ExamRepository()
    return _repo
