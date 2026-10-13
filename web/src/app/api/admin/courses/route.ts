import { NextResponse } from 'next/server';
import { z } from 'zod';
import { db } from '@/db';
import { courses } from '@/db/schema';
import { eq, desc } from 'drizzle-orm';
import { requireAdmin } from '@/utils/auth';
import { apiError, readJson, ApiError } from '@/lib/api';
import { courseSchema } from '@/lib/admin-schemas';
export async function GET() {
  try {
    const { errorResponse } = await requireAdmin();
    if (errorResponse) return errorResponse;
    return NextResponse.json(await db.select().from(courses).orderBy(desc(courses.createdAt)).limit(200));
  } catch (error) { return apiError(error); }
}
export async function POST(request: Request) {
  try {
    const { errorResponse } = await requireAdmin();
    if (errorResponse) return errorResponse;
    const body = courseSchema.parse(await readJson(request));
    const [created] = await db.insert(courses).values(body).returning();
    return NextResponse.json(created, { status: 201 });
  } catch (error) { return apiError(error); }
}
