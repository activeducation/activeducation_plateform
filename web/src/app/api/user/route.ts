import { NextResponse } from 'next/server';
import { z } from 'zod';
import { db } from '@/db';
import { users } from '@/db/schema';
import { eq } from 'drizzle-orm';
import { requireAuth } from '@/utils/auth';
import { apiError, readJson } from '@/lib/api';
export async function GET() {
  try {
    const { user, errorResponse } = await requireAuth();
    if (errorResponse) return errorResponse;
    return NextResponse.json(user, { headers: { 'Cache-Control': 'no-store' } });
  } catch (error) { return apiError(error); }
}
export async function PATCH(request: Request) {
  try {
    const { user, errorResponse } = await requireAuth();
    if (errorResponse) return errorResponse;
    const body = z.object({ fullName: z.string().trim().min(2).max(255) }).strict().parse(await readJson(request, 2048));
    const [updated] = await db.update(users).set(body).where(eq(users.id, user.id)).returning();
    return NextResponse.json(updated);
  } catch (error) { return apiError(error); }
}
