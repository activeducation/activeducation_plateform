import { NextResponse } from 'next/server';
import { db } from '@/db';
import { courseProgress, courses, users } from '@/db/schema';
import { eq, and } from 'drizzle-orm';
import { createClient } from '@/utils/supabase/server';
import { requireAuth } from '@/utils/auth';

export async function POST(req: Request) {
  try {
    const { user, errorResponse } = await requireAuth();
    if (errorResponse) return errorResponse;

    const { courseId, lessonId } = await req.json();

    if (!courseId || !lessonId) {
      return NextResponse.json({ error: 'courseId et lessonId requis' }, { status: 400 });
    }

    // 1. Verify the course and lesson exist
    const courseData = await db.select().from(courses).where(eq(courses.id, courseId)).limit(1);

    if (!courseData || courseData.length === 0) {
      return NextResponse.json({ error: 'Cours non trouvé' }, { status: 404 });
    }

    const lessonsData = await db.select().from(require('@/db/schema').lessons).where(eq(require('@/db/schema').lessons.courseId, courseId));
    const lesson = lessonsData.find((l: any) => l.id === lessonId);
    if (!lesson) {
      return NextResponse.json({ error: 'Leçon invalide pour ce cours' }, { status: 400 });
    }

    // 2. Fetch progress
    const progressRecords = await db.select().from(courseProgress).where(
      and(eq(courseProgress.userId, user.id), eq(courseProgress.courseId, courseId))
    );

    if (progressRecords.length === 0) {
      return NextResponse.json({ error: 'Cours non trouvé pour cet utilisateur' }, { status: 404 });
    }

    const record = progressRecords[0];
    const completedLessons = (record.completedLessons as string[]) || [];

    if (!completedLessons.includes(lessonId)) {
      completedLessons.push(lessonId);
      
      // Calculate XP
      const rewardXp = lesson.rewardXp || 50;
      const currentXp = user.xpPoints || 0;
      const currentLevel = user.level || 1;
      const newXp = currentXp + rewardXp;
      const newLevel = Math.max(currentLevel, Math.floor(newXp / 1000) + 1);

      // Check if course is fully completed
      const allLessonIds = lessonsData.filter((l: any) => l.isPublished).map((l: any) => l.id);
      const isCompleted = allLessonIds.every((id: string) => completedLessons.includes(id));

      // We should ideally use a transaction here, but doing sequential updates is okay for now since we just deduplicated.
      await db.transaction(async (tx) => {
        await tx.update(courseProgress)
          .set({ 
            completedLessons, 
            status: isCompleted ? 'COMPLETED' : 'IN_PROGRESS',
            completedAt: isCompleted ? new Date() : null 
          })
          .where(and(eq(courseProgress.userId, user.id), eq(courseProgress.courseId, courseId)));

        await tx.update(users)
          .set({ xpPoints: newXp, level: newLevel })
          .where(eq(users.id, user.id));
      });
      
      return NextResponse.json({ 
        success: true, 
        completedLessons, 
        status: isCompleted ? 'COMPLETED' : 'IN_PROGRESS',
        xpAwarded: rewardXp,
        newXp,
        newLevel
      }, { status: 200 });
    }

    return NextResponse.json({ success: true, completedLessons }, { status: 200 });
  } catch (error: any) {
    console.error("Complete lesson error:", error);
    return NextResponse.json({ error: 'Erreur serveur' }, { status: 500 });
  }
}
