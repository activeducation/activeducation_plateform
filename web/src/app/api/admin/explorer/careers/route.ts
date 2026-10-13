import { apiError, readJson } from '@/lib/api';
import { requireAdmin } from '@/utils/auth';
import { NextResponse } from 'next/server';
import { db } from '@/db';
import { explorerCareers, explorerCareerPrograms } from '@/db/schema';
import { desc, eq } from 'drizzle-orm';
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
  try {
    const { errorResponse } = await requireAdmin();
    if (errorResponse) return errorResponse;
    const data = await db.select().from(explorerCareers).orderBy(desc(explorerCareers.createdAt));
    return NextResponse.json(data);
  } catch (error: unknown) {
    console.error("Fetch careers error:", error);
    return apiError(error);
  }
}

export async function POST(req: Request) {
  try {
    const { errorResponse } = await requireAdmin();
    if (errorResponse) return errorResponse;
    const body = await readJson(req);
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
  } catch (error: unknown) {
    console.error("Create career error:", error);
    if (error instanceof z.ZodError) {
      return NextResponse.json({ error: "Données invalides", details: error.issues }, { status: 400 });
    }
    if (typeof error === 'object' && error !== null && 'code' in error && error.code === '23505') {
      return NextResponse.json({ error: "Ce slug ou titre existe déjà." }, { status: 409 });
    }
    return NextResponse.json({ error: 'Erreur serveur' }, { status: 500 });
  }
}
