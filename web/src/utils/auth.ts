import { createClient } from '@/utils/supabase/server';
import { db } from '@/db';
import { users } from '@/db/schema';
import { eq } from 'drizzle-orm';
import { NextResponse } from 'next/server';

export async function requireAdmin() {
  const supabase = await createClient();
  const { data: { user }, error } = await supabase.auth.getUser();

  if (error || !user) {
    return { errorResponse: NextResponse.json({ error: "Non autorisé. Veuillez vous connecter." }, { status: 401 }) };
  }

  const dbUser = await db.select().from(users).where(eq(users.id, user.id)).limit(1);

  if (!dbUser || dbUser.length === 0 || dbUser[0].role !== 'ADMIN') {
    return { errorResponse: NextResponse.json({ error: "Accès refusé. Privilèges administrateur requis." }, { status: 403 }) };
  }

  return { user: dbUser[0] };
}

export async function requireAuth() {
  const supabase = await createClient();
  const { data: { user }, error } = await supabase.auth.getUser();

  if (error || !user) {
    return { errorResponse: NextResponse.json({ error: "Non autorisé. Veuillez vous connecter." }, { status: 401 }) };
  }
  
  const dbUser = await db.select().from(users).where(eq(users.id, user.id)).limit(1);
  if (!dbUser || dbUser.length === 0) {
    return { errorResponse: NextResponse.json({ error: "Utilisateur non trouvé dans la base de données." }, { status: 404 }) };
  }

  return { user: dbUser[0] };
}
