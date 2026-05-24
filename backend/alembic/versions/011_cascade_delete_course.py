"""ON DELETE CASCADE pour les cles etrangeres des cours e-learning.

Permet la suppression en cascade d'un cours : les modules et lecons
sont automatiquement supprimes.

Revision ID: 011
Revises: 010
Create Date: 2026-05-20
"""
from alembic import op

revision = '011'
down_revision = '010'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("""
        ALTER TABLE elearning_lessons
            DROP CONSTRAINT IF EXISTS elearning_lessons_course_id_fkey,
            ADD CONSTRAINT elearning_lessons_course_id_fkey
                FOREIGN KEY (course_id) REFERENCES elearning_courses(id) ON DELETE CASCADE;

        ALTER TABLE elearning_modules
            DROP CONSTRAINT IF EXISTS elearning_modules_course_id_fkey,
            ADD CONSTRAINT elearning_modules_course_id_fkey
                FOREIGN KEY (course_id) REFERENCES elearning_courses(id) ON DELETE CASCADE;
    """)


def downgrade() -> None:
    op.execute("""
        ALTER TABLE elearning_lessons
            DROP CONSTRAINT IF EXISTS elearning_lessons_course_id_fkey,
            ADD CONSTRAINT elearning_lessons_course_id_fkey
                FOREIGN KEY (course_id) REFERENCES elearning_courses(id);

        ALTER TABLE elearning_modules
            DROP CONSTRAINT IF EXISTS elearning_modules_course_id_fkey,
            ADD CONSTRAINT elearning_modules_course_id_fkey
                FOREIGN KEY (course_id) REFERENCES elearning_courses(id);
    """)
