"""Admin creation fixes and RLS configuration (v3+v4 SQL scripts)

Revision ID: 004
Revises: 003
Create Date: 2025-01-01 00:03:00.000000

"""
from typing import Sequence, Union
from alembic import op

revision: str = "004"
down_revision: Union[str, None] = "003"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # v3: Colonnes manquantes sur orientation_tests
    op.execute("ALTER TABLE orientation_tests ADD COLUMN IF NOT EXISTS display_order INTEGER DEFAULT 0")
    op.execute("ALTER TABLE orientation_tests ADD COLUMN IF NOT EXISTS image_url TEXT")

    # Mettre à jour la contrainte de type pour orientation_tests
    op.execute("ALTER TABLE orientation_tests DROP CONSTRAINT IF EXISTS orientation_tests_type_check")
    op.execute("""
        ALTER TABLE orientation_tests ADD CONSTRAINT orientation_tests_type_check
            CHECK (type IN ('riasec', 'personality', 'skills', 'interests', 'aptitude'))
    """)

    # v4: Désactiver RLS pour les tables gérées par le backend
    # (le backend API gère la sécurité via les tokens et les dépendances FastAPI)
    op.execute("ALTER TABLE orientation_tests DISABLE ROW LEVEL SECURITY")
    op.execute("ALTER TABLE test_questions DISABLE ROW LEVEL SECURITY")
    op.execute("ALTER TABLE question_options DISABLE ROW LEVEL SECURITY")
    op.execute("ALTER TABLE user_test_sessions DISABLE ROW LEVEL SECURITY")
    op.execute("ALTER TABLE careers DISABLE ROW LEVEL SECURITY")
    op.execute("ALTER TABLE career_sectors DISABLE ROW LEVEL SECURITY")
    op.execute("ALTER TABLE user_profiles DISABLE ROW LEVEL SECURITY")

    # Tables de gamification (IF EXISTS via DO block)
    op.execute("""
        DO $$ BEGIN
            ALTER TABLE user_achievements DISABLE ROW LEVEL SECURITY;
        EXCEPTION WHEN undefined_table THEN NULL;
        END $$
    """)
    op.execute("""
        DO $$ BEGIN
            ALTER TABLE challenges DISABLE ROW LEVEL SECURITY;
        EXCEPTION WHEN undefined_table THEN NULL;
        END $$
    """)
    op.execute("""
        DO $$ BEGIN
            ALTER TABLE user_challenges DISABLE ROW LEVEL SECURITY;
        EXCEPTION WHEN undefined_table THEN NULL;
        END $$
    """)
    op.execute("""
        DO $$ BEGIN
            ALTER TABLE schools DISABLE ROW LEVEL SECURITY;
        EXCEPTION WHEN undefined_table THEN NULL;
        END $$
    """)


def downgrade() -> None:
    # Réactiver RLS si on revient en arrière
    op.execute("ALTER TABLE orientation_tests ENABLE ROW LEVEL SECURITY")
    op.execute("ALTER TABLE test_questions ENABLE ROW LEVEL SECURITY")
    op.execute("ALTER TABLE question_options ENABLE ROW LEVEL SECURITY")
    op.execute("ALTER TABLE user_test_sessions ENABLE ROW LEVEL SECURITY")
    op.execute("ALTER TABLE careers ENABLE ROW LEVEL SECURITY")
    op.execute("ALTER TABLE career_sectors ENABLE ROW LEVEL SECURITY")
    op.execute("ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY")
    op.execute("ALTER TABLE orientation_tests DROP COLUMN IF EXISTS image_url")
    op.execute("ALTER TABLE orientation_tests DROP COLUMN IF EXISTS display_order")
