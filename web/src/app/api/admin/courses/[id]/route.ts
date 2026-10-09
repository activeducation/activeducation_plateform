import { requireAdmin } from '@/utils/auth';
import { NextResponse } from 'next/server';
import { db } from '@/db';
import { courses } from '@/db/schema';
import { eq } from 'drizzle-orm';

export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const { errorResponse } = await requireAdmin();
  if (errorResponse) return errorResponse;
  try {
    const { id } = await params;
    const data = await db.select().from(courses).where(eq(courses.id, id));
    
    if (data.length === 0) {
      return NextResponse.json({ error: "Non trouvé" }, { status: 404 });
    }
    
    return NextResponse.json(data[0]);
  } catch (error: any) {
    console.error("Fetch course error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}


export async function PUT(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const { errorResponse } = await requireAdmin();
  if (errorResponse) return errorResponse;
  try {
    const { id } = await params;
    const body = await request.json();

    const updated = await db.update(courses).set({
      title: body.title,
      description: body.description,
      category: body.category,
      difficulty: body.difficulty,
      image: body.image,
      icon: body.icon,
      color: body.color,
      isPublished: body.isPublished,
    }).where(eq(courses.id, id)).returning();

    return NextResponse.json(updated[0]);
  } catch (error: any) {
    console.error("Update course error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function DELETE(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const { errorResponse } = await requireAdmin();
  if (errorResponse) return errorResponse;
  try {
    const { id } = await params;
    await db.delete(courses).where(eq(courses.id, id));
    
    return NextResponse.json({ success: true });
  } catch (error: any) {
    console.error("Delete course error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
