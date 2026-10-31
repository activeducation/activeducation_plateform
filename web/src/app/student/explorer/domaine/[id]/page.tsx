import React from "react";
import { 
  ArrowLeft, 
  ArrowRight, 
  Briefcase, 
  GraduationCap, 
  TrendingUp, 
  Lightbulb, 
  Target, 
  Building2, 
  MapPin, 
  Map, 
  ChevronRight,
  Sparkles
} from "lucide-react";
import Link from "next/link";
import { Card } from "@/components/ui/Card";
import { AidaAssistant } from "@/components/student/AidaAssistant";
import { db } from "@/db";
import { explorerDomains, explorerCareers, explorerPrograms, explorerSchools, explorerCareerPrograms } from "@/db/schema";
import { and, eq } from "drizzle-orm";
import { createClient } from "@/utils/supabase/server";
import { notFound, redirect } from "next/navigation";

export default async function DomainePage({ params }: { params: Promise<{ id: string }> }) {
  const unwrappedParams = await params;
  
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    redirect("/auth/login");
  }

  const { id } = unwrappedParams; // 'id' in URL maps to 'slug' in db

  const domainQuery = await db.select().from(explorerDomains).where(and(eq(explorerDomains.slug, id), eq(explorerDomains.isPublished, true))).limit(1);
  const domaine = domainQuery[0];

  if (!domaine) {
    notFound();
  }

  // Métiers de ce domaine
  const metiers = await db.select().from(explorerCareers).where(and(eq(explorerCareers.domainId, domaine.id), eq(explorerCareers.isPublished, true)));

  // Formations de ce domaine avec leurs écoles respectives
  const formationsData = await db.select({
    program: explorerPrograms,
    school: explorerSchools
  })
  .from(explorerPrograms)
  .leftJoin(explorerSchools, eq(explorerPrograms.schoolId, explorerSchools.id))
  .where(and(eq(explorerPrograms.domainId, domaine.id), eq(explorerPrograms.isPublished, true)));

  // Récupérer les liaisons métiers-formations
  const cpLinks = await db.select().from(explorerCareerPrograms);

  return (
    <div className="flex flex-col gap-6 -mt-4 md:-mt-8 -mx-4 md:-mx-8">
      
      {/* FULL WIDTH BANNER */}
      <div className="relative w-full h-[35dvh] md:h-[45dvh] bg-black overflow-hidden">
        <img 
          src={domaine.bannerImage || "https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=1200&q=80"} 
          alt={domaine.title} 
          className="w-full h-full object-cover opacity-60" 
        />
        
        {/* BREADCRUMB NAVIGATION */}
        <div className="absolute top-4 left-4 md:top-8 md:left-8 z-20 flex items-center gap-2 text-xs md:text-sm font-bold text-white bg-black/40 hover:bg-black/60 px-4 py-2 rounded-full backdrop-blur-sm transition-colors">
          <Link href="/student/explorer" className="hover:underline flex items-center gap-1.5">
            <ArrowLeft className="w-4 h-4" /> Explorer
          </Link>
          <ChevronRight className="w-3.5 h-3.5 opacity-60" />
          <span className="opacity-90">Domaines</span>
          <ChevronRight className="w-3.5 h-3.5 opacity-60" />
          <span className="text-white">{domaine.title}</span>
        </div>

        <div className="absolute bottom-0 left-0 w-full p-6 md:p-10 bg-gradient-to-t from-canvas via-canvas/80 to-transparent">
          <span className="text-[10px] md:text-xs uppercase font-bold text-white bg-primary px-3 py-1.5 rounded-full mb-3 inline-flex items-center gap-1.5 shadow-sm">
            <Map className="w-3.5 h-3.5" /> Secteur d'activité
          </span>
          <h1 className="font-display font-bold text-3xl md:text-5xl text-white mb-2 drop-shadow-lg">
            {domaine.title}
          </h1>
        </div>
      </div>

      <div className="max-w-5xl mx-auto w-full px-4 md:px-8 pb-12 flex flex-col lg:flex-row gap-8">
        
        {/* MAIN COLUMN */}
        <div className="flex-1 flex flex-col gap-8">
          
          {/* STATS & VUE D'ENSEMBLE */}
          <section className="bg-surface p-6 rounded-2xl border border-border-soft flex flex-col gap-6">
            <div>
              <h2 className="text-xl font-bold text-text-primary mb-2 flex items-center gap-2">
                <Lightbulb className="w-5 h-5 text-primary" />
                Présentation du secteur
              </h2>
              <p className="text-text-secondary leading-relaxed">
                {domaine.description || "Ce domaine regroupe des carrières en plein développement au Togo et dans la sous-région ouest-africaine."}
              </p>
            </div>

            {/* STATS GRID */}
            <div className="grid grid-cols-3 gap-3 pt-4 border-t border-border-soft">
              <div className="p-3 rounded-xl bg-surface-alt flex flex-col items-center text-center">
                <TrendingUp className="w-4 h-4 text-primary mb-1" />
                <span className="text-[10px] uppercase font-bold text-text-tertiary">Croissance</span>
                <span className="text-sm font-bold text-text-primary">{domaine.growth || "+15% / an"}</span>
              </div>
              <div className="p-3 rounded-xl bg-surface-alt flex flex-col items-center text-center">
                <Target className="w-4 h-4 text-success mb-1" />
                <span className="text-[10px] uppercase font-bold text-text-tertiary">Employabilité</span>
                <span className="text-sm font-bold text-text-primary">{domaine.employability || "Très forte"}</span>
              </div>
              <div className="p-3 rounded-xl bg-surface-alt flex flex-col items-center text-center">
                <Briefcase className="w-4 h-4 text-gold-dark mb-1" />
                <span className="text-[10px] uppercase font-bold text-text-tertiary">Rémunération</span>
                <span className="text-sm font-bold text-text-primary">{domaine.salary || "Compétitive"}</span>
              </div>
            </div>

            {domaine.why && (
              <div className="p-4 bg-primary/5 rounded-xl border border-primary/10 text-xs md:text-sm text-text-secondary leading-relaxed">
                <strong className="text-primary block mb-1">Pourquoi choisir ce secteur ?</strong>
                {domaine.why}
              </div>
            )}
          </section>

          {/* 1. SECTION MAÎTRESSE : LES MÉTIERS DE CE DOMAINE */}
          <section>
            <div className="flex items-center justify-between mb-4">
              <div>
                <h2 className="text-2xl font-bold text-text-primary flex items-center gap-2">
                  <Briefcase className="w-6 h-6 text-primary" />
                  Métiers de ce domaine ({metiers.length})
                </h2>
                <p className="text-xs text-text-secondary mt-1">
                  Cliquez sur un métier pour voir ses missions et les formations associées :
                </p>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {metiers.length > 0 ? metiers.map((metier) => {
                const skillsList = Array.isArray(metier.skills) ? metier.skills : [];
                const directProgs = cpLinks.filter(cp => cp.careerId === metier.id);
                const count = directProgs.length > 0 ? directProgs.length : formationsData.length;

                return (
                  <Link href={`/student/explorer/metier/${metier.slug}`} key={metier.id} className="group block">
                    <Card variant="interactive" className="h-full flex flex-col overflow-hidden p-0 border border-border-soft hover:border-primary/40">
                      <div className="h-36 relative overflow-hidden bg-surface-alt">
                        <img 
                          src={metier.bannerImage || "https://images.unsplash.com/photo-1517694712202-14dd9538aa97?auto=format&fit=crop&w=600&q=80"} 
                          alt={metier.title} 
                          className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500" 
                        />
                        <div className="absolute top-2 left-2 bg-white/95 px-2 py-0.5 rounded text-[10px] font-bold text-primary shadow-sm">
                          Métier
                        </div>
                      </div>

                      <div className="p-4 flex flex-col flex-1">
                        <h3 className="font-bold text-base text-text-primary mb-1.5 group-hover:text-primary transition-colors leading-snug">
                          {metier.title}
                        </h3>
                        <p className="text-xs text-text-secondary line-clamp-2 mb-3">
                          {metier.description}
                        </p>

                        {skillsList.length > 0 && (
                          <div className="flex flex-wrap gap-1 mb-3">
                            {skillsList.slice(0, 2).map((s: string, idx: number) => (
                              <span key={idx} className="text-[10px] font-medium bg-surface-alt px-1.5 py-0.5 rounded text-text-secondary">
                                {s}
                              </span>
                            ))}
                            {skillsList.length > 2 && (
                              <span className="text-[10px] text-text-tertiary self-center">
                                +{skillsList.length - 2}
                              </span>
                            )}
                          </div>
                        )}

                        <div className="mt-auto pt-2.5 border-t border-border-soft flex items-center justify-between text-xs font-bold text-primary">
                          <span className="text-[11px] text-text-secondary font-medium flex items-center gap-1">
                            <GraduationCap className="w-3.5 h-3.5 text-gold-dark" />
                            {count} formation{count > 1 ? "s" : ""}
                          </span>
                          <span className="group-hover:underline flex items-center gap-1">
                            Découvrir <ArrowRight className="w-3.5 h-3.5" />
                          </span>
                        </div>
                      </div>
                    </Card>
                  </Link>
                );
              }) : (
                <div className="col-span-full p-6 bg-surface-alt rounded-xl text-text-secondary text-sm text-center">
                  Aucun métier spécifique n'est encore répertorié pour ce domaine.
                </div>
              )}
            </div>
          </section>

          {/* 2. SECTION : FORMATIONS DISPONIBLES DANS CE SECTEUR */}
          <section>
            <div className="mb-4">
              <h2 className="text-xl font-bold text-text-primary flex items-center gap-2">
                <GraduationCap className="w-5 h-5 text-primary" />
                Formations et cursus universitaires ({formationsData.length})
              </h2>
              <p className="text-xs text-text-secondary mt-1">
                Les diplômes proposés par les universités et grandes écoles partenaires :
              </p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {formationsData.length > 0 ? formationsData.map(({ program, school }) => (
                <Link href={`/student/explorer/formation/${program.slug}`} key={program.id} className="group block">
                  <Card variant="interactive" className="p-4 flex flex-col h-full border border-border-soft hover:border-primary/40">
                    <span className="text-[10px] uppercase font-bold text-primary bg-primary/10 px-2 py-0.5 rounded self-start mb-2">
                      {program.level || "Diplôme supérieur"}
                    </span>
                    <h3 className="font-bold text-sm text-text-primary group-hover:text-primary transition-colors mb-2">
                      {program.title}
                    </h3>
                    
                    {school && (
                      <div className="flex items-center gap-2 text-xs text-text-secondary mt-auto pt-2 border-t border-border-soft">
                        <Building2 className="w-3.5 h-3.5 text-primary shrink-0" />
                        <span className="truncate font-medium">{school.name}</span>
                      </div>
                    )}
                  </Card>
                </Link>
              )) : (
                <div className="col-span-full p-6 bg-surface-alt rounded-xl text-text-secondary text-sm text-center">
                  Aucune formation rattachée à ce domaine pour le moment.
                </div>
              )}
            </div>
          </section>

        </div>

        {/* RIGHT COLUMN (AÏDA) */}
        <div className="w-full lg:w-80 flex flex-col gap-6">
          <AidaAssistant 
            title="Conseil d'AÏDA pour ce secteur"
            message={`Le domaine "${domaine.title}" recrute activement au Togo. Vous pouvez explorer les métiers ci-contre ou me poser vos questions pour choisir le bon cursus.`}
            variant="floating"
            actionLabel="Demander conseil à AÏDA"
            actionPrompt={`Bonjour AÏDA, le domaine "${domaine.title}" m'intéresse beaucoup. Quels sont les métiers les plus prometteurs et les meilleures formations à Lomé pour ce secteur ?`}
          />
        </div>

      </div>
    </div>
  );
}
