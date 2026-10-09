import { db } from "@/db";
import { opportunities } from "@/db/schema";
import { eq, desc } from "drizzle-orm";
import { createClient } from "@/utils/supabase/server";
import { redirect } from "next/navigation";
import OpportunitesClient from "./OpportunitesClient";

export default async function OpportunitesPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    redirect("/auth/login");
  }

  // Fetch only published opportunities
  const data = await db.select()
    .from(opportunities)
    .where(eq(opportunities.isPublished, true))
    .orderBy(desc(opportunities.createdAt));

  return <OpportunitesClient initialOpportunities={data} />;
}
