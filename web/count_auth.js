require('dotenv').config({path: '.env.local'});
const postgres = require('postgres');
const sql = postgres(process.env.DATABASE_URL);
sql`SELECT count(*) FROM auth.users`.then(console.log).catch(console.error).then(() => process.exit());
