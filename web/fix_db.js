const postgres = require('postgres');
require('dotenv').config({ path: '.env.local' });

const sql = postgres(process.env.DATABASE_URL, { prepare: false });

async function fix() {
  try {
    console.log("Deduplicating course_progress...");
    await sql`
      DELETE FROM course_progress a
      USING course_progress b
      WHERE a.user_id = b.user_id
        AND a.course_id = b.course_id
        AND a.ctid < b.ctid;
    `;
    
    console.log("Adding unique constraint to course_progress...");
    await sql`
      ALTER TABLE course_progress ADD CONSTRAINT course_progress_user_course_unique UNIQUE (user_id, course_id);
    `.catch(e => console.log("Constraint already exists or error:", e.message));

    console.log("Deduplicating explorer_career_programs...");
    await sql`
      DELETE FROM explorer_career_programs a
      USING explorer_career_programs b
      WHERE a.career_id = b.career_id
        AND a.program_id = b.program_id
        AND a.ctid < b.ctid;
    `;

    console.log("Adding unique constraint to explorer_career_programs...");
    await sql`
      ALTER TABLE explorer_career_programs ADD CONSTRAINT career_program_unique UNIQUE (career_id, program_id);
    `.catch(e => console.log("Constraint already exists or error:", e.message));

  } catch (error) {
    console.error(error);
  } finally {
    process.exit(0);
  }
}
fix();
