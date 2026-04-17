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

    assert result.scores["Réaliste"] == 100.0
    assert result.scores["Investigateur"] == 80.0
    assert result.scores["Artistique"] == 60.0
    assert result.dominant_traits[0] == "Réaliste"
    assert result.recommendations == []


@pytest.mark.asyncio
async def test_calculate_riasec_legacy_question_ids_fallback():
    engine = OrientationEngine()
    responses = {"R_1": "2", "S_2": "5", "C_3": "1"}

    result = await engine.calculate_result(OrientationTestType.RIASEC, responses, test_data=None)

    assert result.scores["Social"] == 100.0
    assert result.scores["Réaliste"] == 40.0
    assert result.scores["Conventionnel"] == 20.0
    assert "Social" in result.dominant_traits


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

    # Deux reponses invalides -> fallback 1 chacune -> (2 / 10) * 100 = 20.0
    assert result.scores["Logic"] == 20.0
    assert result.dominant_traits == ["Logic"]


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
    # Linguistique: (5+4) / (2*5) * 100 = 90.0
    # Logique: (3) / (1*5) * 100 = 60.0
    assert result.scores["Linguistique"] == 90.0
    assert result.scores["Logique"] == 60.0
    assert result.dominant_traits[0] == "Linguistique"
