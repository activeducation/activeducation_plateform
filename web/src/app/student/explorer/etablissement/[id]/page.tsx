import React from "react";
import { ArrowLeft, MapPin, Building2, BookOpen, GraduationCap, Star, CheckCircle2, Award } from "lucide-react";
import Link from "next/link";
import { Card } from "@/components/ui/Card";
import { db } from "@/db";
import { explorerSchools, explorerPrograms } from "@/db/schema";
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

  const formations = await db.select().from(explorerPrograms).where(and(eq(explorerPrograms.schoolId, school.id), eq(explorerPrograms.isPublished, true)));

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
        
        <div className="absolute top-4 left-4 md:top-8 md:left-8 z-20">
          <Link href="/student/explorer" className="inline-flex items-center gap-2 text-sm font-bold text-white bg-black/40 hover:bg-black/60 px-4 py-2 rounded-full backdrop-blur-sm transition-colors">
            <ArrowLeft className="w-4 h-4" /> Retour à l'exploration
          </Link>
        </div>

        <div className="absolute bottom-0 left-0 w-full p-6 md:p-10 bg-gradient-to-t from-canvas via-canvas/80 to-transparent flex flex-col md:flex-row md:items-end justify-between gap-4">
          <div>
            <div className="flex flex-wrap items-center gap-3 mb-3">
              <span className="text-[10px] md:text-xs uppercase font-bold text-primary bg-primary/10 backdrop-blur-md px-3 py-1.5 rounded-sm">
                {school.type || "Établissement"}
              </span>
              <span className="text-[10px] md:text-xs uppercase font-bold text-white border border-white/20 backdrop-blur-md px-3 py-1.5 rounded-sm flex items-center gap-1">
                <MapPin className="w-3 h-3" /> {school.city || "Lieu inconnu"}
              </span>
            </div>
            <h1 className="font-display font-bold text-3xl md:text-5xl text-white mb-2">
              {school.name}
            </h1>
          </div>
          
          <div className="flex gap-4">
            <div className="bg-surface/10 backdrop-blur-md border border-white/10 rounded-xl p-3 flex flex-col items-center min-w-[100px]">
              <span className="text-gold flex items-center gap-1 font-bold text-xl"><Star className="w-5 h-5 fill-gold" /> {school.rating || "N/A"}</span>
              <span className="text-xs text-white/70">{school.reviewsCount || 0} avis</span>
            </div>
            <div className="bg-surface/10 backdrop-blur-md border border-white/10 rounded-xl p-3 flex flex-col items-center min-w-[100px]">
              <span className="text-success flex items-center gap-1 font-bold text-xl"><Award className="w-5 h-5" /> {school.insertionRate || "N/A"}</span>
              <span className="text-xs text-white/70">Insertion pro</span>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-5xl mx-auto w-full px-4 md:px-8 pb-12 flex flex-col lg:flex-row gap-8">
        
        {/* MAIN COLUMN */}
        <div className="flex-1 flex flex-col gap-8">
          
          <section>
            <h2 className="text-xl font-bold text-text-primary mb-4 flex items-center gap-2">
              <Building2 className="w-6 h-6 text-primary" />
              Présentation de l'établissement
            </h2>
            <p className="text-text-secondary leading-relaxed">
              {school.description || "Aucune description détaillée n'est disponible pour cet établissement."}
            </p>
          </section>

          {facilities.length > 0 && (
            <section>
              <h2 className="text-xl font-bold text-text-primary mb-4 flex items-center gap-2">
                <BookOpen className="w-6 h-6 text-primary" />
                Infrastructures & Services
              </h2>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                {facilities.map((fac: string, i: number) => (
                  <div key={i} className="flex items-start gap-3 p-3 bg-surface border border-border-soft rounded-lg">
                    <CheckCircle2 className="w-5 h-5 text-primary shrink-0" />
                    <span className="text-sm text-text-secondary">{fac}</span>
                  </div>
                ))}
              </div>
            </section>
          )}

          <section>
            <h2 className="text-xl font-bold text-text-primary mb-4 flex items-center gap-2">
              <GraduationCap className="w-6 h-6 text-primary" />
              Formations proposées ({formations.length})
            </h2>
            <div className="grid grid-cols-1 gap-4">
              {formations.length > 0 ? formations.map((form) => (
                <Link href={`/student/explorer/formation/${form.slug}`} key={form.id}>
                  <Card variant="standard" className="p-4 hover:border-primary/30 cursor-pointer group flex items-center justify-between">
                    <div>
                      <h3 className="font-bold text-text-primary group-hover:text-primary transition-colors">{form.title}</h3>
                      <p className="text-sm text-text-secondary mt-1">{form.level || "Niveau non précisé"}</p>
                    </div>
                    <span className="text-xs font-bold text-primary bg-primary/10 px-3 py-1.5 rounded-md opacity-0 group-hover:opacity-100 transition-opacity">
                      Détails
                    </span>
                  </Card>
                </Link>
              )) : (
                <div className="p-4 bg-surface-alt rounded-lg text-text-secondary text-sm">
                  Aucune formation n'a été rattachée à cet établissement pour le moment.
                </div>
              )}
            </div>
          </section>

        </div>
      </div>
    </div>
  );
}
