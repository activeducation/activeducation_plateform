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
  bannerImage: z.string().optional().nullable().or(z.literal('')),
  description: z.string().optional().nullable(),
  skills: z.array(z.string()).optional().default([]),
  opportunities: z.array(z.string()).optional().default([]),
  isPublished: z.boolean().default(false),
  programIds: z.array(z.string().uuid()).optional(),
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

    const validatedData = careerSchema.parse(body);
    const { programIds, ...careerData } = validatedData;
    const slug = careerData.slug || slugify(careerData.title);

    const result = await db.transaction(async (tx) => {
      const [updatedCareer] = await tx.update(explorerCareers)
        .set({
          ...careerData,
          slug,
        })
        .where(eq(explorerCareers.id, id))
        .returning();

      if (!updatedCareer) return null;

      if (programIds !== undefined) {
        await tx.delete(explorerCareerPrograms).where(eq(explorerCareerPrograms.careerId, id));
        if (programIds.length > 0) {
          const links = programIds.map(programId => ({
            careerId: id,
            programId,
          }));
          await tx.insert(explorerCareerPrograms).values(links);
        }
      }

      return updatedCareer;
    });

    if (!result) {
      return NextResponse.json({ error: "Métier introuvable." }, { status: 404 });
    }

    return NextResponse.json(result);
  } catch (error: unknown) {
    console.error("Update career error:", error);
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

    const [deleted] = await db.delete(explorerCareers)
      .where(eq(explorerCareers.id, id))
      .returning();

    if (!deleted) {
      return NextResponse.json({ error: "Métier introuvable." }, { status: 404 });
    }

    return NextResponse.json({ success: true, id: deleted.id });
  } catch (error: unknown) {
    console.error("Delete career error:", error);
    return NextResponse.json({ error: 'Erreur serveur lors de la suppression' }, { status: 500 });
  }
}
