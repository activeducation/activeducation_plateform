"""Tests du service de recommandation d'orientation multi-criteres."""

from uuid import uuid4

from app.services.orientation_recommendation_service import (
    OrientationRecommendationService,
)


class _FakeRepo:
    def __init__(self, profile=None, riasec=None, careers=None, programs=None):
        self._profile = profile
        self._riasec = riasec
        self._careers = careers or []
        self._programs = programs or {}

    async def get_profile(self, user_id):
        return self._profile

    async def get_latest_test_result(self, user_id):
        return self._riasec

    async def list_active_careers(self, limit=200):
        return self._careers

    async def list_programs_grouped_by_career(self):
        return self._programs


_DEV = {
    "id": "c1",
    "name": "Développeur logiciel",
    "description": "Programmation et algorithmes.",
    "riasec_codes": ["I"],
    "key_subjects": ["Mathématiques"],
}
_INFIRMIER = {
    "id": "c2",
    "name": "Infirmier",
    "description": "Soigne les patients.",
    "riasec_codes": ["S"],
    "key_subjects": ["SVT"],
}


# ---------------------------------------------------------------------------
# Complétude du profil
# ---------------------------------------------------------------------------


def test_completeness_full_profile():
    profile = {
        "grades": {"Mathématiques": 15},
        "interests": ["informatique"],
        "budget_annual_fcfa": 300000,
        "career_project": "Devenir développeur",
    }
    out = OrientationRecommendationService.profile_completeness(profile, True)
    assert out["percent"] == 100
    assert out["missing"] == []


def test_completeness_empty_profile_lists_all_missing():
    out = OrientationRecommendationService.profile_completeness({}, False)
    assert out["percent"] == 0
    assert len(out["missing"]) == 5


def test_completeness_counts_favorite_subjects_as_interests():
    out = OrientationRecommendationService.profile_completeness(
        {"favorite_subjects": ["Maths"]}, False
    )
    assert out["criteria"]["interests"] is True


# ---------------------------------------------------------------------------
# Recommandations
# ---------------------------------------------------------------------------


async def test_recommend_ranks_careers_and_reports_completeness():
    profile = {
        "grades": {"Mathématiques": 18, "SVT": 5},
        "career_project": "Je veux devenir développeur logiciel",
    }
    repo = _FakeRepo(profile=profile, riasec=None, careers=[_INFIRMIER, _DEV])
    svc = OrientationRecommendationService(repository=repo)

    out = await svc.recommend(uuid4(), limit=5)

    names = [r["career_name"] for r in out["recommendations"]]
    assert names[0] == "Développeur logiciel"
    assert out["has_test_result"] is False
    # tests + intérêts + budget manquants
    assert out["profile_completeness"]["percent"] == 40


async def test_recommend_without_any_profile_still_returns_list():
    repo = _FakeRepo(profile=None, riasec=None, careers=[_DEV])
    svc = OrientationRecommendationService(repository=repo)

    out = await svc.recommend(uuid4())

    assert len(out["recommendations"]) == 1
    assert out["recommendations"][0]["factors_used"] == 0
    assert out["profile_completeness"]["percent"] == 0


async def test_recommend_uses_test_result_when_available():
    riasec = {"dominant_traits": ["Investigateur"], "scores": {"Investigateur": 90.0}}
    repo = _FakeRepo(profile={}, riasec=riasec, careers=[_DEV])
    svc = OrientationRecommendationService(repository=repo)

    out = await svc.recommend(uuid4())

    assert out["has_test_result"] is True
    assert out["recommendations"][0]["breakdown"]["riasec"] is not None


async def test_recommend_budget_uses_linked_programs():
    profile = {"budget_annual_fcfa": 200_000}
    programs = {"c1": [{"tuition_annual_fcfa": 150_000}]}
    repo = _FakeRepo(profile=profile, careers=[_DEV], programs=programs)
    svc = OrientationRecommendationService(repository=repo)

    out = await svc.recommend(uuid4())

    assert out["recommendations"][0]["breakdown"]["budget"] == 100.0
