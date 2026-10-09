import { requireAdmin } from '@/utils/auth';
import { NextResponse } from 'next/server';
import { db } from '@/db';
import { courses } from '@/db/schema';
import { desc } from 'drizzle-orm';
import { createClient } from '@/utils/supabase/server';
import { z } from 'zod';

const courseSchema = z.object({
  title: z.string().min(3).max(255).trim(),
  description: z.string().max(2000).optional().nullable(),
  category: z.string().min(1),
  difficulty: z.enum(['Débutant', 'Intermédiaire', 'Avancé']),
  image: z.string().url().optional().or(z.literal('')),
  icon: z.string().optional().nullable(),
  color: z.string().regex(/^[a-z0-9\- ]+$/, "Format de couleur invalide").optional().nullable(),
  isPublished: z.boolean().default(false),
});


export async function GET() {
  const { errorResponse } = await requireAdmin();
  if (errorResponse) return errorResponse;
  try {
    const data = await db.select().from(courses).orderBy(desc(courses.createdAt)).limit(100);
    return NextResponse.json(data);
  } catch (error: any) {
    console.error("Fetch courses error:", error);
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
    // Ideally we should also check `user.role === 'ADMIN'` from DB here

    const body = await req.json();
    const validatedData = courseSchema.parse(body);

    const newCourse = await db.insert(courses).values(validatedData).returning();

    return NextResponse.json(newCourse[0], { status: 201 });
  } catch (error: any) {
    console.error("Create course error:", error);
    if (error instanceof z.ZodError) {
      return NextResponse.json({ error: "Données invalides", details: error.issues }, { status: 400 });
    }
    return NextResponse.json({ error: 'Erreur serveur' }, { status: 500 });
  }
}
