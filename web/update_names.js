require('dotenv').config({path: '.env.local'});
const postgres = require('postgres');
const sql = postgres(process.env.DATABASE_URL);

async function updateNames() {
  try {
    const authUsers = await sql`SELECT id, raw_user_meta_data FROM auth.users`;
    
    for (const au of authUsers) {
      if (au.raw_user_meta_data) {
        const firstName = au.raw_user_meta_data.first_name || '';
        const lastName = au.raw_user_meta_data.last_name || '';
        const fullName = `${firstName} ${lastName}`.trim();
        
        if (fullName) {
          await sql`
            UPDATE public.users 
            SET full_name = ${fullName} 
            WHERE id = ${au.id}
          `;
        }
      }
    }
    console.log('Names updated successfully!');
  } catch (err) {
    console.error(err);
  } finally {
    process.exit();
  }
}

updateNames();
