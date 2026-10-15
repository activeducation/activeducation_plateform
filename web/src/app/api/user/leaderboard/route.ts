import { NextResponse } from 'next/server';
import { db } from '@/db';
import { users } from '@/db/schema';
import { desc } from 'drizzle-orm';
import { createClient } from '@/utils/supabase/server';

export async function GET(request: Request) {
  try {
    const supabase = await createClient();
    const { data: { session } } = await supabase.auth.getSession();
    
    const currentUserEmail = session?.user?.email;

    // Fetch top 5 users by XP
    const topUsers = await db.select({
      id: users.id,
      email: users.email,
      fullName: users.fullName,
      xpPoints: users.xpPoints,
      avatarUrl: users.avatarUrl
    })
    .from(users)
    .orderBy(desc(users.xpPoints))
    .limit(5);

    const formattedLeaderboard = topUsers.map((u, index) => {
      let displayName = u.fullName;
      if (!displayName) {
        displayName = u.email.split('@')[0];
      }

      const isMe = currentUserEmail && u.email === currentUserEmail;

      const avatar = u.avatarUrl || `https://api.dicebear.com/7.x/avataaars/svg?seed=${displayName}`;

      return {
        rank: index + 1,
        name: isMe ? "Vous" : displayName,
        xp: u.xpPoints || 0,
        avatar: avatar,
        isMe: !!isMe
      };
    });

    return NextResponse.json(formattedLeaderboard);

  } catch (error: any) {
    console.error("Leaderboard error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
