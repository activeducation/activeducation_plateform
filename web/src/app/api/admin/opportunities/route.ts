import { NextResponse } from 'next/server';
import { z } from 'zod';
import { db } from '@/db';
import { opportunities } from '@/db/schema';
import { eq, desc } from 'drizzle-orm';
import { requireAdmin } from '@/utils/auth';
import { apiError, readJson, ApiError } from '@/lib/api';
import { opportunitySchema } from '@/lib/admin-schemas';
export async function GET() {
  try {
    const { errorResponse } = await requireAdmin();
    if (errorResponse) return errorResponse;
    return NextResponse.json(await db.select().from(opportunities).orderBy(desc(opportunities.createdAt)).limit(200));
  } catch (error) { return apiError(error); }
}
export async function POST(request: Request) {
  try {
    const { errorResponse } = await requireAdmin();
    if (errorResponse) return errorResponse;
    const body = opportunitySchema.parse(await readJson(request));
    const [created] = await db.insert(opportunities).values(body).returning();
    return NextResponse.json(created, { status: 201 });
  } catch (error) { return apiError(error); }
}
