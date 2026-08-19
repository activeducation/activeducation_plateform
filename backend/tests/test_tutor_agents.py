"""Tests des agents TutorAI (AssessorAgent, PlannerAgent).

LLM et dépendances remplacés par des doubles : aucun accès réseau/DB.
"""

from uuid import uuid4

import pytest

from app.core.exceptions import ExternalServiceError
from app.services.tutor.agents.assessor import AssessorAgent
from app.services.tutor.agents.planner import PlannerAgent


class _FakeProvider:
    def __init__(self, reply):
        self._reply = reply

    async def complete(self, messages):
        return self._reply

    async def stream(self, messages):  # pragma: no cover - non utilisé ici
        yield self._reply


_VALID_QUIZ = (
    '{"questions":[{"question":"Combien font 2+2 ?",'
    '"options":[{"text":"4","is_correct":true},'
    '{"text":"3","is_correct":false},'
    '{"text":"5","is_correct":false}],'
    '"explanation":"2+2=4"}]}'
)


# ---------------------------------------------------------------------------
# AssessorAgent
# ---------------------------------------------------------------------------


async def test_generate_quiz_parses_valid_json():
    agent = AssessorAgent(provider=_FakeProvider(_VALID_QUIZ))
    quiz = await agent.generate_quiz("arithmétique", num_questions=1)
    assert len(quiz["questions"]) == 1
    q = quiz["questions"][0]
    assert q["question"].startswith("Combien")
    assert sum(1 for o in q["options"] if o["is_correct"]) == 1


async def test_generate_quiz_handles_markdown_fenced_json():
    reply = f"Voici ton quiz :\n```json\n{_VALID_QUIZ}\n```"
    agent = AssessorAgent(provider=_FakeProvider(reply))
    quiz = await agent.generate_quiz("maths", 1)
    assert len(quiz["questions"]) == 1


async def test_generate_quiz_filters_questions_without_single_correct():
    bad = (
        '{"questions":[{"question":"Q sans bonne réponse",'
        '"options":[{"text":"a","is_correct":false},'
        '{"text":"b","is_correct":false}]}]}'
    )
    agent = AssessorAgent(provider=_FakeProvider(bad))
    with pytest.raises(ExternalServiceError):
        await agent.generate_quiz("maths", 1)


async def test_generate_quiz_invalid_json_raises():
    agent = AssessorAgent(provider=_FakeProvider("désolé, pas de JSON ici"))
    with pytest.raises(ExternalServiceError):
        await agent.generate_quiz("maths", 1)


async def test_generate_quiz_empty_reply_raises():
    agent = AssessorAgent(provider=_FakeProvider(""))
    with pytest.raises(ExternalServiceError):
        await agent.generate_quiz("maths", 1)


# ---------------------------------------------------------------------------
# PlannerAgent
# ---------------------------------------------------------------------------


class _FakeMastery:
    def __init__(self, weak):
        self._weak = weak

    async def weak_skills(self, user_id, limit=10):
        return self._weak


class _FakeSkillRepo:
    def __init__(self, titles):
        self._titles = titles

    async def get_skill(self, skill_id):
        return {"title": self._titles.get(str(skill_id))}


async def test_planner_recommends_weak_skills_with_titles():
    sid = uuid4()
    planner = PlannerAgent(
        mastery_service=_FakeMastery([{"skill_id": str(sid), "p_mastery": 0.2}]),
        skill_repository=_FakeSkillRepo({str(sid): "Fractions"}),
    )
    rec = await planner.recommend(uuid4())
    assert rec["has_recommendation"] is True
    assert rec["weak_skills"][0]["title"] == "Fractions"
    assert "Fractions" in rec["message"]


async def test_planner_no_weak_skills_message():
    planner = PlannerAgent(
        mastery_service=_FakeMastery([]),
        skill_repository=_FakeSkillRepo({}),
    )
    rec = await planner.recommend(uuid4())
    assert rec["has_recommendation"] is False
    assert rec["weak_skills"] == []
    assert "Aucune lacune" in rec["message"]
