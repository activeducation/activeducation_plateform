"""Marque l'agrement MESR sur les fiches `schools`.

Rapproche la table `schools` de la liste officielle du ministere
(`docs/reference_mesr_<annee>.csv`) et ecrit le millesime dans la colonne
`schools.accreditations` (text[]). Rien n'est supprime : une fiche non agreee
est simplement laissee sans marqueur, ce qui permet ensuite de filtrer cote
app ou de decider d'un retrait en connaissance de cause.

Le rapprochement suit trois voies, de la plus sure a la plus souple :
    1. alias manuels (`docs/alias_etablissements.csv`) — renommages officiels,
    2. acronyme entre parentheses,
    3. nom normalise, puis inclusion, puis similarite.

Attention a la RLS : la policy `schools_public_read` (migration 007) expose
`is_active = true AND is_verified = true`. Une fiche importee avec
`is_verified = false` est donc INVISIBLE de l'API publique, agrement ou non.
`--publier` leve ce verrou pour les fiches portant le millesime : figurer sur
la liste du ministere est precisement ce qui les verifie.

Usage :
    cd backend
    python scripts/tag_accreditation_mesr.py --dry-run
    python scripts/tag_accreditation_mesr.py
    python scripts/tag_accreditation_mesr.py --publier     # is_verified=true si agreee
    python scripts/tag_accreditation_mesr.py --retirer     # enleve le marqueur

Options :
    --millesime  libelle ecrit dans accreditations (defaut "MESR 2026-2027")
    --reference  CSV de reference (defaut docs/reference_mesr_2026_2027.csv)
"""

from __future__ import annotations

import argparse
import csv
import difflib
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from import_etablissements_xlsx import normalize, acronyms, get_client, fetch_schools  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_REF = ROOT / "docs" / "reference_mesr_2026_2027.csv"
ALIAS = ROOT / "docs" / "alias_etablissements.csv"


def acronym_keys(name: str) -> list[str]:
    """Acronyme brut + racine avant le premier tiret (ESA-Lome et Kara -> ESA)."""
    keys = []
    for a in acronyms(name):
        flat = a.replace(" ", "").upper()
        keys.append(flat)
        keys.append(re.split(r"[-\s]", a.replace(" ", "-"))[0].upper())
    return keys


def load_reference(path: Path) -> tuple[dict, dict]:
    rows = list(csv.DictReader(path.open(encoding="utf-8-sig"), delimiter=";"))
    by_name = {normalize(r["nom_mesr"]): r for r in rows}
    by_acro: dict[str, dict] = {}
    for r in rows:
        for key in acronym_keys(r["nom_mesr"]):
            by_acro.setdefault(key, r)
    return by_name, by_acro


def load_alias() -> dict[str, str]:
    if not ALIAS.exists():
        return {}
    return {a["nom_en_base"]: a["nom_mesr_2026_2027"]
            for a in csv.DictReader(ALIAS.open(encoding="utf-8-sig"), delimiter=";")}


def match(name: str, by_name: dict, by_acro: dict, alias: dict):
    if name in alias:
        target = normalize(alias[name])
        if target in by_name:
            return by_name[target], "alias"
    for key in acronym_keys(name):
        if key in by_acro:
            return by_acro[key], "acronyme"
    for key in (normalize(name), normalize(re.sub(r"\(.*?\)", "", name))):
        if key in by_name:
            return by_name[key], "nom"
        sub = [v for k, v in by_name.items() if len(key) > 14 and (key in k or k in key)]
        if sub:
            return sub[0], "inclusion"
        close = difflib.get_close_matches(key, list(by_name), n=1, cutoff=0.86)
        if close:
            return by_name[close[0]], "similarite"
    return None, ""


def main() -> int:
    parser = argparse.ArgumentParser(description="Marque l'agrement MESR sur schools.accreditations")
    parser.add_argument("--millesime", default="MESR 2026-2027")
    parser.add_argument("--reference", type=Path, default=DEFAULT_REF)
    parser.add_argument("--retirer", action="store_true", help="retire le marqueur au lieu de l'ajouter")
    parser.add_argument("--publier", action="store_true",
                        help="passe is_verified=true sur les fiches agreees (visibilite RLS)")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    if not args.reference.exists():
        print(f"ERREUR : reference introuvable {args.reference}", file=sys.stderr)
        return 1

    by_name, by_acro = load_reference(args.reference)
    alias = load_alias()
    client = get_client()
    schools = (client.table("schools")
               .select("id, name, accreditations, is_verified").execute().data or [])

    a_ecrire, non_agrees = [], []
    for s in schools:
        ref, how = match(s["name"], by_name, by_acro, alias)
        current = list(s.get("accreditations") or [])
        if args.retirer:
            if args.millesime in current:
                a_ecrire.append((s, {"accreditations": [x for x in current if x != args.millesime]}, "retrait"))
            continue
        if not ref:
            non_agrees.append(s)
            continue
        patch: dict = {}
        if args.millesime not in current:
            patch["accreditations"] = current + [args.millesime]
        if args.publier and not s.get("is_verified"):
            patch["is_verified"] = True
        if patch:
            a_ecrire.append((s, patch, how))

    verbe = "retirer" if args.retirer else "mettre a jour"
    print(f"{len(schools)} fiches | a {verbe} : {len(a_ecrire)}")
    if args.publier:
        n_pub = sum(1 for _s, p, _h in a_ecrire if "is_verified" in p)
        print(f"   dont passage is_verified=true : {n_pub}")
    if not args.retirer:
        print(f"non agreees (laissees intactes) : {len(non_agrees)}")
        for s in non_agrees:
            print(f"   - {s['name'][:70]}")

    if args.dry_run:
        print("\n--dry-run : aucune ecriture.")
        return 0

    done = 0
    for s, patch, _how in a_ecrire:
        try:
            client.table("schools").update(patch).eq("id", s["id"]).execute()
            done += 1
        except Exception as exc:  # noqa: BLE001
            print(f"  ECHEC {s['name']} : {exc}", file=sys.stderr)
    print(f"\n{done}/{len(a_ecrire)} fiche(s) mise(s) a jour.")
    return 0 if done == len(a_ecrire) else 1


if __name__ == "__main__":
    raise SystemExit(main())
