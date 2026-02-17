-- ============================================================
-- A EXECUTER DANS : Supabase Dashboard > SQL Editor > New Query
-- ============================================================

-- 1) Ajouter les colonnes admin sur user_profiles
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'student';
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMPTZ;

-- Ajouter la contrainte CHECK sur role (ignorer si deja existante)
DO $$
BEGIN
    ALTER TABLE user_profiles ADD CONSTRAINT user_profiles_role_check
        CHECK (role IN ('student', 'admin', 'super_admin'));
EXCEPTION WHEN duplicate_object THEN
    NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON user_profiles(role);
CREATE INDEX IF NOT EXISTS idx_user_profiles_is_active ON user_profiles(is_active);

-- 2) Promouvoir l'admin deja cree en super_admin
UPDATE user_profiles
SET role = 'super_admin', is_active = TRUE
WHERE email = 'admin@activeducation.com';

-- 3) Tables supplementaires (programmes, images, settings, annonces, audit)
CREATE TABLE IF NOT EXISTS school_programs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    level TEXT,
    duration_years INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_school_programs_school_id ON school_programs(school_id);

CREATE TABLE IF NOT EXISTS school_images (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    caption TEXT,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_school_images_school_id ON school_images(school_id);

CREATE TABLE IF NOT EXISTS app_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key TEXT UNIQUE NOT NULL,
    value JSONB NOT NULL DEFAULT '{}',
    description TEXT,
    updated_by UUID REFERENCES user_profiles(id),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS announcements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'info' CHECK (type IN ('info', 'warning', 'promotion', 'update')),
    target_audience TEXT NOT NULL DEFAULT 'all' CHECK (target_audience IN ('all', 'students', 'mentors', 'admins')),
    image_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    start_date TIMESTAMPTZ,
    end_date TIMESTAMPTZ,
    created_by UUID REFERENCES user_profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS admin_audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_id UUID NOT NULL REFERENCES user_profiles(id),
    action TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id TEXT,
    changes JSONB,
    ip_address TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_admin_audit_log_admin_id ON admin_audit_log(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_audit_log_entity ON admin_audit_log(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_admin_audit_log_created_at ON admin_audit_log(created_at DESC);

-- Desactiver RLS pour ces tables
ALTER TABLE school_programs DISABLE ROW LEVEL SECURITY;
ALTER TABLE school_images DISABLE ROW LEVEL SECURITY;
ALTER TABLE app_settings DISABLE ROW LEVEL SECURITY;
ALTER TABLE announcements DISABLE ROW LEVEL SECURITY;
ALTER TABLE admin_audit_log DISABLE ROW LEVEL SECURITY;

-- 4) Parametres initiaux
INSERT INTO app_settings (key, value, description) VALUES
    ('maintenance_mode', 'false', 'Mode maintenance de l''application'),
    ('default_language', '"fr"', 'Langue par defaut'),
    ('points_per_test', '50', 'Points accordes par test complete'),
    ('welcome_message', '"Bienvenue sur ActivEducation !"', 'Message d''accueil')
ON CONFLICT (key) DO NOTHING;

-- Verifier le resultat
SELECT id, email, role, is_active FROM user_profiles WHERE email = 'admin@activeducation.com';
