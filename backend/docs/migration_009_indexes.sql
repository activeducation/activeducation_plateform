-- =============================================================================
-- Migration 009: Add scalability indexes for better query performance
-- Execute this in Supabase SQL Editor or via supabase CLI
--
-- NOTE: Cette migration utilise des blocs DO conditionnels pour éviter les erreurs
-- si certaines colonnes n'existent pas encore dans la base de données.
-- =============================================================================

DO $$
BEGIN
    -- Schools - filtering common fields
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'schools' AND column_name = 'city')
    AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'schools' AND column_name = 'type') THEN
        CREATE INDEX IF NOT EXISTS idx_schools_city_type ON schools(city, type);
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'schools' AND column_name = 'is_active') THEN
        CREATE INDEX IF NOT EXISTS idx_schools_is_active ON schools(is_active);
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'schools' AND column_name = 'type')
    AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'schools' AND column_name = 'is_active') THEN
        CREATE INDEX IF NOT EXISTS idx_schools_type_active ON schools(type, is_active);
    END IF;
END $$;

DO $$
BEGIN
    -- User profiles - common queries
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'organization_id') THEN
        CREATE INDEX IF NOT EXISTS idx_user_profiles_org ON user_profiles(organization_id);
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'created_at') THEN
        CREATE INDEX IF NOT EXISTS idx_user_profiles_created ON user_profiles(created_at DESC);
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'role') THEN
        CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON user_profiles(role);
    END IF;
END $$;

DO $$
BEGIN
    -- Elearning - enrollments and progress
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'elearning_enrollments' AND column_name = 'user_id')
    AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'elearning_enrollments' AND column_name = 'course_id') THEN
        CREATE INDEX IF NOT EXISTS idx_elearning_enrollments_user_course ON elearning_enrollments(user_id, course_id);
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'elearning_enrollments' AND column_name = 'course_id') THEN
        CREATE INDEX IF NOT EXISTS idx_elearning_enrollments_course ON elearning_enrollments(course_id);
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'elearning_user_progress' AND column_name = 'user_id') THEN
        CREATE INDEX IF NOT EXISTS idx_elearning_progress_user ON elearning_user_progress(user_id);
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'elearning_user_progress' AND column_name = 'lesson_id') THEN
        CREATE INDEX IF NOT EXISTS idx_elearning_progress_lesson ON elearning_user_progress(lesson_id);
    END IF;
END $$;

DO $$
BEGIN
    -- Gamification - points queries
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'gamification_points' AND column_name = 'user_id') THEN
        CREATE INDEX IF NOT EXISTS idx_gamification_points_user ON gamification_points(user_id);
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'gamification_points' AND column_name = 'points_type') THEN
        CREATE INDEX IF NOT EXISTS idx_gamification_points_type ON gamification_points(points_type);
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'gamification_badges' AND column_name = 'user_id') THEN
        CREATE INDEX IF NOT EXISTS idx_gamification_badges_user ON gamification_badges(user_id);
    END IF;
END $$;

DO $$
BEGIN
    -- Mentor availability
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'mentor_availability' AND column_name = 'is_available') THEN
        CREATE INDEX IF NOT EXISTS idx_mentor_availability_active ON mentor_availability(is_available);
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'mentor_availability' AND column_name = 'available_from')
    AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'mentor_availability' AND column_name = 'available_to') THEN
        CREATE INDEX IF NOT EXISTS idx_mentor_availability_time ON mentor_availability(available_from, available_to);
    END IF;
END $$;

DO $$
BEGIN
    -- Opportunities
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'opportunities' AND column_name = 'status') THEN
        CREATE INDEX IF NOT EXISTS idx_opportunities_status ON opportunities(status);
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'opportunities' AND column_name = 'opportunity_type') THEN
        CREATE INDEX IF NOT EXISTS idx_opportunities_type ON opportunities(opportunity_type);
    END IF;
END $$;

-- Verify indexes created
SELECT indexname, tablename
FROM pg_indexes
WHERE schemaname = 'public'
AND indexname LIKE 'idx_%'
ORDER BY tablename, indexname;