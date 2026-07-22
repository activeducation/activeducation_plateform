"""Tests du moteur d'orientation multi-criteres.

Moteur pur : aucun I/O, tout est verifiable directement.
"""

from app.services.orientation_match_engine import (
    MatchWeights,
    OrientationMatchEngine,
)


_ENGINE = OrientationMatchEngine(weights=MatchWeights())

_DEV = {
    "id": "c1",
    "name": "Développeur logiciel",
    "sector_name": "Informatique",
    "description": "Conçoit des applications, programmation et algorithmes.",
    "riasec_codes": ["I", "R"],
    "key_subjects": ["Mathématiques", "Physique"],
}

_INFIRMIER = {
    "id": "c2",
    "name": "Infirmier",
    "sector_name": "Santé",
    "description": "Accompagne et soigne les patients au quotidien.",
    "riasec_codes": ["S"],
    "key_subjects": ["SVT", "Physique-Chimie"],
}


# ---------------------------------------------------------------------------
# Critère notes (academic)
# ---------------------------------------------------------------------------


def test_academic_uses_grades_of_key_subjects():
    profile = {"grades": {"Mathématiques": 16, "Physique": 14}}
    result = _ENGINE.score_career(profile, _DEV)
    # moyenne 15/20 -> 75
    assert result["breakdown"]["academic"] == 75.0


def test_academic_matching_ignores_accents_and_case():
    profile = {"grades": {"mathematiques": 16, "PHYSIQUE": 14}}
    result = _ENGINE.score_career(profile, _DEV)
    assert result["breakdown"]["academic"] == 75.0


def test_academic_absent_when_no_matching_subject():
    profile = {"grades": {"Histoire": 18}}
    result = _ENGINE.score_career(profile, _DEV)
    assert result["breakdown"]["academic"] is None


# ---------------------------------------------------------------------------
# Critère tests (RIASEC)
# ---------------------------------------------------------------------------


def test_riasec_scores_when_profile_available():
    riasec = {
        "dominant_traits": ["Investigateur", "Réaliste"],
        "scores": {"Investigateur": 80.0, "Réaliste": 70.0},
    }
    result = _ENGINE.score_career({}, _DEV, riasec=riasec)
    assert result["breakdown"]["riasec"] is not None
    assert result["breakdown"]["riasec"] > 0


def test_riasec_absent_without_test():
    result = _ENGINE.score_career({}, _DEV, riasec=None)
    assert result["breakdown"]["riasec"] is None


# ---------------------------------------------------------------------------
# Critère intérêts / matières préférées
# ---------------------------------------------------------------------------


def test_interests_match_career_text():
    profile = {"interests": ["programmation"], "favorite_subjects": ["Mathématiques"]}
    result = _ENGINE.score_career(profile, _DEV)
    assert result["breakdown"]["interests"] == 100.0


def test_interests_partial_match():
    profile = {"interests": ["programmation", "cuisine"]}
    result = _ENGINE.score_career(profile, _DEV)
    assert result["breakdown"]["interests"] == 50.0


def test_interests_absent_when_nothing_declared():
    result = _ENGINE.score_career({}, _DEV)
    assert result["breakdown"]["interests"] is None


# ---------------------------------------------------------------------------
# Critère projet professionnel
# ---------------------------------------------------------------------------


def test_project_mentioning_career_is_maximal():
    profile = {"career_project": "Je veux devenir développeur logiciel"}
    result = _ENGINE.score_career(profile, _DEV)
    assert result["breakdown"]["project"] == 100.0


def test_project_unrelated_scores_zero():
    profile = {"career_project": "Je veux ouvrir une boulangerie"}
    result = _ENGINE.score_career(profile, _DEV)
    assert result["breakdown"]["project"] == 0.0


def test_project_absent_when_empty():
    result = _ENGINE.score_career({"career_project": "   "}, _DEV)
    assert result["breakdown"]["project"] is None


# ---------------------------------------------------------------------------
# Critère budget
# ---------------------------------------------------------------------------


def test_budget_within_means_is_maximal():
    profile = {"budget_annual_fcfa": 500_000}
    programs = [{"tuition_annual_fcfa": 300_000}]
    result = _ENGINE.score_career(profile, _DEV, programs=programs)
    assert result["breakdown"]["budget"] == 100.0


def test_budget_slightly_over_is_partial():
    profile = {"budget_annual_fcfa": 250_000}
    programs = [{"tuition_annual_fcfa": 300_000}]  # <= 250k * 1.25
    result = _ENGINE.score_career(profile, _DEV, programs=programs)
    assert result["breakdown"]["budget"] == 60.0


def test_budget_far_over_is_zero():
    profile = {"budget_annual_fcfa": 100_000}
    programs = [{"tuition_annual_fcfa": 900_000}]
    result = _ENGINE.score_career(profile, _DEV, programs=programs)
    assert result["breakdown"]["budget"] == 0.0


def test_budget_absent_without_cost_data():
    profile = {"budget_annual_fcfa": 500_000}
    programs = [{"tuition_annual_fcfa": None}]
    result = _ENGINE.score_career(profile, _DEV, programs=programs)
    assert result["breakdown"]["budget"] is None


def test_budget_uses_cheapest_program():
    profile = {"budget_annual_fcfa": 400_000}
    programs = [
        {"tuition_annual_fcfa": 900_000},
        {"tuition_annual_fcfa": 350_000},
    ]
    result = _ENGINE.score_career(profile, _DEV, programs=programs)
    assert result["breakdown"]["budget"] == 100.0


# ---------------------------------------------------------------------------
# Renormalisation : un élève sans test n'est pas pénalisé
# ---------------------------------------------------------------------------


def test_missing_factors_are_excluded_not_penalized():
    profile = {"grades": {"Mathématiques": 16, "Physique": 14}}
    result = _ENGINE.score_career(profile, _DEV)  # ni test, ni intérêts, ni budget
    assert result["factors_used"] == 1
    # Le score global vaut exactement le seul critère disponible.
    assert result["score"] == 75.0


def test_no_data_at_all_yields_zero_and_no_factor():
    result = _ENGINE.score_career({}, {"id": "x", "name": "Métier"})
    assert result["factors_used"] == 0
    assert result["score"] == 0.0


def test_reasons_are_returned_for_strong_factors():
    profile = {
        "grades": {"Mathématiques": 18, "Physique": 17},
        "interests": ["programmation"],
    }
    result = _ENGINE.score_career(profile, _DEV)
    assert any("notes" in r.lower() for r in result["reasons"])


# ---------------------------------------------------------------------------
# Classement
# ---------------------------------------------------------------------------


def test_rank_careers_sorts_by_score_desc_and_limits():
    profile = {
        "grades": {"Mathématiques": 18, "Physique": 17, "SVT": 6},
        "career_project": "Je veux devenir développeur logiciel",
    }
    ranked = _ENGINE.rank_careers(profile, [_INFIRMIER, _DEV], limit=2)

    assert [r["career_name"] for r in ranked] == ["Développeur logiciel", "Infirmier"]
    assert ranked[0]["score"] >= ranked[1]["score"]

    top_only = _ENGINE.rank_careers(profile, [_INFIRMIER, _DEV], limit=1)
    assert len(top_only) == 1
