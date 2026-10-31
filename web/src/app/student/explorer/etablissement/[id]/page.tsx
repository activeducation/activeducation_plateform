import React from "react";
import { 
  ArrowLeft, 
  ArrowRight, 
  MapPin, 
  Building2, 
  BookOpen, 
  GraduationCap, 
  Star, 
  CheckCircle2, 
  Award,
  ChevronRight,
  Briefcase
} from "lucide-react";
import Link from "next/link";
import { Card } from "@/components/ui/Card";
import { AidaAssistant } from "@/components/student/AidaAssistant";
import { db } from "@/db";
import { explorerSchools, explorerPrograms, explorerDomains } from "@/db/schema";
import { and, eq } from "drizzle-orm";
import { createClient } from "@/utils/supabase/server";
import { notFound, redirect } from "next/navigation";

export default async function EtablissementPage({ params }: { params: Promise<{ id: string }> }) {
  const unwrappedParams = await params;
  
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    redirect("/auth/login");
  }

  const { id } = unwrappedParams;

  const schoolQuery = await db.select().from(explorerSchools).where(and(eq(explorerSchools.slug, id), eq(explorerSchools.isPublished, true))).limit(1);

  if (schoolQuery.length === 0) {
    notFound();
  }

  const school = schoolQuery[0];

  // Fetch formations of this school with domain title
  const formations = await db.select({
    program: explorerPrograms,
    domain: explorerDomains
  })
  .from(explorerPrograms)
  .leftJoin(explorerDomains, eq(explorerPrograms.domainId, explorerDomains.id))
  .where(and(eq(explorerPrograms.schoolId, school.id), eq(explorerPrograms.isPublished, true)));

  const facilities = Array.isArray(school.facilities) ? school.facilities : [];

  return (
    <div className="flex flex-col gap-6 -mt-4 md:-mt-8 -mx-4 md:-mx-8">
      
      {/* FULL WIDTH BANNER */}
      <div className="relative w-full h-[40dvh] md:h-[50dvh] bg-black overflow-hidden">
        <img 
          src={school.bannerImage || "https://images.unsplash.com/photo-1541339907198-e08756dedf3f?auto=format&fit=crop&w=1200&q=80"} 
          alt={school.name} 
          className="w-full h-full object-cover opacity-60" 
        />
        
        {/* BREADCRUMB */}
        <div className="absolute top-4 left-4 md:top-8 md:left-8 z-20 flex items-center gap-2 text-xs md:text-sm font-bold text-white bg-black/40 hover:bg-black/60 px-4 py-2 rounded-full backdrop-blur-sm transition-colors">
          <Link href="/student/explorer" className="hover:underline flex items-center gap-1.5">
            <ArrowLeft className="w-4 h-4" /> Explorer
          </Link>
          <ChevronRight className="w-3.5 h-3.5 opacity-60" />
          <span className="opacity-90">Établissements</span>
          <ChevronRight className="w-3.5 h-3.5 opacity-60" />
          <span className="text-white truncate max-w-[150px] md:max-w-none">{school.name}</span>
        </div>

        <div className="absolute bottom-0 left-0 w-full p-6 md:p-10 bg-gradient-to-t from-canvas via-canvas/80 to-transparent flex flex-col md:flex-row md:items-end justify-between gap-4">
          <div>
            <div className="flex flex-wrap items-center gap-2 mb-3">
              <span className="text-[10px] md:text-xs uppercase font-bold text-white bg-primary px-3 py-1.5 rounded-full inline-flex items-center gap-1.5 shadow-sm">
                <Building2 className="w-3.5 h-3.5" /> {school.type || "Établissement supérieur"}
              </span>
              <span className="text-[10px] md:text-xs uppercase font-bold text-white bg-black/50 backdrop-blur-md px-3 py-1.5 rounded-full flex items-center gap-1">
                <MapPin className="w-3.5 h-3.5 text-primary" /> {school.city || "Lomé, Togo"}
              </span>
            </div>
            <h1 className="font-display font-bold text-3xl md:text-5xl text-white mb-2 drop-shadow-sm">
              {school.name}
            </h1>
          </div>
          
          <div className="flex gap-3">
            {school.rating && (
              <div className="bg-surface/20 backdrop-blur-md border border-white/10 rounded-xl p-3 flex flex-col items-center min-w-[90px]">
                <span className="text-gold flex items-center gap-1 font-bold text-lg"><Star className="w-4 h-4 fill-gold" /> {school.rating}</span>
                <span className="text-[11px] text-white/80">{school.reviewsCount || 0} avis</span>
              </div>
            )}
            {school.insertionRate && (
              <div className="bg-surface/20 backdrop-blur-md border border-white/10 rounded-xl p-3 flex flex-col items-center min-w-[90px]">
                <span className="text-success flex items-center gap-1 font-bold text-lg"><Award className="w-4 h-4" /> {school.insertionRate}</span>
                <span className="text-[11px] text-white/80">Insertion</span>
              </div>
            )}
          </div>
        </div>
      </div>

      <div className="max-w-5xl mx-auto w-full px-4 md:px-8 pb-12 flex flex-col lg:flex-row gap-8">
        
        {/* MAIN COLUMN */}
        <div className="flex-1 flex flex-col gap-8">
          
          <section className="bg-surface p-6 rounded-2xl border border-border-soft">
            <h2 className="text-xl font-bold text-text-primary mb-3 flex items-center gap-2">
              <Building2 className="w-5 h-5 text-primary" />
              Présentation de l'établissement
            </h2>
            <p className="text-text-secondary leading-relaxed">
              {school.description || "Aucune description détaillée n'est disponible pour cet établissement."}
            </p>
          </section>

          {facilities.length > 0 && (
            <section className="bg-surface p-6 rounded-2xl border border-border-soft">
              <h2 className="text-xl font-bold text-text-primary mb-3 flex items-center gap-2">
                <BookOpen className="w-5 h-5 text-primary" />
                Infrastructures & Services aux étudiants
              </h2>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-2.5">
                {facilities.map((fac: string, i: number) => (
                  <div key={i} className="flex items-start gap-2.5 p-2.5 bg-surface-alt border border-border-soft rounded-lg">
                    <CheckCircle2 className="w-4 h-4 text-primary shrink-0 mt-0.5" />
                    <span className="text-xs md:text-sm text-text-secondary">{fac}</span>
                  </div>
                ))}
              </div>
            </section>
          )}

          {/* FORMATIONS PROPOSÉES */}
          <section>
            <div className="mb-4">
              <h2 className="text-2xl font-bold text-text-primary flex items-center gap-2">
                <GraduationCap className="w-6 h-6 text-primary" />
                Formations dispensées ({formations.length})
              </h2>
              <p className="text-xs text-text-secondary mt-1">
                Filières accréditées et diplômes d'État proposés aux étudiants :
              </p>
            </div>

            <div className="grid grid-cols-1 gap-3">
              {formations.length > 0 ? formations.map(({ program, domain }) => (
                <Link href={`/student/explorer/formation/${program.slug}`} key={program.id} className="group block">
                  <Card variant="interactive" className="p-4 md:p-5 border border-border-soft hover:border-primary/40 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                    <div className="flex-1">
                      <div className="flex flex-wrap items-center gap-2 mb-1.5">
                        <span className="text-[10px] font-bold text-primary bg-primary/10 px-2 py-0.5 rounded uppercase">
                          {program.level || "Diplôme supérieur"}
                        </span>
                        {domain && (
                          <span className="text-[10px] font-medium text-text-secondary bg-surface-alt px-2 py-0.5 rounded">
                            {domain.title}
                          </span>
                        )}
                        {program.duration && (
                          <span className="text-[10px] font-medium text-text-tertiary">
                            • {program.duration}
                          </span>
                        )}
                      </div>
                      <h3 className="font-bold text-base text-text-primary group-hover:text-primary transition-colors">
                        {program.title}
                      </h3>
                      {program.description && (
                        <p className="text-xs text-text-secondary line-clamp-2 mt-1">
                          {program.description}
                        </p>
                      )}
                    </div>

                    <div className="flex items-center gap-1.5 text-xs font-bold text-primary group-hover:underline shrink-0">
                      <span>Voir le programme</span>
                      <ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
                    </div>
                  </Card>
                </Link>
              )) : (
                <div className="p-6 bg-surface-alt rounded-2xl text-text-secondary text-sm text-center">
                  Aucune formation n'a été rattachée à cet établissement pour le moment.
                </div>
              )}
            </div>
          </section>

        </div>

        {/* RIGHT COLUMN (AÏDA) */}
        <div className="w-full lg:w-80 flex flex-col gap-6">
          <AidaAssistant 
            title="S'informer sur cette université"
            message={`Vous souhaitez intégrer ${school.name} ? AÏDA peut vous renseigner sur les dates des concours, les frais de scolarité et les bourses disponibles.`}
            variant="floating"
            actionLabel="Poser une question à AÏDA"
            actionPrompt={`Bonjour AÏDA ! Peux-tu me renseigner sur ${school.name} à ${school.city || "Lomé"} : conditions d'accès, réputation des diplômes et opportunités post-études ?`}
          />
        </div>

      </div>
    </div>
  );
}
