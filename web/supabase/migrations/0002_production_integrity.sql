CREATE TABLE IF NOT EXISTS "api_rate_limits" (
	"key" varchar(150) PRIMARY KEY NOT NULL,
	"count" integer NOT NULL,
	"reset_at" timestamp with time zone NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "explorer_career_programs" (
	"career_id" uuid NOT NULL,
	"program_id" uuid NOT NULL,
	CONSTRAINT "career_program_unique" UNIQUE("career_id","program_id")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "explorer_careers" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"slug" varchar(255) NOT NULL,
	"title" varchar(255) NOT NULL,
	"domain_id" uuid NOT NULL,
	"banner_image" varchar(500),
	"description" text,
	"skills" jsonb DEFAULT '[]'::jsonb,
	"opportunities" jsonb DEFAULT '[]'::jsonb,
	"is_published" boolean DEFAULT false NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "explorer_careers_slug_unique" UNIQUE("slug")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "explorer_domains" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"slug" varchar(255) NOT NULL,
	"title" varchar(255) NOT NULL,
	"banner_image" varchar(500),
	"description" text,
	"growth" varchar(100),
	"employability" varchar(100),
	"salary" varchar(100),
	"why" text,
	"is_published" boolean DEFAULT false NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "explorer_domains_slug_unique" UNIQUE("slug")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "explorer_programs" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"slug" varchar(255) NOT NULL,
	"title" varchar(255) NOT NULL,
	"school_id" uuid NOT NULL,
	"domain_id" uuid NOT NULL,
	"banner_image" varchar(500),
	"description" text,
	"level" varchar(100),
	"duration" varchar(100),
	"admission" text,
	"status" varchar(255),
	"program_courses" jsonb DEFAULT '[]'::jsonb,
	"is_published" boolean DEFAULT false NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "explorer_programs_slug_unique" UNIQUE("slug")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "explorer_schools" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"slug" varchar(255) NOT NULL,
	"name" varchar(255) NOT NULL,
	"type" varchar(100) DEFAULT 'Public',
	"city" varchar(255),
	"banner_image" varchar(500),
	"description" text,
	"insertion_rate" varchar(50),
	"rating" varchar(10),
	"reviews_count" integer DEFAULT 0,
	"facilities" jsonb DEFAULT '[]'::jsonb,
	"is_published" boolean DEFAULT false NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "explorer_schools_slug_unique" UNIQUE("slug")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "lessons" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"course_id" uuid NOT NULL,
	"title" varchar(255) NOT NULL,
	"description" text,
	"content" jsonb,
	"order_index" integer DEFAULT 0 NOT NULL,
	"reward_xp" integer DEFAULT 50 NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "opportunities" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"type" varchar(50) NOT NULL,
	"title" varchar(255) NOT NULL,
	"provider" varchar(255),
	"description" text,
	"location" varchar(255),
	"amount_or_salary" varchar(255),
	"deadline" timestamp,
	"event_date" timestamp,
	"criteria" jsonb,
	"documents" jsonb,
	"link" varchar(500),
	"image" varchar(500),
	"is_recommended" boolean DEFAULT false NOT NULL,
	"is_published" boolean DEFAULT false NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "courses" ALTER COLUMN "description" SET DATA TYPE text;--> statement-breakpoint
ALTER TABLE "course_progress" ADD COLUMN IF NOT EXISTS "completed_lessons" jsonb DEFAULT '[]'::jsonb;--> statement-breakpoint
ALTER TABLE "courses" ADD COLUMN IF NOT EXISTS "difficulty" varchar(50) DEFAULT 'Débutant';--> statement-breakpoint
ALTER TABLE "courses" ADD COLUMN IF NOT EXISTS "image" varchar(500);--> statement-breakpoint
ALTER TABLE "courses" ADD COLUMN IF NOT EXISTS "icon" varchar(50);--> statement-breakpoint
ALTER TABLE "courses" ADD COLUMN IF NOT EXISTS "color" varchar(100);--> statement-breakpoint
ALTER TABLE "courses" ADD COLUMN IF NOT EXISTS "is_published" boolean DEFAULT false NOT NULL;--> statement-breakpoint
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "avatar_url" varchar(500);--> statement-breakpoint
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'explorer_career_programs_career_id_explorer_careers_id_fk' AND conrelid = 'public.explorer_career_programs'::regclass) THEN
    ALTER TABLE "explorer_career_programs" ADD CONSTRAINT "explorer_career_programs_career_id_explorer_careers_id_fk" FOREIGN KEY ("career_id") REFERENCES "public"."explorer_careers"("id") ON DELETE cascade ON UPDATE no action;
  END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'explorer_career_programs_program_id_explorer_programs_id_fk' AND conrelid = 'public.explorer_career_programs'::regclass) THEN
    ALTER TABLE "explorer_career_programs" ADD CONSTRAINT "explorer_career_programs_program_id_explorer_programs_id_fk" FOREIGN KEY ("program_id") REFERENCES "public"."explorer_programs"("id") ON DELETE cascade ON UPDATE no action;
  END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'explorer_careers_domain_id_explorer_domains_id_fk' AND conrelid = 'public.explorer_careers'::regclass) THEN
    ALTER TABLE "explorer_careers" ADD CONSTRAINT "explorer_careers_domain_id_explorer_domains_id_fk" FOREIGN KEY ("domain_id") REFERENCES "public"."explorer_domains"("id") ON DELETE cascade ON UPDATE no action;
  END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'explorer_programs_school_id_explorer_schools_id_fk' AND conrelid = 'public.explorer_programs'::regclass) THEN
    ALTER TABLE "explorer_programs" ADD CONSTRAINT "explorer_programs_school_id_explorer_schools_id_fk" FOREIGN KEY ("school_id") REFERENCES "public"."explorer_schools"("id") ON DELETE cascade ON UPDATE no action;
  END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'explorer_programs_domain_id_explorer_domains_id_fk' AND conrelid = 'public.explorer_programs'::regclass) THEN
    ALTER TABLE "explorer_programs" ADD CONSTRAINT "explorer_programs_domain_id_explorer_domains_id_fk" FOREIGN KEY ("domain_id") REFERENCES "public"."explorer_domains"("id") ON DELETE cascade ON UPDATE no action;
  END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'lessons_course_id_courses_id_fk' AND conrelid = 'public.lessons'::regclass) THEN
    ALTER TABLE "lessons" ADD CONSTRAINT "lessons_course_id_courses_id_fk" FOREIGN KEY ("course_id") REFERENCES "public"."courses"("id") ON DELETE cascade ON UPDATE no action;
  END IF;
END $$;--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "cp_career_id_idx" ON "explorer_career_programs" USING btree ("career_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "cp_program_id_idx" ON "explorer_career_programs" USING btree ("program_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "careers_domain_id_idx" ON "explorer_careers" USING btree ("domain_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "programs_school_id_idx" ON "explorer_programs" USING btree ("school_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "programs_domain_id_idx" ON "explorer_programs" USING btree ("domain_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "lessons_course_id_idx" ON "lessons" USING btree ("course_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "progress_user_id_idx" ON "course_progress" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "progress_course_id_idx" ON "course_progress" USING btree ("course_id");--> statement-breakpoint
-- Retain legacy courses.reward_xp to avoid deleting historical data.
--> statement-breakpoint
-- Preserve every source row before merging pre-existing duplicate enrollments.
LOCK TABLE course_progress, explorer_career_programs IN ACCESS EXCLUSIVE MODE;
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS migration_course_progress_backup AS SELECT * FROM course_progress WITH NO DATA;
--> statement-breakpoint
INSERT INTO migration_course_progress_backup SELECT p.* FROM course_progress p
WHERE EXISTS (SELECT 1 FROM course_progress other WHERE other.user_id = p.user_id AND other.course_id = p.course_id AND other.ctid <> p.ctid);
--> statement-breakpoint
CREATE TEMP TABLE merged_course_progress ON COMMIT DROP AS
SELECT p.user_id, p.course_id,
 COALESCE((SELECT jsonb_agg(DISTINCT entry.id) FROM course_progress p2
 CROSS JOIN LATERAL jsonb_array_elements(COALESCE(p2.completed_lessons, '[]'::jsonb)) entry(id)
 WHERE p2.user_id=p.user_id AND p2.course_id=p.course_id), '[]'::jsonb) AS completed_lessons
FROM course_progress p GROUP BY p.user_id,p.course_id;
--> statement-breakpoint
UPDATE course_progress p SET completed_lessons = m.completed_lessons
FROM merged_course_progress m WHERE m.user_id=p.user_id AND m.course_id=p.course_id;
--> statement-breakpoint
DELETE FROM course_progress a USING course_progress b
WHERE a.user_id=b.user_id AND a.course_id=b.course_id AND a.ctid < b.ctid;
--> statement-breakpoint
-- Recompute completion from real lesson IDs; old COMPLETED flags may be premature.
UPDATE course_progress p SET
 status = CASE WHEN EXISTS (SELECT 1 FROM lessons l WHERE l.course_id=p.course_id)
 AND NOT EXISTS (SELECT 1 FROM lessons l WHERE l.course_id=p.course_id AND NOT (p.completed_lessons ? l.id::text))
 THEN 'COMPLETED' ELSE 'IN_PROGRESS' END,
 completed_at = CASE WHEN EXISTS (SELECT 1 FROM lessons l WHERE l.course_id=p.course_id)
 AND NOT EXISTS (SELECT 1 FROM lessons l WHERE l.course_id=p.course_id AND NOT (p.completed_lessons ? l.id::text))
 THEN p.completed_at ELSE NULL END;
--> statement-breakpoint
DELETE FROM explorer_career_programs a USING explorer_career_programs b
WHERE a.career_id=b.career_id AND a.program_id=b.program_id AND a.ctid < b.ctid;
--> statement-breakpoint
DO $$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='career_program_unique' AND conrelid='public.explorer_career_programs'::regclass) THEN
  ALTER TABLE explorer_career_programs ADD CONSTRAINT career_program_unique UNIQUE(career_id, program_id);
 END IF;
END $$;
--> statement-breakpoint
UPDATE users SET role=upper(role) WHERE lower(role) IN ('student','admin');
--> statement-breakpoint
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'course_progress_user_course_unique' AND conrelid = 'public.course_progress'::regclass) THEN
    ALTER TABLE "course_progress" ADD CONSTRAINT "course_progress_user_course_unique" UNIQUE("user_id","course_id");
  END IF;
END $$;
--> statement-breakpoint
ALTER TABLE migration_course_progress_backup ENABLE ROW LEVEL SECURITY;
