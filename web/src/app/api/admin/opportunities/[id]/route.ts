import { NextResponse } from 'next/server';
import { z } from 'zod';
import { db } from '@/db';
import { opportunities } from '@/db/schema';
import { eq, desc } from 'drizzle-orm';
import { requireAdmin } from '@/utils/auth';
import { apiError, readJson, ApiError } from '@/lib/api';
import { opportunitySchema } from '@/lib/admin-schemas';
type Context = { params: Promise<{ id: string }> };
export async function GET(request: Request, { params }: Context) {
  try {
    const { errorResponse } = await requireAdmin();
    if (errorResponse) return errorResponse;
    const id = z.string().uuid().parse((await params).id);
    const [record] = await db.select().from(opportunities).where(eq(opportunities.id, id));
    if (!record) throw new ApiError(404, 'Ressource introuvable.');
    return NextResponse.json(record);
  } catch (error) { return apiError(error); }
}
export async function PUT(request: Request, { params }: Context) {
  try {
    const { errorResponse } = await requireAdmin();
    if (errorResponse) return errorResponse;
    const id = z.string().uuid().parse((await params).id);
    const [record] = await db.update(opportunities).set(opportunitySchema.parse(await readJson(request))).where(eq(opportunities.id, id)).returning();
    if (!record) throw new ApiError(404, 'Ressource introuvable.');
    return NextResponse.json(record);
  } catch (error) { return apiError(error); }
}
export async function DELETE(request: Request, { params }: Context) {
  try {
    const { errorResponse } = await requireAdmin();
    if (errorResponse) return errorResponse;
    const id = z.string().uuid().parse((await params).id);
    const [record] = await db.delete(opportunities).where(eq(opportunities.id, id)).returning({ id: opportunities.id });
    if (!record) throw new ApiError(404, 'Ressource introuvable.');
    return NextResponse.json(record);
  } catch (error) { return apiError(error); }
}
