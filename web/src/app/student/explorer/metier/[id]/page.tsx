import React from "react";
import { 
  ArrowLeft, 
  ArrowRight, 
  CheckCircle2, 
  Building2, 
  MapPin, 
  GraduationCap, 
  TrendingUp, 
  Banknote, 
  Award, 
  Briefcase,
  ChevronRight,
  Sparkles,
  BookOpen
} from "lucide-react";
import Link from "next/link";
import { AidaAssistant } from "@/components/student/AidaAssistant";
import { Card } from "@/components/ui/Card";
import { db } from "@/db";
import { explorerCareers, explorerDomains, explorerCareerPrograms, explorerPrograms, explorerSchools } from "@/db/schema";
import { and, eq } from "drizzle-orm";
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
  .where(and(eq(explorerCareers.slug, id), eq(explorerCareers.isPublished, true), eq(explorerDomains.isPublished, true)))
  .limit(1);

  if (metierQuery.length === 0) {
    notFound();
  }

  const metier = metierQuery[0].career;
  const domain = metierQuery[0].domain;

  // 2. Fetch Formations via intersection table with domain fallback
  let formationsData = await db.select({
    program: explorerPrograms,
    school: explorerSchools
  })
  .from(explorerCareerPrograms)
  .innerJoin(explorerPrograms, eq(explorerCareerPrograms.programId, explorerPrograms.id))
  .leftJoin(explorerSchools, eq(explorerPrograms.schoolId, explorerSchools.id))
  .where(and(eq(explorerCareerPrograms.careerId, metier.id), eq(explorerPrograms.isPublished, true), eq(explorerSchools.isPublished, true)));

  if (formationsData.length === 0 && metier.domainId) {
    formationsData = await db.select({
      program: explorerPrograms,
      school: explorerSchools
    })
    .from(explorerPrograms)
    .leftJoin(explorerSchools, eq(explorerPrograms.schoolId, explorerSchools.id))
    .where(and(eq(explorerPrograms.domainId, metier.domainId), eq(explorerPrograms.isPublished, true), eq(explorerSchools.isPublished, true)))
    .limit(3);
  }

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
        
        {/* BREADCRUMB */}
        <div className="absolute top-4 left-4 md:top-8 md:left-8 z-20 flex items-center gap-2 text-xs md:text-sm font-bold text-white bg-black/40 hover:bg-black/60 px-4 py-2 rounded-full backdrop-blur-sm transition-colors">
          <Link href="/student/explorer" className="hover:underline flex items-center gap-1.5">
            <ArrowLeft className="w-4 h-4" /> Explorer
          </Link>
          <ChevronRight className="w-3.5 h-3.5 opacity-60" />
          {domain ? (
            <Link href={`/student/explorer/domaine/${domain.slug}`} className="hover:underline opacity-90">
              {domain.title}
            </Link>
          ) : (
            <span className="opacity-90">Métiers</span>
          )}
          <ChevronRight className="w-3.5 h-3.5 opacity-60" />
          <span className="text-white truncate max-w-[150px] md:max-w-none">{metier.title}</span>
        </div>

        <div className="absolute bottom-0 left-0 w-full p-6 md:p-10 bg-gradient-to-t from-canvas via-canvas/80 to-transparent flex flex-col md:flex-row md:items-end justify-between gap-4">
          <div>
            {domain && (
              <Link 
                href={`/student/explorer/domaine/${domain.slug}`} 
                className="text-[10px] md:text-xs uppercase font-bold text-white bg-primary px-3 py-1.5 rounded-full mb-3 inline-flex items-center gap-1.5 shadow-sm hover:bg-primary/90 transition-colors"
              >
                <Briefcase className="w-3.5 h-3.5" /> Secteur : {domain.title}
              </Link>
            )}
            <h1 className="font-display font-bold text-3xl md:text-5xl text-white mb-2 drop-shadow-sm">
              {metier.title}
            </h1>
          </div>

          <div className="flex flex-wrap gap-3">
            {domain?.salary && (
              <div className="bg-surface/20 backdrop-blur-md border border-white/10 rounded-xl p-3 flex flex-col items-center min-w-[120px]">
                <span className="text-white text-xs text-white/80 flex items-center gap-1 font-medium">
                  <Banknote className="w-3.5 h-3.5 text-gold" /> Rémunération estimée
                </span>
                <span className="text-sm font-bold text-gold mt-0.5">{domain.salary}</span>
              </div>
            )}
            {domain?.employability && (
              <div className="bg-surface/20 backdrop-blur-md border border-white/10 rounded-xl p-3 flex flex-col items-center min-w-[100px]">
                <span className="text-white text-xs text-white/80 flex items-center gap-1 font-medium">
                  <TrendingUp className="w-3.5 h-3.5 text-success" /> Employabilité
                </span>
                <span className="text-sm font-bold text-success mt-0.5">{domain.employability}</span>
              </div>
            )}
          </div>
        </div>
      </div>

      <div className="max-w-5xl mx-auto w-full px-4 md:px-8 pb-12 flex flex-col lg:flex-row gap-8">
        
        {/* MAIN COLUMN */}
        <div className="flex-1 flex flex-col gap-8">
          
          {/* MISSIONS & DESCRIPTION */}
          <section className="bg-surface p-6 rounded-2xl border border-border-soft">
            <h2 className="text-xl font-bold text-text-primary mb-3 flex items-center gap-2">
              <Briefcase className="w-5 h-5 text-primary" /> Missions & Rôle au quotidien
            </h2>
            <p className="text-text-secondary leading-relaxed text-base">
              {metier.description || "Aucune description détaillée n'est disponible pour ce métier."}
            </p>
          </section>

          {/* COMPÉTENCES REQUISES */}
          {skills.length > 0 && (
            <section className="bg-surface p-6 rounded-2xl border border-border-soft">
              <h2 className="text-xl font-bold text-text-primary mb-3 flex items-center gap-2">
                <CheckCircle2 className="w-5 h-5 text-primary" /> Compétences requises & Technologies
              </h2>
              <div className="flex flex-wrap gap-2">
                {skills.map((skill: string, i: number) => (
                  <span key={i} className="px-3 py-1.5 bg-surface-alt border border-border-soft rounded-lg text-xs md:text-sm font-medium text-text-primary flex items-center gap-2">
                    <CheckCircle2 className="w-3.5 h-3.5 text-primary shrink-0" /> {skill}
                  </span>
                ))}
              </div>
            </section>
          )}

          {/* DÉBOUCHÉS & PERSPECTIVES */}
          {opportunities.length > 0 && (
            <section className="bg-surface p-6 rounded-2xl border border-border-soft">
              <h2 className="text-xl font-bold text-text-primary mb-3 flex items-center gap-2">
                <Award className="w-5 h-5 text-gold-dark" /> Évolutions de carrière & Postes cibles
              </h2>
              <div className="flex flex-wrap gap-2">
                {opportunities.map((opp: string, i: number) => (
                  <span key={i} className="px-3.5 py-2 bg-gold/10 border border-gold/20 rounded-lg text-xs md:text-sm font-bold text-gold-dark">
                    {opp}
                  </span>
                ))}
              </div>
            </section>
          )}

          {/* 🎯 SECTION MAJEURE : FORMATIONS POUR ACCÉDER À CE MÉTIER & ÉTABLISSEMENTS QUI LES DISPENSENT */}
          <section>
            <div className="mb-4">
              <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-primary/10 text-primary text-xs font-bold uppercase tracking-wider mb-2">
                <GraduationCap className="w-3.5 h-3.5" />
                Cursus & Établissements
              </div>
              <h2 className="text-2xl font-bold text-text-primary">
                Formations recommandées pour exercer ce métier
              </h2>
              <p className="text-sm text-text-secondary mt-1">
                Voici les diplômes universitaires reconnus et les universités qui les dispensent au Togo :
              </p>
            </div>

            <div className="flex flex-col gap-4">
              {formationsData.length > 0 ? formationsData.map(({ program, school }, i) => (
                <Card 
                  key={i} 
                  variant="standard" 
                  className="p-5 md:p-6 border border-border-soft hover:border-primary/40 transition-all flex flex-col gap-4"
                >
                  <div className="flex flex-col md:flex-row md:items-start justify-between gap-3">
                    <div className="flex-1">
                      <div className="flex flex-wrap items-center gap-2 mb-2">
                        <span className="text-[10px] uppercase font-bold text-primary bg-primary/10 px-2.5 py-0.5 rounded">
                          {program.level || "Diplôme supérieur"}
                        </span>
                        {program.duration && (
                          <span className="text-[10px] font-bold text-text-secondary bg-surface-alt px-2.5 py-0.5 rounded">
                            {program.duration}
                          </span>
                        )}
                        {program.status && (
                          <span className="text-[10px] font-bold text-success bg-success/10 px-2.5 py-0.5 rounded">
                            {program.status}
                          </span>
                        )}
                      </div>
                      
                      <Link href={`/student/explorer/formation/${program.slug}`} className="group">
                        <h3 className="text-lg font-bold text-text-primary group-hover:text-primary transition-colors">
                          {program.title}
                        </h3>
                      </Link>
                      
                      {program.description && (
                        <p className="text-xs md:text-sm text-text-secondary line-clamp-2 mt-2">
                          {program.description}
                        </p>
                      )}
                    </div>
                  </div>

                  {/* 🏛️ BLOC ÉTABLISSEMENT QUI DISPENSE CETTE FORMATION */}
                  {school ? (
                    <div className="p-4 rounded-xl bg-surface-alt border border-border-soft flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-lg bg-primary/10 flex items-center justify-center text-primary shrink-0">
                          <Building2 className="w-5 h-5" />
                        </div>
                        <div>
                          <p className="text-[10px] uppercase font-bold text-text-tertiary">
                            Dispensé par
                          </p>
                          <Link href={`/student/explorer/etablissement/${school.slug}`} className="font-bold text-sm text-text-primary hover:text-primary transition-colors">
                            {school.name}
                          </Link>
                          <p className="text-xs text-text-secondary flex items-center gap-1 mt-0.5">
                            <MapPin className="w-3 h-3 text-primary" /> {school.city || "Lomé, Togo"} • {school.type || "Établissement"}
                          </p>
                        </div>
                      </div>

                      <div className="flex items-center gap-2 shrink-0">
                        <Link 
                          href={`/student/explorer/etablissement/${school.slug}`}
                          className="px-3 py-1.5 text-xs font-bold text-text-secondary hover:text-text-primary bg-surface border border-border-soft rounded-lg transition-colors"
                        >
                          Voir l'école
                        </Link>
                        <Link 
                          href={`/student/explorer/formation/${program.slug}`}
                          className="px-3.5 py-1.5 text-xs font-bold text-white bg-primary hover:bg-primary/90 rounded-lg transition-colors flex items-center gap-1.5 shadow-sm"
                        >
                          Détails formation <ArrowRight className="w-3.5 h-3.5" />
                        </Link>
                      </div>
                    </div>
                  ) : (
                    <div className="text-xs text-text-secondary">
                      Établissement partenaire au Togo.
                    </div>
                  )}
                </Card>
              )) : (
                <div className="p-6 bg-surface-alt rounded-2xl text-center text-sm text-text-secondary">
                  Aucune formation spécifique n'a encore été rattachée à ce métier.
                </div>
              )}
            </div>
          </section>

        </div>

        {/* RIGHT COLUMN (AÏDA) */}
        <div className="w-full lg:w-80 flex flex-col gap-6">
          <AidaAssistant 
            title="Poser une question à AÏDA"
            message={`Vous envisagez de devenir ${metier.title} ? AÏDA peut vous aider à comparer les formations et vous conseiller sur les prérequis d'admission.`}
            variant="floating"
            actionLabel="Conseil d'orientation"
            actionPrompt={`Bonjour AÏDA ! J'aimerais devenir "${metier.title}". Peux-tu m'expliquer quelles sont les meilleures écoles au Togo pour y arriver, et comment bien préparer mon admission ?`}
          />

          <Card variant="standard" className="p-5 flex flex-col gap-3">
            <h3 className="font-bold text-sm text-text-primary flex items-center gap-2">
              <BookOpen className="w-4 h-4 text-primary" />
              Parcours type résumé
            </h3>
            <ol className="text-xs text-text-secondary space-y-2 list-decimal list-inside leading-relaxed">
              <li>Obtention du Baccalauréat requis (C, D ou E recommandé)</li>
              <li>Inscription dans une formation accréditée (Licence ou Ingénieur)</li>
              <li>Stages pratiques & certifications professionnelles</li>
              <li>Insertion sur le marché de l'emploi togolais ou régional</li>
            </ol>
          </Card>
        </div>

      </div>
    </div>
  );
}
