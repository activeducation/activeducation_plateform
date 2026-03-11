"""Initial schema - etat de reference

Revision ID: 001_initial
Revises:
Create Date: 2024-01-01 00:00:00.000000

Cette migration represente l'etat initial de la base de donnees
tel qu'il a ete cree manuellement via Supabase SQL editor.

Elle ne fait rien lors de l'upgrade (schema deja en place),
mais permet d'etablir une ligne de base pour les migrations suivantes.
"""

from alembic import op
import sqlalchemy as sa


# revision identifiers
revision = '001_initial'
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    """
    Schema initial deja applique via database/schema.sql et app/db/migrations/.

    Tables existantes:
    - user_profiles
    - orientation_tests, test_questions, test_sessions, test_answers
    - careers, career_sectors, career_school_mapping
    - schools, school_programs, school_images
    - gamification_points, badges, user_badges
    - mentors, mentor_sessions
    - settings
    """
    # Schema deja en place - pas d'action necessaire
    # Les migrations futures partiront de cet etat
    pass


def downgrade() -> None:
    """
    Rollback vers avant la creation initiale.
    ATTENTION: Supprime TOUTES les tables - utiliser avec extreme precaution.
    """
    # Ne pas executer sans confirmation explicite
    # op.execute("-- Uncomment to drop all tables")
    pass
