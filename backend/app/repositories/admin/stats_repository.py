"""Repository pour les statistiques du dashboard admin."""

from typing import Any
from app.db.supabase_client import get_supabase_client, SupabaseClient
from app.core.logging import get_logger
from app.schemas.admin.dashboard import (
    DashboardStats,
    WeeklyUsersPoint,
    TestsByType,
    RecentActivity,
)

logger = get_logger("repositories.admin.stats")


class StatsRepository:
    def __init__(self):
        self._db: SupabaseClient = get_supabase_client()

    async def get_dashboard_stats(self) -> DashboardStats:
        """Recupere les statistiques agregees."""
        try:
            # Compteurs
            users = self._db.client.table("user_profiles").select("id", count="exact").execute()
            total_users = users.count or 0

            tests = self._db.client.table("user_test_sessions").select(
                "id", count="exact"
            ).eq("status", "completed").execute()
            total_tests = tests.count or 0

            schools = self._db.client.table("schools").select("id", count="exact").execute()
            total_schools = schools.count or 0

            mentors = self._db.client.table("mentors").select("id", count="exact").execute()
            total_mentors = mentors.count or 0

            # Tests par type
            tests_by_type = []
            for t in ["riasec", "personality", "skills", "interests", "aptitude"]:
                count_result = self._db.client.table("user_test_sessions").select(
                    "id", count="exact"
                ).eq("status", "completed").execute()
                # Simplified - in production would join with orientation_tests
                tests_by_type.append(TestsByType(type=t, count=0))

            # Try to get actual test type counts
            try:
                all_sessions = self._db.client.table("user_test_sessions").select(
                    "test_id, orientation_tests(type)"
                ).eq("status", "completed").limit(1000).execute()

                type_counts: dict[str, int] = {}
                for s in (all_sessions.data or []):
                    test_data = s.get("orientation_tests")
                    if test_data:
                        t = test_data.get("type", "unknown")
                        type_counts[t] = type_counts.get(t, 0) + 1

                if type_counts:
                    tests_by_type = [
                        TestsByType(type=t, count=c) for t, c in type_counts.items()
                    ]
            except Exception:
                pass

            # Activite recente (audit log)
            recent = []
            try:
                audit = self._db.client.table("admin_audit_log").select(
                    "id, action, entity_type, entity_id, created_at, user_profiles(first_name, last_name)"
                ).order("created_at", desc=True).limit(10).execute()

                for entry in (audit.data or []):
                    user_info = entry.get("user_profiles") or {}
                    name = f"{user_info.get('first_name', '')} {user_info.get('last_name', '')}".strip() or "Admin"
                    recent.append(RecentActivity(
                        id=entry["id"],
                        user_name=name,
                        action=entry.get("action", ""),
                        entity=f"{entry.get('entity_type', '')} {entry.get('entity_id', '')}".strip(),
                        created_at=entry.get("created_at", ""),
                    ))
            except Exception:
                pass

            return DashboardStats(
                total_users=total_users,
                total_tests_completed=total_tests,
                total_schools=total_schools,
                total_mentors=total_mentors,
                tests_by_type=tests_by_type,
                recent_activity=recent,
            )

        except Exception as e:
            logger.error(f"Error fetching dashboard stats: {e}")
            return DashboardStats()


_stats_repo = StatsRepository()


def get_stats_repository() -> StatsRepository:
    return _stats_repo
