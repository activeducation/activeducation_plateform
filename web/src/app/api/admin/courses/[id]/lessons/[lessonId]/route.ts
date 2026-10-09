import { requireAdmin } from '@/utils/auth';
import { NextResponse } from 'next/server';
import { db } from '@/db';
import { lessons } from '@/db/schema';
import { eq, and } from 'drizzle-orm';

export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string, lessonId: string }> }
) {
  const { errorResponse } = await requireAdmin();
  if (errorResponse) return errorResponse;
  try {
    const { id, lessonId } = await params;
    const data = await db.select().from(lessons).where(
      and(eq(lessons.id, lessonId), eq(lessons.courseId, id))
    );
    
    if (data.length === 0) {
      return NextResponse.json({ error: "Non trouvé" }, { status: 404 });
    }
    
    return NextResponse.json(data[0]);
  } catch (error: any) {
    console.error("Fetch lesson error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function PUT(
  request: Request,
  { params }: { params: Promise<{ id: string, lessonId: string }> }
) {
  const { errorResponse } = await requireAdmin();
  if (errorResponse) return errorResponse;
  try {
    const { id, lessonId } = await params;
    const body = await request.json();

    const updated = await db.update(lessons).set({
      title: body.title,
      description: body.description,
      content: body.content,
      orderIndex: body.orderIndex,
      rewardXp: body.rewardXp,
    }).where(and(eq(lessons.id, lessonId), eq(lessons.courseId, id))).returning();

    return NextResponse.json(updated[0]);
  } catch (error: any) {
    console.error("Update lesson error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function DELETE(
  request: Request,
  { params }: { params: Promise<{ id: string, lessonId: string }> }
) {
  const { errorResponse } = await requireAdmin();
  if (errorResponse) return errorResponse;
  try {
    const { id, lessonId } = await params;
    await db.delete(lessons).where(and(eq(lessons.id, lessonId), eq(lessons.courseId, id)));
    
    return NextResponse.json({ success: true });
  } catch (error: any) {
    console.error("Delete lesson error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
