-- ============================================================
-- MIGRATION V3 : Fix Admin Creation & Mobile Support (Tests Table)
-- ============================================================

-- 1. Ajouter les colonnes manquantes sur orientation_tests
-- Ces colonnes sont requises par le schema TestCreate lors de l'insertion
ALTER TABLE orientation_tests ADD COLUMN IF NOT EXISTS display_order INTEGER DEFAULT 0;
ALTER TABLE orientation_tests ADD COLUMN IF NOT EXISTS image_url TEXT;

-- 2. Mettre a jour la contrainte de type sur orientation_tests
-- Pour supporter 'personality', 'skills', 'interests', 'aptitude' en plus de 'riasec'
ALTER TABLE orientation_tests DROP CONSTRAINT IF EXISTS orientation_tests_type_check;

ALTER TABLE orientation_tests ADD CONSTRAINT orientation_tests_type_check
    CHECK (type IN ('riasec', 'personality', 'skills', 'interests', 'aptitude'));

-- 3. Verification
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'orientation_tests' 
AND column_name IN ('display_order', 'image_url');
