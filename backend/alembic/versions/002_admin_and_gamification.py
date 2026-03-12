"""Admin roles and gamification tables

Revision ID: 002
Revises: 001
Create Date: 2025-01-01 00:01:00.000000

"""
from typing import Sequence, Union
from alembic import op

revision: str = "002"
down_revision: Union[str, None] = "001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Ajouter la colonne role si elle n'existe pas (safety)
    op.execute("""
        DO $$ BEGIN
            ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'student'
                CHECK (role IN ('student', 'admin', 'super_admin'));
        EXCEPTION WHEN duplicate_column THEN NULL;
        END $$
    """)

    # Ajouter is_active si elle n'existe pas
    op.execute("""
        ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE
    """)

    # Tables de gamification
    op.execute("""
        CREATE TABLE IF NOT EXISTS challenges (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            title TEXT NOT NULL,
            description TEXT,
            points INTEGER DEFAULT 0,
            challenge_type TEXT DEFAULT 'quiz',
            is_active BOOLEAN DEFAULT TRUE,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        )
    """)

    op.execute("""
        CREATE TABLE IF NOT EXISTS user_challenges (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
            challenge_id UUID NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
            status TEXT DEFAULT 'not_started' CHECK (status IN ('not_started', 'in_progress', 'completed')),
            score INTEGER DEFAULT 0,
            completed_at TIMESTAMPTZ,
            created_at TIMESTAMPTZ DEFAULT NOW()
        )
    """)

    op.execute("""
        CREATE TABLE IF NOT EXISTS user_achievements (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
            achievement_type TEXT NOT NULL,
            achievement_data JSONB DEFAULT '{}',
            earned_at TIMESTAMPTZ DEFAULT NOW()
        )
    """)


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS user_achievements CASCADE")
    op.execute("DROP TABLE IF EXISTS user_challenges CASCADE")
    op.execute("DROP TABLE IF EXISTS challenges CASCADE")
