-- =============================================================================
-- ActivEducation - Schema de Base de Donnees Supabase
-- =============================================================================
-- Ce fichier contient toutes les tables necessaires pour l'application.
-- A executer dans l'editeur SQL de Supabase.
-- =============================================================================

-- Activer les extensions necessaires
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- TABLES UTILISATEURS
-- =============================================================================

-- Profils utilisateurs
-- Note: pas de FK vers auth.users car le backend gere ses propres UUIDs
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT,
    reset_token TEXT,
    reset_token_expires TIMESTAMPTZ,
    first_name TEXT,
    last_name TEXT,
    display_name TEXT,
    avatar_url TEXT,
    date_of_birth DATE,
    phone_number TEXT,
    school_name TEXT,
    class_level TEXT, -- e.g., "Terminale", "1ere", "2nde"
    preferred_language TEXT DEFAULT 'fr',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour les recherches
CREATE INDEX idx_user_profiles_email ON user_profiles(email);
CREATE INDEX idx_user_profiles_reset_token ON user_profiles(reset_token);

-- Refresh tokens (stockes hashes, pas les tokens en clair)
CREATE TABLE IF NOT EXISTS auth_refresh_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    token_hash TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    revoked_at TIMESTAMPTZ
);
CREATE INDEX idx_auth_refresh_tokens_user_id ON auth_refresh_tokens(user_id);
CREATE INDEX idx_auth_refresh_tokens_expires_at ON auth_refresh_tokens(expires_at);

-- =============================================================================
-- TABLES ORIENTATION (Tests et Resultats)
-- =============================================================================

-- Types de tests (ENUM simule via TEXT + CHECK)
-- Types valides: 'riasec', 'personality', 'skills', 'interests', 'aptitude'

-- Tests d'orientation
CREATE TABLE IF NOT EXISTS orientation_tests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('riasec', 'personality', 'skills', 'interests', 'aptitude')),
    duration_minutes INTEGER NOT NULL DEFAULT 15,
    image_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Questions des tests
CREATE TABLE IF NOT EXISTS test_questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    test_id UUID NOT NULL REFERENCES orientation_tests(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    question_type TEXT NOT NULL CHECK (question_type IN ('likert', 'multiple_choice', 'boolean')),
    category TEXT, -- e.g., "Realistic", "Artistic", "Social"
    display_order INTEGER NOT NULL DEFAULT 0,
    is_required BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour charger les questions d'un test
CREATE INDEX idx_test_questions_test_id ON test_questions(test_id);

-- Options de reponse pour les questions
CREATE TABLE IF NOT EXISTS question_options (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_id UUID NOT NULL REFERENCES test_questions(id) ON DELETE CASCADE,
    option_text TEXT NOT NULL,
    option_value INTEGER NOT NULL, -- Points attribues
    display_order INTEGER NOT NULL DEFAULT 0,
    icon TEXT -- Optionnel: icone pour l'affichage
);

-- Index pour charger les options d'une question
CREATE INDEX idx_question_options_question_id ON question_options(question_id);

-- Sessions de test utilisateur
CREATE TABLE IF NOT EXISTS user_test_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    test_id UUID NOT NULL REFERENCES orientation_tests(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed', 'abandoned')),
    responses JSONB DEFAULT '{}', -- {"question_id": "option_id", ...}
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour l'historique d'un utilisateur
CREATE INDEX idx_user_test_sessions_user_id ON user_test_sessions(user_id);
CREATE INDEX idx_user_test_sessions_status ON user_test_sessions(status);

-- Resultats des tests
CREATE TABLE IF NOT EXISTS test_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES user_test_sessions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    test_id UUID NOT NULL REFERENCES orientation_tests(id) ON DELETE CASCADE,
    scores JSONB NOT NULL, -- {"Realistic": 85.0, "Investigative": 40.0, ...}
    dominant_traits TEXT[] NOT NULL, -- ["Realistic", "Investigative", "Artistic"]
    recommendations UUID[], -- Liste des career_id recommandes
    calculated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour recuperer les resultats d'un utilisateur
CREATE INDEX idx_test_results_user_id ON test_results(user_id);

-- =============================================================================
-- TABLES CARRIERES
-- =============================================================================

-- Secteurs d'activite
CREATE TABLE IF NOT EXISTS career_sectors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    icon TEXT,
    display_order INTEGER DEFAULT 0
);

-- Carrieres/Metiers
CREATE TABLE IF NOT EXISTS careers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    sector_id UUID REFERENCES career_sectors(id),
    sector_name TEXT NOT NULL, -- Denormalise pour les requetes simples
    image_url TEXT,

    -- Competences et traits
    required_skills TEXT[] NOT NULL DEFAULT '{}',
    related_traits TEXT[] NOT NULL DEFAULT '{}', -- RIASEC codes: ["R", "I", "A"]

    -- Parcours educatif (JSONB pour flexibilite)
    education_path JSONB NOT NULL DEFAULT '{
        "minimum_level": "BAC",
        "recommended_formations": [],
        "schools_in_togo": [],
        "duration_years": 3,
        "certifications": null
    }',

    -- Informations salariales (en FCFA)
    salary_min_fcfa INTEGER,
    salary_max_fcfa INTEGER,
    salary_avg_fcfa INTEGER,
    salary_note TEXT,

    -- Perspectives d'emploi
    job_demand TEXT CHECK (job_demand IN ('high', 'medium', 'low')),
    growth_trend TEXT CHECK (growth_trend IN ('growing', 'stable', 'declining')),
    outlook_description TEXT,
    top_employers TEXT[] DEFAULT '{}',
    entrepreneurship_potential BOOLEAN DEFAULT FALSE,

    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour les recherches
CREATE INDEX idx_careers_sector ON careers(sector_name);
CREATE INDEX idx_careers_demand ON careers(job_demand);
CREATE INDEX idx_careers_traits ON careers USING GIN(related_traits);

-- Carrieres favorites des utilisateurs
CREATE TABLE IF NOT EXISTS user_favorite_careers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    career_id UUID NOT NULL REFERENCES careers(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, career_id)
);

-- =============================================================================
-- TABLES GAMIFICATION
-- =============================================================================

-- Profil de gamification utilisateur
CREATE TABLE IF NOT EXISTS user_gamification (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES user_profiles(id) ON DELETE CASCADE,
    total_points INTEGER DEFAULT 0,
    current_level INTEGER DEFAULT 1,
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    last_activity_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Badges/Achievements
CREATE TABLE IF NOT EXISTS achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    icon TEXT NOT NULL,
    category TEXT NOT NULL, -- 'test', 'exploration', 'social', 'streak'
    points_reward INTEGER DEFAULT 0,
    requirement_type TEXT NOT NULL, -- 'tests_completed', 'careers_explored', etc.
    requirement_value INTEGER NOT NULL, -- Nombre requis
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Achievements deverrouilles par utilisateur
CREATE TABLE IF NOT EXISTS user_achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    achievement_id UUID NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
    unlocked_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, achievement_id)
);

-- Challenges/Defis
CREATE TABLE IF NOT EXISTS challenges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    challenge_type TEXT NOT NULL, -- 'daily', 'weekly', 'special'
    points_reward INTEGER NOT NULL,
    requirement_type TEXT NOT NULL,
    requirement_value INTEGER NOT NULL,
    start_date TIMESTAMPTZ,
    end_date TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Participation aux challenges
CREATE TABLE IF NOT EXISTS user_challenges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    challenge_id UUID NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
    progress INTEGER DEFAULT 0,
    is_completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, challenge_id)
);

-- Leaderboard (vue materialisee pour performance)
CREATE TABLE IF NOT EXISTS leaderboard_weekly (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    week_start DATE NOT NULL,
    points_earned INTEGER DEFAULT 0,
    rank INTEGER,
    UNIQUE(user_id, week_start)
);

-- =============================================================================
-- TABLES MENTORING
-- =============================================================================

-- Profils mentors
CREATE TABLE IF NOT EXISTS mentors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE REFERENCES user_profiles(id) ON DELETE CASCADE,
    profession TEXT NOT NULL,
    company TEXT,
    bio TEXT NOT NULL,
    expertise_areas TEXT[] NOT NULL DEFAULT '{}',
    years_experience INTEGER,
    availability TEXT, -- 'available', 'limited', 'unavailable'
    max_mentees INTEGER DEFAULT 5,
    current_mentees INTEGER DEFAULT 0,
    rating_avg DECIMAL(3,2) DEFAULT 0,
    rating_count INTEGER DEFAULT 0,
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Relations mentor-mentee
CREATE TABLE IF NOT EXISTS mentor_relationships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    mentor_id UUID NOT NULL REFERENCES mentors(id) ON DELETE CASCADE,
    mentee_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'completed', 'cancelled')),
    message TEXT, -- Message initial du mentee
    started_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(mentor_id, mentee_id)
);

-- Avis sur les mentors
CREATE TABLE IF NOT EXISTS mentor_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    mentor_id UUID NOT NULL REFERENCES mentors(id) ON DELETE CASCADE,
    reviewer_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(mentor_id, reviewer_id)
);

-- =============================================================================
-- TABLES MESSAGERIE
-- =============================================================================

-- Conversations
CREATE TABLE IF NOT EXISTS conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    participant_1 UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    participant_2 UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    last_message_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(participant_1, participant_2)
);

-- Messages
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour charger les messages d'une conversation
CREATE INDEX idx_messages_conversation ON messages(conversation_id, created_at DESC);

-- =============================================================================
-- TABLES ECOLES
-- =============================================================================

-- Etablissements scolaires au Togo
CREATE TABLE IF NOT EXISTS schools (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    type TEXT NOT NULL, -- 'university', 'grande_ecole', 'institut', 'centre_formation'
    city TEXT NOT NULL,
    address TEXT,
    phone TEXT,
    email TEXT,
    website TEXT,
    description TEXT,
    programs_offered TEXT[] DEFAULT '{}',
    is_public BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,
    logo_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour les recherches
CREATE INDEX idx_schools_city ON schools(city);
CREATE INDEX idx_schools_type ON schools(type);

-- =============================================================================
-- FONCTIONS ET TRIGGERS
-- =============================================================================

-- Fonction pour mettre a jour updated_at automatiquement
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Appliquer le trigger aux tables avec updated_at
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orientation_tests_updated_at
    BEFORE UPDATE ON orientation_tests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_careers_updated_at
    BEFORE UPDATE ON careers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_gamification_updated_at
    BEFORE UPDATE ON user_gamification
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_mentors_updated_at
    BEFORE UPDATE ON mentors
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_schools_updated_at
    BEFORE UPDATE ON schools
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================================================
-- Note: Le backend gere ses propres JWT (pas Supabase Auth), donc auth.uid()
-- n'est pas disponible. On desactive RLS pour que le backend (via anon key)
-- puisse acceder aux tables. La securite est geree par le backend (JWT + middleware).
-- En production, utilisez la service_role key ou configurez des policies adaptees.

-- Desactiver RLS pour permettre l'acces depuis le backend
ALTER TABLE user_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE user_test_sessions DISABLE ROW LEVEL SECURITY;
ALTER TABLE test_results DISABLE ROW LEVEL SECURITY;
ALTER TABLE user_favorite_careers DISABLE ROW LEVEL SECURITY;
ALTER TABLE user_gamification DISABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements DISABLE ROW LEVEL SECURITY;
ALTER TABLE user_challenges DISABLE ROW LEVEL SECURITY;
ALTER TABLE mentor_relationships DISABLE ROW LEVEL SECURITY;
ALTER TABLE messages DISABLE ROW LEVEL SECURITY;

-- =============================================================================
-- DONNEES INITIALES
-- =============================================================================

-- Secteurs d'activite
INSERT INTO career_sectors (name, description, icon, display_order) VALUES
    ('Technologie & IT', 'Informatique, developpement, reseaux', 'computer', 1),
    ('Sante', 'Medecine, pharmacie, soins infirmiers', 'health', 2),
    ('Education', 'Enseignement, formation, recherche', 'school', 3),
    ('Finance & Banque', 'Comptabilite, banque, assurance', 'bank', 4),
    ('Commerce & Entrepreneuriat', 'Vente, marketing, gestion', 'store', 5),
    ('Ingenierie & Construction', 'Genie civil, architecture, BTP', 'construction', 6),
    ('Agriculture & Environnement', 'Agronomie, environnement, ressources naturelles', 'agriculture', 7),
    ('Arts & Media', 'Communication, design, audiovisuel', 'media', 8),
    ('Droit & Administration', 'Juridique, administration publique', 'law', 9)
ON CONFLICT (name) DO NOTHING;

-- Test RIASEC initial
INSERT INTO orientation_tests (id, name, description, type, duration_minutes, display_order) VALUES
    ('123e4567-e89b-12d3-a456-426614174000',
     'Test d''Interets Professionnels (RIASEC)',
     'Decouvrez les metiers qui correspondent le mieux a vos centres d''interet selon la theorie de Holland.',
     'riasec',
     15,
     1)
ON CONFLICT (id) DO NOTHING;

-- Questions RIASEC (6 categories, plusieurs questions par categorie)
-- Realistic
INSERT INTO test_questions (test_id, question_text, question_type, category, display_order) VALUES
    ('123e4567-e89b-12d3-a456-426614174000', 'J''aime reparer des appareils electriques ou mecaniques.', 'likert', 'Realistic', 1),
    ('123e4567-e89b-12d3-a456-426614174000', 'Je prefere travailler avec des outils et des machines.', 'likert', 'Realistic', 2),
    ('123e4567-e89b-12d3-a456-426614174000', 'J''aime construire ou fabriquer des objets de mes mains.', 'likert', 'Realistic', 3);

-- Investigative
INSERT INTO test_questions (test_id, question_text, question_type, category, display_order) VALUES
    ('123e4567-e89b-12d3-a456-426614174000', 'J''aime resoudre des problemes mathematiques complexes.', 'likert', 'Investigative', 4),
    ('123e4567-e89b-12d3-a456-426614174000', 'Je suis curieux et j''aime comprendre comment les choses fonctionnent.', 'likert', 'Investigative', 5),
    ('123e4567-e89b-12d3-a456-426614174000', 'J''aime mener des experiences et analyser des donnees.', 'likert', 'Investigative', 6);

-- Artistic
INSERT INTO test_questions (test_id, question_text, question_type, category, display_order) VALUES
    ('123e4567-e89b-12d3-a456-426614174000', 'J''aime dessiner, peindre ou faire de la musique.', 'likert', 'Artistic', 7),
    ('123e4567-e89b-12d3-a456-426614174000', 'J''ai une imagination debordante et j''aime creer.', 'likert', 'Artistic', 8),
    ('123e4567-e89b-12d3-a456-426614174000', 'Je prefere m''exprimer de maniere creative plutot que suivre des regles.', 'likert', 'Artistic', 9);

-- Social
INSERT INTO test_questions (test_id, question_text, question_type, category, display_order) VALUES
    ('123e4567-e89b-12d3-a456-426614174000', 'J''aime aider les autres et leur enseigner de nouvelles choses.', 'likert', 'Social', 10),
    ('123e4567-e89b-12d3-a456-426614174000', 'Je suis a l''aise pour parler en public ou animer des groupes.', 'likert', 'Social', 11),
    ('123e4567-e89b-12d3-a456-426614174000', 'Je me soucie du bien-etre des autres et j''aime les conseiller.', 'likert', 'Social', 12);

-- Enterprising
INSERT INTO test_questions (test_id, question_text, question_type, category, display_order) VALUES
    ('123e4567-e89b-12d3-a456-426614174000', 'J''aime diriger une equipe et prendre des decisions.', 'likert', 'Enterprising', 13),
    ('123e4567-e89b-12d3-a456-426614174000', 'Je suis motive par la reussite et les defis ambitieux.', 'likert', 'Enterprising', 14),
    ('123e4567-e89b-12d3-a456-426614174000', 'J''aime convaincre et negocier avec les autres.', 'likert', 'Enterprising', 15);

-- Conventional
INSERT INTO test_questions (test_id, question_text, question_type, category, display_order) VALUES
    ('123e4567-e89b-12d3-a456-426614174000', 'J''aime organiser des dossiers et des donnees de maniere ordonnee.', 'likert', 'Conventional', 16),
    ('123e4567-e89b-12d3-a456-426614174000', 'Je prefere suivre des procedures etablies et claires.', 'likert', 'Conventional', 17),
    ('123e4567-e89b-12d3-a456-426614174000', 'Je suis minutieux et attentif aux details.', 'likert', 'Conventional', 18);

-- Options pour les questions Likert (1-5)
-- Cette requete insere les options pour toutes les questions likert du test RIASEC
INSERT INTO question_options (question_id, option_text, option_value, display_order)
SELECT
    q.id,
    opt.text,
    opt.value,
    opt.value
FROM test_questions q
CROSS JOIN (
    VALUES
        ('Pas du tout', 1),
        ('Un peu', 2),
        ('Moyennement', 3),
        ('Beaucoup', 4),
        ('Passionnement', 5)
) AS opt(text, value)
WHERE q.test_id = '123e4567-e89b-12d3-a456-426614174000'
AND q.question_type = 'likert';

-- Achievements initiaux
INSERT INTO achievements (name, description, icon, category, points_reward, requirement_type, requirement_value) VALUES
    ('Premier Pas', 'Completez votre premier test d''orientation', 'star', 'test', 50, 'tests_completed', 1),
    ('Explorateur', 'Explorez 5 carrieres differentes', 'explore', 'exploration', 30, 'careers_explored', 5),
    ('Assidu', 'Connectez-vous 7 jours consecutifs', 'fire', 'streak', 100, 'streak_days', 7),
    ('Expert', 'Completez tous les tests disponibles', 'trophy', 'test', 200, 'all_tests_completed', 1),
    ('Curieux', 'Explorez 20 carrieres differentes', 'search', 'exploration', 75, 'careers_explored', 20),
    ('Mentor en herbe', 'Demandez conseil a un mentor', 'people', 'social', 40, 'mentor_requests', 1)
ON CONFLICT DO NOTHING;

-- =============================================================================
-- FIN DU SCHEMA
-- =============================================================================
