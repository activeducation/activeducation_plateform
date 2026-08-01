"""Add enriched columns to schools table.

Adds columns for data from the National Database of Higher Education
Institutions: region, GPS coordinates, degrees offered, admission info,
tuition range, student count, and infrastructure metadata.

Revision ID: 021
Revises: 020
Create Date: 2026-07-22
"""
from alembic import op

revision = "021"
down_revision = "020"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("""
        ALTER TABLE schools
            ADD COLUMN IF NOT EXISTS region          TEXT,
            ADD COLUMN IF NOT EXISTS latitude        DOUBLE PRECISION,
            ADD COLUMN IF NOT EXISTS longitude       DOUBLE PRECISION,
            ADD COLUMN IF NOT EXISTS degrees_offered TEXT,
            ADD COLUMN IF NOT EXISTS admission_info  TEXT,
            ADD COLUMN IF NOT EXISTS infrastructure  JSONB DEFAULT '{}'::jsonb;
    """)


def downgrade() -> None:
    op.execute("""
        ALTER TABLE schools
            DROP COLUMN IF EXISTS region,
            DROP COLUMN IF EXISTS latitude,
            DROP COLUMN IF EXISTS longitude,
            DROP COLUMN IF EXISTS degrees_offered,
            DROP COLUMN IF EXISTS admission_info,
            DROP COLUMN IF EXISTS infrastructure;
    """)
