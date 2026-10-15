"""schools.is_public : cesser d'affirmer un statut jamais renseigne.

Constat
-------
Les 133 etablissements de la production portaient tous `is_public = true`.
Ce n'etait pas une donnee mais un defaut : la colonne est declaree
`is_public BOOLEAN DEFAULT TRUE` dans le schema.sql historique, et l'import
ne l'a jamais renseignee. Le code repetait ensuite le meme defaut a chaque
couche (`s.get("is_public", True)` cote API, `?? true` cote Flutter), si bien
qu'une valeur absente redevenait "publique" trois fois de suite.

Consequence visible : l'application affichait le badge "Publique" sur des
etablissements que la liste du MESR classe en `prive` — ESIBA Business School,
Institut Polytechnique Jameson, Adaptation Finance Academy, entre autres. Pour
une famille, public ou prive est l'attribut le plus determinant apres la
filiere, puisqu'il commande le cout.

Ce que fait la migration
------------------------
1. supprime le DEFAULT, pour que toute ligne creee sans statut reste NULL
   au lieu d'etre declaree publique ;
2. remet les valeurs existantes a NULL, car aucune n'a ete verifiee : ce sont
   toutes des defauts. NULL signifie desormais "inconnu", et l'application
   masque le badge dans ce cas.

Le statut reel est ensuite ecrit par
`scripts/tag_secteur_mesr.py`, qui le lit dans la colonne `secteur` de
docs/reference_mesr_<annee>.csv (13 public / 98 prive). Cette migration et ce
script se lancent l'un derriere l'autre : entre les deux, aucun badge
public/prive n'est affiche.

Aucune information n'est perdue : la remise a NULL efface des defauts, pas des
observations, et la reference MESR restitue les etablissements publics.

Revision ID: 029
Revises: 028
Create Date: 2026-08-25
"""
from alembic import op

revision = '029'
down_revision = '028'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # La base de production vient d'un schema.sql que les migrations ne
    # declarent pas : on verifie l'existence de la colonne plutot que de la
    # supposer.
    op.execute("""
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'public'
           AND table_name = 'schools'
           AND column_name = 'is_public'
    ) THEN
        ALTER TABLE schools ALTER COLUMN is_public DROP DEFAULT;
        UPDATE schools SET is_public = NULL WHERE is_public IS NOT NULL;
    END IF;
END $$;
""")


def downgrade() -> None:
    # On retablit le DEFAULT pour revenir a la structure d'origine, mais SANS
    # reecrire `true` sur les lignes : ce serait reintroduire l'affirmation
    # que cette migration corrige.
    op.execute("""
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'public'
           AND table_name = 'schools'
           AND column_name = 'is_public'
    ) THEN
        ALTER TABLE schools ALTER COLUMN is_public SET DEFAULT TRUE;
    END IF;
END $$;
""")
