import { NextResponse } from 'next/server';
import { createClient } from '@/utils/supabase/server';
import { db } from '@/db';
import { users } from '@/db/schema';
import { eq } from 'drizzle-orm';

export async function POST(req: Request) {
  try {
    const supabase = await createClient();
    const { data: { user }, error } = await supabase.auth.getUser();

    if (error || !user) {
      return NextResponse.json({ error: 'Non autorisé' }, { status: 401 });
    }

    const { xpToAdd } = await req.json();

    if (typeof xpToAdd !== 'number' || xpToAdd <= 0) {
      return NextResponse.json({ error: 'Montant XP invalide' }, { status: 400 });
    }

    // Récupérer le profil actuel
    let userProfile = await db.select().from(users).where(eq(users.id, user.id)).limit(1);

    if (userProfile.length === 0) {
      // Lazy creation pour les anciens utilisateurs
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

    const currentXp = userProfile[0].xpPoints || 0;
    const currentLevel = userProfile[0].level || 1;

    const newXp = currentXp + xpToAdd;
    // Logique de niveau simplifiée : 1 niveau tous les 100 XP
    const newLevel = Math.max(currentLevel, Math.floor(newXp / 100) + 1);

    // Mettre à jour l'utilisateur
    await db.update(users)
      .set({ xpPoints: newXp, level: newLevel })
      .where(eq(users.id, user.id));

    return NextResponse.json({ success: true, xpPoints: newXp, level: newLevel });
  } catch (error) {
    console.error("Erreur lors de la mise à jour de l'XP", error);
    return NextResponse.json({ error: 'Erreur serveur' }, { status: 500 });
  }
}
