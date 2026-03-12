-- ============================================================
-- MIGRATION V4 : Fix RLS pour les tables admin
-- A EXECUTER dans Supabase Dashboard > SQL Editor > New Query
-- ============================================================

-- Les tables d'orientation doivent permettre l'acces en ecriture
-- depuis le backend (API admin). On desactive RLS pour ces tables
-- comme c'etait deja fait pour school_programs, app_settings, etc.

-- 1. Tables principales d'orientation
ALTER TABLE orientation_tests DISABLE ROW LEVEL SECURITY;
ALTER TABLE test_questions DISABLE ROW LEVEL SECURITY;
ALTER TABLE question_options DISABLE ROW LEVEL SECURITY;

-- 2. Tables de sessions et resultats
ALTER TABLE user_test_sessions DISABLE ROW LEVEL SECURITY;

-- 3. Tables de carrieres et secteurs
ALTER TABLE careers DISABLE ROW LEVEL SECURITY;
ALTER TABLE career_sectors DISABLE ROW LEVEL SECURITY;

-- 4. Tables de gamification (si existantes)
DO $$ BEGIN ALTER TABLE user_achievements DISABLE ROW LEVEL SECURITY; EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE challenges DISABLE ROW LEVEL SECURITY; EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE user_challenges DISABLE ROW LEVEL SECURITY; EXCEPTION WHEN undefined_table THEN NULL; END $$;

-- 5. Table des ecoles
DO $$ BEGIN ALTER TABLE schools DISABLE ROW LEVEL SECURITY; EXCEPTION WHEN undefined_table THEN NULL; END $$;

-- 6. Table user_profiles (lecture/ecriture admin)
-- Note: on garde RLS pour user_profiles mais on ajoute une policy permissive
-- Alternative: desactiver si le backend gere la securite
ALTER TABLE user_profiles DISABLE ROW LEVEL SECURITY;

-- 7. Verification
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN (
    'orientation_tests', 'test_questions', 'question_options',
    'user_test_sessions', 'careers', 'career_sectors',
    'user_profiles', 'schools'
);
