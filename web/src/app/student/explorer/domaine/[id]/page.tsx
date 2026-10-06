"use client";

import React from "react";
import { ArrowLeft, Briefcase, GraduationCap, TrendingUp, Lightbulb, Target } from "lucide-react";
import Link from "next/link";
import { Card } from "@/components/ui/Card";
import { AidaAssistant } from "@/components/student/AidaAssistant";

export default function DomainePage({ params }: { params: Promise<{ id: string }> }) {
  const unwrappedParams = React.use(params);
  
  // Mock data mapping for Domains
  const domainesDb: Record<string, any> = {
    "tech-numerique": {
      title: "Tech & Numérique",
      bannerImage: "https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=1200&q=80",
      description: "Le secteur du numérique est le moteur de la transformation au Togo et en Afrique. De la création d'applications à la protection des données, en passant par l'intelligence artificielle, c're secteur offre des opportunités de carrière exceptionnelles, d'innovation et d'entrepreneuriat.",
      stats: {
        growth: "+15% / an",
        employability: "Très forte",
        salary: "Élevé"
      },
      why: "Le gouvernement togolais a pour ambition de faire du pays un hub technologique sous-régional. Le déploiement de la fibre optique et la digitalisation des services publics créent un besoin massif en talents qualifiés.",
      metiers: [
        { id: "cybersecurite", title: "Ingénieur Cybersécurité" },
        { id: "data-analyst", title: "Data Analyst" },
        { id: "dev-mobile", title: "Développeur Mobile" }
      ],
      formations: [
        { id: "ul-cyber", title: "Licence Pro Sécurité Informatique", level: "Bac+3" },
        { id: "iai-genie", title: "Génie Logiciel", level: "Bac+3 / Bac+5" }
      ]
    },
    "agro-industrie": {
      title: "Agro-industrie",
      bannerImage: "https://images.unsplash.com/photo-1625246333195-78d9c38ad449?auto=format&fit=crop&w=1200&q=80",
      description: "L'agriculture est le pilier de l'économie africaine. L'agro-industrie moderne va au-delà du champ : elle intègre la transformation, la qualité, la logistique et l'innovation technologique pour nourrir le continent.",
      stats: {
        growth: "+8% / an",
        employability: "Forte",
        salary: "Moyen à Élevé"
      },
      why: "Avec d'immenses terres arables et une population croissante, le Togo investit massivement (agropoles) pour transformer localement ses produits (soja, coton, ananas). Les techniciens et ingénieurs agronomes sont vitaux.",
      metiers: [
        { id: "agronome", title: "Ingénieur Agronome" },
        { id: "qualiticien", title: "Responsable Qualité" }
      ],
      formations: [
        { id: "infa-agro", title: "BTS Agriculture", level: "Bac+2" },
        { id: "ul-agro", title: "Master Sciences Agronomiques", level: "Bac+5" }
      ]
    }
  };

  const domaine = domainesDb[unwrappedParams.id] || {
    title: "Domaine Inconnu",
    bannerImage: "https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=1200&q=80",
    description: "La description de ce domaine d'activité n'est pas encore disponible.",
    stats: { growth: "N/A", employability: "N/A", salary: "N/A" },
    why: "Information non disponible.",
    metiers: [],
    formations: []
  };

  return (
    <div className="flex flex-col gap-6 -mt-4 md:-mt-8 -mx-4 md:-mx-8">
      
      {/* FULL WIDTH BANNER */}
      <div className="relative w-full h-[35dvh] md:h-[45dvh] bg-black overflow-hidden">
        <img 
          src={domaine.bannerImage} 
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
              {domaine.description}
            </p>
          </section>

          {/* STATS GRID */}
          <section className="grid grid-cols-3 gap-4">
            <Card variant="standard" className="p-4 flex flex-col items-center justify-center text-center gap-1 bg-surface-alt border-primary/20">
              <TrendingUp className="w-5 h-5 text-primary mb-1" />
              <span className="text-[10px] uppercase font-bold text-text-secondary">Croissance (Togo)</span>
              <span className="text-sm font-bold text-text-primary">{domaine.stats.growth}</span>
            </Card>
            <Card variant="standard" className="p-4 flex flex-col items-center justify-center text-center gap-1 bg-surface-alt border-primary/20">
              <Target className="w-5 h-5 text-primary mb-1" />
              <span className="text-[10px] uppercase font-bold text-text-secondary">Employabilité</span>
              <span className="text-sm font-bold text-text-primary">{domaine.stats.employability}</span>
            </Card>
            <Card variant="standard" className="p-4 flex flex-col items-center justify-center text-center gap-1 bg-surface-alt border-primary/20">
              <Briefcase className="w-5 h-5 text-primary mb-1" />
              <span className="text-[10px] uppercase font-bold text-text-secondary">Rémunération</span>
              <span className="text-sm font-bold text-text-primary">{domaine.stats.salary}</span>
            </Card>
          </section>

          <section className="p-6 bg-primary/5 rounded-2xl border border-primary/10">
            <h3 className="font-bold text-primary mb-2">Pourquoi ce secteur est stratégique ?</h3>
            <p className="text-text-secondary text-sm leading-relaxed">
              {domaine.why}
            </p>
          </section>

          <section>
            <h2 className="text-xl font-bold text-text-primary mb-4 flex items-center gap-2">
              <Briefcase className="w-6 h-6 text-primary" />
              Métiers phares de ce domaine
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {domaine.metiers.length > 0 ? domaine.metiers.map((metier: any, i: number) => (
                <Link href={`/student/explorer/metier/${metier.id}`} key={i}>
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
              {domaine.formations.length > 0 ? domaine.formations.map((form: any, i: number) => (
                <Link href={`/student/explorer/formation/${form.id}`} key={i}>
                  <Card variant="standard" className="p-4 hover:border-primary/30 cursor-pointer group flex flex-col h-full">
                    <h3 className="font-bold text-sm text-text-primary group-hover:text-primary transition-colors">{form.title}</h3>
                    <div className="mt-auto pt-4 flex justify-between items-center text-xs">
                      <span className="text-text-secondary bg-surface-alt px-2 py-1 rounded-sm">{form.level}</span>
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
            message={`L'exploration par "Domaine" est la meilleure façon de découvrir des métiers auxquels vous n'auriez jamais pensé. Si ce secteur vous intéresse globalement, regardez les métiers liés pour affiner votre choix !`}
            variant="floating"
            actionLabel="J'aime ce domaine"
            actionHref="#"
          />
        </div>

      </div>
    </div>
  );
}
