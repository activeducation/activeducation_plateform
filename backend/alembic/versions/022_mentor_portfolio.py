"""Add portfolio JSONB column to mentors and mentor_applications.

Stocke les données structurées du portfolio mentor sous forme JSONB :
formations, expériences, certifications, projets, langues, liens sociaux.

Revision ID: 022
Revises: 021
Create Date: 2026-07-23
"""
from alembic import op

revision = '022'
down_revision = '021'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("""
        ALTER TABLE mentors
            ADD COLUMN IF NOT EXISTS portfolio JSONB NOT NULL DEFAULT '{}'::jsonb;
    """)
    op.execute("""
        ALTER TABLE mentor_applications
            ADD COLUMN IF NOT EXISTS portfolio JSONB DEFAULT '{}'::jsonb;
    """)


def downgrade() -> None:
    op.execute("ALTER TABLE mentors DROP COLUMN IF EXISTS portfolio;")
    op.execute("ALTER TABLE mentor_applications DROP COLUMN IF EXISTS portfolio;")
