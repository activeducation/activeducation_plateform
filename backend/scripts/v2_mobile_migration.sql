-- ============================================================
-- MIGRATION V2 : Support Mobile App (Questions Riches & UI)
-- ============================================================

-- 1. Mettre a jour les types de questions supportes
-- Supprimer la contrainte existante si elle gene, ou la remplacer
ALTER TABLE test_questions DROP CONSTRAINT IF EXISTS test_questions_question_type_check;

-- Ajouter la nouvelle contrainte incluant 'scenario', 'thisOrThat', etc.
ALTER TABLE test_questions ADD CONSTRAINT test_questions_question_type_check
    CHECK (question_type IN ('likert', 'multiple_choice', 'boolean', 'scenario', 'thisOrThat', 'ranking', 'slider'));


-- 2. Ajouter les colonnes UI manquantes sur test_questions
-- Ces colonnes sont utilisees par l'app mobile pour l'affichage riche
ALTER TABLE test_questions ADD COLUMN IF NOT EXISTS image_asset TEXT;
ALTER TABLE test_questions ADD COLUMN IF NOT EXISTS section_title TEXT;
ALTER TABLE test_questions ADD COLUMN IF NOT EXISTS slider_left_label TEXT;
ALTER TABLE test_questions ADD COLUMN IF NOT EXISTS slider_right_label TEXT;


-- 3. Mettre a jour question_options pour supporter les valeurs textuelles et emojis
-- Convertir la colonne option_value en TEXT pour supporter 'Realistic', 'Investigative', etc.
-- Note: Les valeurs existantes (1, 2, 3...) seront converties en chaines ('1', '2', '3'...)
DO $$
BEGIN
    -- Verifier le type actuel avant de changer pour eviter des erreurs si deja fait
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'question_options' 
        AND column_name = 'option_value' 
        AND data_type = 'integer'
    ) THEN
        ALTER TABLE question_options ALTER COLUMN option_value TYPE TEXT;
    END IF;
END $$;

-- Ajouter les colonnes pour l'UI des options
ALTER TABLE question_options ADD COLUMN IF NOT EXISTS emoji TEXT;
ALTER TABLE question_options ADD COLUMN IF NOT EXISTS icon TEXT;


-- 4. Verification
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'test_questions' 
AND column_name IN ('image_asset', 'section_title');
