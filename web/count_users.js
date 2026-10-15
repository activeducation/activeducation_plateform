require('dotenv').config({path: '.env.local'});
const postgres = require('postgres');
const sql = postgres(process.env.DATABASE_URL);
sql`SELECT count(*) FROM users`.then(console.log).then(() => process.exit());
