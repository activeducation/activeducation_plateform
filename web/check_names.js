require('dotenv').config({path: '.env.local'});
const postgres = require('postgres');
const sql = postgres(process.env.DATABASE_URL);

async function checkNames() {
  try {
    const authUsers = await sql`SELECT id, raw_user_meta_data FROM auth.users LIMIT 5`;
    console.log(JSON.stringify(authUsers, null, 2));
  } catch (err) {
    console.error(err);
  } finally {
    process.exit();
  }
}

checkNames();
