import { and, asc, eq } from 'drizzle-orm';
import { db } from '@/db';
import { users, courses, lessons, courseProgress, orientationResults } from '@/db/schema';
import { ApiError } from './api';
import { computeProgress, rewardTotal, validateCompletion } from './learning';

// All XP/progress writers lock the user first. PostgreSQL holds this lock until
// commit/rollback, including when requests run on different server instances.
export async function completeLesson(userId: string, courseId: string, lessonId: string, answers: Record<string, number>) {
  return db.transaction(async tx => {
    const [user] = await tx.select().from(users).where(eq(users.id, userId)).for('update');
    if (!user) throw new ApiError(404, 'Profil introuvable.');
    const [course] = await tx.select().from(courses).where(and(eq(courses.id, courseId), eq(courses.isPublished, true))).for('share');
    if (!course) throw new ApiError(404, 'Cours indisponible.');
    const courseLessons = await tx.select().from(lessons).where(eq(lessons.courseId, courseId)).orderBy(asc(lessons.orderIndex), asc(lessons.id)).for('share');
    const lessonIndex = courseLessons.findIndex(lesson => lesson.id === lessonId);
    if (lessonIndex < 0) throw new ApiError(400, 'Leçon invalide pour ce cours.');
    const [progress] = await tx.select().from(courseProgress).where(and(eq(courseProgress.userId, userId), eq(courseProgress.courseId, courseId))).for('update');
    if (!progress) throw new ApiError(404, 'Inscrivez-vous à ce cours avant de commencer.');
    const ids = courseLessons.map(lesson => lesson.id);
    const old = computeProgress(ids, progress.completedLessons ?? []).completedLessons;
    const alreadyDone = old.includes(lessonId);
    const lesson = courseLessons[lessonIndex];
    if (!alreadyDone) {
      if (!ids.slice(0, lessonIndex).every(id => old.includes(id))) throw new ApiError(409, 'Terminez les leçons précédentes.');
      validateCompletion(lesson.content, answers);
    }
    const { completedLessons, isCompleted } = computeProgress(ids, [...old, lessonId]);
    const xpAwarded = alreadyDone ? 0 : lesson.rewardXp;
    const total = rewardTotal(user.xpPoints ?? 0, xpAwarded);
    await tx.update(courseProgress).set({ completedLessons, status: isCompleted ? 'COMPLETED' : 'IN_PROGRESS', completedAt: isCompleted ? (progress.completedAt ?? new Date()) : null })
      .where(and(eq(courseProgress.userId, userId), eq(courseProgress.courseId, courseId)));
    if (!alreadyDone) await tx.update(users).set(total).where(eq(users.id, userId));
    return { success: true, completedLessons, status: isCompleted ? 'COMPLETED' : 'IN_PROGRESS', xpAwarded, newXp: total.xpPoints, newLevel: total.level };
  });
}

export async function enroll(userId: string, courseId: string) {
  return db.transaction(async tx => {
    const [user] = await tx.select({ id: users.id }).from(users).where(eq(users.id, userId)).for('update');
    if (!user) throw new ApiError(404, 'Profil introuvable.');
    const [course] = await tx.select({ id: courses.id }).from(courses).where(and(eq(courses.id, courseId), eq(courses.isPublished, true))).for('share');
    if (!course) throw new ApiError(404, 'Cours indisponible.');
    await tx.insert(courseProgress).values({ userId, courseId, completedLessons: [], status: 'IN_PROGRESS' }).onConflictDoNothing({ target: [courseProgress.userId, courseProgress.courseId] });
    return { success: true };
  });
}

export async function saveOrientation(userId: string, inputs: unknown, results: unknown) {
  return db.transaction(async tx => {
    const [user] = await tx.select().from(users).where(eq(users.id, userId)).for('update');
    if (!user) throw new ApiError(404, 'Profil introuvable.');
    const existing = await tx.select({ id: orientationResults.id }).from(orientationResults).where(eq(orientationResults.userId, userId)).limit(1);
    await tx.insert(orientationResults).values({ userId, inputs, results });
    if (existing.length === 0) await tx.update(users).set(rewardTotal(user.xpPoints ?? 0, 200)).where(eq(users.id, userId));
  });
}
