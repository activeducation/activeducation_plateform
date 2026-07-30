"""Create gamification_profiles view mapping user_profiles columns.

Le code backend (gamification.py, admin/gamification.py) requete
gamification_profiles(total_xp, current_level, current_streak,
last_active_at). Cette table n'existe pas et n'a jamais ete creee par
une migration : user_profiles contient total_xp + streaks (migration
014), et user_gamification contient total_points + current_level.

Plutot que de modifier 5+ requetes cote code, on cree une vue qui
aligne le vocabulaire : gamification_profiles devient un alias
semantique de user_profiles, avec current_level=1 par defaut
(pas de colonne niveau cote user_profiles) et last_active_at=updated_at
(plus proche equivalent cote profil).

Aucune migration de donnees requise : la vue lit user_profiles
directement. Le classement (migration 014, base sur user_profiles.total_xp)
reste la source de verite.

Revision ID: 023
Revises: 022
Create Date: 2026-07-30
"""
from alembic import op

revision = '023'
down_revision = '022'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("""
        CREATE OR REPLACE VIEW gamification_profiles AS
        SELECT
            u.id                         AS user_id,
            u.total_xp                   AS total_xp,
            1::INTEGER                   AS current_level,
            u.current_streak             AS current_streak,
            u.longest_streak             AS longest_streak,
            u.updated_at                 AS last_active_at,
            u.created_at                 AS created_at,
            u.updated_at                 AS updated_at
        FROM user_profiles u
    """)


def downgrade() -> None:
    op.execute("DROP VIEW IF EXISTS gamification_profiles")
