require('dotenv').config({path: '.env.local'});
const postgres = require('postgres');
const sql = postgres(process.env.DATABASE_URL);

async function syncUsers() {
  try {
    const authUsers = await sql`SELECT id, email, created_at FROM auth.users`;
    console.log(`Found ${authUsers.length} users in auth.users`);

    for (const au of authUsers) {
      await sql`
        INSERT INTO public.users (id, email, created_at, role)
        VALUES (${au.id}, ${au.email}, ${au.created_at}, 'STUDENT')
        ON CONFLICT (id) DO NOTHING
      `;
    }
    console.log('Sync complete!');
  } catch (err) {
    console.error(err);
  } finally {
    process.exit();
  }
}

syncUsers();
