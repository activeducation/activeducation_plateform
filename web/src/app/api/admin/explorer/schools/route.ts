import { requireAdmin } from '@/utils/auth';
import { NextResponse } from 'next/server';
import { db } from '@/db';
import { explorerSchools, users } from '@/db/schema';
import { desc, eq } from 'drizzle-orm';
import { createClient } from '@/utils/supabase/server';
import { z } from 'zod';

const schoolSchema = z.object({
  name: z.string().min(2).max(255).trim(),
  slug: z.string().max(255).optional(),
  type: z.string().max(100).optional().default('Public'),
  city: z.string().max(255).optional().nullable(),
  bannerImage: z.string().url().optional().or(z.literal('')),
  description: z.string().optional().nullable(),
  insertionRate: z.string().max(50).optional().nullable(),
  rating: z.string().max(10).optional().nullable(),
  reviewsCount: z.number().int().min(0).optional().default(0),
  facilities: z.array(z.string()).optional().default([]),
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
    const data = await db.select().from(explorerSchools).orderBy(desc(explorerSchools.createdAt));
    return NextResponse.json(data);
  } catch (error: any) {
    console.error("Fetch schools error:", error);
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
    const validatedData = schoolSchema.parse(body);

    const slug = validatedData.slug || slugify(validatedData.name);

    const newSchool = await db.insert(explorerSchools).values({
      ...validatedData,
      slug,
    }).returning();

    return NextResponse.json(newSchool[0], { status: 201 });
  } catch (error: any) {
    console.error("Create school error:", error);
    if (error instanceof z.ZodError) {
      return NextResponse.json({ error: "Données invalides", details: error.issues }, { status: 400 });
    }
    if (error.code === '23505') {
      return NextResponse.json({ error: "Ce slug ou nom existe déjà." }, { status: 409 });
    }
    return NextResponse.json({ error: 'Erreur serveur' }, { status: 500 });
  }
}
