-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==========================================
-- ENUMS
-- ==========================================
CREATE TYPE user_type AS ENUM ('student', 'professional', 'mentor', 'admin');
CREATE TYPE test_type AS ENUM ('riasec', 'personality', 'skills');
CREATE TYPE mentor_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE relationship_status AS ENUM ('pending', 'accepted', 'declined', 'completed');
CREATE TYPE challenge_type AS ENUM ('daily', 'weekly', 'milestone');

-- ==========================================
-- USERS & PROFILES
-- ==========================================
-- Note: Supabase handles auth.users. We extend it with public.users or profiles table.
-- We will use a trigger to auto-create profile on auth.sign_up usually, but here is the definition.

CREATE TABLE public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    avatar_url TEXT,
    role user_type DEFAULT 'student',
    bio TEXT,
    
    -- Gamification Stats
    xp_points INTEGER DEFAULT 0,
    level INTEGER DEFAULT 1,
    current_streak INTEGER DEFAULT 0,
    last_activity_at TIMESTAMPTZ DEFAULT NOW(),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Turn on RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Policies (Simple examples)
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles
    FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- ==========================================
-- MENTORS
-- ==========================================
CREATE TABLE public.mentors (
    id UUID REFERENCES public.profiles(id) ON DELETE CASCADE PRIMARY KEY,
    specialty TEXT NOT NULL,
    expertise_areas TEXT[], -- Array of strings
    hourly_rate DECIMAL(10, 2) DEFAULT 0,
    is_verified BOOLEAN DEFAULT FALSE,
    rating FLOAT DEFAULT 0,
    review_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.mentors ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Mentors are viewable by everyone" ON public.mentors
    FOR SELECT USING (true);

-- ==========================================
-- ORIENTATION
-- ==========================================
CREATE TABLE public.orientation_tests (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    type test_type NOT NULL,
    content JSONB NOT NULL, -- Questions and logic
    duration_minutes INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.user_test_sessions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    test_id UUID REFERENCES public.orientation_tests(id),
    responses JSONB,
    results JSONB,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

ALTER TABLE public.user_test_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can see their own sessions" ON public.user_test_sessions
    FOR SELECT USING (auth.uid() = user_id);

-- ==========================================
-- MENTORING RELATIONSHIPS
-- ==========================================
CREATE TABLE public.mentor_relationships (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    student_id UUID REFERENCES public.profiles(id),
    mentor_id UUID REFERENCES public.mentors(id),
    status relationship_status DEFAULT 'pending',
    message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.mentor_relationships ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- MESSAGES
-- ==========================================
CREATE TABLE public.conversations (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.conversation_participants (
    conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    PRIMARY KEY (conversation_id, user_id)
);

CREATE TABLE public.messages (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES public.profiles(id),
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- GAMIFICATION
-- ==========================================
CREATE TABLE public.achievements (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    icon_code TEXT,
    xp_reward INTEGER DEFAULT 100,
    condition_type TEXT -- Helper for backend logic
);

CREATE TABLE public.user_achievements (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    achievement_id UUID REFERENCES public.achievements(id),
    earned_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================
-- FUNCTIONS & TRIGGERS
-- ==========================================
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, avatar_url)
  VALUES (new.id, new.email, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'avatar_url');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE handle_new_user();
