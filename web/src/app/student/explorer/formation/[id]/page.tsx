import React from "react";
import { ArrowLeft, ArrowRight, Building2, MapPin, GraduationCap, CheckCircle2, Clock, Wallet, ShieldCheck, Briefcase } from "lucide-react";
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
  const linkedCareers = await db.select({
    career: explorerCareers
  })
  .from(explorerCareerPrograms)
  .innerJoin(explorerCareers, eq(explorerCareerPrograms.careerId, explorerCareers.id))
  .where(and(eq(explorerCareerPrograms.programId, program.id), eq(explorerCareers.isPublished, true)));

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
        
        <div className="absolute top-4 left-4 md:top-8 md:left-8 z-20">
          <Link href="/student/explorer" className="inline-flex items-center gap-2 text-sm font-bold text-white bg-black/40 hover:bg-black/60 px-4 py-2 rounded-full backdrop-blur-sm transition-colors">
            <ArrowLeft className="w-4 h-4" /> Retour à l'exploration
          </Link>
        </div>

        <div className="absolute bottom-0 left-0 w-full p-6 md:p-10 bg-gradient-to-t from-canvas via-canvas/80 to-transparent">
          <span className="text-[10px] md:text-xs uppercase font-bold text-primary bg-primary/10 backdrop-blur-md px-3 py-1.5 rounded-sm mb-3 inline-block">
            {domain?.title || "Domaine"}
          </span>
          <h1 className="font-display font-bold text-3xl md:text-5xl text-text-primary mb-2">
            {program.title}
          </h1>
        </div>
      </div>

      <div className="max-w-5xl mx-auto w-full px-4 md:px-8 pb-12 flex flex-col lg:flex-row gap-8">
        
        {/* MAIN COLUMN */}
        <div className="flex-1 flex flex-col gap-8">
          
          <section>
            <h2 className="text-xl font-bold text-text-primary mb-4">À propos de cette formation</h2>
            <p className="text-text-secondary leading-relaxed">
              {program.description || "Aucune description détaillée n'est disponible pour cette formation."}
            </p>
          </section>

          <section className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <Card variant="standard" className="p-4 flex flex-col gap-1 bg-surface border-border-soft">
              <GraduationCap className="w-5 h-5 text-primary mb-2" />
              <span className="text-xs text-text-tertiary uppercase font-bold">Niveau</span>
              <span className="text-sm font-bold text-text-primary">{program.level || "Non précisé"}</span>
            </Card>
            <Card variant="standard" className="p-4 flex flex-col gap-1 bg-surface border-border-soft">
              <Clock className="w-5 h-5 text-primary mb-2" />
              <span className="text-xs text-text-tertiary uppercase font-bold">Durée</span>
              <span className="text-sm font-bold text-text-primary">{program.duration || "Non précisée"}</span>
            </Card>
            <Card variant="standard" className="p-4 flex flex-col gap-1 bg-surface border-border-soft">
              <Wallet className="w-5 h-5 text-primary mb-2" />
              <span className="text-xs text-text-tertiary uppercase font-bold">Scolarité</span>
              <span className="text-sm font-bold text-text-primary">Variable</span>
            </Card>
            <Card variant="standard" className="p-4 flex flex-col gap-1 bg-surface border-border-soft">
              <ShieldCheck className="w-5 h-5 text-primary mb-2" />
              <span className="text-xs text-text-tertiary uppercase font-bold">Statut</span>
              <span className="text-sm font-bold text-text-primary">{program.status || "Non précisé"}</span>
            </Card>
          </section>

          <section>
            <h2 className="text-xl font-bold text-text-primary mb-4">Conditions d'admission</h2>
            <Card variant="standard" className="p-6 bg-surface-alt border-none">
              <p className="text-sm text-text-secondary">
                {program.admission || "Les conditions d'admission ne sont pas renseignées."}
              </p>
            </Card>
          </section>

          {courses.length > 0 && (
            <section>
              <h2 className="text-xl font-bold text-text-primary mb-4">Programme type</h2>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                {courses.map((course: string, i: number) => (
                  <div key={i} className="flex items-start gap-3 p-3 bg-surface border border-border-soft rounded-lg">
                    <CheckCircle2 className="w-5 h-5 text-primary shrink-0" />
                    <span className="text-sm text-text-secondary">{course}</span>
                  </div>
                ))}
              </div>
            </section>
          )}

          <section>
            <h2 className="text-xl font-bold text-text-primary mb-4">Métiers accessibles</h2>
            <div className="flex flex-wrap gap-2">
              {linkedCareers.length > 0 ? linkedCareers.map((item, i) => (
                <Link href={`/student/explorer/metier/${item.career.slug}`} key={i}>
                  <span className="px-3 py-1.5 bg-gold/10 border border-gold/20 hover:bg-gold/20 transition-colors cursor-pointer rounded-md text-sm font-bold text-gold-dark">
                    {item.career.title}
                  </span>
                </Link>
              )) : (
                <span className="text-sm text-text-secondary">Aucun métier renseigné.</span>
              )}
            </div>
          </section>

          <section>
            <h2 className="text-xl font-bold text-text-primary mb-4">Où suivre cette formation ?</h2>
            <div className="flex flex-col gap-3">
              {school ? (
                <Link href={`/student/explorer/etablissement/${school.slug}`}>
                  <Card variant="standard" className="p-4 flex items-center justify-between hover:border-primary/30 transition-colors group cursor-pointer">
                    <div className="flex items-center gap-4">
                      <div className="w-10 h-10 bg-primary/10 rounded-lg flex items-center justify-center text-primary">
                        <Building2 className="w-5 h-5" />
                      </div>
                      <div>
                        <h3 className="font-bold text-sm text-text-primary group-hover:text-primary transition-colors">{school.name}</h3>
                        <p className="text-xs text-text-secondary flex items-center gap-1 mt-1">
                          <MapPin className="w-3 h-3" /> {school.city || "Localisation non précisée"}
                        </p>
                      </div>
                    </div>
                    <ArrowRight className="w-5 h-5 text-text-tertiary group-hover:text-primary transition-colors" />
                  </Card>
                </Link>
              ) : (
                <span className="text-sm text-text-secondary">Établissement inconnu.</span>
              )}
            </div>
          </section>

        </div>

        {/* RIGHT COLUMN (AÏDA) */}
        <div className="w-full lg:w-80 flex flex-col gap-6">
          <AidaAssistant 
            title="Avis sur la formation"
            message={`Cette formation de type ${program.level || "Diplôme supérieur"} offre des débouchés très recherchés en Afrique de l'Ouest. Voulez-vous connaître les critères exacts d'admission pour la rentrée prochaine ?`}
            variant="floating"
            actionLabel="Poser une question"
            actionPrompt={`Bonjour AÏDA ! Peux-tu me donner des détails sur la formation "${program.title}" (${program.level || ""}) à ${school?.name || "cet établissement"} : conditions d'admission, durée et opportunités réelles au Togo et dans la sous-région ?`}
          />
        </div>

      </div>
    </div>
  );
}
