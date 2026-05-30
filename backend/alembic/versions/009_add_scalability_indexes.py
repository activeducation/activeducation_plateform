"""Add scalability indexes for better query performance.

Improves performance for:
- School filtering (city, type, is_active)
- User profiles (organization, created_at)
- Elearning (enrollments, progress)
- Gamification (points by user)

Revision ID: 009
Revises: 008
Create Date: 2026-05-11
"""

from alembic import op

# revision identifiers
revision = '009'
down_revision = '008'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Schools - filtering common fields
    op.execute("CREATE INDEX IF NOT EXISTS idx_schools_city_type ON schools(city, type)")
    op.execute("CREATE INDEX IF NOT EXISTS idx_schools_is_active ON schools(is_active)")
    op.execute("CREATE INDEX IF NOT EXISTS idx_schools_type_active ON schools(type, is_active)")

    # User profiles - common queries (idx_user_profiles_org already in 008)
    # op.execute("CREATE INDEX IF NOT EXISTS idx_user_profiles_org ON user_profiles(organization_id)")  # REMOVED - duplicate from 008
    op.execute("CREATE INDEX IF NOT EXISTS idx_user_profiles_created ON user_profiles(created_at DESC)")
    op.execute("CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON user_profiles(role)")

    # Elearning - enrollments and progress (tables creees en 005)
    op.execute("CREATE INDEX IF NOT EXISTS idx_elearning_enrollments_user_course ON elearning_enrollments(user_id, course_id)")
    op.execute("CREATE INDEX IF NOT EXISTS idx_elearning_enrollments_course ON elearning_enrollments(course_id)")
    op.execute("CREATE INDEX IF NOT EXISTS idx_elearning_progress_user ON elearning_user_progress(user_id)")
    op.execute("CREATE INDEX IF NOT EXISTS idx_elearning_progress_lesson ON elearning_user_progress(lesson_id)")

    # NOTE: les index gamification_points / gamification_badges ont ete RETIRES.
    # Ces tables n'existent dans aucune migration (les vraies tables de
    # gamification sont `challenges` et `user_challenges`, creees en 002).
    #
    # NOTE: les index mentor_availability et opportunities ont ete DEPLACES
    # vers la migration 012, qui cree ces tables. Les creer ici provoquait un
    # echec "relation does not exist" lors d'un `alembic upgrade head` from
    # scratch (009 s'execute AVANT 012).


def downgrade() -> None:
    op.execute("DROP INDEX IF EXISTS idx_schools_city_type")
    op.execute("DROP INDEX IF EXISTS idx_schools_is_active")
    op.execute("DROP INDEX IF EXISTS idx_schools_type_active")
    # idx_user_profiles_org NOT dropped - belongs to 008
    op.execute("DROP INDEX IF EXISTS idx_user_profiles_created")
    op.execute("DROP INDEX IF EXISTS idx_user_profiles_role")
    op.execute("DROP INDEX IF EXISTS idx_elearning_enrollments_user_course")
    op.execute("DROP INDEX IF EXISTS idx_elearning_enrollments_course")
    op.execute("DROP INDEX IF EXISTS idx_elearning_progress_user")
    op.execute("DROP INDEX IF EXISTS idx_elearning_progress_lesson")
    # gamification_* / mentor_availability / opportunities : voir note dans upgrade()