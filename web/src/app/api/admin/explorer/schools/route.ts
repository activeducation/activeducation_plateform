import { apiError, readJson } from '@/lib/api';
import { requireAdmin } from '@/utils/auth';
import { NextResponse } from 'next/server';
import { db } from '@/db';
import { explorerSchools } from '@/db/schema';
import { desc, eq } from 'drizzle-orm';
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
  try {
    const { errorResponse } = await requireAdmin();
    if (errorResponse) return errorResponse;
    const data = await db.select().from(explorerSchools).orderBy(desc(explorerSchools.createdAt));
    return NextResponse.json(data);
  } catch (error: unknown) {
    console.error("Fetch schools error:", error);
    return apiError(error);
  }
}

export async function POST(req: Request) {
  try {
    const { errorResponse } = await requireAdmin();
    if (errorResponse) return errorResponse;
    const body = await readJson(req);
    const validatedData = schoolSchema.parse(body);

    const slug = validatedData.slug || slugify(validatedData.name);

    const newSchool = await db.insert(explorerSchools).values({
      ...validatedData,
      slug,
    }).returning();

    return NextResponse.json(newSchool[0], { status: 201 });
  } catch (error: unknown) {
    console.error("Create school error:", error);
    if (error instanceof z.ZodError) {
      return NextResponse.json({ error: "Données invalides", details: error.issues }, { status: 400 });
    }
    if (typeof error === 'object' && error !== null && 'code' in error && error.code === '23505') {
      return NextResponse.json({ error: "Ce slug ou nom existe déjà." }, { status: 409 });
    }
    return NextResponse.json({ error: 'Erreur serveur' }, { status: 500 });
  }
}
