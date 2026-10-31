import { db } from "@/db";
import { explorerCareers, explorerPrograms, explorerSchools, explorerDomains, explorerCareerPrograms } from "@/db/schema";
import { desc, eq, inArray } from "drizzle-orm";
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
  const [careers, programs, schools, domains, careerPrograms] = await Promise.all([
    db.select().from(explorerCareers).where(eq(explorerCareers.isPublished, true)).orderBy(desc(explorerCareers.createdAt)),
    db.select().from(explorerPrograms).where(eq(explorerPrograms.isPublished, true)).orderBy(desc(explorerPrograms.createdAt)),
    db.select().from(explorerSchools).where(eq(explorerSchools.isPublished, true)).orderBy(desc(explorerSchools.createdAt)),
    db.select().from(explorerDomains).where(eq(explorerDomains.isPublished, true)).orderBy(desc(explorerDomains.createdAt)),
    db.select().from(explorerCareerPrograms)
  ]);

  // Enrich domains with counts
  const enrichedDomains = domains.map(d => ({
    ...d,
    careersCount: careers.filter(c => c.domainId === d.id).length,
    programsCount: programs.filter(p => p.domainId === d.id).length,
  }));

  // Enrich careers with domain and linked programs count
  const enrichedCareers = careers.map(c => {
    const domain = domains.find(d => d.id === c.domainId);
    const directProgIds = careerPrograms.filter(cp => cp.careerId === c.id).map(cp => cp.programId);
    const count = directProgIds.length > 0 
      ? directProgIds.length 
      : programs.filter(p => p.domainId === c.domainId).length;
    return {
      ...c,
      domainTitle: domain?.title || "Secteur porteur",
      domainSlug: domain?.slug,
      programsCount: count
    };
  });

  // Enrich programs with school and domain info
  const enrichedPrograms = programs.map(p => {
    const school = schools.find(s => s.id === p.schoolId);
    const domain = domains.find(d => d.id === p.domainId);
    return {
      ...p,
      schoolName: school?.name || "Établissement supérieur",
      schoolCity: school?.city || "Togo",
      schoolSlug: school?.slug,
      schoolType: school?.type || "Enseignement supérieur",
      domainTitle: domain?.title || "Domaine d'études",
      domainSlug: domain?.slug
    };
  });

  // Enrich schools with programs count
  const enrichedSchools = schools.map(s => ({
    ...s,
    programsCount: programs.filter(p => p.schoolId === s.id).length,
  }));

  return (
    <ExplorerClient 
      initialDomains={enrichedDomains}
      initialCareers={enrichedCareers}
      initialPrograms={enrichedPrograms}
      initialSchools={enrichedSchools}
    />
  );
}
