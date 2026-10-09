import { requireAdmin } from '@/utils/auth';
import { NextResponse } from 'next/server';
import { db } from '@/db';
import { explorerCareers, users, explorerCareerPrograms } from '@/db/schema';
import { desc, eq } from 'drizzle-orm';
import { createClient } from '@/utils/supabase/server';
import { z } from 'zod';

const careerSchema = z.object({
  title: z.string().min(2).max(255).trim(),
  slug: z.string().max(255).optional(),
  domainId: z.string().uuid(),
  bannerImage: z.string().url().optional().or(z.literal('')),
  description: z.string().optional().nullable(),
  skills: z.array(z.string()).optional().default([]),
  opportunities: z.array(z.string()).optional().default([]),
  isPublished: z.boolean().default(false),
  programIds: z.array(z.string().uuid()).optional(), // to link to programs
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
    const data = await db.select().from(explorerCareers).orderBy(desc(explorerCareers.createdAt));
    return NextResponse.json(data);
  } catch (error: any) {
    console.error("Fetch careers error:", error);
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
    const validatedData = careerSchema.parse(body);

    const { programIds, ...careerData } = validatedData;
    const slug = careerData.slug || slugify(careerData.title);

    // Drizzle transactions can be used here
    const result = await db.transaction(async (tx) => {
      const newCareer = await tx.insert(explorerCareers).values({
        ...careerData,
        slug,
      }).returning();

      const careerId = newCareer[0].id;

      if (programIds && programIds.length > 0) {
        const links = programIds.map(programId => ({
          careerId,
          programId,
        }));
        await tx.insert(explorerCareerPrograms).values(links);
      }

      return newCareer[0];
    });

    return NextResponse.json(result, { status: 201 });
  } catch (error: any) {
    console.error("Create career error:", error);
    if (error instanceof z.ZodError) {
      return NextResponse.json({ error: "Données invalides", details: error.issues }, { status: 400 });
    }
    if (error.code === '23505') {
      return NextResponse.json({ error: "Ce slug ou titre existe déjà." }, { status: 409 });
    }
    return NextResponse.json({ error: 'Erreur serveur' }, { status: 500 });
  }
}
