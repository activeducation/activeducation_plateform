import { NextResponse } from 'next/server';
import { requireAuth } from '@/utils/auth';
import { apiError, readJson } from '@/lib/api';
import { completionSchema } from '@/lib/learning';
import { completeLesson } from '@/lib/learning-service';
export async function POST(req: Request) {
  try {
    const { user, errorResponse } = await requireAuth();
    if (errorResponse) return errorResponse;
    const { courseId, lessonId, answers } = completionSchema.parse(await readJson(req));
    return NextResponse.json(await completeLesson(user.id, courseId, lessonId, answers));
  } catch (error) { return apiError(error); }
}
