require('dotenv').config({path: '.env.local'});
const postgres = require('postgres');
const sql = postgres(process.env.DATABASE_URL);
async function run() {
  await sql`CREATE INDEX IF NOT EXISTS lessons_course_id_idx ON lessons (course_id)`;
  await sql`CREATE INDEX IF NOT EXISTS progress_user_id_idx ON course_progress (user_id)`;
  await sql`CREATE INDEX IF NOT EXISTS progress_course_id_idx ON course_progress (course_id)`;
  console.log('Indexes created successfully');
}
run().catch(console.error).finally(()=>process.exit(0));
