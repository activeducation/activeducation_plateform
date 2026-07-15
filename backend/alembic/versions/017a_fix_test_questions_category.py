"""Aligne test_questions.category avec le code (derive de schema).

Contexte
--------
La migration 001 cree la colonne `riasec_dimension`, mais TOUT le code
(endpoints, moteur d'orientation, back-office) lit et ecrit `category` :
  - app/api/v1/endpoints/orientation.py        -> q.get("category")
  - app/services/orientation_engine.py         -> q.get("category")
  - app/repositories/admin/tests_repository.py -> category=...
`riasec_dimension` n'est reference nulle part dans app/.

Consequence sur une base issue des migrations : `category` est absente, donc
la categorie de chaque question vaut None, aucun score RIASEC n'est accumule,
les 6 scores tombent a 0, dominant_traits est vide et le moteur ne renvoie
AUCUNE recommandation de metier -- silencieusement, sans erreur.

Cette migration retablit `category` comme unique source de verite.
Elle est idempotente et couvre les 4 etats possibles de la base, car
certaines bases ont recu `category` a la main, hors migration.

Numerotation
------------
Revision '017a' (et non '018') : la branche TutorAI possede deja une revision
'018' (018_tutor_foundations). Se greffer sur '017' avec un identifiant
distinct evite toute collision d'identifiant Alembic lors de la fusion.
A la fusion de TutorAI, les deux tetes ('017a' et '020') se resolvent avec un
`alembic merge -m "merge tutor + fix category" 017a 020`.

Revision ID: 017a
Revises: 017
Create Date: 2026-07-15
"""
from alembic import op

revision = '017a'
down_revision = '017'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("""
DO $$
DECLARE
    has_category BOOLEAN;
    has_riasec   BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'test_questions' AND column_name = 'category'
    ) INTO has_category;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'test_questions' AND column_name = 'riasec_dimension'
    ) INTO has_riasec;

    IF has_riasec AND NOT has_category THEN
        -- Cas nominal (base construite par les migrations) : simple renommage,
        -- les eventuelles valeurs deja saisies sont conservees.
        ALTER TABLE test_questions RENAME COLUMN riasec_dimension TO category;

    ELSIF has_riasec AND has_category THEN
        -- Base deja patchee a la main : on rapatrie ce qui ne serait que dans
        -- riasec_dimension, puis on supprime la colonne redondante.
        UPDATE test_questions
           SET category = riasec_dimension
         WHERE category IS NULL AND riasec_dimension IS NOT NULL;
        ALTER TABLE test_questions DROP COLUMN riasec_dimension;

    ELSIF NOT has_riasec AND NOT has_category THEN
        -- Ni l'une ni l'autre : on cree la colonne attendue par le code.
        ALTER TABLE test_questions ADD COLUMN category TEXT;

    END IF;
    -- has_category AND NOT has_riasec : deja aligne, rien a faire.
END $$;
""")


def downgrade() -> None:
    op.execute("""
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'test_questions' AND column_name = 'category'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'test_questions' AND column_name = 'riasec_dimension'
    ) THEN
        ALTER TABLE test_questions RENAME COLUMN category TO riasec_dimension;
    END IF;
END $$;
""")
