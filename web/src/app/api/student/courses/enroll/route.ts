import { NextResponse } from 'next/server';
import { z } from 'zod';
import { requireAuth } from '@/utils/auth';
import { apiError, readJson } from '@/lib/api';
import { enroll } from '@/lib/learning-service';
export async function POST(req: Request) {
  try {
    const { user, errorResponse } = await requireAuth();
    if (errorResponse) return errorResponse;
    const { courseId } = z.object({ courseId: z.string().uuid() }).parse(await readJson(req));
    return NextResponse.json(await enroll(user.id, courseId));
  } catch (error) { return apiError(error); }
}
