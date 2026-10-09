import { db } from "@/db";
import { opportunities } from "@/db/schema";
import { desc } from "drizzle-orm";
import { createClient } from "@/utils/supabase/server";
import { redirect } from "next/navigation";
import OpportunitesAdminClient from "./OpportunitesAdminClient";

export default async function AdminOpportunitesPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    redirect("/auth/login");
  }

  // Check admin role if needed (assuming middleware or layout handles it, but good practice)
  // Fetch ALL opportunities for Admin
  const data = await db.select()
    .from(opportunities)
    .orderBy(desc(opportunities.createdAt));

  return <OpportunitesAdminClient initialOpportunities={data} />;
}
