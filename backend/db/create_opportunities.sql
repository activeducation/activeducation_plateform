-- Table: opportunities
-- Types: internship, job, volunteer, scholarship

CREATE TABLE IF NOT EXISTS opportunities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    opportunity_type TEXT NOT NULL CHECK (opportunity_type IN ('internship', 'job', 'volunteer', 'scholarship')),
    organization_name TEXT NOT NULL,
    organization_logo TEXT,
    location TEXT,
    remote_type TEXT CHECK (remote_type IN ('onsite', 'remote', 'hybrid')),
    duration TEXT,
    requirements TEXT,
    benefits TEXT,
    salary_min INTEGER,
    salary_max INTEGER,
    salary_currency TEXT DEFAULT 'EUR',
    application_url TEXT,
    application_deadline TIMESTAMP WITH TIME ZONE,
    is_published BOOLEAN DEFAULT false,
    is_featured BOOLEAN DEFAULT false,
    school_id UUID REFERENCES schools(id) ON DELETE SET NULL,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS
ALTER TABLE opportunities ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Opportunities admin full access" ON opportunities
    FOR ALL USING (
        EXISTS (SELECT 1 FROM user_profiles WHERE user_id = auth.uid() AND role IN ('super_admin', 'school_admin'))
    );

CREATE POLICY "Opportunities public read published" ON opportunities
    FOR SELECT USING (is_published = true);

-- Index
CREATE INDEX idx_opportunities_type ON opportunities(opportunity_type);
CREATE INDEX idx_opportunities_published ON opportunities(is_published);
CREATE INDEX idx_opportunities_school ON opportunities(school_id);