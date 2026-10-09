import { requireAdmin } from '@/utils/auth';
import { NextResponse } from 'next/server';
import { db } from '@/db';
import { lessons } from '@/db/schema';
import { eq, asc } from 'drizzle-orm';

export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const { errorResponse } = await requireAdmin();
  if (errorResponse) return errorResponse;
  try {
    const { id } = await params;
    const data = await db.select().from(lessons).where(eq(lessons.courseId, id)).orderBy(asc(lessons.orderIndex));
    return NextResponse.json(data);
  } catch (error: any) {
    console.error("Fetch lessons error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function POST(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const { errorResponse } = await requireAdmin();
  if (errorResponse) return errorResponse;
  try {
    const { id } = await params;
    const body = await request.json();

    const newLesson = await db.insert(lessons).values({
      courseId: id,
      title: body.title,
      description: body.description,
      content: body.content || [],
      orderIndex: body.orderIndex || 0,
      rewardXp: body.rewardXp || 50,
    }).returning();

    return NextResponse.json(newLesson[0], { status: 201 });
  } catch (error: any) {
    console.error("Create lesson error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
