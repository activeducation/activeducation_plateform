require('dotenv').config({path: '.env.local'});
const postgres = require('postgres');
const sql = postgres(process.env.DATABASE_URL);

async function checkLessons() {
  try {
    const lessons = await sql`SELECT id, title, content FROM lessons LIMIT 5`;
    console.log(JSON.stringify(lessons, null, 2));
  } catch (err) {
    console.error(err);
  } finally {
    process.exit();
  }
}

checkLessons();
