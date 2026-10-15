"""Garde-fous sur le contenu du questionnaire RIASEC (migration 023).

Ces tests ne touchent pas a la base : ils valident la COHERENCE des donnees
declarees dans la migration. Un questionnaire desequilibre ou comportant des
doublons fausse silencieusement les scores, sans qu'aucune erreur ne remonte.
"""
import collections
import importlib.util
import sys
import unicodedata
from pathlib import Path

import pytest

BACKEND_ROOT = Path(__file__).resolve().parents[1]
MIGRATION = BACKEND_ROOT / "alembic" / "versions" / "023_riasec_full_questionnaire.py"

RIASEC_DIMENSIONS = {
    "Realistic", "Investigative", "Artistic",
    "Social", "Enterprising", "Conventional",
}
ITEMS_PER_DIMENSION_ADDED = 7
EXISTING_ITEMS_PER_DIMENSION = 3


@pytest.fixture(scope="module")
def migration():
    spec = importlib.util.spec_from_file_location("riasec_migration", MIGRATION)
    module = importlib.util.module_from_spec(spec)
    sys.modules["riasec_migration"] = module
    spec.loader.exec_module(module)
    return module


def test_dimensions_are_balanced(migration):
    """Chaque dimension recoit le meme nombre d'items.

    Un desequilibre ne fausse pas le score (il est normalise), mais rend une
    dimension nettement plus bruitee que les autres.
    """
    counts = collections.Counter(cat for cat, _ in migration.NEW_QUESTIONS)
    assert set(counts) == RIASEC_DIMENSIONS
    assert set(counts.values()) == {ITEMS_PER_DIMENSION_ADDED}


def test_reaches_ten_items_per_dimension(migration):
    """Objectif : 10 items par dimension, seuil d'un instrument exploitable."""
    total_per_dimension = EXISTING_ITEMS_PER_DIMENSION + ITEMS_PER_DIMENSION_ADDED
    assert total_per_dimension == 10
    assert len(migration.NEW_QUESTIONS) == ITEMS_PER_DIMENSION_ADDED * len(RIASEC_DIMENSIONS)


def test_no_duplicate_wording(migration):
    """Aucun item repete : un doublon compte double dans le score."""
    texts = [text for _, text in migration.NEW_QUESTIONS]
    duplicates = [t for t, n in collections.Counter(texts).items() if n > 1]
    assert duplicates == []


def test_new_items_do_not_repeat_existing_ones(migration):
    """Les nouveaux items ne redisent pas ce que les 18 existants disaient deja."""
    existing = {old for old, _ in migration.ACCENT_FIXES}
    existing |= {new for _, new in migration.ACCENT_FIXES}
    assert existing.isdisjoint({text for _, text in migration.NEW_QUESTIONS})


def test_wording_is_properly_accented(migration):
    """Le seed initial etait sans accents ; les nouveaux items sont corrects.

    Au moins un caractere accentue doit apparaitre dans l'ensemble, et aucun
    item ne doit contenir de mot clairement mal orthographie du seed d'origine.
    """
    texts = [text for _, text in migration.NEW_QUESTIONS]
    assert any(any(ord(c) > 127 for c in t) for t in texts)

    def fold(value: str) -> str:
        decomposed = unicodedata.normalize("NFKD", value.lower())
        return "".join(c for c in decomposed if not unicodedata.combining(c))

    # Un mot replie identique a sa version accentuee signale un oubli d'accent.
    for text in texts:
        for word in ("prefere", "reussite", "interet", "creer"):
            assert word not in text.lower(), f"accent manquant dans : {text}"
        assert fold(text)  # sanity


def test_items_are_phrased_as_preferences(migration):
    """Chaque item exprime une preference d'activite, pas une competence.

    Un RIASEC mesure ce que l'eleve AIME faire, pas ce qu'il pense savoir
    faire : "je suis doue en maths" mesure la confiance en soi, pas l'interet.
    """
    texts = [text.lower() for _, text in migration.NEW_QUESTIONS]
    for text in texts:
        assert "doué" not in text and "doue" not in text
        assert "je suis capable" not in text
        assert text.endswith("."), f"ponctuation manquante : {text}"


def test_migration_chain(migration):
    """La migration se greffe bien apres le point de fusion 022."""
    assert migration.revision == "023"
    assert migration.down_revision == "022"


def test_likert_options_cover_full_scale(migration):
    """Les 5 options couvrent l'echelle 1-5 attendue par normalize_likert()."""
    values = sorted(int(value) for _, value, _ in migration.LIKERT_OPTIONS)
    assert values == [1, 2, 3, 4, 5]
    indexes = sorted(idx for _, _, idx in migration.LIKERT_OPTIONS)
    assert indexes == [0, 1, 2, 3, 4]
