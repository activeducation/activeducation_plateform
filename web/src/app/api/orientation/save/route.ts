import { NextResponse } from 'next/server';
import { requireAuth } from '@/utils/auth';
import { apiError, readJson } from '@/lib/api';
import { saveOrientation } from '@/lib/learning-service';
import { sanitizeObject } from '@/lib/orientation';
import { z } from 'zod';

const SaveOrientationSchema = z.object({
  answers: z.record(z.string(), z.any()),
  results: z.record(z.string(), z.any()),
});

export async function POST(req: Request) {
  try {
    const { user, errorResponse } = await requireAuth();
    if (errorResponse) return errorResponse;

    const rawJson = await readJson(req, 128_000);
    const body = SaveOrientationSchema.parse(rawJson);

    const sanitizedResults = sanitizeObject(body.results);
    const sanitizedAnswers = sanitizeObject(body.answers);

    await saveOrientation(user.id, sanitizedAnswers, sanitizedResults);

    return NextResponse.json({ success: true });
  } catch (error) {
    return apiError(error);
  }
}
