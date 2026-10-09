import { db } from "@/db";
import { users, orientationResults } from "@/db/schema";
import { eq, desc } from "drizzle-orm";
import { createClient } from "@/utils/supabase/server";
import { redirect } from "next/navigation";
import StudentDashboardClient from "./StudentDashboardClient";

export default async function StudentDashboardPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    redirect("/auth/login");
  }

  // Fetch User profile
  const dbUser = await db.select().from(users).where(eq(users.id, user.id)).limit(1);
  const userData = dbUser.length > 0 ? dbUser[0] : null;

  // Fetch Orientation Result
  const orientationData = await db.select()
    .from(orientationResults)
    .where(eq(orientationResults.userId, user.id))
    .orderBy(desc(orientationResults.createdAt))
    .limit(1);

  return (
    <StudentDashboardClient 
      initialUser={userData} 
      initialOrientation={orientationData.length > 0 ? orientationData[0] : null} 
    />
  );
}
