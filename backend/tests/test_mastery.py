"""Tests du modele de maitrise TutorAI (BKT + MasteryService)."""

from uuid import uuid4

from app.core.config import get_settings
from app.services.tutor.mastery.bkt import BktParams, bkt_update
from app.services.tutor.mastery.service import MasteryService


# ---------------------------------------------------------------------------
# BKT (fonction pure)
# ---------------------------------------------------------------------------


def test_bkt_correct_increases_mastery():
    p = BktParams()
    assert bkt_update(0.3, True, p) > 0.3


def test_bkt_incorrect_decreases_mastery():
    p = BktParams()
    assert bkt_update(0.3, False, p) < 0.3


def test_bkt_stays_in_unit_interval():
    p = BktParams()
    for prior in (0.0, 0.01, 0.5, 0.99, 1.0):
        for correct in (True, False):
            v = bkt_update(prior, correct, p)
            assert 0.0 <= v <= 1.0


def test_bkt_zero_prior_can_still_learn():
    # Depuis 0, la transition d'apprentissage remonte la maitrise.
    p = BktParams()
    assert bkt_update(0.0, True, p) > 0.0


def test_bkt_params_from_settings():
    p = BktParams.from_settings()
    s = get_settings()
    assert p.p_init == s.BKT_P_INIT
    assert p.p_slip == s.BKT_P_SLIP


# ---------------------------------------------------------------------------
# MasteryService (faux repository)
# ---------------------------------------------------------------------------


class _FakeMasteryRepo:
    def __init__(self, existing=None):
        self.existing = existing
        self.upserts = []
        self.weak_args = None

    async def get(self, user_id, skill_id):
        return self.existing

    async def upsert(self, user_id, skill_id, p_mastery, attempts, correct):
        row = {
            "user_id": str(user_id),
            "skill_id": str(skill_id),
            "p_mastery": p_mastery,
            "attempts": attempts,
            "correct": correct,
        }
        self.upserts.append(row)
        return row

    async def list_for_user(self, user_id):
        return [{"skill_id": "x", "p_mastery": 0.2}]

    async def list_weak(self, user_id, threshold, limit):
        self.weak_args = (threshold, limit)
        return [{"skill_id": "x", "p_mastery": 0.2}]


async def test_record_answer_new_skill_uses_p_init():
    repo = _FakeMasteryRepo(existing=None)
    svc = MasteryService(repository=repo, params=BktParams())
    uid, sid = uuid4(), uuid4()

    res = await svc.record_answer(uid, sid, correct=True)

    assert res["attempts"] == 1
    assert res["correct"] == 1
    # Depuis p_init=0.3, une bonne reponse fait monter la maitrise.
    assert res["p_mastery"] > 0.3


async def test_record_answer_existing_skill_uses_stored_prior():
    repo = _FakeMasteryRepo(existing={"p_mastery": 0.7, "attempts": 3, "correct": 2})
    svc = MasteryService(repository=repo, params=BktParams())
    uid, sid = uuid4(), uuid4()

    res = await svc.record_answer(uid, sid, correct=False)

    assert res["attempts"] == 4
    assert res["correct"] == 2          # reponse fausse : correct inchange
    assert res["p_mastery"] < 0.7       # la maitrise baisse


async def test_weak_skills_uses_settings_threshold_by_default():
    repo = _FakeMasteryRepo()
    svc = MasteryService(repository=repo)
    await svc.weak_skills(uuid4())
    assert repo.weak_args[0] == get_settings().MASTERY_THRESHOLD


# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------


def test_mastery_config_defaults():
    s = get_settings()
    assert s.TUTOR_MASTERY_ENABLED is False
    assert 0.0 < s.MASTERY_THRESHOLD < 1.0
    assert 0.0 <= s.BKT_P_SLIP <= 1.0
