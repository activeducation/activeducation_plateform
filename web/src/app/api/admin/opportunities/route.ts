import { NextResponse } from 'next/server';
import { db } from '@/db';
import { opportunities } from '@/db/schema';
import { desc } from 'drizzle-orm';

export async function GET(request: Request) {
  try {
    const data = await db.select().from(opportunities).orderBy(desc(opportunities.createdAt));
    return NextResponse.json(data);
  } catch (error: any) {
    console.error("Fetch opportunities error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    
    // In a real app, we'd validate the admin session here

    const newOpp = await db.insert(opportunities).values({
      type: body.type, // 'bourse', 'stage', 'evenement'
      title: body.title,
      provider: body.provider,
      description: body.description,
      location: body.location,
      amountOrSalary: body.amountOrSalary,
      deadline: body.deadline ? new Date(body.deadline) : null,
      eventDate: body.eventDate ? new Date(body.eventDate) : null,
      criteria: body.criteria || [], // array of strings
      documents: body.documents || [], // array of strings
      link: body.link,
      image: body.image || 'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?auto=format&fit=crop&w=1200&q=80',
      isRecommended: body.isRecommended || false,
      isPublished: body.isPublished || true,
    }).returning();

    return NextResponse.json(newOpp[0]);
  } catch (error: any) {
    console.error("Create opportunity error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
