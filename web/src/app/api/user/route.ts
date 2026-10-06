import { NextResponse } from 'next/server';
import { createClient } from '@/utils/supabase/server';
import { db } from '@/db';
import { users } from '@/db/schema';
import { eq } from 'drizzle-orm';

export async function GET() {
  try {
    const supabase = await createClient();
    const { data: { user }, error } = await supabase.auth.getUser();

    if (error || !user) {
      return NextResponse.json({ error: 'Non autorisé' }, { status: 401 });
    }

    // Récupérer le profil utilisateur depuis PostgreSQL via Drizzle
    let userProfile = await db.select().from(users).where(eq(users.id, user.id)).limit(1);

    if (userProfile.length === 0) {
      // Lazy creation : Si c'est un ancien utilisateur qui n'a pas déclenché le trigger
      const newUser = await db.insert(users).values({
        id: user.id,
        email: user.email!,
        fullName: user.user_metadata?.full_name || null,
        role: 'STUDENT',
        xpPoints: 0,
        level: 1
      }).returning();
      
      userProfile = newUser;
    }

    return NextResponse.json(userProfile[0]);
  } catch (error) {
    console.error("Erreur lors de la récupération du profil", error);
    return NextResponse.json({ error: 'Erreur serveur' }, { status: 500 });
  }
}
