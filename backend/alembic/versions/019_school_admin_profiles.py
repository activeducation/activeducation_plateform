"""Create school_admin_profiles table.

school_admin_profiles links user_profiles (role=school_admin) to their
managed school. Created idempotently — the raw v5_school_dashboard.sql
may have already created it.

Revision ID: 019
Revises: 018
Create Date: 2026-07-21
"""
from alembic import op

revision = '019'
down_revision = '018'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("""
        CREATE TABLE IF NOT EXISTS school_admin_profiles (
            id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id     UUID NOT NULL UNIQUE REFERENCES user_profiles(id) ON DELETE CASCADE,
            school_id   UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
            position    TEXT,
            is_active   BOOLEAN NOT NULL DEFAULT TRUE,
            created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );
    """)
    op.execute("""
        CREATE INDEX IF NOT EXISTS idx_school_admin_profiles_user_id
            ON school_admin_profiles(user_id);
    """)
    op.execute("""
        CREATE INDEX IF NOT EXISTS idx_school_admin_profiles_school_id
            ON school_admin_profiles(school_id);
    """)
    # Trigger updated_at — tolerate if function doesn't exist yet
    op.execute("""
        DO $$ BEGIN
            CREATE TRIGGER update_school_admin_profiles_updated_at
                BEFORE UPDATE ON school_admin_profiles
                FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        EXCEPTION WHEN undefined_function THEN NULL;
        END $$;
    """)


def downgrade() -> None:
    op.execute("DROP TRIGGER IF EXISTS update_school_admin_profiles_updated_at ON school_admin_profiles;")
    op.execute("DROP TABLE IF EXISTS school_admin_profiles CASCADE;")
