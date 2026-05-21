"""Add missing columns to mentors table + create opportunities table.

La table mentors existante (schema 001) manque les colonnes attendues par le
nouveau endpoint /mentors. La table opportunities n'existe que dans un script
SQL ad-hoc, pas dans Alembic. Ce migration corrige les deux lacunes.

Revision ID: 012
Revises: 011
Create Date: 2026-05-20
"""
from alembic import op

revision = '012'
down_revision = '011'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # =========================================================================
    # 1. Colonnes manquantes sur la table mentors
    # =========================================================================
    op.execute("""
        ALTER TABLE mentors
            ADD COLUMN IF NOT EXISTS full_name     TEXT,
            ADD COLUMN IF NOT EXISTS bio           TEXT,
            ADD COLUMN IF NOT EXISTS avatar_url    TEXT,
            ADD COLUMN IF NOT EXISTS years_experience INTEGER,
            ADD COLUMN IF NOT EXISTS available_slots  INTEGER DEFAULT 3,
            ADD COLUMN IF NOT EXISTS location      TEXT,
            ADD COLUMN IF NOT EXISTS linkedin_url  TEXT,
            ADD COLUMN IF NOT EXISTS specialty     TEXT,
            ADD COLUMN IF NOT EXISTS hourly_rate   NUMERIC(10,2);
    """)

    # =========================================================================
    # 2. Table mentor_reviews (si absente)
    # =========================================================================
    op.execute("""
        CREATE TABLE IF NOT EXISTS mentor_reviews (
            id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            mentor_id   UUID NOT NULL REFERENCES mentors(id) ON DELETE CASCADE,
            user_id     UUID NOT NULL REFERENCES auth.users(id),
            rating      INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
            comment     TEXT,
            created_at  TIMESTAMPTZ DEFAULT NOW()
        );
    """)

    op.execute("""
        ALTER TABLE mentor_reviews ENABLE ROW LEVEL SECURITY;
    """)

    op.execute("""
        DO $$ BEGIN
            CREATE POLICY "mentor_reviews_public_read"
            ON mentor_reviews FOR SELECT USING (true);
        EXCEPTION WHEN duplicate_object THEN NULL; END $$;
    """)

    op.execute("""
        DO $$ BEGIN
            CREATE POLICY "mentor_reviews_auth_insert"
            ON mentor_reviews FOR INSERT WITH CHECK (auth.uid() = user_id);
        EXCEPTION WHEN duplicate_object THEN NULL; END $$;
    """)

    # =========================================================================
    # 3. Table mentor_availability (si absente)
    # =========================================================================
    op.execute("""
        CREATE TABLE IF NOT EXISTS mentor_availability (
            id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            mentor_id      UUID NOT NULL REFERENCES mentors(id) ON DELETE CASCADE,
            day_of_week    INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
            available_from TIME NOT NULL,
            available_to   TIME NOT NULL,
            is_available   BOOLEAN DEFAULT TRUE,
            created_at     TIMESTAMPTZ DEFAULT NOW()
        );
    """)

    op.execute("CREATE INDEX IF NOT EXISTS idx_mentor_availability_mentor ON mentor_availability(mentor_id);")

    # =========================================================================
    # 4. Table opportunities (si absente, avec currency XOF)
    # =========================================================================
    op.execute("""
        CREATE TABLE IF NOT EXISTS opportunities (
            id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            title                TEXT NOT NULL,
            description          TEXT NOT NULL,
            opportunity_type     TEXT NOT NULL CHECK (opportunity_type IN ('internship','job','volunteer','scholarship')),
            organization_name    TEXT NOT NULL,
            organization_logo    TEXT,
            location             TEXT,
            remote_type          TEXT CHECK (remote_type IN ('onsite','remote','hybrid')),
            duration             TEXT,
            requirements         TEXT,
            benefits             TEXT,
            salary_min           INTEGER,
            salary_max           INTEGER,
            salary_currency      TEXT DEFAULT 'XOF',
            application_url      TEXT,
            application_deadline TIMESTAMPTZ,
            is_published         BOOLEAN DEFAULT false,
            is_featured          BOOLEAN DEFAULT false,
            status               TEXT DEFAULT 'draft' CHECK (status IN ('draft','published','closed')),
            school_id            UUID REFERENCES schools(id) ON DELETE SET NULL,
            created_by           UUID REFERENCES auth.users(id),
            created_at           TIMESTAMPTZ DEFAULT NOW(),
            updated_at           TIMESTAMPTZ DEFAULT NOW()
        );
    """)

    op.execute("ALTER TABLE opportunities ENABLE ROW LEVEL SECURITY;")

    # Lecture publique des opportunités publiées
    op.execute("""
        DO $$ BEGIN
            CREATE POLICY "opportunities_public_read"
            ON opportunities FOR SELECT USING (is_published = true);
        EXCEPTION WHEN duplicate_object THEN NULL; END $$;
    """)

    # Accès complet pour admins via service_role
    op.execute("""
        DO $$ BEGIN
            CREATE POLICY "opportunities_service_role_all"
            ON opportunities FOR ALL
            USING (auth.role() = 'service_role')
            WITH CHECK (auth.role() = 'service_role');
        EXCEPTION WHEN duplicate_object THEN NULL; END $$;
    """)

    op.execute("CREATE INDEX IF NOT EXISTS idx_opportunities_status ON opportunities(status);")
    op.execute("CREATE INDEX IF NOT EXISTS idx_opportunities_type ON opportunities(opportunity_type);")
    op.execute("CREATE INDEX IF NOT EXISTS idx_opportunities_published ON opportunities(is_published);")


def downgrade() -> None:
    # Supprimer opportunities
    op.execute("DROP TABLE IF EXISTS opportunities;")

    # Supprimer mentor_availability
    op.execute("DROP TABLE IF EXISTS mentor_availability;")

    # Supprimer mentor_reviews (si créée par cette migration)
    # Note: peut échouer si des données existent
    # op.execute("DROP TABLE IF EXISTS mentor_reviews;")

    # Supprimer colonnes ajoutées à mentors
    op.execute("""
        ALTER TABLE mentors
            DROP COLUMN IF EXISTS full_name,
            DROP COLUMN IF EXISTS bio,
            DROP COLUMN IF EXISTS avatar_url,
            DROP COLUMN IF EXISTS years_experience,
            DROP COLUMN IF EXISTS available_slots,
            DROP COLUMN IF EXISTS location,
            DROP COLUMN IF EXISTS linkedin_url,
            DROP COLUMN IF EXISTS specialty,
            DROP COLUMN IF EXISTS hourly_rate;
    """)
