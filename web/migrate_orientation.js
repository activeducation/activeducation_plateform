const postgres = require('postgres');
require('dotenv').config({ path: '.env.local' });

const sql = postgres(process.env.DATABASE_URL, { max: 1 });

async function main() {
  try {
    console.log('Creating explorer_domains table...');
    await sql`
      CREATE TABLE IF NOT EXISTS explorer_domains (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        slug VARCHAR(255) NOT NULL UNIQUE,
        title VARCHAR(255) NOT NULL,
        banner_image VARCHAR(500),
        description TEXT,
        growth VARCHAR(100),
        employability VARCHAR(100),
        salary VARCHAR(100),
        why TEXT,
        is_published BOOLEAN DEFAULT false NOT NULL,
        created_at TIMESTAMP DEFAULT now() NOT NULL
      );
    `;

    console.log('Creating explorer_schools table...');
    await sql`
      CREATE TABLE IF NOT EXISTS explorer_schools (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        slug VARCHAR(255) NOT NULL UNIQUE,
        name VARCHAR(255) NOT NULL,
        type VARCHAR(100) DEFAULT 'Public',
        city VARCHAR(255),
        banner_image VARCHAR(500),
        description TEXT,
        insertion_rate VARCHAR(50),
        rating VARCHAR(10),
        reviews_count INTEGER DEFAULT 0,
        facilities JSONB DEFAULT '[]'::jsonb,
        is_published BOOLEAN DEFAULT false NOT NULL,
        created_at TIMESTAMP DEFAULT now() NOT NULL
      );
    `;

    console.log('Creating explorer_programs table...');
    await sql`
      CREATE TABLE IF NOT EXISTS explorer_programs (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        slug VARCHAR(255) NOT NULL UNIQUE,
        title VARCHAR(255) NOT NULL,
        school_id UUID NOT NULL REFERENCES explorer_schools(id) ON DELETE CASCADE,
        domain_id UUID NOT NULL REFERENCES explorer_domains(id) ON DELETE CASCADE,
        banner_image VARCHAR(500),
        description TEXT,
        level VARCHAR(100),
        duration VARCHAR(100),
        admission TEXT,
        status VARCHAR(255),
        program_courses JSONB DEFAULT '[]'::jsonb,
        is_published BOOLEAN DEFAULT false NOT NULL,
        created_at TIMESTAMP DEFAULT now() NOT NULL
      );
    `;
    await sql`CREATE INDEX IF NOT EXISTS explorer_programs_school_id_idx ON explorer_programs(school_id);`;
    await sql`CREATE INDEX IF NOT EXISTS explorer_programs_domain_id_idx ON explorer_programs(domain_id);`;

    console.log('Creating explorer_careers table...');
    await sql`
      CREATE TABLE IF NOT EXISTS explorer_careers (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        slug VARCHAR(255) NOT NULL UNIQUE,
        title VARCHAR(255) NOT NULL,
        domain_id UUID NOT NULL REFERENCES explorer_domains(id) ON DELETE CASCADE,
        banner_image VARCHAR(500),
        description TEXT,
        skills JSONB DEFAULT '[]'::jsonb,
        opportunities JSONB DEFAULT '[]'::jsonb,
        is_published BOOLEAN DEFAULT false NOT NULL,
        created_at TIMESTAMP DEFAULT now() NOT NULL
      );
    `;
    await sql`CREATE INDEX IF NOT EXISTS explorer_careers_domain_id_idx ON explorer_careers(domain_id);`;

    console.log('Creating explorer_career_programs table...');
    await sql`
      CREATE TABLE IF NOT EXISTS explorer_career_programs (
        career_id UUID NOT NULL REFERENCES explorer_careers(id) ON DELETE CASCADE,
        program_id UUID NOT NULL REFERENCES explorer_programs(id) ON DELETE CASCADE
      );
    `;
    await sql`CREATE INDEX IF NOT EXISTS explorer_cp_career_id_idx ON explorer_career_programs(career_id);`;
    await sql`CREATE INDEX IF NOT EXISTS explorer_cp_program_id_idx ON explorer_career_programs(program_id);`;

    console.log('All orientation tables created successfully.');
  } catch (error) {
    console.error('Error creating tables:', error);
  } finally {
    await sql.end();
  }
}

main();
