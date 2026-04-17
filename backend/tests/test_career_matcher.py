"""
Tests unitaires pour CareerMatcherService (services/career_matcher.py).

Couvre les branches non-triviales :
- _normalize_career_trait : EN_TO_FR, CODE_TO_FR, _NO_ACCENT_TO_ACCENT, fallback
- _extract_education_level : dict, JSON string, invalid string, autre type
- enrich_result : dominant_traits vide (early return)
- _match_careers : exception repo, tri par match_score, diversification
- _fetch_school_programs : secteurs vides, exception repo
"""

import os
import sys
from pathlib import Path
from unittest.mock import AsyncMock, MagicMock
from uuid import UUID, uuid4

import pytest

os.environ.setdefault("SUPABASE_URL", "https://placeholder.supabase.co")
os.environ.setdefault("SUPABASE_KEY", "placeholder_key_for_testing_only_not_real")
os.environ.setdefault("SUPABASE_SERVICE_ROLE_KEY", "placeholder_service_role_key_for_testing")
os.environ.setdefault("ENVIRONMENT", "development")
os.environ.setdefault("DEBUG", "True")

BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app.schemas.orientation import TestResult
from app.services.career_matcher import (
    CareerMatcherService,
    _diversify_by_tier,
    _extract_education_level,
    _normalize_career_trait,
    _build_career_summary,
)


# =============================================================================
# _normalize_career_trait
# =============================================================================


def test_normalize_trait_from_english():
    """'Realistic' (EN) doit etre mappe sur 'Réaliste' (FR accentue)."""
    assert _normalize_career_trait("Realistic") == "Réaliste"
    assert _normalize_career_trait("Investigative") == "Investigateur"


def test_normalize_trait_from_code():
    """Les codes RIASEC (R, I, A, ...) sont mappes sur leur label FR."""
    assert _normalize_career_trait("R") == "Réaliste"
    assert _normalize_career_trait("I") == "Investigateur"


def test_normalize_trait_from_unaccented():
    """'Realiste' sans accent est remappe sur 'Réaliste' accentue."""
    assert _normalize_career_trait("Realiste") == "Réaliste"


def test_normalize_trait_fallback_returns_input():
    """Un trait inconnu est retourne tel quel."""
    assert _normalize_career_trait("Mystique") == "Mystique"


# =============================================================================
# _extract_education_level
# =============================================================================


def test_extract_education_from_dict():
    assert _extract_education_level({"education_path": {"minimum_level": "LICENCE"}}) == "LICENCE"


def test_extract_education_from_dict_without_min():
    """dict sans minimum_level renvoie le defaut BAC."""
    assert _extract_education_level({"education_path": {}}) == "BAC"


def test_extract_education_from_json_string():
    assert _extract_education_level({"education_path": '{"minimum_level": "MASTER"}'}) == "MASTER"


def test_extract_education_from_invalid_json_string():
    """String non-JSON → fallback BAC."""
    assert _extract_education_level({"education_path": "not a json"}) == "BAC"


def test_extract_education_missing_key():
    """Pas de education_path du tout → BAC."""
    assert _extract_education_level({}) == "BAC"


def test_extract_education_other_type():
    """education_path de type inattendu (list) → BAC."""
    assert _extract_education_level({"education_path": ["LICENCE"]}) == "BAC"


# =============================================================================
# _diversify_by_tier
# =============================================================================


def _make_summary(score: float, name: str = "X") -> object:
    """Helper : cree un objet minimal avec match_score et name."""
    s = MagicMock()
    s.match_score = score
    s.name = name
    return s


def test_diversify_preserves_count():
    """La diversification ne supprime aucune carriere."""
    items = [_make_summary(s, f"C{i}") for i, s in enumerate([90, 85, 82, 60, 55])]
    out = _diversify_by_tier(items)
    assert len(out) == 5


def test_diversify_separates_tiers():
    """Les tiers separes par plus de TIER_MARGIN ne sont pas melanges."""
    # Tier1 (90-85), puis tier2 isole (50)
    items = [_make_summary(90, "A"), _make_summary(85, "B"), _make_summary(50, "Z")]
    out = _diversify_by_tier(items)
    # "Z" doit rester en dernier car tier distinct
    assert out[-1].name == "Z"


# =============================================================================
# enrich_result : early return si dominant_traits vide
# =============================================================================


def _make_result(traits=None, scores=None, sectors=None) -> TestResult:
    return TestResult(
        test_id=uuid4(),
        scores=scores or {"Réaliste": 80.0},
        dominant_traits=traits if traits is not None else ["Réaliste"],
        interpretation={"recommended_sectors": sectors or []},
    )


@pytest.mark.asyncio
async def test_enrich_result_returns_early_when_no_dominant_traits():
    """enrich_result avec dominant_traits vide retourne sans appeler le repo."""
    service = CareerMatcherService()
    result = TestResult(
        test_id=uuid4(),
        scores={},
        dominant_traits=[],
    )
    repo = MagicMock()
    repo.get_careers_by_traits = AsyncMock()

    out = await service.enrich_result(result, repo)

    assert out is result
    repo.get_careers_by_traits.assert_not_called()


# =============================================================================
# _match_careers
# =============================================================================


@pytest.mark.asyncio
async def test_match_careers_returns_empty_on_repo_exception():
    """Une exception du repo ne plante pas : retourne [] et log."""
    service = CareerMatcherService()
    result = _make_result()
    repo = MagicMock()
    repo.get_careers_by_traits = AsyncMock(side_effect=Exception("DB down"))

    out = await service._match_careers(result, repo)

    assert out == []


@pytest.mark.asyncio
async def test_match_careers_sorts_and_limits():
    """Les carrieres sont triees par match_score descendant et limitees a 6."""
    service = CareerMatcherService()
    result = _make_result(
        traits=["Réaliste", "Investigateur"],
        scores={"Réaliste": 90.0, "Investigateur": 85.0},
    )

    # 8 carrieres avec related_traits varies
    careers_data = []
    for i in range(8):
        careers_data.append({
            "id": str(uuid4()),
            "name": f"Career {i}",
            "sector_name": "Tech",
            "related_traits": ["R", "I"] if i < 4 else ["A"],
            "education_path": {"minimum_level": "BAC"},
        })
    repo = MagicMock()
    repo.get_careers_by_traits = AsyncMock(return_value=careers_data)

    out = await service._match_careers(result, repo)

    assert len(out) <= 6
    # Les scores doivent etre globalement decroissants (la diversification peut
    # permuter a l'interieur d'un tier de +/- TIER_MARGIN).
    for earlier, later in zip(out, out[1:]):
        assert earlier.match_score >= later.match_score - 8


# =============================================================================
# _fetch_school_programs
# =============================================================================


@pytest.mark.asyncio
async def test_fetch_school_programs_empty_sectors():
    """Sans recommended_sectors, pas d'appel au repo."""
    service = CareerMatcherService()
    result = _make_result(sectors=[])
    repo = MagicMock()
    repo.get_matching_school_programs = AsyncMock()

    out = await service._fetch_school_programs(result, repo)

    assert out == []
    repo.get_matching_school_programs.assert_not_called()


@pytest.mark.asyncio
async def test_fetch_school_programs_with_sectors():
    """Avec des secteurs, le repo est interroge."""
    service = CareerMatcherService()
    result = _make_result(sectors=["Tech", "Sante"])
    repo = MagicMock()
    repo.get_matching_school_programs = AsyncMock(return_value=[{"id": "1"}])

    out = await service._fetch_school_programs(result, repo)

    assert out == [{"id": "1"}]
    repo.get_matching_school_programs.assert_called_once_with(["Tech", "Sante"], limit=8)


@pytest.mark.asyncio
async def test_fetch_school_programs_swallows_exception():
    """Exception repo ne plante pas : retourne []."""
    service = CareerMatcherService()
    result = _make_result(sectors=["Tech"])
    repo = MagicMock()
    repo.get_matching_school_programs = AsyncMock(side_effect=Exception("boom"))

    out = await service._fetch_school_programs(result, repo)

    assert out == []


# =============================================================================
# enrich_result : chemin complet
# =============================================================================


@pytest.mark.asyncio
async def test_enrich_result_full_path():
    """Le chemin normal appelle _match_careers ET _fetch_school_programs."""
    service = CareerMatcherService()
    result = _make_result(
        traits=["Réaliste"],
        scores={"Réaliste": 80.0},
        sectors=["Tech"],
    )
    repo = MagicMock()
    repo.get_careers_by_traits = AsyncMock(return_value=[{
        "id": str(uuid4()),
        "name": "Ingenieur",
        "sector_name": "Tech",
        "related_traits": ["R"],
        "education_path": {"minimum_level": "BAC+3"},
    }])
    repo.get_matching_school_programs = AsyncMock(return_value=[{"id": "1"}])

    out = await service.enrich_result(result, repo)

    assert len(out.recommendations) == 1
    assert out.recommendations[0].name == "Ingenieur"
    assert out.matching_programs == [{"id": "1"}]


# =============================================================================
# _build_career_summary
# =============================================================================


def test_build_career_summary_minimal():
    """_build_career_summary construit un CareerSummary avec les defaults."""
    career_id = str(uuid4())
    c = {"id": career_id, "name": "Medecin", "sector_name": "Sante"}

    summary = _build_career_summary(c, match_score=75.0, matching_traits=["Investigateur"])

    assert str(summary.id) == career_id
    assert summary.name == "Medecin"
    assert summary.match_score == 75.0
    assert summary.matching_traits == ["Investigateur"]
    assert summary.education_minimum_level == "BAC"
    assert summary.required_skills == []


def test_build_career_summary_truncates_skills():
    """required_skills est tronque a 5 elements."""
    c = {
        "id": str(uuid4()),
        "name": "Dev",
        "sector_name": "Tech",
        "required_skills": [f"skill{i}" for i in range(10)],
    }
    summary = _build_career_summary(c, match_score=50.0, matching_traits=[])
    assert len(summary.required_skills) == 5
