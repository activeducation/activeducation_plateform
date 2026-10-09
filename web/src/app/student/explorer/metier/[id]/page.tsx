import React from "react";
import { ArrowLeft, CheckCircle2, Building2, MapPin, GraduationCap } from "lucide-react";
import Link from "next/link";
import { AidaAssistant } from "@/components/student/AidaAssistant";
import { Card } from "@/components/ui/Card";
import { db } from "@/db";
import { explorerCareers, explorerDomains, explorerCareerPrograms, explorerPrograms, explorerSchools } from "@/db/schema";
import { eq } from "drizzle-orm";
import { createClient } from "@/utils/supabase/server";
import { notFound, redirect } from "next/navigation";

export default async function MetierPage({ params }: { params: Promise<{ id: string }> }) {
  const unwrappedParams = await params;
  
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    redirect("/auth/login");
  }

  const { id } = unwrappedParams;

  // 1. Fetch Career + Domain
  const metierQuery = await db.select({
    career: explorerCareers,
    domain: explorerDomains
  })
  .from(explorerCareers)
  .leftJoin(explorerDomains, eq(explorerCareers.domainId, explorerDomains.id))
  .where(eq(explorerCareers.slug, id))
  .limit(1);

  if (metierQuery.length === 0) {
    notFound();
  }

  const metier = metierQuery[0].career;
  const domain = metierQuery[0].domain;

  // 2. Fetch Formations via intersection table
  const formationsData = await db.select({
    program: explorerPrograms,
    school: explorerSchools
  })
  .from(explorerCareerPrograms)
  .innerJoin(explorerPrograms, eq(explorerCareerPrograms.programId, explorerPrograms.id))
  .leftJoin(explorerSchools, eq(explorerPrograms.schoolId, explorerSchools.id))
  .where(eq(explorerCareerPrograms.careerId, metier.id));

  // Parse JSONB arrays with safe fallbacks
  const skills = Array.isArray(metier.skills) ? metier.skills : [];
  const opportunities = Array.isArray(metier.opportunities) ? metier.opportunities : [];

  return (
    <div className="flex flex-col gap-6 -mt-4 md:-mt-8 -mx-4 md:-mx-8">
      
      {/* FULL WIDTH BANNER */}
      <div className="relative w-full h-[40dvh] md:h-[50dvh] bg-black overflow-hidden">
        <img 
          src={metier.bannerImage || "https://images.unsplash.com/photo-1555949963-ff9fe0c870eb?auto=format&fit=crop&w=1200&q=80"} 
          alt={metier.title} 
          className="w-full h-full object-cover opacity-60" 
        />
        
        <div className="absolute top-4 left-4 md:top-8 md:left-8 z-20">
          <Link href="/student/explorer" className="inline-flex items-center gap-2 text-sm font-bold text-white bg-black/40 hover:bg-black/60 px-4 py-2 rounded-full backdrop-blur-sm transition-colors">
            <ArrowLeft className="w-4 h-4" /> Retour à l'exploration
          </Link>
        </div>

        <div className="absolute bottom-0 left-0 w-full p-6 md:p-10 bg-gradient-to-t from-canvas via-canvas/80 to-transparent">
          <span className="text-[10px] md:text-xs uppercase font-bold text-primary bg-primary/10 backdrop-blur-md px-3 py-1.5 rounded-sm mb-3 inline-block">
            {domain?.title || "Secteur"}
          </span>
          <h1 className="font-display font-bold text-3xl md:text-5xl text-text-primary mb-2 drop-shadow-sm">
            {metier.title}
          </h1>
        </div>
      </div>

      <div className="max-w-5xl mx-auto w-full px-4 md:px-8 pb-12 flex flex-col lg:flex-row gap-8">
        
        {/* MAIN COLUMN */}
        <div className="flex-1 flex flex-col gap-8">
          
          <section>
            <h2 className="text-xl font-bold text-text-primary mb-4">Description du métier</h2>
            <p className="text-text-secondary leading-relaxed">
              {metier.description || "Aucune description détaillée n'est disponible pour ce métier."}
            </p>
          </section>

          {skills.length > 0 && (
            <section>
              <h2 className="text-xl font-bold text-text-primary mb-4">Compétences nécessaires</h2>
              <div className="flex flex-wrap gap-2">
                {skills.map((skill: string, i: number) => (
                  <span key={i} className="px-3 py-1.5 bg-surface border border-border-soft rounded-md text-sm font-medium text-text-secondary flex items-center gap-2">
                    <CheckCircle2 className="w-4 h-4 text-primary" /> {skill}
                  </span>
                ))}
              </div>
            </section>
          )}

          {opportunities.length > 0 && (
            <section>
              <h2 className="text-xl font-bold text-text-primary mb-4">Débouchés & Opportunités</h2>
              <div className="flex flex-wrap gap-2">
                {opportunities.map((opp: string, i: number) => (
                  <span key={i} className="px-3 py-1.5 bg-gold/10 border border-gold/20 rounded-md text-sm font-bold text-gold-dark">
                    {opp}
                  </span>
                ))}
              </div>
            </section>
          )}

        </div>

        {/* RIGHT COLUMN (AÏDA + Formations) */}
        <div className="w-full lg:w-96 flex flex-col gap-6">
          
          <AidaAssistant 
            title="Pourquoi AÏDA vous le recommande"
            message={`Cette suggestion s'appuie notamment sur vos intérêts et les données actuelles du marché pour le secteur ${domain?.title || ""}.`}
            variant="floating"
          />

          <Card variant="standard" className="p-6">
            <h2 className="font-bold text-text-primary mb-4 flex items-center gap-2">
              <GraduationCap className="w-5 h-5 text-primary" />
              Formations possibles
            </h2>
            
            <div className="flex flex-col gap-4">
              {formationsData.length > 0 ? formationsData.map((f, i) => (
                <Link href={`/student/explorer/formation/${f.program.slug}`} key={i} className="group block outline-none">
                  <div className="flex flex-col gap-1 pb-4 border-b border-border-soft last:border-0 last:pb-0">
                    <h3 className="font-bold text-sm text-text-primary group-hover:text-primary transition-colors">{f.program.title}</h3>
                    <div className="flex flex-col gap-1 mt-1">
                      <span className="text-xs text-text-secondary flex items-center gap-1">
                        <Building2 className="w-3 h-3" /> {f.school?.name || "Non précisé"}
                      </span>
                      <span className="text-xs text-text-secondary flex items-center gap-1">
                        <MapPin className="w-3 h-3" /> {f.school?.city || "Localisation non précisée"} ({f.program.duration || "Durée inconnue"})
                      </span>
                    </div>
                  </div>
                </Link>
              )) : (
                <div className="text-sm text-text-secondary">Aucune formation rattachée à ce métier.</div>
              )}
            </div>
          </Card>

        </div>
      </div>
    </div>
  );
}
