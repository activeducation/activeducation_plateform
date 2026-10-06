import { NextResponse } from 'next/server';
import { db } from '@/db';
import { opportunities } from '@/db/schema';
import { eq } from 'drizzle-orm';

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
