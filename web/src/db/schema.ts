import { pgTable, uuid, varchar, integer, timestamp, jsonb, text, boolean } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';

// Table des utilisateurs
export const users = pgTable('users', {
  id: uuid('id').primaryKey().defaultRandom(), // Lien avec auth.users() de Supabase
  email: varchar('email', { length: 255 }).notNull().unique(),
  fullName: varchar('full_name', { length: 255 }),
  avatarUrl: varchar('avatar_url', { length: 500 }),
  role: varchar('role', { length: 50 }).default('STUDENT'), // STUDENT, ADMIN
  xpPoints: integer('xp_points').default(0),
  level: integer('level').default(1),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

// ==========================================
// CATALOGUE & COURS
// ==========================================
export const courses = pgTable('courses', {
  id: uuid('id').primaryKey().defaultRandom(),
  title: varchar('title', { length: 255 }).notNull(),
  description: text('description'),
  category: varchar('category', { length: 100 }).notNull(),
  difficulty: varchar('difficulty', { length: 50 }).default('Débutant'),
  image: varchar('image', { length: 500 }),
  icon: varchar('icon', { length: 50 }), // Nom de l'icône Lucide
  color: varchar('color', { length: 100 }), // Classe Tailwind (ex: from-blue-500 to-primary)
  isPublished: boolean('is_published').default(false).notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

export const lessons = pgTable('lessons', {
  id: uuid('id').primaryKey().defaultRandom(),
  courseId: uuid('course_id').references(() => courses.id, { onDelete: 'cascade' }).notNull(),
  title: varchar('title', { length: 255 }).notNull(),
  description: text('description'),
  content: jsonb('content'), // Les différentes étapes (théorie, quiz, etc)
  orderIndex: integer('order_index').default(0).notNull(),
  rewardXp: integer('reward_xp').default(50).notNull(),
});

export const courseProgress = pgTable('course_progress', {
  userId: uuid('user_id').references(() => users.id, { onDelete: 'cascade' }).notNull(),
  courseId: uuid('course_id').references(() => courses.id, { onDelete: 'cascade' }).notNull(),
  status: varchar('status', { length: 50 }).default('IN_PROGRESS'), // NOT_STARTED, IN_PROGRESS, COMPLETED
  completedAt: timestamp('completed_at'),
});

// ==========================================
// OPPORTUNITÉS (Bourses, Stages, Événements)
// ==========================================
export const opportunities = pgTable('opportunities', {
  id: uuid('id').primaryKey().defaultRandom(),
  type: varchar('type', { length: 50 }).notNull(), // 'bourse', 'stage', 'evenement'
  title: varchar('title', { length: 255 }).notNull(),
  provider: varchar('provider', { length: 255 }), // Qui propose (L'Etat, Ecobank...)
  description: text('description'),
  location: varchar('location', { length: 255 }),
  amountOrSalary: varchar('amount_or_salary', { length: 255 }),
  deadline: timestamp('deadline'),
  eventDate: timestamp('event_date'), // Si c'est un événement
  criteria: jsonb('criteria'), // Tableau de critères
  documents: jsonb('documents'), // Pièces à fournir
  link: varchar('link', { length: 500 }),
  image: varchar('image', { length: 500 }),
  isRecommended: boolean('is_recommended').default(false).notNull(),
  isPublished: boolean('is_published').default(false).notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

// ==========================================
// IA & ORIENTATION
// ==========================================
export const aiConversations = pgTable('ai_conversations', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').references(() => users.id, { onDelete: 'cascade' }).notNull(),
  context: jsonb('context'),
  messages: jsonb('messages'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

export const orientationResults = pgTable('orientation_results', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').references(() => users.id, { onDelete: 'cascade' }).notNull(),
  inputs: jsonb('inputs').notNull(),
  results: jsonb('results').notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});
