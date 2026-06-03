"""Repository mentors : candidatures, creation, taches.

Utilise le client service_role (ecritures privilegiees + tables RLS verrouillees
mentor_applications / mentor_tasks).
"""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any, Optional
from uuid import UUID

from app.db.supabase_client import get_admin_supabase_client, SupabaseClient
from app.core.logging import get_logger

logger = get_logger("repositories.mentor")


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


class MentorRepository:
    def __init__(self) -> None:
        self._db: SupabaseClient = get_admin_supabase_client()

    # ── Candidatures ────────────────────────────────────────────────────────

    def create_application(self, data: dict[str, Any]) -> dict[str, Any]:
        payload = {**data, "status": "pending", "created_at": _now(), "updated_at": _now()}
        res = self._db.client.table("mentor_applications").insert(payload).execute()
        return res.data[0] if res.data else payload

    def list_applications(
        self, status: Optional[str] = None, page: int = 1, per_page: int = 20
    ) -> dict[str, Any]:
        offset = (page - 1) * per_page
        query = self._db.client.table("mentor_applications").select("*", count="exact")
        if status:
            query = query.eq("status", status)
        res = (
            query.order("created_at", desc=True)
            .range(offset, offset + per_page - 1)
            .execute()
        )
        return {
            "items": res.data or [],
            "total": res.count or len(res.data or []),
            "page": page,
            "per_page": per_page,
        }

    def get_application(self, app_id: UUID) -> Optional[dict[str, Any]]:
        res = (
            self._db.client.table("mentor_applications")
            .select("*")
            .eq("id", str(app_id))
            .limit(1)
            .execute()
        )
        return res.data[0] if res.data else None

    def update_application(self, app_id: UUID, changes: dict[str, Any]) -> Optional[dict[str, Any]]:
        changes = {**changes, "updated_at": _now()}
        res = (
            self._db.client.table("mentor_applications")
            .update(changes)
            .eq("id", str(app_id))
            .execute()
        )
        return res.data[0] if res.data else None

    # ── Mentors ──────────────────────────────────────────────────────────────

    def create_mentor(self, data: dict[str, Any]) -> dict[str, Any]:
        payload = {**data, "created_at": _now()}
        res = self._db.client.table("mentors").insert(payload).execute()
        return res.data[0] if res.data else payload

    # ── Taches ────────────────────────────────────────────────────────────────

    def create_task(self, mentor_id: UUID, data: dict[str, Any]) -> dict[str, Any]:
        payload = {
            **data,
            "mentor_id": str(mentor_id),
            "status": "todo",
            "created_at": _now(),
            "updated_at": _now(),
        }
        res = self._db.client.table("mentor_tasks").insert(payload).execute()
        return res.data[0] if res.data else payload

    def list_tasks(self, mentor_id: UUID) -> list[dict[str, Any]]:
        res = (
            self._db.client.table("mentor_tasks")
            .select("*")
            .eq("mentor_id", str(mentor_id))
            .order("created_at", desc=True)
            .execute()
        )
        return res.data or []

    def update_task(self, task_id: UUID, changes: dict[str, Any]) -> Optional[dict[str, Any]]:
        changes = {**changes, "updated_at": _now()}
        if changes.get("status") == "done" and "completed_at" not in changes:
            changes["completed_at"] = _now()
        res = (
            self._db.client.table("mentor_tasks")
            .update(changes)
            .eq("id", str(task_id))
            .execute()
        )
        return res.data[0] if res.data else None

    def delete_task(self, task_id: UUID) -> bool:
        self._db.client.table("mentor_tasks").delete().eq("id", str(task_id)).execute()
        return True


_repo: Optional[MentorRepository] = None


def get_mentor_repository() -> MentorRepository:
    global _repo
    if _repo is None:
        _repo = MentorRepository()
    return _repo
