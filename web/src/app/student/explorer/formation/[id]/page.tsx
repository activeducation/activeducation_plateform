import React from "react";
import { 
  ArrowLeft, 
  ArrowRight, 
  Building2, 
  MapPin, 
  GraduationCap, 
  CheckCircle2, 
  Clock, 
  Wallet, 
  ShieldCheck, 
  Briefcase,
  ChevronRight,
  Star,
  Award
} from "lucide-react";
import Link from "next/link";
import { AidaAssistant } from "@/components/student/AidaAssistant";
import { Card } from "@/components/ui/Card";
import { db } from "@/db";
import { explorerPrograms, explorerDomains, explorerSchools, explorerCareers, explorerCareerPrograms } from "@/db/schema";
import { and, eq } from "drizzle-orm";
import { createClient } from "@/utils/supabase/server";
import { notFound, redirect } from "next/navigation";

export default async function FormationPage({ params }: { params: Promise<{ id: string }> }) {
  const unwrappedParams = await params;
  
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    redirect("/auth/login");
  }

  const { id } = unwrappedParams;

  // Fetch Program + School + Domain
  const programQuery = await db.select({
    program: explorerPrograms,
    school: explorerSchools,
    domain: explorerDomains
  })
  .from(explorerPrograms)
  .innerJoin(explorerSchools, eq(explorerPrograms.schoolId, explorerSchools.id))
  .innerJoin(explorerDomains, eq(explorerPrograms.domainId, explorerDomains.id))
  .where(and(eq(explorerPrograms.slug, id), eq(explorerPrograms.isPublished, true), eq(explorerSchools.isPublished, true), eq(explorerDomains.isPublished, true)))
  .limit(1);

  if (programQuery.length === 0) {
    notFound();
  }

  const { program, school, domain } = programQuery[0];

  // Fetch linked careers (jobs)
  let linkedCareers = await db.select({
    career: explorerCareers
  })
  .from(explorerCareerPrograms)
  .innerJoin(explorerCareers, eq(explorerCareerPrograms.careerId, explorerCareers.id))
  .where(and(eq(explorerCareerPrograms.programId, program.id), eq(explorerCareers.isPublished, true)));

  // Fallback to domain careers if no specific careerProgram link
  if (linkedCareers.length === 0 && program.domainId) {
    const domainCareers = await db.select().from(explorerCareers)
      .where(and(eq(explorerCareers.domainId, program.domainId), eq(explorerCareers.isPublished, true)))
      .limit(3);
    linkedCareers = domainCareers.map(c => ({ career: c }));
  }

  const courses = Array.isArray(program.programCourses) ? program.programCourses : [];

  return (
    <div className="flex flex-col gap-6 -mt-4 md:-mt-8 -mx-4 md:-mx-8">
      
      {/* FULL WIDTH BANNER */}
      <div className="relative w-full h-[35dvh] md:h-[45dvh] bg-black overflow-hidden">
        <img 
          src={program.bannerImage || "https://images.unsplash.com/photo-1541339907198-e08756dedf3f?auto=format&fit=crop&w=1200&q=80"} 
          alt={program.title} 
          className="w-full h-full object-cover opacity-60" 
        />
        
        {/* BREADCRUMB */}
        <div className="absolute top-4 left-4 md:top-8 md:left-8 z-20 flex items-center gap-2 text-xs md:text-sm font-bold text-white bg-black/40 hover:bg-black/60 px-4 py-2 rounded-full backdrop-blur-sm transition-colors">
          <Link href="/student/explorer" className="hover:underline flex items-center gap-1.5">
            <ArrowLeft className="w-4 h-4" /> Explorer
          </Link>
          <ChevronRight className="w-3.5 h-3.5 opacity-60" />
          {domain && (
            <Link href={`/student/explorer/domaine/${domain.slug}`} className="hover:underline opacity-90">
              {domain.title}
            </Link>
          )}
          <ChevronRight className="w-3.5 h-3.5 opacity-60" />
          <span className="text-white truncate max-w-[150px] md:max-w-none">{program.title}</span>
        </div>

        <div className="absolute bottom-0 left-0 w-full p-6 md:p-10 bg-gradient-to-t from-canvas via-canvas/80 to-transparent">
          <div className="flex flex-wrap items-center gap-2 mb-3">
            <span className="text-[10px] md:text-xs uppercase font-bold text-white bg-primary px-3 py-1.5 rounded-full inline-flex items-center gap-1.5 shadow-sm">
              <GraduationCap className="w-3.5 h-3.5" /> {program.level || "Diplôme supérieur"}
            </span>
            {school && (
              <Link 
                href={`/student/explorer/etablissement/${school.slug}`}
                className="text-[10px] md:text-xs font-bold text-white bg-black/50 hover:bg-black/70 backdrop-blur-md px-3 py-1.5 rounded-full inline-flex items-center gap-1.5 transition-colors"
              >
                <Building2 className="w-3.5 h-3.5" /> {school.name}
              </Link>
            )}
          </div>
          <h1 className="font-display font-bold text-3xl md:text-5xl text-white mb-2 drop-shadow-sm">
            {program.title}
          </h1>
        </div>
      </div>

      <div className="max-w-5xl mx-auto w-full px-4 md:px-8 pb-12 flex flex-col lg:flex-row gap-8">
        
        {/* MAIN COLUMN */}
        <div className="flex-1 flex flex-col gap-8">
          
          {/* PRÉSENTATION DE LA FORMATION */}
          <section className="bg-surface p-6 rounded-2xl border border-border-soft">
            <h2 className="text-xl font-bold text-text-primary mb-3">À propos de cette formation</h2>
            <p className="text-text-secondary leading-relaxed">
              {program.description || "Aucune description détaillée n'est disponible pour cette formation."}
            </p>
          </section>

          {/* CRITÈRES CLÉS */}
          <section className="grid grid-cols-2 md:grid-cols-4 gap-3">
            <Card variant="standard" className="p-4 flex flex-col gap-1 bg-surface border-border-soft">
              <GraduationCap className="w-5 h-5 text-primary mb-1" />
              <span className="text-[10px] text-text-tertiary uppercase font-bold">Niveau</span>
              <span className="text-sm font-bold text-text-primary">{program.level || "Bac+3"}</span>
            </Card>
            <Card variant="standard" className="p-4 flex flex-col gap-1 bg-surface border-border-soft">
              <Clock className="w-5 h-5 text-primary mb-1" />
              <span className="text-[10px] text-text-tertiary uppercase font-bold">Durée</span>
              <span className="text-sm font-bold text-text-primary">{program.duration || "3 ans"}</span>
            </Card>
            <Card variant="standard" className="p-4 flex flex-col gap-1 bg-surface border-border-soft">
              <Wallet className="w-5 h-5 text-gold-dark mb-1" />
              <span className="text-[10px] text-text-tertiary uppercase font-bold">Scolarité</span>
              <span className="text-sm font-bold text-text-primary">{school?.type === 'Public' ? 'Tarif public' : 'Tarif privé'}</span>
            </Card>
            <Card variant="standard" className="p-4 flex flex-col gap-1 bg-surface border-border-soft">
              <ShieldCheck className="w-5 h-5 text-success mb-1" />
              <span className="text-[10px] text-text-tertiary uppercase font-bold">Reconnaissance</span>
              <span className="text-sm font-bold text-text-primary">{program.status || "CAMES / État"}</span>
            </Card>
          </section>

          {/* 🏛️ SECTION : ÉTABLISSEMENT QUI DISPENSE CETTE FORMATION */}
          <section>
            <div className="mb-3">
              <span className="text-[10px] uppercase font-bold text-primary tracking-wider block mb-1">
                Université ou Grande École
              </span>
              <h2 className="text-xl font-bold text-text-primary flex items-center gap-2">
                <Building2 className="w-5 h-5 text-primary" />
                Où suivre cette formation au Togo ?
              </h2>
            </div>

            {school ? (
              <Card variant="standard" className="p-5 md:p-6 border border-border-soft hover:border-primary/40 transition-all flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div className="flex items-start gap-4">
                  <div className="w-14 h-14 rounded-xl bg-primary/10 flex items-center justify-center text-primary shrink-0">
                    <Building2 className="w-7 h-7" />
                  </div>
                  <div>
                    <div className="flex flex-wrap items-center gap-2 mb-1">
                      <span className="text-[10px] font-bold text-primary bg-primary/10 px-2 py-0.5 rounded">
                        {school.type || "Établissement supérieur"}
                      </span>
                      {school.insertionRate && (
                        <span className="text-[10px] font-bold text-success bg-success/10 px-2 py-0.5 rounded flex items-center gap-1">
                          <Award className="w-3 h-3" /> {school.insertionRate} insertion
                        </span>
                      )}
                    </div>
                    <h3 className="font-bold text-lg text-text-primary">
                      {school.name}
                    </h3>
                    <p className="text-xs text-text-secondary flex items-center gap-1 mt-1">
                      <MapPin className="w-3.5 h-3.5 text-primary" /> {school.city || "Lomé, Togo"}
                    </p>
                  </div>
                </div>

                <div className="flex items-center gap-2 self-end md:self-center shrink-0">
                  <Link 
                    href={`/student/explorer/etablissement/${school.slug}`}
                    className="px-4 py-2 text-xs font-bold text-white bg-primary hover:bg-primary/90 rounded-lg transition-colors flex items-center gap-1.5 shadow-sm"
                  >
                    Voir l'établissement <ArrowRight className="w-3.5 h-3.5" />
                  </Link>
                </div>
              </Card>
            ) : (
              <div className="p-4 bg-surface-alt rounded-xl text-sm text-text-secondary">
                Établissement partenaire.
              </div>
            )}
          </section>

          {/* 🎯 SECTION : MÉTIERS ACCESSIBLES AVEC CETTE FORMATION */}
          <section>
            <div className="mb-3">
              <span className="text-[10px] uppercase font-bold text-gold-dark tracking-wider block mb-1">
                Débouchés Professionnels
              </span>
              <h2 className="text-xl font-bold text-text-primary flex items-center gap-2">
                <Briefcase className="w-5 h-5 text-primary" />
                Métiers accessibles après ce diplôme ({linkedCareers.length})
              </h2>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              {linkedCareers.length > 0 ? linkedCareers.map(({ career }) => (
                <Link href={`/student/explorer/metier/${career.slug}`} key={career.id} className="group block">
                  <Card variant="interactive" className="p-4 flex items-center justify-between border border-border-soft hover:border-primary/40">
                    <div className="flex items-center gap-3">
                      <div className="w-9 h-9 rounded-lg bg-gold/10 flex items-center justify-center text-gold-dark shrink-0">
                        <Briefcase className="w-4 h-4" />
                      </div>
                      <div>
                        <h4 className="font-bold text-sm text-text-primary group-hover:text-primary transition-colors">
                          {career.title}
                        </h4>
                        <span className="text-[11px] text-text-tertiary">
                          Découvrir les missions
                        </span>
                      </div>
                    </div>
                    <ArrowRight className="w-4 h-4 text-text-tertiary group-hover:text-primary group-hover:translate-x-1 transition-all" />
                  </Card>
                </Link>
              )) : (
                <div className="p-4 bg-surface-alt rounded-xl text-xs text-text-secondary col-span-full">
                  Débouchés variés dans le secteur {domain?.title || ""}.
                </div>
              )}
            </div>
          </section>

          {/* CONDITIONS D'ADMISSION */}
          <section className="bg-surface p-6 rounded-2xl border border-border-soft">
            <h2 className="text-xl font-bold text-text-primary mb-3">Conditions d'admission & Prérequis</h2>
            <p className="text-sm text-text-secondary leading-relaxed">
              {program.admission || "Baccalauréat requis (séries scientifiques ou économiques selon la filière), sélection sur dossier et/ou test."}
            </p>
          </section>

          {/* PROGRAMME TYPE */}
          {courses.length > 0 && (
            <section className="bg-surface p-6 rounded-2xl border border-border-soft">
              <h2 className="text-xl font-bold text-text-primary mb-3">Enseignements majeurs</h2>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-2.5">
                {courses.map((course: string, i: number) => (
                  <div key={i} className="flex items-start gap-2.5 p-2.5 bg-surface-alt border border-border-soft rounded-lg">
                    <CheckCircle2 className="w-4 h-4 text-primary shrink-0 mt-0.5" />
                    <span className="text-xs md:text-sm text-text-secondary">{course}</span>
                  </div>
                ))}
              </div>
            </section>
          )}

        </div>

        {/* RIGHT COLUMN (AÏDA) */}
        <div className="w-full lg:w-80 flex flex-col gap-6">
          <AidaAssistant 
            title="Conseil sur la formation"
            message={`Cette formation "${program.title}" à ${school?.name || "Lomé"} est l'une des voies royales pour accéder aux métiers de ce domaine.`}
            variant="floating"
            actionLabel="Poser une question à AÏDA"
            actionPrompt={`Bonjour AÏDA ! Peux-tu me donner ton avis sur la formation "${program.title}" (${program.level || ""}) à ${school?.name || "cet établissement"} : est-elle reconnue et quelles sont les chances réelles d'insertion professionnelle au Togo ?`}
          />
        </div>

      </div>
    </div>
  );
}
