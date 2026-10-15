import { db } from "@/db";
import { explorerCareers, explorerPrograms, explorerSchools, explorerDomains } from "@/db/schema";
import { desc, eq } from "drizzle-orm";
import { createClient } from "@/utils/supabase/server";
import { redirect } from "next/navigation";
import ExplorerClient from "./ExplorerClient";

export default async function ExplorerPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    redirect("/auth/login");
  }

  // Fetch all active records
  const careers = await db.select().from(explorerCareers).where(eq(explorerCareers.isPublished, true)).orderBy(desc(explorerCareers.createdAt));
  const programs = await db.select().from(explorerPrograms).where(eq(explorerPrograms.isPublished, true)).orderBy(desc(explorerPrograms.createdAt));
  const schools = await db.select().from(explorerSchools).where(eq(explorerSchools.isPublished, true)).orderBy(desc(explorerSchools.createdAt));
  const domains = await db.select().from(explorerDomains).where(eq(explorerDomains.isPublished, true)).orderBy(desc(explorerDomains.createdAt));

  return (
    <ExplorerClient 
      initialCareers={careers}
      initialPrograms={programs}
      initialSchools={schools}
      initialDomains={domains}
    />
  );
}
