import { NextResponse } from 'next/server';
import { z } from 'zod';
import { db } from '@/db';
import { lessons, courses } from '@/db/schema';
import { eq, and, asc } from 'drizzle-orm';
import { requireAdmin } from '@/utils/auth';
import { apiError, readJson, ApiError } from '@/lib/api';
import { lessonSchema } from '@/lib/admin-schemas';
type Context = { params: Promise<{ id: string; lessonId: string }> };
export async function GET(request: Request, { params }: Context) {
  try {
    const { errorResponse } = await requireAdmin();
    if (errorResponse) return errorResponse;
    const { id, lessonId } = z.object({ id: z.string().uuid(), lessonId: z.string().uuid() }).parse(await params);
    const [record] = await db.select().from(lessons).where(and(eq(lessons.id, lessonId), eq(lessons.courseId, id)));
    if (!record) throw new ApiError(404, 'Leçon introuvable.');
    return NextResponse.json(record);
  } catch (error) { return apiError(error); }
}
export async function PUT(request: Request, { params }: Context) {
  try {
    const { errorResponse } = await requireAdmin();
    if (errorResponse) return errorResponse;
    const { id, lessonId } = z.object({ id: z.string().uuid(), lessonId: z.string().uuid() }).parse(await params);
    const [record] = await db.update(lessons).set(lessonSchema.parse(await readJson(request))).where(and(eq(lessons.id, lessonId), eq(lessons.courseId, id))).returning();
    if (!record) throw new ApiError(404, 'Leçon introuvable.');
    return NextResponse.json(record);
  } catch (error) { return apiError(error); }
}
export async function DELETE(request: Request, { params }: Context) {
  try {
    const { errorResponse } = await requireAdmin();
    if (errorResponse) return errorResponse;
    const { id, lessonId } = z.object({ id: z.string().uuid(), lessonId: z.string().uuid() }).parse(await params);
    const [record] = await db.delete(lessons).where(and(eq(lessons.id, lessonId), eq(lessons.courseId, id))).returning({ id: lessons.id });
    if (!record) throw new ApiError(404, 'Leçon introuvable.');
    return NextResponse.json(record);
  } catch (error) { return apiError(error); }
}
