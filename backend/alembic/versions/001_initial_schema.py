"""Initial schema

Revision ID: 001
Revises:
Create Date: 2025-01-01 00:00:00.000000

"""
from typing import Sequence, Union
from alembic import op

revision: str = "001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\"")

    op.execute("""
        CREATE TABLE IF NOT EXISTS user_profiles (
            id UUID PRIMARY KEY,
            email TEXT UNIQUE NOT NULL,
            password_hash TEXT,
            reset_token TEXT,
            reset_token_expires TIMESTAMPTZ,
            first_name TEXT,
            last_name TEXT,
            display_name TEXT,
            avatar_url TEXT,
            date_of_birth DATE,
            phone_number TEXT,
            school_name TEXT,
            class_level TEXT,
            preferred_language TEXT DEFAULT 'fr',
            role TEXT DEFAULT 'student' CHECK (role IN ('student', 'admin', 'super_admin')),
            is_active BOOLEAN DEFAULT TRUE,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        )
    """)
    op.execute("CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON user_profiles(email)")

    op.execute("""
        CREATE TABLE IF NOT EXISTS orientation_tests (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            name TEXT NOT NULL,
            description TEXT,
            type TEXT NOT NULL CHECK (type IN ('riasec', 'personality', 'skills', 'interests', 'aptitude')),
            is_active BOOLEAN DEFAULT TRUE,
            display_order INTEGER DEFAULT 0,
            image_url TEXT,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        )
    """)

    op.execute("""
        CREATE TABLE IF NOT EXISTS test_questions (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            test_id UUID NOT NULL REFERENCES orientation_tests(id) ON DELETE CASCADE,
            question_text TEXT NOT NULL,
            question_type TEXT NOT NULL CHECK (
                question_type IN ('likert', 'multiple_choice', 'boolean', 'scenario', 'thisOrThat', 'ranking', 'slider')
            ),
            riasec_dimension TEXT,
            order_index INTEGER DEFAULT 0,
            image_asset TEXT,
            section_title TEXT,
            slider_left_label TEXT,
            slider_right_label TEXT,
            created_at TIMESTAMPTZ DEFAULT NOW()
        )
    """)
    op.execute("CREATE INDEX IF NOT EXISTS idx_test_questions_test_id ON test_questions(test_id)")

    op.execute("""
        CREATE TABLE IF NOT EXISTS question_options (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            question_id UUID NOT NULL REFERENCES test_questions(id) ON DELETE CASCADE,
            option_text TEXT NOT NULL,
            option_value TEXT,
            emoji TEXT,
            icon TEXT,
            order_index INTEGER DEFAULT 0
        )
    """)
    op.execute("CREATE INDEX IF NOT EXISTS idx_question_options_question_id ON question_options(question_id)")

    op.execute("""
        CREATE TABLE IF NOT EXISTS user_test_sessions (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
            test_id UUID NOT NULL REFERENCES orientation_tests(id),
            status TEXT DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed', 'abandoned')),
            answers JSONB DEFAULT '{}',
            result JSONB,
            started_at TIMESTAMPTZ DEFAULT NOW(),
            completed_at TIMESTAMPTZ,
            created_at TIMESTAMPTZ DEFAULT NOW()
        )
    """)
    op.execute("CREATE INDEX IF NOT EXISTS idx_user_test_sessions_user_id ON user_test_sessions(user_id)")

    op.execute("""
        CREATE TABLE IF NOT EXISTS career_sectors (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            name TEXT NOT NULL UNIQUE,
            description TEXT,
            icon_name TEXT,
            created_at TIMESTAMPTZ DEFAULT NOW()
        )
    """)

    op.execute("""
        CREATE TABLE IF NOT EXISTS careers (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            name TEXT NOT NULL,
            sector_id UUID REFERENCES career_sectors(id),
            description TEXT,
            riasec_codes TEXT[],
            required_education TEXT,
            salary_min INTEGER,
            salary_max INTEGER,
            job_market_trend TEXT DEFAULT 'stable' CHECK (job_market_trend IN ('growing', 'stable', 'declining')),
            is_active BOOLEAN DEFAULT TRUE,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        )
    """)

    op.execute("""
        CREATE TABLE IF NOT EXISTS schools (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            name TEXT NOT NULL,
            type TEXT DEFAULT 'university' CHECK (type IN ('university', 'grande_ecole', 'vocational', 'online')),
            location TEXT,
            website TEXT,
            description TEXT,
            is_active BOOLEAN DEFAULT TRUE,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        )
    """)

    op.execute("""
        CREATE TABLE IF NOT EXISTS school_programs (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
            name TEXT NOT NULL,
            degree_level TEXT,
            duration_years NUMERIC,
            career_ids UUID[],
            riasec_fit TEXT[],
            description TEXT,
            created_at TIMESTAMPTZ DEFAULT NOW()
        )
    """)

    op.execute("""
        CREATE TABLE IF NOT EXISTS app_settings (
            key TEXT PRIMARY KEY,
            value JSONB NOT NULL,
            description TEXT,
            updated_at TIMESTAMPTZ DEFAULT NOW()
        )
    """)


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS app_settings CASCADE")
    op.execute("DROP TABLE IF EXISTS school_programs CASCADE")
    op.execute("DROP TABLE IF EXISTS schools CASCADE")
    op.execute("DROP TABLE IF EXISTS careers CASCADE")
    op.execute("DROP TABLE IF EXISTS career_sectors CASCADE")
    op.execute("DROP TABLE IF EXISTS user_test_sessions CASCADE")
    op.execute("DROP TABLE IF EXISTS question_options CASCADE")
    op.execute("DROP TABLE IF EXISTS test_questions CASCADE")
    op.execute("DROP TABLE IF EXISTS orientation_tests CASCADE")
    op.execute("DROP TABLE IF EXISTS user_profiles CASCADE")
