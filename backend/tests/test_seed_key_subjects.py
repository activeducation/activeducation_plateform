"""Tests de la deduction des matieres cles (script seed_key_subjects).

Charge la fonction pure depuis le script via importlib (pas de connexion DB :
la partie Supabase vit dans main(), non executee a l'import).
"""

import importlib.util
from pathlib import Path

_MODULE_PATH = Path(__file__).resolve().parents[1] / "scripts" / "seed_key_subjects.py"
_spec = importlib.util.spec_from_file_location("seed_key_subjects", _MODULE_PATH)
_seed = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_seed)
infer_key_subjects = _seed.infer_key_subjects


def test_name_keyword_takes_priority_over_sector_and_riasec():
    # Nom "developpeur" -> Informatique, meme si secteur/RIASEC diraient autre chose.
    subs = infer_key_subjects("Développeur logiciel", "Santé", ["S"])
    assert "Informatique" in subs


def test_sector_used_when_name_has_no_keyword():
    subs = infer_key_subjects("Métier générique", "Santé & Bien-être", [])
    assert "SVT" in subs


def test_riasec_fallback_when_no_name_or_sector_match():
    subs = infer_key_subjects("Métier obscur", "Secteur inconnu", ["I"])
    assert "Mathématiques" in subs
    assert "Physique" in subs


def test_default_when_nothing_matches():
    assert infer_key_subjects("Zzz", "Yyy", []) == ["Mathématiques", "Français", "Anglais"]


def test_result_is_capped_and_deduplicated():
    subs = infer_key_subjects("obscur", "inconnu", ["I", "R", "I"])
    assert len(subs) <= 5
    assert len(subs) == len(set(subs))


def test_sector_matching_is_accent_and_case_insensitive():
    subs = infer_key_subjects("X", "SANTE", [])  # sans accent, majuscules
    assert "SVT" in subs
