import os
import sys
from pathlib import Path
from uuid import UUID, uuid4

import pytest
from fastapi.testclient import TestClient


os.environ.setdefault("SUPABASE_URL", "https://placeholder.supabase.co")
os.environ.setdefault("SUPABASE_KEY", "placeholder_key")
os.environ.setdefault("SECRET_KEY", "test_secret_key_with_at_least_32_characters")
os.environ.setdefault("ENVIRONMENT", "development")
os.environ.setdefault("DEBUG", "True")

BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app.main import app
from app.api.v1.endpoints.orientation import get_repo
from app.core.security import get_current_user_id


class FakeOrientationRepo:
    def __init__(self):
        self.saved = False

    async def get_test_by_id(self, test_id: UUID):
        return {
            "id": str(test_id),
            "name": "Test RIASEC",
            "description": "desc",
            "type": "riasec",
            "duration_minutes": 15,
            "questions": [
                {"id": "q1", "category": "R"},
                {"id": "q2", "category": "I"},
                {"id": "q3", "category": "A"},
            ],
        }

    async def create_test_session(self, user_id: UUID, test_id: UUID):
        return {"id": str(uuid4()), "user_id": str(user_id), "test_id": str(test_id)}

    async def get_careers_by_traits(self, traits: list[str], limit: int = 5):
        return [
            {
                "id": str(uuid4()),
                "name": "Data Scientist",
                "sector_name": "Technologie",
                "job_demand": "high",
                "salary_avg_fcfa": 500000,
                "image_url": None,
            }
        ]

    async def complete_test_session(self, **kwargs):
        self.saved = True
        return {"id": str(uuid4())}


@pytest.fixture
def client():
    app.dependency_overrides.clear()
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()


@pytest.fixture
def auth_client():
    app.dependency_overrides.clear()
    fake_repo = FakeOrientationRepo()
    fake_user_id = UUID("11111111-1111-1111-1111-111111111111")

    def _get_repo():
        return fake_repo

    async def _get_current_user():
        return fake_user_id

    app.dependency_overrides[get_repo] = _get_repo
    app.dependency_overrides[get_current_user_id] = _get_current_user

    with TestClient(app) as c:
        yield c, fake_repo

    app.dependency_overrides.clear()
