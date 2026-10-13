import { apiError, readJson } from '@/lib/api';
import { requireAdmin } from '@/utils/auth';
import { NextResponse } from 'next/server';
import { db } from '@/db';
import { explorerPrograms } from '@/db/schema';
import { desc, eq } from 'drizzle-orm';
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
  try {
    const { errorResponse } = await requireAdmin();
    if (errorResponse) return errorResponse;
    const data = await db.select().from(explorerPrograms).orderBy(desc(explorerPrograms.createdAt));
    return NextResponse.json(data);
  } catch (error: unknown) {
    console.error("Fetch programs error:", error);
    return apiError(error);
  }
}

export async function POST(req: Request) {
  try {
    const { errorResponse } = await requireAdmin();
    if (errorResponse) return errorResponse;
    const body = await readJson(req);
    const validatedData = programSchema.parse(body);

    const slug = validatedData.slug || slugify(validatedData.title);

    const newProgram = await db.insert(explorerPrograms).values({
      ...validatedData,
      slug,
    }).returning();

    return NextResponse.json(newProgram[0], { status: 201 });
  } catch (error: unknown) {
    console.error("Create program error:", error);
    if (error instanceof z.ZodError) {
      return NextResponse.json({ error: "Données invalides", details: error.issues }, { status: 400 });
    }
    if (typeof error === 'object' && error !== null && 'code' in error && error.code === '23505') {
      return NextResponse.json({ error: "Ce slug ou titre existe déjà." }, { status: 409 });
    }
    return NextResponse.json({ error: 'Erreur serveur' }, { status: 500 });
  }
}
