import { requireAdmin } from '@/utils/auth';
import { NextResponse } from 'next/server';
import { db } from '@/db';
import { explorerPrograms, users } from '@/db/schema';
import { desc, eq } from 'drizzle-orm';
import { createClient } from '@/utils/supabase/server';
import { z } from 'zod';

const programSchema = z.object({
  title: z.string().min(2).max(255).trim(),
  slug: z.string().max(255).optional(),
  schoolId: z.string().uuid(),
  domainId: z.string().uuid(),
  bannerImage: z.string().url().optional().or(z.literal('')),
  description: z.string().optional().nullable(),
  level: z.string().max(100).optional().nullable(),
  duration: z.string().max(100).optional().nullable(),
  admission: z.string().optional().nullable(),
  status: z.string().max(255).optional().nullable(),
  programCourses: z.array(z.string()).optional().default([]),
  isPublished: z.boolean().default(false),
});

function slugify(text: string) {
  return text.toString().toLowerCase()
    .normalize("NFD").replace(/[\u0300-\u036f]/g, "") // remove accents
    .replace(/\s+/g, '-')
    .replace(/[^\w\-]+/g, '')
    .replace(/\-\-+/g, '-')
    .replace(/^-+/, '')
    .replace(/-+$/, '');
}

export async function GET() {
  const { errorResponse } = await requireAdmin();
  if (errorResponse) return errorResponse;
  try {
    const data = await db.select().from(explorerPrograms).orderBy(desc(explorerPrograms.createdAt));
    return NextResponse.json(data);
  } catch (error: any) {
    console.error("Fetch programs error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function POST(req: Request) {
  const { errorResponse } = await requireAdmin();
  if (errorResponse) return errorResponse;
  try {
    const supabase = await createClient();
    const { data: { user }, error: authError } = await supabase.auth.getUser();

    if (authError || !user) {
      return NextResponse.json({ error: 'Non autorisé' }, { status: 401 });
    }

    const userDb = await db.select().from(users).where(eq(users.id, user.id)).limit(1);
    if (!userDb.length || userDb[0].role !== 'admin') {
      return NextResponse.json({ error: 'Accès refusé. Privilèges administrateur requis.' }, { status: 403 });
    }

    const body = await req.json();
    const validatedData = programSchema.parse(body);

    const slug = validatedData.slug || slugify(validatedData.title);

    const newProgram = await db.insert(explorerPrograms).values({
      ...validatedData,
      slug,
    }).returning();

    return NextResponse.json(newProgram[0], { status: 201 });
  } catch (error: any) {
    console.error("Create program error:", error);
    if (error instanceof z.ZodError) {
      return NextResponse.json({ error: "Données invalides", details: error.issues }, { status: 400 });
    }
    if (error.code === '23505') {
      return NextResponse.json({ error: "Ce slug ou titre existe déjà." }, { status: 409 });
    }
    return NextResponse.json({ error: 'Erreur serveur' }, { status: 500 });
  }
}
