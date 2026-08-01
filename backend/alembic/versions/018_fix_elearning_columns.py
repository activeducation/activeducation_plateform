"""Ajoute school_id sur elearning_courses et course_id sur elearning_lessons.

Migration 005 a cree les tables sans ces colonnes. Le backend les requete
mais elles sont absentes -> 500. Ajout en idempotent (IF NOT EXISTS).

Revision ID: 018
Revises: 017
Create Date: 2026-07-18
"""
from alembic import op

revision = '018'
down_revision = '017'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # 1. school_id sur elearning_courses
    op.execute("""
        ALTER TABLE elearning_courses
            ADD COLUMN IF NOT EXISTS school_id UUID
            REFERENCES schools(id) ON DELETE SET NULL;
    """)
    op.execute("""
        CREATE INDEX IF NOT EXISTS idx_elearning_courses_school_id
            ON elearning_courses(school_id);
    """)

    # 2. course_id sur elearning_lessons
    op.execute("""
        ALTER TABLE elearning_lessons
            ADD COLUMN IF NOT EXISTS course_id UUID
            REFERENCES elearning_courses(id) ON DELETE CASCADE;
    """)
    op.execute("""
        CREATE INDEX IF NOT EXISTS idx_elearning_lessons_course_id
            ON elearning_lessons(course_id);
    """)

    # 3. Mettre a jour course_id dans les lecons existantes via module->course
    op.execute("""
        UPDATE elearning_lessons l
        SET course_id = m.course_id
        FROM elearning_modules m
        WHERE l.module_id = m.id AND l.course_id IS NULL;
    """)


def downgrade() -> None:
    op.execute("DROP INDEX IF EXISTS idx_elearning_lessons_course_id;")
    op.execute("ALTER TABLE elearning_lessons DROP COLUMN IF EXISTS course_id;")
    op.execute("DROP INDEX IF EXISTS idx_elearning_courses_school_id;")
    op.execute("ALTER TABLE elearning_courses DROP COLUMN IF EXISTS school_id;")
