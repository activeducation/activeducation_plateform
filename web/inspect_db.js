const postgres = require('postgres');
require('dotenv').config({ path: '.env.local' });

const sql = postgres(process.env.DATABASE_URL, { max: 1 });

async function main() {
  try {
    const res = await sql`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'careers'
    `;
    console.log('careers:', res);
    
    const res2 = await sql`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'schools'
    `;
    console.log('schools:', res2);
  } finally {
    await sql.end();
  }
}

main();
