import { createClient } from '@/utils/supabase/server';
import { db } from '@/db';
import { users } from '@/db/schema';
import { eq } from 'drizzle-orm';
import { NextResponse } from 'next/server';

export async function requireAdmin() {
  const access = await requireAuth();
  if (access.errorResponse) return access;
  if (access.user.role?.toUpperCase() !== 'ADMIN') {
    return { errorResponse: NextResponse.json({ error: 'Accès administrateur requis.' }, { status: 403 }) };
  }
  return access;
}

export async function requireAuth() {
  const supabase = await createClient();
  const { data: { user }, error } = await supabase.auth.getUser();

  if (error || !user) {
    return { errorResponse: NextResponse.json({ error: "Non autorisé. Veuillez vous connecter." }, { status: 401 }) };
  }
  
  let dbUser = await db.select().from(users).where(eq(users.id, user.id)).limit(1);
  if (!dbUser || dbUser.length === 0) {
    if (!user.email) return { errorResponse: NextResponse.json({ error: 'Adresse email requise.' }, { status: 403 }) };
    await db.insert(users).values({ id: user.id, email: user.email, fullName: typeof user.user_metadata?.full_name === 'string' ? user.user_metadata.full_name.slice(0, 255) : null, role: 'STUDENT' }).onConflictDoNothing({ target: users.id });
    dbUser = await db.select().from(users).where(eq(users.id, user.id)).limit(1);
    if (!dbUser.length) return { errorResponse: NextResponse.json({ error: 'Profil indisponible.' }, { status: 503 }) };
  }

  return { user: dbUser[0] };
}
