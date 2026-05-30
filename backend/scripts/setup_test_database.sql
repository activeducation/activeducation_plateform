-- =============================================================================
-- Script de préparation pour les tests — branche feat/wip-gamification-partner-mentors
-- À exécuter dans le SQL Editor du Supabase Dashboard
-- =============================================================================

-- 1. Colonnes manquantes sur mentors
ALTER TABLE mentors
    ADD COLUMN IF NOT EXISTS full_name        TEXT,
    ADD COLUMN IF NOT EXISTS bio              TEXT,
    ADD COLUMN IF NOT EXISTS avatar_url       TEXT,
    ADD COLUMN IF NOT EXISTS years_experience INTEGER,
    ADD COLUMN IF NOT EXISTS available_slots  INTEGER DEFAULT 3,
    ADD COLUMN IF NOT EXISTS location         TEXT,
    ADD COLUMN IF NOT EXISTS linkedin_url     TEXT;

-- 2. Table mentor_reviews
CREATE TABLE IF NOT EXISTS mentor_reviews (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mentor_id   UUID NOT NULL REFERENCES mentors(id) ON DELETE CASCADE,
    user_id     UUID NOT NULL REFERENCES auth.users(id),
    rating      INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment     TEXT,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE mentor_reviews ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
    CREATE POLICY "mentor_reviews_public_read" ON mentor_reviews FOR SELECT USING (true);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
    CREATE POLICY "mentor_reviews_auth_insert" ON mentor_reviews FOR INSERT WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- 3. Table mentor_availability
CREATE TABLE IF NOT EXISTS mentor_availability (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mentor_id      UUID NOT NULL REFERENCES mentors(id) ON DELETE CASCADE,
    day_of_week    INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    available_from TIME NOT NULL,
    available_to   TIME NOT NULL,
    is_available   BOOLEAN DEFAULT TRUE,
    created_at     TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_mentor_availability_mentor ON mentor_availability(mentor_id);

-- 4. Table opportunities (currency XOF)
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
ALTER TABLE opportunities ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
    CREATE POLICY "opportunities_public_read" ON opportunities FOR SELECT USING (is_published = true);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
    CREATE POLICY "opportunities_service_role_all" ON opportunities FOR ALL
        USING (auth.role() = 'service_role') WITH CHECK (auth.role() = 'service_role');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
CREATE INDEX IF NOT EXISTS idx_opportunities_status ON opportunities(status);
CREATE INDEX IF NOT EXISTS idx_opportunities_type ON opportunities(opportunity_type);

-- 5. Tables partner_organizations + beneficiary_dossiers (migration 008)
DO $$
BEGIN
    ALTER TABLE user_profiles DROP CONSTRAINT IF EXISTS user_profiles_role_check;
EXCEPTION WHEN others THEN NULL;
END $$;
ALTER TABLE user_profiles
    ADD CONSTRAINT user_profiles_role_check
    CHECK (role IN ('student','admin','super_admin','partner','partner_admin'));

CREATE TABLE IF NOT EXISTS partner_organizations (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name         TEXT NOT NULL,
    type         TEXT NOT NULL,
    description  TEXT,
    website      TEXT,
    logo_url     TEXT,
    contact_email TEXT,
    contact_phone TEXT,
    address      TEXT,
    city         TEXT,
    country      TEXT DEFAULT 'TG',
    is_active    BOOLEAN DEFAULT true,
    is_approved  BOOLEAN DEFAULT false,
    created_by   UUID REFERENCES auth.users(id),
    created_at   TIMESTAMPTZ DEFAULT NOW(),
    updated_at   TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE partner_organizations ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
    CREATE POLICY "public_read_approved_orgs" ON partner_organizations
        FOR SELECT USING (is_approved = TRUE AND is_active = TRUE);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
    CREATE POLICY "service_role_full_access_orgs" ON partner_organizations FOR ALL
        USING (auth.role() = 'service_role') WITH CHECK (auth.role() = 'service_role');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS beneficiary_dossiers (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES partner_organizations(id) ON DELETE CASCADE,
    first_name      TEXT NOT NULL,
    last_name       TEXT NOT NULL,
    date_of_birth   DATE,
    gender          TEXT CHECK (gender IN ('male','female','other')),
    email           TEXT,
    phone           TEXT,
    address         TEXT,
    education_level TEXT,
    school_name     TEXT,
    program         TEXT,
    orientation_score JSONB,
    notes           TEXT,
    status          TEXT DEFAULT 'active' CHECK (status IN ('active','inactive','graduated','dropped')),
    created_by      UUID REFERENCES auth.users(id),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE beneficiary_dossiers ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
    CREATE POLICY "service_role_full_access_beneficiaries" ON beneficiary_dossiers FOR ALL
        USING (auth.role() = 'service_role') WITH CHECK (auth.role() = 'service_role');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Index partner
CREATE INDEX IF NOT EXISTS idx_user_profiles_org ON user_profiles(organization_id)
    WHERE organization_id IS NOT NULL;

-- 6. Colonne organization_id sur user_profiles (si absente)
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS organization_id UUID;

SELECT 'Setup terminé avec succès !' AS result;
