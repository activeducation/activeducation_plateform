import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';
import * as schema from './schema';

// Utilise la variable d'environnement de connexion directe à PostgreSQL
const connectionString = process.env.DATABASE_URL!;

// Configuration du client PostgreSQL
const client = postgres(connectionString, { prepare: false });

// Initialisation de Drizzle ORM avec notre schéma
export const db = drizzle(client, { schema });
