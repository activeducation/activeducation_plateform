"""Repository pour la gestion admin des utilisateurs."""

from typing import Any, Optional
from uuid import UUID

from app.db.supabase_client import get_supabase_client, SupabaseClient
from app.core.logging import get_logger
from app.core.exceptions import NotFoundError
from app.schemas.admin.users import (
    AdminUserListResponse,
    AdminUserSummary,
    AdminUserDetail,
    AdminUserUpdate,
    UserActivitySummary,
)

logger = get_logger("repositories.admin.users")


class UsersAdminRepository:
    def __init__(self):
        self._db: SupabaseClient = get_supabase_client()

    async def list_users(
        self,
        page: int = 1,
        per_page: int = 20,
        search: Optional[str] = None,
        role: Optional[str] = None,
        is_active: Optional[bool] = None,
    ) -> AdminUserListResponse:
        """Liste paginee des utilisateurs."""
        offset = (page - 1) * per_page

        query = self._db.client.table("user_profiles").select(
            "id, email, first_name, last_name, display_name, avatar_url, "
            "role, is_active, class_level, school_name, created_at, last_login_at",
            count="exact",
        )

        if role:
            query = query.eq("role", role)
        if is_active is not None:
            query = query.eq("is_active", is_active)
        if search:
            query = query.or_(
                f"email.ilike.%{search}%,first_name.ilike.%{search}%,last_name.ilike.%{search}%"
            )

        result = query.order("created_at", desc=True).range(offset, offset + per_page - 1).execute()

        items = [AdminUserSummary(**u) for u in (result.data or [])]

        return AdminUserListResponse(
            items=items,
            total=result.count or len(items),
            page=page,
            per_page=per_page,
        )

    async def get_user_detail(self, user_id: UUID) -> AdminUserDetail:
        """Detail d'un utilisateur avec resume d'activite."""
        user = self._db.fetch_one(
            table="user_profiles", id_column="id", id_value=str(user_id)
        )
        if not user:
            raise NotFoundError("Utilisateur", str(user_id))

        # Activity summary
        activity = await self._get_activity_summary(user_id)

        return AdminUserDetail(
            **{k: v for k, v in user.items() if k != "password_hash"},
            activity=activity,
        )

    async def _get_activity_summary(self, user_id: UUID) -> UserActivitySummary:
        """Resume de l'activite d'un utilisateur."""
        try:
            uid = str(user_id)

            tests_completed = self._db.client.table("user_test_sessions").select(
                "id", count="exact"
            ).eq("user_id", uid).eq("status", "completed").execute()

            tests_in_progress = self._db.client.table("user_test_sessions").select(
                "id", count="exact"
            ).eq("user_id", uid).eq("status", "in_progress").execute()

            favorites = self._db.client.table("user_favorite_careers").select(
                "id", count="exact"
            ).eq("user_id", uid).execute()

            achievements = self._db.client.table("user_achievements").select(
                "id", count="exact"
            ).eq("user_id", uid).execute()

            gamification = self._db.fetch_one(
                table="user_gamification", id_column="user_id", id_value=uid
            )

            return UserActivitySummary(
                tests_completed=tests_completed.count or 0,
                tests_in_progress=tests_in_progress.count or 0,
                favorite_careers=favorites.count or 0,
                achievements_unlocked=achievements.count or 0,
                total_points=gamification.get("total_points", 0) if gamification else 0,
                current_level=gamification.get("current_level", 1) if gamification else 1,
            )
        except Exception as e:
            logger.warning(f"Error fetching activity for {user_id}: {e}")
            return UserActivitySummary()

    async def update_user(self, user_id: UUID, data: AdminUserUpdate) -> AdminUserDetail:
        """Met a jour un utilisateur."""
        update_data = data.model_dump(exclude_unset=True)
        if not update_data:
            return await self.get_user_detail(user_id)

        result = self._db.update(
            table="user_profiles", id_column="id",
            id_value=str(user_id), data=update_data,
        )
        if not result:
            raise NotFoundError("Utilisateur", str(user_id))

        return await self.get_user_detail(user_id)

    async def update_role(self, user_id: UUID, role: str) -> dict:
        """Change le role d'un utilisateur."""
        result = self._db.update(
            table="user_profiles", id_column="id",
            id_value=str(user_id), data={"role": role},
        )
        if not result:
            raise NotFoundError("Utilisateur", str(user_id))
        return {"success": True, "user_id": str(user_id), "role": role}

    async def toggle_active(self, user_id: UUID, is_active: bool) -> dict:
        """Active/desactive un utilisateur."""
        result = self._db.update(
            table="user_profiles", id_column="id",
            id_value=str(user_id), data={"is_active": is_active},
        )
        if not result:
            raise NotFoundError("Utilisateur", str(user_id))
        return {"success": True, "user_id": str(user_id), "is_active": is_active}


_users_admin_repo = UsersAdminRepository()


def get_users_admin_repository() -> UsersAdminRepository:
    return _users_admin_repo
