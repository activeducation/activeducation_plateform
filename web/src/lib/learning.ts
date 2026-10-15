import { z } from 'zod';
import { ApiError } from './api';

export const lessonStepSchema = z.object({
  type: z.enum(['theory', 'quiz', 'video', 'reward']), title: z.string().max(500),
  content: z.string().max(20_000).optional(),
  url: z.string().url().refine(value => value.startsWith('https://')).optional().or(z.literal('')),
  options: z.array(z.string().max(2000)).min(2).max(10).optional(),
  correctOptionIndex: z.number().int().min(0).optional(),
  feedbackSuccess: z.string().max(2000).optional(), feedbackError: z.string().max(2000).optional(),
}).superRefine((step, ctx) => {
  if (step.type === 'quiz' && (!step.options || step.correctOptionIndex === undefined || step.correctOptionIndex >= step.options.length)) {
    ctx.addIssue({ code: 'custom', message: 'Quiz incomplet ou réponse hors limites.' });
  }
});
export type LessonStep = z.infer<typeof lessonStepSchema>;
export const lessonContentSchema = z.array(lessonStepSchema).min(1).max(100);
export const completionSchema = z.object({
  courseId: z.string().uuid(), lessonId: z.string().uuid(),
  answers: z.record(z.string(), z.number().int().min(0).max(9)).default({}),
});

export function validateCompletion(content: unknown, answers: Record<string, number>) {
  const parsed = lessonContentSchema.safeParse(content);
  if (!parsed.success) throw new ApiError(409, 'Le contenu de cette leçon doit être corrigé avant sa validation.');
  parsed.data.forEach((step, index) => {
    if (step.type === 'quiz' && answers[String(index)] !== step.correctOptionIndex) throw new ApiError(422, 'Répondez correctement à chaque question avant de terminer la leçon.');
  });
}

export function computeProgress(lessonIds: string[], completedIds: string[]) {
  const completedLessons = [...new Set(completedIds)].filter(id => lessonIds.includes(id));
  const isCompleted = lessonIds.length > 0 && lessonIds.every(id => completedLessons.includes(id));
  return { completedLessons, isCompleted };
}

export function rewardTotal(current: number, reward: number) {
  if (!Number.isSafeInteger(reward) || reward < 0 || reward > 10_000) throw new ApiError(409, 'Récompense de leçon invalide.');
  const xpPoints = current + reward;
  if (!Number.isSafeInteger(xpPoints) || xpPoints > 2_147_483_647) throw new ApiError(409, 'Limite de points atteinte.');
  return { xpPoints, level: Math.floor(xpPoints / 1000) + 1 };
}
