import { NextResponse } from 'next/server';
import { db } from '@/db';
import { courseProgress } from '@/db/schema';
import { eq, and } from 'drizzle-orm';
import { createClient } from '@/utils/supabase/server';

export async function POST(req: Request) {
  try {
    const supabase = await createClient();
    const { data: { user }, error: authError } = await supabase.auth.getUser();

    if (authError || !user) {
      return NextResponse.json({ error: 'Non autorisé' }, { status: 401 });
    }

    const { courseId } = await req.json();

    if (!courseId) {
      return NextResponse.json({ error: 'courseId requis' }, { status: 400 });
    }

    // Check if already enrolled
    const existing = await db.select().from(courseProgress).where(
      and(eq(courseProgress.userId, user.id), eq(courseProgress.courseId, courseId))
    );

    if (existing.length === 0) {
      await db.insert(courseProgress).values({
        userId: user.id,
        courseId: courseId,
        status: 'IN_PROGRESS',
        completedLessons: []
      });
    }

    return NextResponse.json({ success: true }, { status: 200 });
  } catch (error: any) {
    console.error("Enroll error:", error);
    return NextResponse.json({ error: 'Erreur serveur' }, { status: 500 });
  }
}
