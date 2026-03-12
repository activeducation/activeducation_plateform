"""Mobile app support — questions riches et options UI (v2_mobile_migration.sql)

Revision ID: 003
Revises: 002
Create Date: 2025-01-01 00:02:00.000000

"""
from typing import Sequence, Union
from alembic import op

revision: str = "003"
down_revision: Union[str, None] = "002"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Mettre à jour les types de questions pour l'app mobile
    op.execute("""
        ALTER TABLE test_questions DROP CONSTRAINT IF EXISTS test_questions_question_type_check
    """)
    op.execute("""
        ALTER TABLE test_questions ADD CONSTRAINT test_questions_question_type_check
            CHECK (question_type IN ('likert', 'multiple_choice', 'boolean', 'scenario', 'thisOrThat', 'ranking', 'slider'))
    """)

    # Colonnes UI pour les questions
    op.execute("ALTER TABLE test_questions ADD COLUMN IF NOT EXISTS image_asset TEXT")
    op.execute("ALTER TABLE test_questions ADD COLUMN IF NOT EXISTS section_title TEXT")
    op.execute("ALTER TABLE test_questions ADD COLUMN IF NOT EXISTS slider_left_label TEXT")
    op.execute("ALTER TABLE test_questions ADD COLUMN IF NOT EXISTS slider_right_label TEXT")

    # Convertir option_value en TEXT (pour les valeurs RIASEC textuelles)
    op.execute("""
        DO $$
        BEGIN
            IF EXISTS (
                SELECT 1
                FROM information_schema.columns
                WHERE table_name = 'question_options'
                AND column_name = 'option_value'
                AND data_type = 'integer'
            ) THEN
                ALTER TABLE question_options ALTER COLUMN option_value TYPE TEXT;
            END IF;
        END $$
    """)

    # Colonnes UI pour les options
    op.execute("ALTER TABLE question_options ADD COLUMN IF NOT EXISTS emoji TEXT")
    op.execute("ALTER TABLE question_options ADD COLUMN IF NOT EXISTS icon TEXT")


def downgrade() -> None:
    op.execute("ALTER TABLE question_options DROP COLUMN IF EXISTS icon")
    op.execute("ALTER TABLE question_options DROP COLUMN IF EXISTS emoji")
    op.execute("ALTER TABLE test_questions DROP COLUMN IF EXISTS slider_right_label")
    op.execute("ALTER TABLE test_questions DROP COLUMN IF EXISTS slider_left_label")
    op.execute("ALTER TABLE test_questions DROP COLUMN IF EXISTS section_title")
    op.execute("ALTER TABLE test_questions DROP COLUMN IF EXISTS image_asset")
