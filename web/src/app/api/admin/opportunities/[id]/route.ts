import { NextResponse } from 'next/server';
import { db } from '@/db';
import { opportunities } from '@/db/schema';
import { eq } from 'drizzle-orm';

export async function DELETE(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    await db.delete(opportunities).where(eq(opportunities.id, id));
    
    return NextResponse.json({ success: true });
  } catch (error: any) {
    console.error("Delete opportunity error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const data = await db.select().from(opportunities).where(eq(opportunities.id, id));
    
    if (data.length === 0) {
      return NextResponse.json({ error: "Non trouvé" }, { status: 404 });
    }
    
    return NextResponse.json(data[0]);
  } catch (error: any) {
    console.error("Fetch opportunity error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function PUT(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const body = await request.json();

    const updated = await db.update(opportunities).set({
      type: body.type,
      title: body.title,
      provider: body.provider,
      description: body.description,
      location: body.location,
      amountOrSalary: body.amountOrSalary,
      deadline: body.deadline ? new Date(body.deadline) : null,
      eventDate: body.eventDate ? new Date(body.eventDate) : null,
      criteria: body.criteria || [],
      documents: body.documents || [],
      link: body.link,
      image: body.image,
      isRecommended: body.isRecommended,
      isPublished: body.isPublished,
    }).where(eq(opportunities.id, id)).returning();

    return NextResponse.json(updated[0]);
  } catch (error: any) {
    console.error("Update opportunity error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
