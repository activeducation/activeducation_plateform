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

    # User profiles - common queries
    op.execute("CREATE INDEX IF NOT EXISTS idx_user_profiles_org ON user_profiles(organization_id)")
    op.execute("CREATE INDEX IF NOT EXISTS idx_user_profiles_created ON user_profiles(created_at DESC)")
    op.execute("CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON user_profiles(role)")

    # Elearning - enrollments and progress
    op.execute("CREATE INDEX IF NOT EXISTS idx_elearning_enrollments_user_course ON elearning_enrollments(user_id, course_id)")
    op.execute("CREATE INDEX IF NOT EXISTS idx_elearning_enrollments_course ON elearning_enrollments(course_id)")
    op.execute("CREATE INDEX IF NOT EXISTS idx_elearning_progress_user ON elearning_user_progress(user_id)")
    op.execute("CREATE INDEX IF NOT EXISTS idx_elearning_progress_lesson ON elearning_user_progress(lesson_id)")

    # Gamification - points queries
    op.execute("CREATE INDEX IF NOT EXISTS idx_gamification_points_user ON gamification_points(user_id)")
    op.execute("CREATE INDEX IF NOT EXISTS idx_gamification_points_type ON gamification_points(points_type)")
    op.execute("CREATE INDEX IF NOT EXISTS idx_gamification_badges_user ON gamification_badges(user_id)")

    # Mentor availability
    op.execute("CREATE INDEX IF NOT EXISTS idx_mentor_availability_active ON mentor_availability(is_available)")
    op.execute("CREATE INDEX IF NOT EXISTS idx_mentor_availability_time ON mentor_availability(available_from, available_to)")

    # Opportunities
    op.execute("CREATE INDEX IF NOT EXISTS idx_opportunities_status ON opportunities(status)")
    op.execute("CREATE INDEX IF NOT EXISTS idx_opportunities_type ON opportunities(opportunity_type)")


def downgrade() -> None:
    op.execute("DROP INDEX IF EXISTS idx_schools_city_type")
    op.execute("DROP INDEX IF EXISTS idx_schools_is_active")
    op.execute("DROP INDEX IF EXISTS idx_schools_type_active")
    op.execute("DROP INDEX IF EXISTS idx_user_profiles_org")
    op.execute("DROP INDEX IF EXISTS idx_user_profiles_created")
    op.execute("DROP INDEX IF EXISTS idx_user_profiles_role")
    op.execute("DROP INDEX IF EXISTS idx_elearning_enrollments_user_course")
    op.execute("DROP INDEX IF EXISTS idx_elearning_enrollments_course")
    op.execute("DROP INDEX IF EXISTS idx_elearning_progress_user")
    op.execute("DROP INDEX IF EXISTS idx_elearning_progress_lesson")
    op.execute("DROP INDEX IF EXISTS idx_gamification_points_user")
    op.execute("DROP INDEX IF EXISTS idx_gamification_points_type")
    op.execute("DROP INDEX IF EXISTS idx_gamification_badges_user")
    op.execute("DROP INDEX IF EXISTS idx_mentor_availability_active")
    op.execute("DROP INDEX IF EXISTS idx_mentor_availability_time")
    op.execute("DROP INDEX IF EXISTS idx_opportunities_status")
    op.execute("DROP INDEX IF EXISTS idx_opportunities_type")