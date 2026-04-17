"""Supabase Auth cleanup - remove legacy JWT artifacts

Revision ID: 006
Revises: 005
Create Date: 2024-01-15 00:00:00.000000

Nettoyage post-migration vers Supabase Auth natif.

NOTE: Cette migration etait initialement numerotee 002_supabase_auth avec un
down_revision '001_initial' inexistant (le chainon reel est '001'). Resultat:
la migration etait orpheline et n'etait jamais appliquee. Elle est desormais
positionnee en tete de chaine (apres 005) afin d'etre executee par
`alembic upgrade head`.

Changements:
- Suppression de user_profiles.password_hash (Supabase Auth gere ca)
- Suppression de user_profiles.reset_token / reset_token_expires
- Suppression de la table auth_refresh_tokens (Supabase gere ca)
- Ajout de last_login_at, is_active, role si absents
"""

from alembic import op
import sqlalchemy as sa


revision = '006'
down_revision = '005'
branch_labels = None
depends_on = None


def upgrade() -> None:
    """
    Migration vers Supabase Auth natif.
    Supprime les artefacts du JWT maison.
    """
    # Supprimer la table de refresh tokens (Supabase gere ca maintenant)
    op.execute("""
        DROP TABLE IF EXISTS auth_refresh_tokens CASCADE;
    """)

    # Supprimer les colonnes liees au JWT maison dans user_profiles
    op.execute("""
        ALTER TABLE user_profiles
            DROP COLUMN IF EXISTS password_hash,
            DROP COLUMN IF EXISTS reset_token,
            DROP COLUMN IF EXISTS reset_token_expires;
    """)

    # Supprimer les index devenus inutiles
    op.execute("""
        DROP INDEX IF EXISTS idx_user_profiles_reset_token;
    """)

    # Ajouter colonne last_login_at si pas encore presente
    op.execute("""
        ALTER TABLE user_profiles
            ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMPTZ;
    """)

    # Ajouter colonne is_active si pas encore presente
    op.execute("""
        ALTER TABLE user_profiles
            ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;
    """)

    # Ajouter colonne role si pas encore presente
    op.execute("""
        ALTER TABLE user_profiles
            ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'student'
                CHECK (role IN ('student', 'admin', 'super_admin'));
    """)


def downgrade() -> None:
    """
    Retour vers JWT maison (si rollback necessaire).
    """
    # Recreer la table auth_refresh_tokens
    op.execute("""
        CREATE TABLE IF NOT EXISTS auth_refresh_tokens (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
            token_hash TEXT NOT NULL UNIQUE,
            expires_at TIMESTAMPTZ NOT NULL,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            revoked_at TIMESTAMPTZ
        );
        CREATE INDEX idx_auth_refresh_tokens_user_id ON auth_refresh_tokens(user_id);
    """)

    # Restaurer les colonnes dans user_profiles
    op.execute("""
        ALTER TABLE user_profiles
            ADD COLUMN IF NOT EXISTS password_hash TEXT,
            ADD COLUMN IF NOT EXISTS reset_token TEXT,
            ADD COLUMN IF NOT EXISTS reset_token_expires TIMESTAMPTZ;
        CREATE INDEX IF NOT EXISTS idx_user_profiles_reset_token
            ON user_profiles(reset_token);
    """)
