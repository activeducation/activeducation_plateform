"""
Tests pour le module School Admin Dashboard.

Teste:
- Validation des schemas Pydantic
- Logique de la dependency get_current_school_admin
- Operations CRUD du repository (avec mocks)
"""

import pytest
from unittest.mock import MagicMock, patch, AsyncMock
from uuid import uuid4

from pydantic import ValidationError as PydanticValidationError


# =============================================================================
# SCHEMA VALIDATION TESTS
# =============================================================================


class TestSchoolCourseSchemas:
    """Tests pour les schemas de cours."""

    def test_course_create_valid(self):
        from app.schemas.school_admin import SchoolCourseCreate

        course = SchoolCourseCreate(
            title="Introduction au Python",
            description="Un cours d'introduction",
            difficulty="beginner",
            category="Informatique",
            duration_minutes=120,
            points_reward=50,
        )
        assert course.title == "Introduction au Python"
        assert course.difficulty == "beginner"

    def test_course_create_invalid_title_too_short(self):
        from app.schemas.school_admin import SchoolCourseCreate

        with pytest.raises(PydanticValidationError):
            SchoolCourseCreate(title="AB")

    def test_course_create_invalid_difficulty(self):
        from app.schemas.school_admin import SchoolCourseCreate

        with pytest.raises(PydanticValidationError):
            SchoolCourseCreate(title="Test Course", difficulty="expert")

    def test_course_update_partial(self):
        from app.schemas.school_admin import SchoolCourseUpdate

        update = SchoolCourseUpdate(title="Nouveau titre")
        data = update.model_dump(exclude_none=True)
        assert data == {"title": "Nouveau titre"}

    def test_course_update_empty(self):
        from app.schemas.school_admin import SchoolCourseUpdate

        update = SchoolCourseUpdate()
        data = update.model_dump(exclude_none=True)
        assert data == {}


class TestSchoolModuleSchemas:
    """Tests pour les schemas de modules."""

    def test_module_create_valid(self):
        from app.schemas.school_admin import SchoolModuleCreate

        module = SchoolModuleCreate(
            title="Module 1 - Les bases",
            description="Premier module du cours",
            display_order=0,
        )
        assert module.title == "Module 1 - Les bases"

    def test_module_create_invalid_title_too_short(self):
        from app.schemas.school_admin import SchoolModuleCreate

        with pytest.raises(PydanticValidationError):
            SchoolModuleCreate(title="A")


class TestSchoolLessonSchemas:
    """Tests pour les schemas de lecons."""

    def test_lesson_create_valid(self):
        from app.schemas.school_admin import SchoolLessonCreate

        lesson = SchoolLessonCreate(
            title="Lecon 1 - Variables",
            lesson_type="video",
            duration_minutes=15,
            points_reward=10,
            is_free=True,
        )
        assert lesson.lesson_type == "video"
        assert lesson.is_free is True

    def test_lesson_create_invalid_type(self):
        from app.schemas.school_admin import SchoolLessonCreate

        with pytest.raises(PydanticValidationError):
            SchoolLessonCreate(title="Test", lesson_type="podcast")

    def test_lesson_create_with_content(self):
        from app.schemas.school_admin import SchoolLessonCreate

        lesson = SchoolLessonCreate(
            title="Quiz Python",
            lesson_type="quiz",
            content_data={"questions": [{"q": "1+1?", "a": "2"}]},
        )
        assert lesson.content_data is not None


class TestDashboardStatsSchema:
    """Tests pour le schema de stats."""

    def test_stats_defaults(self):
        from app.schemas.school_admin import SchoolDashboardStats

        stats = SchoolDashboardStats()
        assert stats.total_courses == 0
        assert stats.published_courses == 0
        assert stats.total_enrollments == 0
        assert stats.avg_progress == 0.0


class TestSchoolProfileUpdateSchema:
    """Tests pour le schema de profil ecole."""

    def test_profile_update_partial(self):
        from app.schemas.school_admin import SchoolProfileUpdate

        update = SchoolProfileUpdate(description="Nouvelle description")
        data = update.model_dump(exclude_none=True)
        assert data == {"description": "Nouvelle description"}


# =============================================================================
# SECURITY DEPENDENCY TESTS
# =============================================================================


class TestSchoolAdminSecurity:
    """Tests pour la dependency get_current_school_admin."""

    @pytest.mark.asyncio
    async def test_rejects_no_credentials(self):
        from app.core.security import get_current_school_admin
        from app.core.exceptions import AuthenticationError

        with pytest.raises(AuthenticationError):
            await get_current_school_admin(credentials=None)

    @pytest.mark.asyncio
    async def test_rejects_student_role(self):
        from app.core.security import get_current_school_admin
        from app.core.exceptions import AuthorizationError

        mock_creds = MagicMock()
        mock_creds.credentials = "fake_token"

        with patch("app.core.security.get_user_from_token") as mock_token:
            mock_token.return_value = {
                "user_id": str(uuid4()),
                "email": "student@test.com",
                "role": "authenticated",
            }
            with patch("app.db.supabase_client.get_supabase_client") as mock_db:
                mock_client = MagicMock()
                mock_client.fetch_one.return_value = {
                    "id": str(uuid4()),
                    "email": "student@test.com",
                    "role": "student",
                    "is_active": True,
                }
                mock_db.return_value = mock_client

                with pytest.raises(AuthorizationError):
                    await get_current_school_admin(credentials=mock_creds)

    @pytest.mark.asyncio
    async def test_rejects_admin_role(self):
        from app.core.security import get_current_school_admin
        from app.core.exceptions import AuthorizationError

        mock_creds = MagicMock()
        mock_creds.credentials = "fake_token"

        with patch("app.core.security.get_user_from_token") as mock_token:
            mock_token.return_value = {
                "user_id": str(uuid4()),
                "email": "admin@test.com",
                "role": "authenticated",
            }
            with patch("app.db.supabase_client.get_supabase_client") as mock_db:
                mock_client = MagicMock()
                mock_client.fetch_one.return_value = {
                    "id": str(uuid4()),
                    "email": "admin@test.com",
                    "role": "admin",
                    "is_active": True,
                }
                mock_db.return_value = mock_client

                with pytest.raises(AuthorizationError):
                    await get_current_school_admin(credentials=mock_creds)

    @pytest.mark.asyncio
    async def test_accepts_school_admin(self):
        from app.core.security import get_current_school_admin

        user_id = str(uuid4())
        school_id = str(uuid4())
        mock_creds = MagicMock()
        mock_creds.credentials = "fake_token"

        with patch("app.core.security.get_user_from_token") as mock_token:
            mock_token.return_value = {
                "user_id": user_id,
                "email": "school@test.com",
                "role": "authenticated",
            }
            with patch("app.db.supabase_client.get_supabase_client") as mock_db:
                mock_client = MagicMock()

                def fetch_one_side_effect(table, id_column, id_value):
                    if table == "user_profiles":
                        return {
                            "id": user_id,
                            "email": "school@test.com",
                            "role": "school_admin",
                            "is_active": True,
                        }
                    elif table == "school_admin_profiles":
                        return {
                            "user_id": user_id,
                            "school_id": school_id,
                            "is_active": True,
                        }
                    return None

                mock_client.fetch_one.side_effect = fetch_one_side_effect
                mock_db.return_value = mock_client

                result = await get_current_school_admin(credentials=mock_creds)
                assert str(result["user_id"]) == user_id
                assert result["school_id"] == school_id


# =============================================================================
# REPOSITORY TESTS (with mocked Supabase)
# =============================================================================


class TestSchoolAdminRepository:
    """Tests pour le repository school_admin."""

    def _make_repo(self, mock_client):
        from app.repositories.school_admin_repository import SchoolAdminRepository
        return SchoolAdminRepository(db=mock_client)

    def test_get_school_for_admin_found(self):
        mock_db = MagicMock()
        mock_result = MagicMock()
        mock_result.data = [{"user_id": "uid1", "school_id": "sid1", "is_active": True}]
        mock_db.client.table.return_value.select.return_value.eq.return_value.eq.return_value.limit.return_value.execute.return_value = mock_result

        repo = self._make_repo(mock_db)
        result = repo.get_school_for_admin("uid1")
        assert result["school_id"] == "sid1"

    def test_get_school_for_admin_not_found(self):
        mock_db = MagicMock()
        mock_result = MagicMock()
        mock_result.data = []
        mock_db.client.table.return_value.select.return_value.eq.return_value.eq.return_value.limit.return_value.execute.return_value = mock_result

        repo = self._make_repo(mock_db)
        result = repo.get_school_for_admin("uid_unknown")
        assert result is None

    def test_get_courses(self):
        mock_db = MagicMock()
        mock_result = MagicMock()
        mock_result.data = [
            {"id": "c1", "title": "Cours 1", "school_id": "sid1"},
            {"id": "c2", "title": "Cours 2", "school_id": "sid1"},
        ]
        mock_db.client.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value = mock_result

        repo = self._make_repo(mock_db)
        courses = repo.get_courses("sid1")
        assert len(courses) == 2

    def test_create_course(self):
        mock_db = MagicMock()
        mock_result = MagicMock()
        mock_result.data = [{"id": "new_id", "title": "New", "school_id": "sid1"}]
        mock_db.client.table.return_value.insert.return_value.execute.return_value = mock_result

        repo = self._make_repo(mock_db)
        course = repo.create_course("sid1", {"title": "New"})
        assert course["id"] == "new_id"
        assert course["school_id"] == "sid1"

    def test_delete_course_success(self):
        mock_db = MagicMock()
        mock_result = MagicMock()
        mock_result.data = [{"id": "c1"}]
        mock_db.client.table.return_value.delete.return_value.eq.return_value.eq.return_value.execute.return_value = mock_result

        repo = self._make_repo(mock_db)
        assert repo.delete_course("c1", "sid1") is True

    def test_delete_course_not_found(self):
        mock_db = MagicMock()
        mock_result = MagicMock()
        mock_result.data = []
        mock_db.client.table.return_value.delete.return_value.eq.return_value.eq.return_value.execute.return_value = mock_result

        repo = self._make_repo(mock_db)
        assert repo.delete_course("c_unknown", "sid1") is False

    def test_dashboard_stats_empty(self):
        mock_db = MagicMock()
        mock_result = MagicMock()
        mock_result.data = []
        mock_db.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_result

        repo = self._make_repo(mock_db)
        stats = repo.get_dashboard_stats("sid1")
        assert stats["total_courses"] == 0
        assert stats["total_enrollments"] == 0
