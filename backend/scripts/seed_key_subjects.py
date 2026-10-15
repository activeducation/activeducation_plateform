"""Script de seed — matieres cles (key_subjects) des metiers.

Pre-remplit `careers.key_subjects` pour activer le critere "notes" du moteur
d'orientation multi-criteres, sans saisie manuelle initiale. La deduction va
du plus precis au plus general :
    1. mots-cles du NOM du metier (ex: "developpeur" -> Informatique),
    2. sinon le SECTEUR (ex: "Sante" -> SVT/Physique/Chimie),
    3. sinon les CODES RIASEC du metier,
    4. sinon un defaut generaliste.

Idempotent : par defaut ne touche QUE les metiers dont key_subjects est vide
(ne pas ecraser les ajustements faits via l'admin). --force pour tout recalculer.

Usage :
    cd backend
    python scripts/seed_key_subjects.py --dry-run   # apercu sans ecrire
    python scripts/seed_key_subjects.py             # remplit les vides
    python scripts/seed_key_subjects.py --force      # recalcule tout

Prerequis :
    - .env avec SUPABASE_URL et SUPABASE_SERVICE_ROLE_KEY
    - migration 021 appliquee (colonne careers.key_subjects)
"""

from __future__ import annotations

import argparse
import sys
import unicodedata
from pathlib import Path

# Vocabulaire de matieres (labels simples, alignes sur ce qu'un eleve saisit
# comme notes — le moteur fait une correspondance exacte apres normalisation).
MATHS = "Mathématiques"
PHYSIQUE = "Physique"
CHIMIE = "Chimie"
SVT = "SVT"
FRANCAIS = "Français"
PHILO = "Philosophie"
HISTOIRE = "Histoire"
GEO = "Géographie"
ANGLAIS = "Anglais"
ECO = "Économie"
COMPTA = "Comptabilité"
INFO = "Informatique"
ARTS = "Arts plastiques"

# 1. Mots-cles du NOM du metier (normalises : minuscules sans accents).
NAME_SUBJECTS: dict[str, list[str]] = {
    "developp": [MATHS, INFO, PHYSIQUE],
    "informatic": [MATHS, INFO, PHYSIQUE],
    "data": [MATHS, INFO, PHYSIQUE],
    "cyber": [MATHS, INFO, PHYSIQUE],
    "reseau": [MATHS, INFO, PHYSIQUE],
    "logiciel": [MATHS, INFO, PHYSIQUE],
    "medecin": [SVT, PHYSIQUE, CHIMIE],
    "infirm": [SVT, CHIMIE, FRANCAIS],
    "pharmac": [SVT, CHIMIE, PHYSIQUE],
    "sage-femme": [SVT, CHIMIE, FRANCAIS],
    "kinesi": [SVT, PHYSIQUE, CHIMIE],
    "avocat": [FRANCAIS, PHILO, HISTOIRE],
    "juriste": [FRANCAIS, PHILO, HISTOIRE],
    "notaire": [FRANCAIS, PHILO, ECO],
    "magistrat": [FRANCAIS, PHILO, HISTOIRE],
    "comptable": [MATHS, COMPTA, ECO],
    "financ": [MATHS, ECO, COMPTA],
    "auditeur": [MATHS, COMPTA, ECO],
    "banqu": [MATHS, ECO, COMPTA],
    "ingenieur": [MATHS, PHYSIQUE, CHIMIE],
    "architecte": [MATHS, PHYSIQUE, ARTS],
    "technicien": [MATHS, PHYSIQUE, INFO],
    "professeur": [FRANCAIS, PHILO, MATHS],
    "enseignant": [FRANCAIS, PHILO, MATHS],
    "journalist": [FRANCAIS, ANGLAIS, HISTOIRE],
    "graphi": [ARTS, FRANCAIS, INFO],
    "design": [ARTS, FRANCAIS, INFO],
    "agronom": [SVT, CHIMIE, PHYSIQUE],
    "agricol": [SVT, CHIMIE, GEO],
    "commercial": [ECO, FRANCAIS, MATHS],
    "marketing": [ECO, FRANCAIS, ANGLAIS],
    "entrepreneur": [ECO, MATHS, FRANCAIS],
    "psycholog": [SVT, PHILO, FRANCAIS],
    "traduc": [FRANCAIS, ANGLAIS, PHILO],
}

# 2. Mots-cles du SECTEUR.
SECTOR_SUBJECTS: dict[str, list[str]] = {
    "informatique": [MATHS, INFO, PHYSIQUE],
    "numerique": [MATHS, INFO, PHYSIQUE],
    "technolog": [MATHS, PHYSIQUE, INFO],
    "sante": [SVT, PHYSIQUE, CHIMIE],
    "medic": [SVT, PHYSIQUE, CHIMIE],
    "pharma": [SVT, CHIMIE, PHYSIQUE],
    "ingenier": [MATHS, PHYSIQUE, CHIMIE],
    "genie": [MATHS, PHYSIQUE, CHIMIE],
    "btp": [MATHS, PHYSIQUE, GEO],
    "batiment": [MATHS, PHYSIQUE, GEO],
    "industrie": [MATHS, PHYSIQUE, CHIMIE],
    "mecani": [MATHS, PHYSIQUE, INFO],
    "electr": [MATHS, PHYSIQUE, INFO],
    "finance": [MATHS, ECO, COMPTA],
    "banque": [MATHS, ECO, COMPTA],
    "comptab": [MATHS, COMPTA, ECO],
    "gestion": [MATHS, ECO, COMPTA],
    "commerce": [ECO, FRANCAIS, MATHS],
    "vente": [ECO, FRANCAIS, ANGLAIS],
    "marketing": [ECO, FRANCAIS, ANGLAIS],
    "droit": [FRANCAIS, PHILO, HISTOIRE],
    "administration": [FRANCAIS, ECO, HISTOIRE],
    "juridique": [FRANCAIS, PHILO, HISTOIRE],
    "education": [FRANCAIS, PHILO, MATHS],
    "enseign": [FRANCAIS, PHILO, MATHS],
    "agricult": [SVT, CHIMIE, PHYSIQUE],
    "environnement": [SVT, CHIMIE, GEO],
    "agro": [SVT, CHIMIE, PHYSIQUE],
    "communication": [FRANCAIS, ANGLAIS, PHILO],
    "media": [FRANCAIS, ANGLAIS, HISTOIRE],
    "journal": [FRANCAIS, ANGLAIS, HISTOIRE],
    "art": [ARTS, FRANCAIS, ANGLAIS],
    "design": [ARTS, FRANCAIS, INFO],
    "culture": [ARTS, FRANCAIS, HISTOIRE],
    "social": [SVT, FRANCAIS, PHILO],
    "psycholog": [SVT, PHILO, FRANCAIS],
    "science": [MATHS, PHYSIQUE, SVT],
    "recherche": [MATHS, PHYSIQUE, SVT],
    "biolog": [SVT, CHIMIE, PHYSIQUE],
    "tourisme": [FRANCAIS, ANGLAIS, GEO],
    "hotel": [FRANCAIS, ANGLAIS, GEO],
    "transport": [MATHS, GEO, ECO],
    "logistique": [MATHS, GEO, ECO],
}

# 3. Fallback par code RIASEC.
RIASEC_SUBJECTS: dict[str, list[str]] = {
    "R": [PHYSIQUE, MATHS, CHIMIE],
    "I": [MATHS, PHYSIQUE, SVT],
    "A": [FRANCAIS, ARTS, ANGLAIS],
    "S": [SVT, FRANCAIS, PHILO],
    "E": [ECO, MATHS, FRANCAIS],
    "C": [MATHS, COMPTA, ECO],
}

# 4. Defaut generaliste.
DEFAULT_SUBJECTS = [MATHS, FRANCAIS, ANGLAIS]

MAX_SUBJECTS = 5


def _normalize(text: str) -> str:
    if not text:
        return ""
    decomposed = unicodedata.normalize("NFKD", str(text))
    stripped = "".join(c for c in decomposed if not unicodedata.combining(c))
    return stripped.lower()


def _dedupe(items: list[str]) -> list[str]:
    seen: set[str] = set()
    out: list[str] = []
    for item in items:
        if item not in seen:
            seen.add(item)
            out.append(item)
    return out


def infer_key_subjects(
    name: str,
    sector_name: str,
    riasec_codes: list[str] | None,
) -> list[str]:
    """Deduit les matieres cles d'un metier (nom > secteur > RIASEC > defaut)."""
    norm_name = _normalize(name)
    for keyword, subjects in NAME_SUBJECTS.items():
        if keyword in norm_name:
            return _dedupe(subjects)[:MAX_SUBJECTS]

    norm_sector = _normalize(sector_name)
    for keyword, subjects in SECTOR_SUBJECTS.items():
        if keyword in norm_sector:
            return _dedupe(subjects)[:MAX_SUBJECTS]

    collected: list[str] = []
    for code in (riasec_codes or []):
        collected.extend(RIASEC_SUBJECTS.get(str(code).upper(), []))
    if collected:
        return _dedupe(collected)[:MAX_SUBJECTS]

    return list(DEFAULT_SUBJECTS)


def main() -> int:
    parser = argparse.ArgumentParser(description="Seed careers.key_subjects")
    parser.add_argument("--dry-run", action="store_true", help="Apercu sans ecrire")
    parser.add_argument("--force", action="store_true",
                        help="Recalcule aussi les metiers ayant deja des key_subjects")
    args = parser.parse_args()

    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    from dotenv import load_dotenv
    load_dotenv(Path(__file__).resolve().parents[1] / ".env")

    import os
    from supabase import create_client

    url = os.environ.get("SUPABASE_URL")
    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    if not url or not key:
        print("ERREUR : SUPABASE_URL et SUPABASE_SERVICE_ROLE_KEY requis (.env).")
        return 1

    supabase = create_client(url, key)

    sectors = supabase.table("career_sectors").select("id, name").execute().data or []
    sector_map = {s["id"]: s.get("name", "") for s in sectors}

    careers = (
        supabase.table("careers")
        .select("id, name, sector_id, riasec_codes, key_subjects")
        .execute()
        .data
        or []
    )

    updated = 0
    skipped = 0
    for career in careers:
        has_subjects = bool(career.get("key_subjects"))
        if has_subjects and not args.force:
            skipped += 1
            continue

        subjects = infer_key_subjects(
            career.get("name", ""),
            sector_map.get(career.get("sector_id"), ""),
            career.get("riasec_codes") or [],
        )

        print(f"  {career.get('name', '?'):45s} -> {', '.join(subjects)}")
        if not args.dry_run:
            supabase.table("careers").update(
                {"key_subjects": subjects}
            ).eq("id", career["id"]).execute()
        updated += 1

    action = "seraient mis a jour" if args.dry_run else "mis a jour"
    print(f"\n{updated} metier(s) {action}, {skipped} ignore(s) (deja renseignes).")
    if args.dry_run:
        print("Dry-run : aucune ecriture. Relancez sans --dry-run pour appliquer.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
