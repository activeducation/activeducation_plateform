-- Migrations TutorAI + orientation (018 -> 021)
-- Genere depuis les fichiers Alembic. A coller dans le SQL editor Supabase.
-- Toutes les instructions sont idempotentes (IF NOT EXISTS).

BEGIN;

-- ===== 018_tutor_foundations.py =====
CREATE TABLE IF NOT EXISTS chat_sessions (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id         UUID NOT NULL
                            REFERENCES user_profiles(id) ON DELETE CASCADE,
            title           TEXT,                          -- resume court, optionnel
            subject_context JSONB NOT NULL DEFAULT '{}',   -- contexte RIASEC / matiere
            provider        TEXT,                          -- llm provider utilise (groq, ollama...)
            message_count   INTEGER NOT NULL DEFAULT 0,
            last_active_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );
CREATE INDEX IF NOT EXISTS idx_chat_sessions_user
            ON chat_sessions(user_id, last_active_at DESC);
CREATE TABLE IF NOT EXISTS chat_messages (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            session_id  UUID NOT NULL
                        REFERENCES chat_sessions(id) ON DELETE CASCADE,
            user_id     UUID NOT NULL
                        REFERENCES user_profiles(id) ON DELETE CASCADE,
            role        TEXT NOT NULL
                        CHECK (role IN ('user', 'assistant', 'system')),
            content     TEXT NOT NULL,
            token_count INTEGER,
            metadata    JSONB NOT NULL DEFAULT '{}',
            created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );
CREATE INDEX IF NOT EXISTS idx_chat_messages_session
            ON chat_messages(session_id, created_at);
CREATE INDEX IF NOT EXISTS idx_chat_messages_user
            ON chat_messages(user_id, created_at DESC);
ALTER TABLE chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- ===== 019_rag_content_chunks.py =====
CREATE EXTENSION IF NOT EXISTS vector;
CREATE TABLE IF NOT EXISTS content_chunks (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            source_type TEXT NOT NULL,          -- 'lesson' | 'knowledge_base' | ...
            source_id   UUID,                   -- id de la source (nullable)
            subject     TEXT,                    -- matiere, pour filtrer la recherche
            title       TEXT,                    -- titre affichable (citation)
            chunk_index INTEGER NOT NULL DEFAULT 0,
            chunk_text  TEXT NOT NULL,
            embedding   vector(768),             -- Ollama nomic-embed-text
            metadata    JSONB NOT NULL DEFAULT '{}',
            created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );
CREATE INDEX IF NOT EXISTS idx_content_chunks_embedding
            ON content_chunks USING hnsw (embedding vector_cosine_ops);
CREATE INDEX IF NOT EXISTS idx_content_chunks_source
            ON content_chunks(source_type, source_id);
ALTER TABLE content_chunks ENABLE ROW LEVEL SECURITY;
CREATE OR REPLACE FUNCTION match_content_chunks(
            query_embedding vector(768),
            match_count int DEFAULT 4,
            min_similarity float DEFAULT 0.3,
            filter_subject text DEFAULT NULL,
            filter_source_id uuid DEFAULT NULL
        )
        RETURNS TABLE (
            id uuid,
            source_type text,
            source_id uuid,
            subject text,
            title text,
            chunk_text text,
            similarity float
        )
        LANGUAGE sql STABLE
        AS $$
            SELECT
                c.id, c.source_type, c.source_id, c.subject, c.title, c.chunk_text,
                1 - (c.embedding <=> query_embedding) AS similarity
            FROM content_chunks c
            WHERE c.embedding IS NOT NULL
              AND (filter_subject IS NULL OR c.subject = filter_subject)
              AND (filter_source_id IS NULL OR c.source_id = filter_source_id)
              AND 1 - (c.embedding <=> query_embedding) >= min_similarity
            ORDER BY c.embedding <=> query_embedding
            LIMIT match_count;
        $$;

-- ===== 020_skills_mastery.py =====
CREATE TABLE IF NOT EXISTS skills (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            subject      TEXT NOT NULL,
            code         TEXT NOT NULL,          -- ex: 'MATH.FRAC.ADD'
            title        TEXT NOT NULL,
            description  TEXT,
            prerequisite_skill_ids UUID[] NOT NULL DEFAULT '{}',
            created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            UNIQUE (subject, code)
        );
CREATE INDEX IF NOT EXISTS idx_skills_subject ON skills(subject);
CREATE TABLE IF NOT EXISTS lesson_skills (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            lesson_id UUID NOT NULL
                      REFERENCES elearning_lessons(id) ON DELETE CASCADE,
            skill_id  UUID NOT NULL REFERENCES skills(id) ON DELETE CASCADE,
            weight    REAL NOT NULL DEFAULT 1.0,   -- poids de la competence dans la lecon
            UNIQUE (lesson_id, skill_id)
        );
CREATE INDEX IF NOT EXISTS idx_lesson_skills_skill
            ON lesson_skills(skill_id);
CREATE TABLE IF NOT EXISTS user_skill_mastery (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id     UUID NOT NULL
                        REFERENCES user_profiles(id) ON DELETE CASCADE,
            skill_id    UUID NOT NULL REFERENCES skills(id) ON DELETE CASCADE,
            p_mastery   REAL NOT NULL DEFAULT 0.3,   -- probabilite de maitrise [0,1]
            attempts    INTEGER NOT NULL DEFAULT 0,
            correct     INTEGER NOT NULL DEFAULT 0,
            last_updated TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            UNIQUE (user_id, skill_id)
        );
CREATE INDEX IF NOT EXISTS idx_user_skill_mastery_user
            ON user_skill_mastery(user_id, p_mastery);
ALTER TABLE skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_skill_mastery ENABLE ROW LEVEL SECURITY;

-- ===== 021_orientation_multi_factor.py =====
CREATE TABLE IF NOT EXISTS student_orientation_profile (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID NOT NULL UNIQUE
                    REFERENCES user_profiles(id) ON DELETE CASCADE,
            grades              JSONB NOT NULL DEFAULT '{}',
                                -- {"Mathematiques": 14.5, "Physique": 12} sur 20
            favorite_subjects   TEXT[] NOT NULL DEFAULT '{}',
            interests           TEXT[] NOT NULL DEFAULT '{}',
            budget_annual_fcfa  INTEGER,      -- budget max annuel pour les etudes
            career_project      TEXT,          -- projet professionnel (texte libre)
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );
ALTER TABLE student_orientation_profile ENABLE ROW LEVEL SECURITY;
ALTER TABLE school_programs
            ADD COLUMN IF NOT EXISTS tuition_annual_fcfa INTEGER;
ALTER TABLE school_programs
            ADD COLUMN IF NOT EXISTS is_public BOOLEAN;
ALTER TABLE careers
            ADD COLUMN IF NOT EXISTS key_subjects TEXT[] NOT NULL DEFAULT '{}';

-- Aligner le versionnement Alembic sur 021
CREATE TABLE IF NOT EXISTS alembic_version (
    version_num VARCHAR(32) NOT NULL CONSTRAINT alembic_version_pkc PRIMARY KEY
);
DELETE FROM alembic_version;
INSERT INTO alembic_version (version_num) VALUES ('021');

COMMIT;