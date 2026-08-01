"""Mentor contact requests table.

Students can send contact requests to mentors. Admins view them
in a dedicated dashboard page.

Revision ID: 020
Revises: 019
Create Date: 2026-07-21
"""
from alembic import op

revision = '020'
down_revision = '019'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("""
        CREATE TABLE IF NOT EXISTS mentor_contact_requests (
            id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            mentor_id   UUID NOT NULL REFERENCES mentors(id) ON DELETE CASCADE,
            student_id  UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            message     TEXT NOT NULL,
            status      TEXT NOT NULL DEFAULT 'pending'
                        CHECK (status IN ('pending', 'read', 'archived')),
            created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );
    """)
    op.execute("""
        CREATE INDEX IF NOT EXISTS idx_mentor_contact_requests_status
            ON mentor_contact_requests(status);
    """)
    op.execute("""
        CREATE INDEX IF NOT EXISTS idx_mentor_contact_requests_mentor
            ON mentor_contact_requests(mentor_id);
    """)


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS mentor_contact_requests CASCADE")
