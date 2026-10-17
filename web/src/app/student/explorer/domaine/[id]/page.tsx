import React from "react";
import { ArrowLeft, Briefcase, GraduationCap, TrendingUp, Lightbulb, Target } from "lucide-react";
import Link from "next/link";
import { Card } from "@/components/ui/Card";
import { AidaAssistant } from "@/components/student/AidaAssistant";
import { db } from "@/db";
import { explorerDomains, explorerCareers, explorerPrograms } from "@/db/schema";
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

  const metiers = await db.select().from(explorerCareers).where(and(eq(explorerCareers.domainId, domaine.id), eq(explorerCareers.isPublished, true)));
  const formations = await db.select().from(explorerPrograms).where(and(eq(explorerPrograms.domainId, domaine.id), eq(explorerPrograms.isPublished, true)));

  return (
    <div className="flex flex-col gap-6 -mt-4 md:-mt-8 -mx-4 md:-mx-8">
      
      {/* FULL WIDTH BANNER */}
      <div className="relative w-full h-[35dvh] md:h-[45dvh] bg-black overflow-hidden">
        <img 
          src={domaine.bannerImage || "https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=1200&q=80"} 
          alt={domaine.title} 
          className="w-full h-full object-cover opacity-50" 
        />
        
        <div className="absolute top-4 left-4 md:top-8 md:left-8 z-20">
          <Link href="/student/explorer" className="inline-flex items-center gap-2 text-sm font-bold text-white bg-black/40 hover:bg-black/60 px-4 py-2 rounded-full backdrop-blur-sm transition-colors">
            <ArrowLeft className="w-4 h-4" /> Retour à l'exploration
          </Link>
        </div>

        <div className="absolute bottom-0 left-0 w-full p-6 md:p-10 bg-gradient-to-t from-canvas via-canvas/80 to-transparent">
          <span className="text-[10px] md:text-xs uppercase font-bold text-white border border-white/30 backdrop-blur-md px-3 py-1.5 rounded-full mb-3 inline-block">
            Secteur d'activité
          </span>
          <h1 className="font-display font-bold text-3xl md:text-6xl text-white mb-2 drop-shadow-lg">
            {domaine.title}
          </h1>
        </div>
      </div>

      <div className="max-w-5xl mx-auto w-full px-4 md:px-8 pb-12 flex flex-col lg:flex-row gap-8">
        
        {/* MAIN COLUMN */}
        <div className="flex-1 flex flex-col gap-8">
          
          <section>
            <h2 className="text-2xl font-bold text-text-primary mb-4 flex items-center gap-2">
              <Lightbulb className="w-6 h-6 text-primary" />
              Vue d'ensemble
            </h2>
            <p className="text-text-secondary leading-relaxed text-lg">
              {domaine.description || "La description de ce domaine n'est pas encore disponible."}
            </p>
          </section>

          {/* STATS GRID */}
          <section className="grid grid-cols-3 gap-4">
            <Card variant="standard" className="p-4 flex flex-col items-center justify-center text-center gap-1 bg-surface-alt border-primary/20">
              <TrendingUp className="w-5 h-5 text-primary mb-1" />
              <span className="text-[10px] uppercase font-bold text-text-secondary">Croissance (Togo)</span>
              <span className="text-sm font-bold text-text-primary">{domaine.growth || "N/A"}</span>
            </Card>
            <Card variant="standard" className="p-4 flex flex-col items-center justify-center text-center gap-1 bg-surface-alt border-primary/20">
              <Target className="w-5 h-5 text-primary mb-1" />
              <span className="text-[10px] uppercase font-bold text-text-secondary">Employabilité</span>
              <span className="text-sm font-bold text-text-primary">{domaine.employability || "N/A"}</span>
            </Card>
            <Card variant="standard" className="p-4 flex flex-col items-center justify-center text-center gap-1 bg-surface-alt border-primary/20">
              <Briefcase className="w-5 h-5 text-primary mb-1" />
              <span className="text-[10px] uppercase font-bold text-text-secondary">Rémunération</span>
              <span className="text-sm font-bold text-text-primary">{domaine.salary || "N/A"}</span>
            </Card>
          </section>

          {domaine.why && (
            <section className="p-6 bg-primary/5 rounded-2xl border border-primary/10">
              <h3 className="font-bold text-primary mb-2">Pourquoi ce secteur est stratégique ?</h3>
              <p className="text-text-secondary text-sm leading-relaxed">
                {domaine.why}
              </p>
            </section>
          )}

          <section>
            <h2 className="text-xl font-bold text-text-primary mb-4 flex items-center gap-2">
              <Briefcase className="w-6 h-6 text-primary" />
              Métiers phares de ce domaine
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {metiers.length > 0 ? metiers.map((metier) => (
                <Link href={`/student/explorer/metier/${metier.slug}`} key={metier.id}>
                  <Card variant="standard" className="p-4 hover:border-primary/30 cursor-pointer group flex items-center justify-between">
                    <span className="font-bold text-sm text-text-primary group-hover:text-primary transition-colors">{metier.title}</span>
                    <ArrowLeft className="w-4 h-4 text-text-tertiary group-hover:text-primary rotate-180 transition-colors" />
                  </Card>
                </Link>
              )) : (
                <div className="col-span-full p-4 bg-surface-alt rounded-lg text-text-secondary text-sm">
                  Aucun métier spécifique n'a encore été ajouté pour ce domaine.
                </div>
              )}
            </div>
          </section>

          <section>
            <h2 className="text-xl font-bold text-text-primary mb-4 flex items-center gap-2">
              <GraduationCap className="w-6 h-6 text-primary" />
              Formations pour y accéder
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {formations.length > 0 ? formations.map((form) => (
                <Link href={`/student/explorer/formation/${form.slug}`} key={form.id}>
                  <Card variant="standard" className="p-4 hover:border-primary/30 cursor-pointer group flex flex-col h-full">
                    <h3 className="font-bold text-sm text-text-primary group-hover:text-primary transition-colors">{form.title}</h3>
                    <div className="mt-auto pt-4 flex justify-between items-center text-xs">
                      <span className="text-text-secondary bg-surface-alt px-2 py-1 rounded-sm">{form.level || "Non précisé"}</span>
                      <span className="text-primary font-bold group-hover:underline">Voir détails</span>
                    </div>
                  </Card>
                </Link>
              )) : (
                <div className="col-span-full p-4 bg-surface-alt rounded-lg text-text-secondary text-sm">
                  Aucune formation n'a été rattachée à ce domaine pour le moment.
                </div>
              )}
            </div>
          </section>

        </div>

        {/* RIGHT COLUMN (AÏDA) */}
        <div className="w-full lg:w-80 flex flex-col gap-6">
          <AidaAssistant 
            title="Orientation Stratégique"
            message={`L'exploration par "Domaine" est la meilleure façon de découvrir des métiers auxquels vous n'auriez jamais pensé. Si ce secteur vous intéresse globalement, demandez conseil à AÏDA pour affiner vos choix !`}
            variant="floating"
            actionLabel="Demander conseil à AÏDA"
            actionPrompt={`Bonjour AÏDA, le domaine "${domaine.title}" m'intéresse beaucoup. Quels sont les métiers d'avenir et les meilleures formations à Lomé pour ce secteur ?`}
          />
        </div>

      </div>
    </div>
  );
}
