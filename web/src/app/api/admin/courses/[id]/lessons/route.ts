import { NextResponse } from 'next/server';
import { z } from 'zod';
import { db } from '@/db';
import { lessons, courses } from '@/db/schema';
import { eq, and, asc } from 'drizzle-orm';
import { requireAdmin } from '@/utils/auth';
import { apiError, readJson, ApiError } from '@/lib/api';
import { lessonSchema } from '@/lib/admin-schemas';
type Context = { params: Promise<{ id: string }> };
export async function GET(request: Request, { params }: Context) {
  try {
    const { errorResponse } = await requireAdmin();
    if (errorResponse) return errorResponse;
    const id = z.string().uuid().parse((await params).id);
    return NextResponse.json(await db.select().from(lessons).where(eq(lessons.courseId, id)).orderBy(asc(lessons.orderIndex), asc(lessons.id)));
  } catch (error) { return apiError(error); }
}
export async function POST(request: Request, { params }: Context) {
  try {
    const { errorResponse } = await requireAdmin();
    if (errorResponse) return errorResponse;
    const id = z.string().uuid().parse((await params).id);
    const body = lessonSchema.parse(await readJson(request));
    const [course] = await db.select({ id: courses.id }).from(courses).where(eq(courses.id, id));
    if (!course) throw new ApiError(404, 'Cours introuvable.');
    const [created] = await db.insert(lessons).values({ ...body, courseId: id }).returning();
    return NextResponse.json(created, { status: 201 });
  } catch (error) { return apiError(error); }
}
