import { NextResponse } from 'next/server';
import { z } from 'zod';
import { db } from '@/db';
import { courses } from '@/db/schema';
import { eq, desc } from 'drizzle-orm';
import { requireAdmin } from '@/utils/auth';
import { apiError, readJson, ApiError } from '@/lib/api';
import { courseSchema } from '@/lib/admin-schemas';
type Context = { params: Promise<{ id: string }> };
export async function GET(request: Request, { params }: Context) {
  try {
    const { errorResponse } = await requireAdmin();
    if (errorResponse) return errorResponse;
    const id = z.string().uuid().parse((await params).id);
    const [record] = await db.select().from(courses).where(eq(courses.id, id));
    if (!record) throw new ApiError(404, 'Ressource introuvable.');
    return NextResponse.json(record);
  } catch (error) { return apiError(error); }
}
export async function PUT(request: Request, { params }: Context) {
  try {
    const { errorResponse } = await requireAdmin();
    if (errorResponse) return errorResponse;
    const id = z.string().uuid().parse((await params).id);
    const [record] = await db.update(courses).set(courseSchema.parse(await readJson(request))).where(eq(courses.id, id)).returning();
    if (!record) throw new ApiError(404, 'Ressource introuvable.');
    return NextResponse.json(record);
  } catch (error) { return apiError(error); }
}
export async function DELETE(request: Request, { params }: Context) {
  try {
    const { errorResponse } = await requireAdmin();
    if (errorResponse) return errorResponse;
    const id = z.string().uuid().parse((await params).id);
    const [record] = await db.delete(courses).where(eq(courses.id, id)).returning({ id: courses.id });
    if (!record) throw new ApiError(404, 'Ressource introuvable.');
    return NextResponse.json(record);
  } catch (error) { return apiError(error); }
}
