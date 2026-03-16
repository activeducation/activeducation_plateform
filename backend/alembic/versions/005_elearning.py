"""E-Learning module — courses, modules, lessons, content, progress

Revision ID: 005
Revises: 004
Create Date: 2026-03-16 00:00:00.000000
"""
from typing import Sequence, Union
from alembic import op

revision: str = "005"
down_revision: Union[str, None] = "004"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Courses catalog
    op.execute("""
        CREATE TABLE IF NOT EXISTS elearning_courses (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            title TEXT NOT NULL,
            description TEXT,
            thumbnail_url TEXT,
            category TEXT,
            difficulty TEXT DEFAULT 'debutant'
                CHECK (difficulty IN ('debutant', 'intermediaire', 'avance')),
            duration_minutes INTEGER DEFAULT 0,
            points_reward INTEGER DEFAULT 0,
            is_published BOOLEAN DEFAULT FALSE,
            display_order INTEGER DEFAULT 0,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        )
    """)

    # Modules (sequential steps in a course)
    op.execute("""
        CREATE TABLE IF NOT EXISTS elearning_modules (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            course_id UUID NOT NULL REFERENCES elearning_courses(id) ON DELETE CASCADE,
            title TEXT NOT NULL,
            description TEXT,
            display_order INTEGER DEFAULT 0,
            is_locked BOOLEAN DEFAULT FALSE
        )
    """)

    # Lessons within modules
    op.execute("""
        CREATE TABLE IF NOT EXISTS elearning_lessons (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            module_id UUID NOT NULL REFERENCES elearning_modules(id) ON DELETE CASCADE,
            title TEXT NOT NULL,
            lesson_type TEXT NOT NULL
                CHECK (lesson_type IN ('video', 'article', 'quiz', 'pdf', 'challenge')),
            duration_minutes INTEGER DEFAULT 5,
            points_reward INTEGER DEFAULT 10,
            display_order INTEGER DEFAULT 0,
            is_free BOOLEAN DEFAULT FALSE
        )
    """)

    # Polymorphic lesson content (JSONB)
    op.execute("""
        CREATE TABLE IF NOT EXISTS elearning_lesson_content (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            lesson_id UUID NOT NULL UNIQUE REFERENCES elearning_lessons(id) ON DELETE CASCADE,
            content_data JSONB NOT NULL DEFAULT '{}'
        )
    """)

    # User progress per lesson
    op.execute("""
        CREATE TABLE IF NOT EXISTS elearning_user_progress (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
            lesson_id UUID NOT NULL REFERENCES elearning_lessons(id) ON DELETE CASCADE,
            status TEXT DEFAULT 'not_started'
                CHECK (status IN ('not_started', 'in_progress', 'completed')),
            score INTEGER,
            quiz_answers JSONB,
            started_at TIMESTAMPTZ,
            completed_at TIMESTAMPTZ,
            UNIQUE (user_id, lesson_id)
        )
    """)

    # Course enrollments
    op.execute("""
        CREATE TABLE IF NOT EXISTS elearning_enrollments (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
            course_id UUID NOT NULL REFERENCES elearning_courses(id) ON DELETE CASCADE,
            enrolled_at TIMESTAMPTZ DEFAULT NOW(),
            progress_pct INTEGER DEFAULT 0,
            completed_at TIMESTAMPTZ,
            UNIQUE (user_id, course_id)
        )
    """)

    # Indexes for performance
    op.execute("CREATE INDEX IF NOT EXISTS idx_elearning_modules_course ON elearning_modules(course_id)")
    op.execute("CREATE INDEX IF NOT EXISTS idx_elearning_lessons_module ON elearning_lessons(module_id)")
    op.execute("CREATE INDEX IF NOT EXISTS idx_elearning_progress_user ON elearning_user_progress(user_id)")
    op.execute("CREATE INDEX IF NOT EXISTS idx_elearning_enrollments_user ON elearning_enrollments(user_id)")


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS elearning_enrollments CASCADE")
    op.execute("DROP TABLE IF EXISTS elearning_user_progress CASCADE")
    op.execute("DROP TABLE IF EXISTS elearning_lesson_content CASCADE")
    op.execute("DROP TABLE IF EXISTS elearning_lessons CASCADE")
    op.execute("DROP TABLE IF EXISTS elearning_modules CASCADE")
    op.execute("DROP TABLE IF EXISTS elearning_courses CASCADE")
