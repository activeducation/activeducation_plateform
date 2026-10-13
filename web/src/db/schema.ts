import { pgTable, uuid, varchar, integer, timestamp, jsonb, text, boolean, index, unique } from 'drizzle-orm/pg-core';

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

export const apiRateLimits = pgTable('api_rate_limits', {
  key: varchar('key', { length: 150 }).primaryKey(),
  count: integer('count').notNull(),
  resetAt: timestamp('reset_at', { withTimezone: true }).notNull(),
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
}, (table) => ({
  courseIdIdx: index('lessons_course_id_idx').on(table.courseId),
}));

export const courseProgress = pgTable('course_progress', {
  userId: uuid('user_id').references(() => users.id, { onDelete: 'cascade' }).notNull(),
  courseId: uuid('course_id').references(() => courses.id, { onDelete: 'cascade' }).notNull(),
  status: varchar('status', { length: 50 }).default('IN_PROGRESS'), // NOT_STARTED, IN_PROGRESS, COMPLETED
  completedLessons: jsonb('completed_lessons').$type<string[]>().default([]),
  completedAt: timestamp('completed_at'),
}, (table) => ({
  userIdIdx: index('progress_user_id_idx').on(table.userId),
  userCourseUnique: unique('course_progress_user_course_unique').on(table.userId, table.courseId),
  courseIdIdx: index('progress_course_id_idx').on(table.courseId),
}));

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


// ==========================================
// EXPLORATEUR D'ORIENTATION
// ==========================================

export const explorerDomains = pgTable('explorer_domains', {
  id: uuid('id').primaryKey().defaultRandom(),
  slug: varchar('slug', { length: 255 }).notNull().unique(), // ex: tech-numerique
  title: varchar('title', { length: 255 }).notNull(),
  bannerImage: varchar('banner_image', { length: 500 }),
  description: text('description'),
  growth: varchar('growth', { length: 100 }), // ex: +15% / an
  employability: varchar('employability', { length: 100 }), // ex: Très forte
  salary: varchar('salary', { length: 100 }), // ex: Élevé
  why: text('why'), // Pourquoi choisir ce domaine
  isPublished: boolean('is_published').default(false).notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

export const explorerSchools = pgTable('explorer_schools', {
  id: uuid('id').primaryKey().defaultRandom(),
  slug: varchar('slug', { length: 255 }).notNull().unique(), // ex: ul
  name: varchar('name', { length: 255 }).notNull(),
  type: varchar('type', { length: 100 }).default('Public'), // Public, Privé
  city: varchar('city', { length: 255 }),
  bannerImage: varchar('banner_image', { length: 500 }),
  description: text('description'),
  insertionRate: varchar('insertion_rate', { length: 50 }),
  rating: varchar('rating', { length: 10 }),
  reviewsCount: integer('reviews_count').default(0),
  facilities: jsonb('facilities').default([]), // ["Bibliothèque", "Campus"]
  isPublished: boolean('is_published').default(false).notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

export const explorerPrograms = pgTable('explorer_programs', {
  id: uuid('id').primaryKey().defaultRandom(),
  slug: varchar('slug', { length: 255 }).notNull().unique(), // ex: ul-cyber
  title: varchar('title', { length: 255 }).notNull(),
  schoolId: uuid('school_id').references(() => explorerSchools.id, { onDelete: 'cascade' }).notNull(),
  domainId: uuid('domain_id').references(() => explorerDomains.id, { onDelete: 'cascade' }).notNull(),
  bannerImage: varchar('banner_image', { length: 500 }),
  description: text('description'),
  level: varchar('level', { length: 100 }), // ex: Licence (Bac+3)
  duration: varchar('duration', { length: 100 }), // ex: 3 ans
  admission: text('admission'),
  status: varchar('status', { length: 255 }), // ex: Reconnu CAMES
  programCourses: jsonb('program_courses').default([]), // ["Algorithmique", "Réseaux"]
  isPublished: boolean('is_published').default(false).notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
}, (table) => ({
  schoolIdIdx: index('programs_school_id_idx').on(table.schoolId),
  domainIdIdx: index('programs_domain_id_idx').on(table.domainId),
}));

export const explorerCareers = pgTable('explorer_careers', {
  id: uuid('id').primaryKey().defaultRandom(),
  slug: varchar('slug', { length: 255 }).notNull().unique(), // ex: cybersecurite
  title: varchar('title', { length: 255 }).notNull(),
  domainId: uuid('domain_id').references(() => explorerDomains.id, { onDelete: 'cascade' }).notNull(),
  bannerImage: varchar('banner_image', { length: 500 }),
  description: text('description'),
  skills: jsonb('skills').default([]), // ["Cryptographie", "Réseaux"]
  opportunities: jsonb('opportunities').default([]), // ["Analyste SOC", "Consultant Cyber"]
  isPublished: boolean('is_published').default(false).notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
}, (table) => ({
  domainIdIdx: index('careers_domain_id_idx').on(table.domainId),
}));

export const explorerCareerPrograms = pgTable('explorer_career_programs', {
  careerId: uuid('career_id').references(() => explorerCareers.id, { onDelete: 'cascade' }).notNull(),
  programId: uuid('program_id').references(() => explorerPrograms.id, { onDelete: 'cascade' }).notNull(),
}, (table) => ({
  careerIdIdx: index('cp_career_id_idx').on(table.careerId),
  careerProgramUnique: unique('career_program_unique').on(table.careerId, table.programId),
  programIdIdx: index('cp_program_id_idx').on(table.programId),
}));
