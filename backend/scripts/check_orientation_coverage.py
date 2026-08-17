#!/usr/bin/env python3
"""Verifie que chaque test d'orientation peut reellement recommander des metiers.

POURQUOI CE SCRIPT
------------------
Les metiers ne sont indexes que par des traits RIASEC (+ intelligences de
Gardner) dans `careers.related_traits`. Chaque test, lui, definit ses propres
dimensions dans `test_questions.category` ("Leadership", "Visuel",
"Securite"...). Si les deux vocabulaires ne se croisent pas -- directement ou
via la table de projection DIMENSION_TO_RIASEC -- le test produit une liste de
recommandations VIDE, sans la moindre erreur dans les logs.

C'est un echec SILENCIEUX : l'eleve repond a 24 questions et n'obtient rien.
Ce script rend le probleme visible, et sert de garde-fou apres l'ajout d'un
test ou d'une dimension.

USAGE
-----
    cd backend
    python scripts/check_orientation_coverage.py
    python scripts/check_orientation_coverage.py --api https://api.mondomaine.com

Code de sortie 1 si au moins un test ne peut rien recommander : utilisable en
CI ou en verification post-deploiement.
"""
from __future__ import annotations

import argparse
import json
import sys
import urllib.request
from pathlib import Path

# Permet d'importer app.* en lançant le script depuis backend/
BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

# Variables minimales pour instancier Settings sans .env complet.
import os
os.environ.setdefault("SUPABASE_URL", "https://placeholder.supabase.co")
os.environ.setdefault("SUPABASE_KEY", "placeholder")
os.environ.setdefault("SUPABASE_SERVICE_ROLE_KEY", "placeholder")
os.environ.setdefault("SECRET_KEY", "placeholder_secret_key_32_characters_min")
os.environ.setdefault("ENVIRONMENT", "development")

from app.services.orientation_engine import (  # noqa: E402
    DIMENSION_TO_RIASEC,
    EN_TO_FR,
    RIASEC_FR,
    project_to_riasec,
)

DEFAULT_API = "https://api.activeducationhub.com"


def fetch(url: str) -> list[dict]:
    with urllib.request.urlopen(url, timeout=30) as response:
        payload = json.load(response)
    if isinstance(payload, list):
        return payload
    return payload.get("items") or payload.get("data") or []


def strip_accents(text: str) -> str:
    import unicodedata

    if not isinstance(text, str):
        return ""
    decomposed = unicodedata.normalize("NFKD", text)
    return "".join(c for c in decomposed if not unicodedata.combining(c))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--api", default=DEFAULT_API, help="URL de base de l'API")
    args = parser.parse_args()

    base = f"{args.api.rstrip('/')}/api/v1/orientation"
    try:
        tests = fetch(f"{base}/mobile/tests")
        careers = fetch(f"{base}/mobile/careers")
    except Exception as exc:  # pragma: no cover - outil de diagnostic
        print(f"ERREUR : impossible d'interroger {base} ({exc})")
        return 2

    # Vocabulaire reellement present sur les metiers, accents replies.
    vocabulary: set[str] = set()
    for career in careers:
        for trait in career.get("relatedTraits") or career.get("related_traits") or []:
            vocabulary.add(trait)
            vocabulary.add(strip_accents(trait))

    print(f"Metiers analyses  : {len(careers)}")
    print(f"Traits distincts  : {len(vocabulary)}")
    print(f"Tests analyses    : {len(tests)}\n")

    header = f"{'TEST':<44}{'Q':>4}{'DIRECT':>8}{'PROJETE':>9}  ETAT"
    print(header)
    print("-" * len(header))

    failing: list[str] = []
    unmapped: set[str] = set()

    for test in tests:
        questions = test.get("questions") or []
        dimensions = sorted({q.get("category") for q in questions if q.get("category")})
        # Le moteur convertit les libelles RIASEC anglais en francais.
        profile = [EN_TO_FR.get(d, d) for d in dimensions]

        direct = {p for p in profile if p in vocabulary}
        projected, _ = project_to_riasec(profile, {})
        effective = set(profile) | set(projected)
        effective |= {strip_accents(e) for e in effective}
        covered = effective & vocabulary

        name = str(test.get("name"))[:43]
        if covered:
            state = "OK"
        else:
            state = "*** AUCUNE RECOMMANDATION ***"
            failing.append(name)

        print(f"{name:<44}{len(questions):>4}{len(direct):>8}{len(covered):>9}  {state}")

        for dimension in profile:
            known = dimension in RIASEC_FR or dimension in DIMENSION_TO_RIASEC
            if not known:
                unmapped.add(dimension)

    print("-" * len(header))

    if unmapped:
        print("\nDimensions sans projection RIASEC (ajouter a DIMENSION_TO_RIASEC")
        print("dans app/services/orientation_engine.py si elles decrivent des interets) :")
        for dimension in sorted(unmapped):
            print(f"  - {dimension}")

    if failing:
        print(f"\nECHEC : {len(failing)} test(s) ne peuvent recommander aucun metier.")
        print("Deux corrections possibles :")
        print("  1. projeter leurs dimensions vers le RIASEC (DIMENSION_TO_RIASEC) ;")
        print("  2. enrichir careers.related_traits depuis le back-office.")
        return 1

    print("\nOK : chaque test peut produire des recommandations.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
