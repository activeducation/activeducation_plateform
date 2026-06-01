"""Add total_xp/current_streak/longest_streak to user_profiles + award_xp RPC.

Ajoute les colonnes de gamification manquantes sur user_profiles et crée
la fonction RPC atomique award_xp() pour incrémenter le XP sans race condition.

Revision ID: 014
Revises: 013
Create Date: 2026-06-01
"""
from alembic import op

revision = '014'
down_revision = '013'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Ajouter les colonnes sur user_profiles (idempotent)
    op.execute("""
        ALTER TABLE user_profiles
            ADD COLUMN IF NOT EXISTS total_xp      INTEGER NOT NULL DEFAULT 0,
            ADD COLUMN IF NOT EXISTS current_streak INTEGER NOT NULL DEFAULT 0,
            ADD COLUMN IF NOT EXISTS longest_streak INTEGER NOT NULL DEFAULT 0
    """)

    # Créer l'index pour le leaderboard (tri par total_xp DESC)
    op.execute("""
        CREATE INDEX IF NOT EXISTS idx_user_profiles_total_xp
            ON user_profiles(total_xp DESC)
    """)

    # Fonction RPC atomique pour incrémenter le XP sans race condition
    op.execute("""
        CREATE OR REPLACE FUNCTION award_xp(p_user_id UUID, p_amount INTEGER)
        RETURNS INTEGER
        LANGUAGE sql
        AS $$
            UPDATE user_profiles
            SET total_xp = total_xp + p_amount,
                updated_at = NOW()
            WHERE id = p_user_id
            RETURNING total_xp;
        $$;
    """)

    # Restreindre l'accès : service_role uniquement
    op.execute("""
        REVOKE ALL ON FUNCTION award_xp(UUID, INTEGER) FROM PUBLIC;
        GRANT EXECUTE ON FUNCTION award_xp(UUID, INTEGER) TO service_role;
    """)

    # Fonction RPC pour obtenir le rang classement
    op.execute("""
        CREATE OR REPLACE FUNCTION get_leaderboard_rank(p_user_id UUID)
        RETURNS TABLE(rank BIGINT)
        LANGUAGE sql
        AS $$
            SELECT rank
            FROM (
                SELECT id, ROW_NUMBER() OVER (ORDER BY total_xp DESC) AS rank
                FROM user_profiles
            ) ranked
            WHERE id = p_user_id;
        $$;
    """)

    op.execute("""
        REVOKE ALL ON FUNCTION get_leaderboard_rank(UUID) FROM PUBLIC;
        GRANT EXECUTE ON FUNCTION get_leaderboard_rank(UUID) TO service_role;
    """)


def downgrade() -> None:
    op.execute("DROP FUNCTION IF EXISTS award_xp(UUID, INTEGER);")
    op.execute("DROP FUNCTION IF EXISTS get_leaderboard_rank(UUID);")
    # Ne PAS dropper les colonnes (perte de données).
    # Downgrade no-op documenté.
