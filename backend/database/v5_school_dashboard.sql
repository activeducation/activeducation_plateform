-- =============================================================================
-- ActivEducation - Migration v5 : School Dashboard
-- =============================================================================
-- Ajoute le role school_admin, la table school_admin_profiles,
-- et le champ school_id sur elearning_courses.
-- A executer dans l'editeur SQL de Supabase.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Etendre la contrainte de role sur user_profiles
-- -----------------------------------------------------------------------------
-- Supabase / PostgreSQL ne supporte pas ALTER CONSTRAINT directement.
-- On supprime l'ancienne contrainte et on la recrée.

ALTER TABLE user_profiles
    DROP CONSTRAINT IF EXISTS user_profiles_role_check;

-- Ajouter la colonne role si elle n'existe pas encore
ALTER TABLE user_profiles
    ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'student';

-- Appliquer la nouvelle contrainte avec school_admin
ALTER TABLE user_profiles
    ADD CONSTRAINT user_profiles_role_check
    CHECK (role IN ('student', 'admin', 'super_admin', 'school_admin'));

-- Index pour accelerer les lookups par role
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON user_profiles(role);

-- -----------------------------------------------------------------------------
-- 2. Table school_admin_profiles
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS school_admin_profiles (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL UNIQUE REFERENCES user_profiles(id) ON DELETE CASCADE,
    school_id   UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    position    TEXT,                          -- ex: "Directeur", "Responsable pedagogique"
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_school_admin_profiles_user_id
    ON school_admin_profiles(user_id);

CREATE INDEX IF NOT EXISTS idx_school_admin_profiles_school_id
    ON school_admin_profiles(school_id);

-- Trigger updated_at
CREATE TRIGGER update_school_admin_profiles_updated_at
    BEFORE UPDATE ON school_admin_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS desactive (securite geree par le backend)
ALTER TABLE school_admin_profiles DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- 3. Tables E-Learning (si pas encore creees)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS elearning_courses (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title           TEXT NOT NULL,
    description     TEXT,
    difficulty      TEXT CHECK (difficulty IN ('beginner', 'intermediate', 'advanced')),
    category        TEXT,
    duration_minutes INTEGER,
    points_reward   INTEGER DEFAULT 0,
    thumbnail_url   TEXT,
    is_published    BOOLEAN DEFAULT FALSE,
    display_order   INTEGER DEFAULT 0,
    school_id       UUID REFERENCES schools(id) ON DELETE SET NULL,  -- NULL = cours plateforme
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_elearning_courses_school_id
    ON elearning_courses(school_id);

CREATE INDEX IF NOT EXISTS idx_elearning_courses_is_published
    ON elearning_courses(is_published);

CREATE TABLE IF NOT EXISTS elearning_modules (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id       UUID NOT NULL REFERENCES elearning_courses(id) ON DELETE CASCADE,
    title           TEXT NOT NULL,
    description     TEXT,
    display_order   INTEGER NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_elearning_modules_course_id
    ON elearning_modules(course_id);

CREATE TABLE IF NOT EXISTS elearning_lessons (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    module_id       UUID NOT NULL REFERENCES elearning_modules(id) ON DELETE CASCADE,
    title           TEXT NOT NULL,
    lesson_type     TEXT NOT NULL CHECK (lesson_type IN ('video', 'text', 'quiz', 'pdf')),
    duration_minutes INTEGER,
    points_reward   INTEGER DEFAULT 0,
    is_free         BOOLEAN DEFAULT FALSE,
    display_order   INTEGER NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_elearning_lessons_module_id
    ON elearning_lessons(module_id);

CREATE TABLE IF NOT EXISTS elearning_lesson_content (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lesson_id   UUID NOT NULL UNIQUE REFERENCES elearning_lessons(id) ON DELETE CASCADE,
    content_data JSONB NOT NULL DEFAULT '{}',
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS elearning_enrollments (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    course_id       UUID NOT NULL REFERENCES elearning_courses(id) ON DELETE CASCADE,
    progress_pct    INTEGER DEFAULT 0 CHECK (progress_pct >= 0 AND progress_pct <= 100),
    enrolled_at     TIMESTAMPTZ DEFAULT NOW(),
    completed_at    TIMESTAMPTZ,
    UNIQUE(user_id, course_id)
);

CREATE INDEX IF NOT EXISTS idx_elearning_enrollments_course_id
    ON elearning_enrollments(course_id);

CREATE INDEX IF NOT EXISTS idx_elearning_enrollments_user_id
    ON elearning_enrollments(user_id);

CREATE TABLE IF NOT EXISTS elearning_user_progress (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    lesson_id   UUID NOT NULL REFERENCES elearning_lessons(id) ON DELETE CASCADE,
    status      TEXT NOT NULL DEFAULT 'in_progress'
                    CHECK (status IN ('in_progress', 'completed')),
    score       INTEGER,
    quiz_answers JSONB,
    started_at  TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    UNIQUE(user_id, lesson_id)
);

-- user_points (pour attribution de points e-learning)
CREATE TABLE IF NOT EXISTS user_points (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL UNIQUE REFERENCES user_profiles(id) ON DELETE CASCADE,
    points_balance  INTEGER DEFAULT 0,
    total_earned    INTEGER DEFAULT 0,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- RLS desactive pour les tables e-learning
ALTER TABLE elearning_courses        DISABLE ROW LEVEL SECURITY;
ALTER TABLE elearning_modules        DISABLE ROW LEVEL SECURITY;
ALTER TABLE elearning_lessons        DISABLE ROW LEVEL SECURITY;
ALTER TABLE elearning_lesson_content DISABLE ROW LEVEL SECURITY;
ALTER TABLE elearning_enrollments    DISABLE ROW LEVEL SECURITY;
ALTER TABLE elearning_user_progress  DISABLE ROW LEVEL SECURITY;
ALTER TABLE user_points              DISABLE ROW LEVEL SECURITY;
ALTER TABLE school_admin_profiles    DISABLE ROW LEVEL SECURITY;

-- =============================================================================
-- FIN DE LA MIGRATION v5
-- =============================================================================
