import { requireAdmin } from '@/utils/auth';
import { db } from "@/db";
import { explorerDomains, explorerSchools, explorerPrograms, explorerCareers } from "@/db/schema";
import { desc } from "drizzle-orm";
import { createClient } from "@/utils/supabase/server";
import { redirect } from "next/navigation";
import AdminExplorerClient from "./AdminExplorerClient";

export default async function AdminExplorerPage() {
  const access = await requireAdmin();
  if (access.errorResponse) redirect('/student');
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    redirect("/auth/login");
  }

  // NOTE: Server role check is done in layout or middleware ideally, 
  // but API routes secure the mutations. We can still pass data safely.
  
  const domains = await db.select().from(explorerDomains).orderBy(desc(explorerDomains.createdAt));
  const schools = await db.select().from(explorerSchools).orderBy(desc(explorerSchools.createdAt));
  const programs = await db.select().from(explorerPrograms).orderBy(desc(explorerPrograms.createdAt));
  const careers = await db.select().from(explorerCareers).orderBy(desc(explorerCareers.createdAt));

  return (
    <AdminExplorerClient 
      initialDomains={domains}
      initialSchools={schools}
      initialPrograms={programs}
      initialCareers={careers}
    />
  );
}
