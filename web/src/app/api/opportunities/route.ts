import { NextResponse } from 'next/server';
import { db } from '@/db';
import { opportunities } from '@/db/schema';
import { desc, eq } from 'drizzle-orm';

export async function GET(request: Request) {
  try {
    const data = await db.select()
      .from(opportunities)
      .where(eq(opportunities.isPublished, true))
      .orderBy(desc(opportunities.createdAt));
      
    return NextResponse.json(data);
  } catch (error: any) {
    console.error("Fetch opportunities error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
