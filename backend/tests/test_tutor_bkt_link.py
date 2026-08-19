"""Tests du rattachement quiz -> compétence -> BKT (fermeture de la boucle)."""

from types import SimpleNamespace
from uuid import uuid4

from app.services.tutor.agents.assessor import AssessorAgent
from app.services.tutor.mastery.bkt import BktParams
from app.services.tutor.mastery.service import MasteryService
from app.repositories.skill_repository import SkillRepository


_VALID_QUIZ = (
    '{"questions":[{"question":"2+2 ?","options":['
    '{"text":"4","is_correct":true},{"text":"3","is_correct":false}]}]}'
)


class _FakeProvider:
    async def complete(self, messages):
        return _VALID_QUIZ

    async def stream(self, messages):  # pragma: no cover
        yield _VALID_QUIZ


# ---------------------------------------------------------------------------
# AssessorAgent — tag skill_id
# ---------------------------------------------------------------------------


async def test_generate_quiz_tags_skill_id_when_provided():
    agent = AssessorAgent(provider=_FakeProvider())
    quiz = await agent.generate_quiz("fractions", 1, skill_id="skill-123")
    assert quiz["skill_id"] == "skill-123"


async def test_generate_quiz_skill_id_none_by_default():
    agent = AssessorAgent(provider=_FakeProvider())
    quiz = await agent.generate_quiz("fractions", 1)
    assert quiz["skill_id"] is None


# ---------------------------------------------------------------------------
# MasteryService.record_answers — lot de réponses -> BKT séquentiel
# ---------------------------------------------------------------------------


class _StatefulMasteryRepo:
    def __init__(self):
        self.row = None
        self.upsert_count = 0

    async def get(self, user_id, skill_id):
        return self.row

    async def upsert(self, user_id, skill_id, p_mastery, attempts, correct):
        self.row = {"p_mastery": p_mastery, "attempts": attempts, "correct": correct}
        self.upsert_count += 1
        return self.row


async def test_record_answers_applies_bkt_sequentially():
    repo = _StatefulMasteryRepo()
    svc = MasteryService(repository=repo, params=BktParams())

    result = await svc.record_answers(uuid4(), uuid4(), [True, True, False])

    assert repo.upsert_count == 3
    assert result["attempts"] == 3       # compteurs cumulés
    assert result["correct"] == 2        # 2 bonnes réponses sur 3


# ---------------------------------------------------------------------------
# SkillRepository.find_skill_by_text — mapping sujet -> compétence
# ---------------------------------------------------------------------------


class _IlikeTable:
    def __init__(self, data, rec):
        self._data = data
        self._rec = rec

    def select(self, *a, **k):
        return self

    def ilike(self, col, pattern):
        self._rec["ilike"] = (col, pattern)
        return self

    def limit(self, n):
        return self

    def execute(self):
        return SimpleNamespace(data=self._data)


class _IlikeDB:
    def __init__(self, data):
        self.rec = {}
        self._client = SimpleNamespace(table=lambda name: _IlikeTable(data, self.rec))

    @property
    def client(self):
        return self._client


async def test_find_skill_by_text_returns_match():
    repo = SkillRepository()
    fake = _IlikeDB([{"id": "s1", "title": "Fractions"}])
    repo._db = fake

    skill = await repo.find_skill_by_text("fraction")
    assert skill["id"] == "s1"
    assert fake.rec["ilike"][0] == "title"


async def test_find_skill_by_text_empty_input_returns_none():
    repo = SkillRepository()
    repo._db = _IlikeDB([])
    assert await repo.find_skill_by_text("   ") is None
