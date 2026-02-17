-- =============================================================================
-- Migration 004: Enrichir la table schools avec des champs supplementaires
-- =============================================================================

-- Nouveaux champs pour les ecoles
ALTER TABLE schools ADD COLUMN IF NOT EXISTS tuition_range TEXT;
ALTER TABLE schools ADD COLUMN IF NOT EXISTS admission_requirements TEXT;
ALTER TABLE schools ADD COLUMN IF NOT EXISTS accreditations TEXT[] DEFAULT '{}';
ALTER TABLE schools ADD COLUMN IF NOT EXISTS founding_year INTEGER;
ALTER TABLE schools ADD COLUMN IF NOT EXISTS student_count INTEGER;
ALTER TABLE schools ADD COLUMN IF NOT EXISTS cover_image_url TEXT;
ALTER TABLE schools ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;

-- Index sur is_active pour filtrer les ecoles actives
CREATE INDEX IF NOT EXISTS idx_schools_is_active ON schools(is_active);

-- Trigger updated_at pour schools (si pas encore present)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'update_schools_updated_at'
    ) THEN
        CREATE TRIGGER update_schools_updated_at
            BEFORE UPDATE ON schools
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END
$$;
