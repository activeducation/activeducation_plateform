"""Reenable Row Level Security on sensitive tables

Revision ID: 007
Revises: 006
Create Date: 2026-04-17 00:00:00.000000

Re-active RLS desactivee par la migration 004.

Modele de securite (cf. docs/RLS_AUDIT.md):
- Backend FastAPI utilise service_role -> bypass RLS implicite.
- Flutter apps n'utilisent PAS le SDK Supabase directement.
- RLS agit en filet "fail-closed" : si la cle Anon fuite ou qu'un
  integrations partner tente un acces direct, les policies restreignent
  l'acces aux seules lignes autorisees.

Policies creees:
- Tables de reference (lecture publique): orientation_tests, test_questions,
  question_options, careers, career_sectors.
- Tables utilisateur (self-access via auth.uid()): user_profiles,
  user_test_sessions, user_achievements, user_challenges, test_results,
  user_favorite_careers, user_points, elearning_user_progress,
  elearning_enrollments.
- schools/school_programs: lecture publique conditionnelle (is_active=true).
- Tables admin-only (challenges, school_admin_profiles, elearning_courses/
  modules/lessons/lesson_content, app_settings): RLS ON sans policy publique
  -> accessible uniquement via service_role.

Idempotent: utilise DO blocks pour tolerer les tables manquantes et
DROP POLICY IF EXISTS avant CREATE POLICY pour permettre re-application.
"""
from typing import Sequence, Union

from alembic import op

revision: str = "007"
down_revision: Union[str, None] = "006"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


# Tables en lecture publique (anon + authenticated)
PUBLIC_READ_TABLES = [
    "orientation_tests",
    "test_questions",
    "question_options",
    "careers",
    "career_sectors",
]

# (table, owner_column) pour policies self-access
USER_OWNED_TABLES = [
    ("user_profiles", "id"),
    ("user_test_sessions", "user_id"),
    ("user_achievements", "user_id"),
    ("user_challenges", "user_id"),
    ("test_results", "user_id"),
    ("user_favorite_careers", "user_id"),
    ("user_points", "user_id"),
    ("elearning_user_progress", "user_id"),
    ("elearning_enrollments", "user_id"),
]

# Tables admin-only : RLS ON sans policy -> service_role uniquement
ADMIN_ONLY_TABLES = [
    "challenges",
    "school_admin_profiles",
    "elearning_courses",
    "elearning_modules",
    "elearning_lessons",
    "elearning_lesson_content",
    "app_settings",
]

# Toutes les tables touchees (pour downgrade)
ALL_TABLES = (
    PUBLIC_READ_TABLES
    + [t for t, _ in USER_OWNED_TABLES]
    + ADMIN_ONLY_TABLES
    + ["schools", "school_programs"]
)


def _enable_rls_if_exists(table: str) -> None:
    """Active RLS sur une table si elle existe (idempotent)."""
    op.execute(f"""
        DO $$ BEGIN
            ALTER TABLE {table} ENABLE ROW LEVEL SECURITY;
        EXCEPTION WHEN undefined_table THEN NULL;
        END $$
    """)


def _disable_rls_if_exists(table: str) -> None:
    op.execute(f"""
        DO $$ BEGIN
            ALTER TABLE {table} DISABLE ROW LEVEL SECURITY;
        EXCEPTION WHEN undefined_table THEN NULL;
        END $$
    """)


def _recreate_policy(table: str, policy_name: str, policy_sql: str) -> None:
    """
    Drop puis re-cree une policy. Tolere l'absence de la table (undefined_table).

    policy_sql doit etre le corps complet de CREATE POLICY (FOR ... TO ... USING ...).
    """
    op.execute(f"""
        DO $$ BEGIN
            DROP POLICY IF EXISTS "{policy_name}" ON {table};
            CREATE POLICY "{policy_name}" ON {table} {policy_sql};
        EXCEPTION WHEN undefined_table THEN NULL;
        END $$
    """)


def upgrade() -> None:
    # -------------------------------------------------------------------------
    # 1. Tables de reference : lecture publique
    # -------------------------------------------------------------------------
    for table in PUBLIC_READ_TABLES:
        _enable_rls_if_exists(table)
        _recreate_policy(
            table,
            f"{table}_public_read",
            "FOR SELECT TO anon, authenticated USING (true)",
        )

    # -------------------------------------------------------------------------
    # 2. Tables utilisateur : self-access via auth.uid()
    # -------------------------------------------------------------------------
    for table, owner_col in USER_OWNED_TABLES:
        _enable_rls_if_exists(table)
        _recreate_policy(
            table,
            f"{table}_self_access",
            f"FOR ALL TO authenticated "
            f"USING (auth.uid() = {owner_col}) "
            f"WITH CHECK (auth.uid() = {owner_col})",
        )

    # -------------------------------------------------------------------------
    # 3. Schools : lecture publique conditionnelle
    # -------------------------------------------------------------------------
    # is_verified peut ne pas exister en Alembic (cf. schema.sql historique).
    # On construit la condition dynamiquement pour tolerer les deux cas.
    op.execute("""
        DO $$
        DECLARE
            has_is_verified BOOLEAN;
            policy_condition TEXT;
        BEGIN
            SELECT EXISTS (
                SELECT 1 FROM information_schema.columns
                WHERE table_name = 'schools' AND column_name = 'is_verified'
            ) INTO has_is_verified;

            IF has_is_verified THEN
                policy_condition := 'is_active = true AND is_verified = true';
            ELSE
                policy_condition := 'is_active = true';
            END IF;

            ALTER TABLE schools ENABLE ROW LEVEL SECURITY;
            DROP POLICY IF EXISTS "schools_public_read" ON schools;
            EXECUTE format(
                'CREATE POLICY "schools_public_read" ON schools FOR SELECT TO anon, authenticated USING (%s)',
                policy_condition
            );
        EXCEPTION WHEN undefined_table THEN NULL;
        END $$
    """)

    _enable_rls_if_exists("school_programs")
    _recreate_policy(
        "school_programs",
        "school_programs_public_read",
        "FOR SELECT TO anon, authenticated USING (true)",
    )

    # -------------------------------------------------------------------------
    # 4. Tables admin-only : RLS ON sans policy publique
    # -------------------------------------------------------------------------
    # service_role bypass implicite -> backend fonctionne normalement.
    # Anon/authenticated : refus systematique (fail-closed).
    for table in ADMIN_ONLY_TABLES:
        _enable_rls_if_exists(table)
        # Pas de policy -> acces refuse par defaut pour anon/authenticated.


def downgrade() -> None:
    """Retour a l'etat post-004 : RLS desactive sur toutes les tables."""
    # Supprimer les policies (safe meme si elles n'existent pas)
    for table in PUBLIC_READ_TABLES:
        op.execute(f"""
            DO $$ BEGIN
                DROP POLICY IF EXISTS "{table}_public_read" ON {table};
            EXCEPTION WHEN undefined_table THEN NULL;
            END $$
        """)

    for table, _ in USER_OWNED_TABLES:
        op.execute(f"""
            DO $$ BEGIN
                DROP POLICY IF EXISTS "{table}_self_access" ON {table};
            EXCEPTION WHEN undefined_table THEN NULL;
            END $$
        """)

    op.execute("""
        DO $$ BEGIN
            DROP POLICY IF EXISTS "schools_public_read" ON schools;
        EXCEPTION WHEN undefined_table THEN NULL;
        END $$
    """)
    op.execute("""
        DO $$ BEGIN
            DROP POLICY IF EXISTS "school_programs_public_read" ON school_programs;
        EXCEPTION WHEN undefined_table THEN NULL;
        END $$
    """)

    # Desactiver RLS sur toutes les tables touchees
    for table in ALL_TABLES:
        _disable_rls_if_exists(table)
