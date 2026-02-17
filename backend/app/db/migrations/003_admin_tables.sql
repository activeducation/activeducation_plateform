-- =============================================================================
-- Migration 003: Tables pour le Dashboard Administratif
-- =============================================================================

-- Ajout de colonnes admin sur user_profiles
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'student'
    CHECK (role IN ('student', 'admin', 'super_admin'));
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON user_profiles(role);
CREATE INDEX IF NOT EXISTS idx_user_profiles_is_active ON user_profiles(is_active);

-- =============================================================================
-- Programmes scolaires (filieres d'une ecole)
-- =============================================================================
CREATE TABLE IF NOT EXISTS school_programs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    level TEXT, -- e.g. 'licence', 'master', 'bts'
    duration_years INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_school_programs_school_id ON school_programs(school_id);

CREATE TRIGGER update_school_programs_updated_at
    BEFORE UPDATE ON school_programs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- Images d'ecoles
-- =============================================================================
CREATE TABLE IF NOT EXISTS school_images (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    caption TEXT,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_school_images_school_id ON school_images(school_id);

-- =============================================================================
-- Parametres de l'application
-- =============================================================================
CREATE TABLE IF NOT EXISTS app_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key TEXT UNIQUE NOT NULL,
    value JSONB NOT NULL DEFAULT '{}',
    description TEXT,
    updated_by UUID REFERENCES user_profiles(id),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================================
-- Annonces / Notifications
-- =============================================================================
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

CREATE TRIGGER update_announcements_updated_at
    BEFORE UPDATE ON announcements
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- Journal d'audit admin
-- =============================================================================
CREATE TABLE IF NOT EXISTS admin_audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_id UUID NOT NULL REFERENCES user_profiles(id),
    action TEXT NOT NULL, -- 'create', 'update', 'delete', 'verify', 'deactivate'
    entity_type TEXT NOT NULL, -- 'school', 'career', 'user', 'test', etc.
    entity_id TEXT,
    changes JSONB,
    ip_address TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admin_audit_log_admin_id ON admin_audit_log(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_audit_log_entity ON admin_audit_log(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_admin_audit_log_created_at ON admin_audit_log(created_at DESC);

-- Desactiver RLS pour les nouvelles tables
ALTER TABLE school_programs DISABLE ROW LEVEL SECURITY;
ALTER TABLE school_images DISABLE ROW LEVEL SECURITY;
ALTER TABLE app_settings DISABLE ROW LEVEL SECURITY;
ALTER TABLE announcements DISABLE ROW LEVEL SECURITY;
ALTER TABLE admin_audit_log DISABLE ROW LEVEL SECURITY;

-- Parametres initiaux
INSERT INTO app_settings (key, value, description) VALUES
    ('maintenance_mode', 'false', 'Mode maintenance de l''application'),
    ('default_language', '"fr"', 'Langue par defaut'),
    ('points_per_test', '50', 'Points accordes par test complete'),
    ('welcome_message', '"Bienvenue sur ActivEducation !"', 'Message d''accueil')
ON CONFLICT (key) DO NOTHING;

-- =============================================================================
-- Super Admin initial
-- Email:    admin@activeducation.com
-- Password: Admin@2024!
-- =============================================================================
INSERT INTO user_profiles (id, email, password_hash, first_name, last_name, display_name, role, is_active, preferred_language, created_at)
VALUES (
    uuid_generate_v4(),
    'admin@activeducation.com',
    '$2b$12$LhIHatlDJFBX/s6BmJH2YudyKx2twKz/lq6gpy7jfAzRCEtow9.42',
    'Super',
    'Admin',
    'Super Admin',
    'super_admin',
    TRUE,
    'fr',
    NOW()
) ON CONFLICT (email) DO UPDATE SET role = 'super_admin', is_active = TRUE;
