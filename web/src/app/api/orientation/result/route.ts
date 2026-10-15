import { NextResponse } from 'next/server';
import { createClient } from '@/utils/supabase/server';
import { db } from '@/db';
import { orientationResults } from '@/db/schema';
import { eq, desc } from 'drizzle-orm';

export async function GET(req: Request) {
  try {
    const supabase = await createClient();
    const { data: { user }, error } = await supabase.auth.getUser();

    if (error || !user) {
      return NextResponse.json({ error: 'Non autorisé' }, { status: 401 });
    }

    // Récupérer le résultat le plus récent
    const results = await db.select()
      .from(orientationResults)
      .where(eq(orientationResults.userId, user.id))
      .orderBy(desc(orientationResults.createdAt))
      .limit(1);

    if (results.length === 0) {
      return NextResponse.json({ result: null });
    }

    return NextResponse.json({ result: results[0].results });
  } catch (error) {
    console.error("Erreur lors de la récupération des résultats", error);
    return NextResponse.json({ error: 'Erreur serveur' }, { status: 500 });
  }
}
