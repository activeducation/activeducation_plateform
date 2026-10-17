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
  bannerImage: z.string().optional().nullable().or(z.literal('')),
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
    if (typeof error === 'object' && error !== null && 'code' in error && error.code === '23505') {
      return NextResponse.json({ error: "Ce slug ou titre existe déjà." }, { status: 409 });
    }
    return NextResponse.json({ error: 'Erreur serveur' }, { status: 500 });
  }
}

export async function PUT(req: Request) {
  try {
    const { errorResponse } = await requireAdmin();
    if (errorResponse) return errorResponse;
    const body = (await readJson(req)) as Record<string, any>;
    const url = new URL(req.url);
    const id = body?.id || url.searchParams.get('id');

    if (!id) {
      return NextResponse.json({ error: "L'identifiant (ID) est requis pour la modification." }, { status: 400 });
    }

    const validatedData = domainSchema.parse(body);
    const slug = validatedData.slug || slugify(validatedData.title);

    const [updated] = await db.update(explorerDomains)
      .set({
        ...validatedData,
        slug,
      })
      .where(eq(explorerDomains.id, id))
      .returning();

    if (!updated) {
      return NextResponse.json({ error: "Domaine introuvable." }, { status: 404 });
    }

    return NextResponse.json(updated);
  } catch (error: unknown) {
    console.error("Update domain error:", error);
    if (error instanceof z.ZodError) {
      return NextResponse.json({ error: "Données invalides", details: error.issues }, { status: 400 });
    }
    if (typeof error === 'object' && error !== null && 'code' in error && error.code === '23505') {
      return NextResponse.json({ error: "Ce slug ou titre existe déjà." }, { status: 409 });
    }
    return NextResponse.json({ error: 'Erreur serveur' }, { status: 500 });
  }
}

export async function DELETE(req: Request) {
  try {
    const { errorResponse } = await requireAdmin();
    if (errorResponse) return errorResponse;
    const url = new URL(req.url);
    let id = url.searchParams.get('id');
    if (!id) {
      try {
        const body = (await readJson(req)) as Record<string, any>;
        id = body?.id;
      } catch {}
    }

    if (!id) {
      return NextResponse.json({ error: "L'identifiant (ID) est requis pour la suppression." }, { status: 400 });
    }

    const [deleted] = await db.delete(explorerDomains)
      .where(eq(explorerDomains.id, id))
      .returning();

    if (!deleted) {
      return NextResponse.json({ error: "Domaine introuvable." }, { status: 404 });
    }

    return NextResponse.json({ success: true, id: deleted.id });
  } catch (error: unknown) {
    console.error("Delete domain error:", error);
    return NextResponse.json({ error: 'Erreur serveur lors de la suppression' }, { status: 500 });
  }
}
