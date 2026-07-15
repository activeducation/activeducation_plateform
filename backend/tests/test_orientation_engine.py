import os
import sys
from pathlib import Path

import pytest


os.environ.setdefault("SUPABASE_URL", "https://placeholder.supabase.co")
os.environ.setdefault("SUPABASE_KEY", "placeholder_key")
os.environ.setdefault("SECRET_KEY", "test_secret_key_with_at_least_32_characters")
os.environ.setdefault("ENVIRONMENT", "development")
os.environ.setdefault("DEBUG", "True")

BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app.schemas.orientation import TestType as OrientationTestType
from app.services.orientation_engine import OrientationEngine


# ============================================================================
# Les scores retournes par le moteur sont normalises en POURCENTAGES (0-100)
# sur une echelle Likert 1-5. Les labels sont en FRANCAIS (public cible).
# ============================================================================


@pytest.mark.asyncio
async def test_calculate_riasec_with_categories_from_test_data():
    engine = OrientationEngine()
    responses = {"q1": "5", "q2": "4", "q3": "3"}
    test_data = {
        "questions": [
            {"id": "q1", "category": "R"},
            {"id": "q2", "category": "I"},
            {"id": "q3", "category": "A"},
        ]
    }

    result = await engine.calculate_result(OrientationTestType.RIASEC, responses, test_data)

    # Baseline Likert retranchee : (valeur - 1) / 4 * 100
    assert result.scores["Réaliste"] == 100.0       # 5 -> max
    assert result.scores["Investigateur"] == 75.0   # 4
    assert result.scores["Artistique"] == 50.0      # 3 -> neutre
    assert result.dominant_traits[0] == "Réaliste"
    assert result.recommendations == []


@pytest.mark.asyncio
async def test_calculate_riasec_legacy_question_ids_fallback():
    engine = OrientationEngine()
    responses = {"R_1": "2", "S_2": "5", "C_3": "1"}

    result = await engine.calculate_result(OrientationTestType.RIASEC, responses, test_data=None)

    assert result.scores["Social"] == 100.0        # 5
    assert result.scores["Réaliste"] == 25.0       # 2
    # "Pas du tout" sur l'unique question du trait => 0, et non 20 comme avant.
    assert result.scores["Conventionnel"] == 0.0   # 1
    assert "Social" in result.dominant_traits
    # Un trait a 0 n'est pas un trait dominant.
    assert "Conventionnel" not in result.dominant_traits


@pytest.mark.asyncio
async def test_calculate_generic_uses_default_score_for_invalid_values():
    engine = OrientationEngine()
    responses = {"q1": "not-a-number", "q2": None}
    test_data = {
        "questions": [
            {"id": "q1", "category": "Logic"},
            {"id": "q2", "category": "Logic"},
        ]
    }

    result = await engine.calculate_result(OrientationTestType.SKILLS, responses, test_data)

    # Deux reponses invalides -> fallback 1 chacune -> plancher de l'echelle -> 0.0
    # (et non 20.0 : la baseline Likert est desormais retranchee).
    assert result.scores["Logic"] == 0.0
    # Des reponses illisibles ne doivent pas produire de trait dominant.
    assert result.dominant_traits == []


@pytest.mark.asyncio
@pytest.mark.parametrize(
    "answer, expected",
    [
        ("1", 0.0),    # "pas du tout" partout -> 0 (et non 20 : bug de baseline)
        ("2", 25.0),
        ("3", 50.0),   # neutre partout -> 50 (et non 60)
        ("4", 75.0),
        ("5", 100.0),
    ],
)
async def test_riasec_likert_baseline_covers_full_range(answer, expected):
    """Le plancher de l'echelle Likert (1) doit valoir 0%, pas 20%.

    Sans retrancher la baseline, l'echelle etait ecrasee sur 20-100 : tous les
    profils paraissaient eleves et un eleve neutre obtenait 60% partout.
    """
    engine = OrientationEngine()
    responses = {"q1": answer, "q2": answer}
    test_data = {"questions": [{"id": "q1", "category": "R"}, {"id": "q2", "category": "R"}]}

    result = await engine.calculate_result(OrientationTestType.RIASEC, responses, test_data)

    assert result.scores["Réaliste"] == expected
    # Les traits sans reponse restent a 0 et ne polluent pas le profil.
    assert result.scores["Artistique"] == 0.0


@pytest.mark.asyncio
async def test_calculate_personality_mbti_dimensions_from_responses():
    engine = OrientationEngine()
    responses = {"q1": "5", "q2": "4", "q3": "2", "q4": "1"}
    test_data = {
        "questions": [
            {"id": "q1", "category": "E-I"},
            {"id": "q2", "category": "S-N"},
            {"id": "q3", "category": "T-F"},
            {"id": "q4", "category": "J-P"},
        ]
    }

    result = await engine.calculate_result(
        OrientationTestType.PERSONALITY,
        responses,
        test_data,
    )

    # MBTI_FR conserve "Extraversion"/"Introversion" en francais identique
    assert result.scores["Extraversion"] > result.scores["Introversion"]
    # Les autres dimensions sont traduites: Sensing->Sensation, Feeling->Sentiment,
    # Perceiving->Perception
    assert result.scores["Sensation"] > result.scores["Intuition"]
    assert result.scores["Sentiment"] > result.scores["Pensée"]
    assert result.scores["Perception"] > result.scores["Jugement"]
    assert result.dominant_traits == ["Extraversion", "Sensation", "Sentiment", "Perception"]


@pytest.mark.asyncio
async def test_calculate_personality_falls_back_to_category_scoring():
    engine = OrientationEngine()
    responses = {"q1": "5", "q2": "4", "q3": "3"}
    test_data = {
        "questions": [
            {"id": "q1", "category": "Linguistique"},
            {"id": "q2", "category": "Linguistique"},
            {"id": "q3", "category": "Logique"},
        ]
    }

    result = await engine.calculate_result(
        OrientationTestType.PERSONALITY,
        responses,
        test_data,
    )

    # Categories non-MBTI => fallback _calculate_generic (pourcentages)
    # Linguistique: ((5+4) - 2*1) / (2*4) * 100 = 87.5
    # Logique:      ((3)   - 1*1) / (1*4) * 100 = 50.0
    assert result.scores["Linguistique"] == 87.5
    assert result.scores["Logique"] == 50.0
    assert result.dominant_traits[0] == "Linguistique"
