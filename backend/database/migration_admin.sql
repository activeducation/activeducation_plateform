-- =============================================================================
-- Migration: Admin roles + school enhancements
-- Execute dans Supabase SQL Editor
-- =============================================================================

-- Ajouter le role aux utilisateurs
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'student'
  CHECK (role IN ('student', 'admin', 'super_admin'));

-- Ajouter les colonnes manquantes aux ecoles
ALTER TABLE schools ADD COLUMN IF NOT EXISTS image_url TEXT;
ALTER TABLE schools ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;

-- Index pour les recherches par role
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON user_profiles(role);
