import { requireAdmin } from '@/utils/auth';
import { db } from "@/db";
import { users } from "@/db/schema";
import { desc } from "drizzle-orm";
import { createClient } from "@/utils/supabase/server";
import { redirect } from "next/navigation";
import UtilisateursClient from "./UtilisateursClient";

export default async function AdminUtilisateursPage() {
  const access = await requireAdmin();
  if (access.errorResponse) redirect('/student');
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    redirect("/auth/login");
  }

  // Fetch all users
  const allUsers = await db.select().from(users).orderBy(desc(users.createdAt));

  return (
    <UtilisateursClient initialUsers={allUsers} />
  );
}
