import { apiError, readJson } from '@/lib/api';
import { requireAdmin } from '@/utils/auth';
import { NextResponse } from 'next/server';
import { db } from '@/db';
import { explorerDomains } from '@/db/schema';
import { desc, eq } from 'drizzle-orm';
import { z } from 'zod';

const domainSchema = z.object({
  title: z.string().min(2).max(255).trim(),
  slug: z.string().max(255).optional(),
  bannerImage: z.string().url().optional().or(z.literal('')),
  description: z.string().optional().nullable(),
  growth: z.string().max(100).optional().nullable(),
  employability: z.string().max(100).optional().nullable(),
  salary: z.string().max(100).optional().nullable(),
  why: z.string().optional().nullable(),
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
    const data = await db.select().from(explorerDomains).orderBy(desc(explorerDomains.createdAt));
    return NextResponse.json(data);
  } catch (error: unknown) {
    console.error("Fetch domains error:", error);
    return apiError(error);
  }
}

export async function POST(req: Request) {
  try {
    const { errorResponse } = await requireAdmin();
    if (errorResponse) return errorResponse;
    const body = await readJson(req);
    const validatedData = domainSchema.parse(body);

    const slug = validatedData.slug || slugify(validatedData.title);

    const newDomain = await db.insert(explorerDomains).values({
      ...validatedData,
      slug,
    }).returning();

    return NextResponse.json(newDomain[0], { status: 201 });
  } catch (error: unknown) {
    console.error("Create domain error:", error);
    if (error instanceof z.ZodError) {
      return NextResponse.json({ error: "Données invalides", details: error.issues }, { status: 400 });
    }
    // Handle unique constraint error on slug
    if (typeof error === 'object' && error !== null && 'code' in error && error.code === '23505') {
      return NextResponse.json({ error: "Ce slug ou titre existe déjà." }, { status: 409 });
    }
    return NextResponse.json({ error: 'Erreur serveur' }, { status: 500 });
  }
}
