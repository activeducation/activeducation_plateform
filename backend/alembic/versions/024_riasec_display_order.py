"""Corrige l'ordre d'affichage du questionnaire RIASEC (display_order).

Le probleme
-----------
La migration 023 a ecrit l'ordre entrelace dans `test_questions.order_index`,
colonne declaree par la migration 001. Or le code ne lit JAMAIS cette colonne :

  - orientation_repository trie les questions par `display_order` ;
  - le back-office ecrit `display_order` (schema QuestionCreate).

`order_index` est une colonne fantome. Resultat : les 60 items etaient bien
crees, mais restaient affiches dans un ordre arbitraire — cinq questions
"Investigative" d'affilee — au lieu de l'entrelacement voulu. Les 42 items
ajoutes par 023 avaient de surcroit un `display_order` a sa valeur par defaut.

Cette migration reapplique l'entrelacement sur `display_order`, la colonne
reellement utilisee, et maintient `order_index` en phase pour eviter que les
deux divergent.

Pourquoi entrelacer : dix questions consecutives sur la meme dimension
induisent un biais de halo, l'eleve devinant ce qui est mesure et repondant en
bloc plutot que question par question.

Revision ID: 024
Revises: 023
Create Date: 2026-08-19
"""
from alembic import op

revision = '024'
down_revision = '023'
branch_labels = None
depends_on = None

TEST_ID = "(SELECT id FROM orientation_tests WHERE type = 'riasec' ORDER BY created_at LIMIT 1)"

DIMENSION_ORDER = [
    "Realistic", "Investigative", "Artistic",
    "Social", "Enterprising", "Conventional",
]


def upgrade() -> None:
    # La base de production diverge des migrations : on ne suppose rien.
    op.execute("ALTER TABLE test_questions ADD COLUMN IF NOT EXISTS display_order INTEGER DEFAULT 0")

    rank_cases = " ".join(
        f"WHEN '{dim}' THEN {i}" for i, dim in enumerate(DIMENSION_ORDER)
    )

    # position_in_dimension : 1..10 au sein de chaque dimension.
    # display_order        : (position - 1) * 6 + rang_dimension  -> 0..59,
    #                        ce qui alterne R, I, A, S, E, C, R, I, ...
    op.execute(f"""
WITH ranked AS (
    SELECT
        id,
        ROW_NUMBER() OVER (
            PARTITION BY category
            ORDER BY created_at NULLS LAST, id
        ) AS position_in_dimension,
        CASE category {rank_cases} ELSE 99 END AS dimension_rank
    FROM test_questions
    WHERE test_id = {TEST_ID}
)
UPDATE test_questions tq
SET display_order = (r.position_in_dimension - 1) * 6 + r.dimension_rank,
    order_index   = (r.position_in_dimension - 1) * 6 + r.dimension_rank,
    section_title = 'Partie '
                    || ((((r.position_in_dimension - 1) * 6 + r.dimension_rank) / 10) + 1)
                    || ' sur 6'
FROM ranked r
WHERE tq.id = r.id AND r.dimension_rank <> 99
""")

    # Les options de Likert doivent elles aussi s'afficher dans l'ordre 1 -> 5.
    op.execute("ALTER TABLE question_options ADD COLUMN IF NOT EXISTS display_order INTEGER DEFAULT 0")
    op.execute("""
UPDATE question_options
SET display_order = CASE
        WHEN option_value ~ '^[0-9]+$' THEN (option_value::int - 1)
        ELSE display_order
    END
WHERE option_value ~ '^[0-9]+$'
""")


def downgrade() -> None:
    """Sans objet : reordonner n'altere aucune donnee de reponse."""
