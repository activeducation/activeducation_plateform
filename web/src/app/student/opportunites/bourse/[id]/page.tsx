"use client";

import React from "react";
import { ArrowLeft, MapPin, Calendar, Clock, DollarSign, CheckCircle2, GraduationCap, ExternalLink, AlertCircle } from "lucide-react";
import Link from "next/link";
import { Card } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";

export default function BoursePage({ params }: { params: Promise<{ id: string }> }) {
  const unwrappedParams = React.use(params);
  const [bourse, setBourse] = React.useState<any>(null);
  const [loading, setLoading] = React.useState(true);

  React.useEffect(() => {
    fetch(`/api/opportunities/${unwrappedParams.id}`)
      .then(res => res.json())
      .then(data => {
        setBourse(data);
        setLoading(false);
      })
      .catch(err => {
        console.error(err);
        setLoading(false);
      });
  }, [unwrappedParams.id]);

  if (loading) {
    return <div className="p-8 text-center text-text-secondary">Chargement des informations...</div>;
  }

  if (!bourse || bourse.error) {
    return (
      <div className="p-8 text-center text-text-secondary">
        <h1 className="text-2xl font-bold mb-4">Opportunité non trouvée</h1>
        <Link href="/student/opportunites">
          <Button variant="secondary">Retour aux opportunités</Button>
        </Link>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-6 -mt-4 md:-mt-8 -mx-4 md:-mx-8 animate-fade-in">
      
      {/* FULL WIDTH BANNER */}
      <div className="relative w-full h-[30dvh] md:h-[40dvh] bg-primary overflow-hidden">
        <img 
          src={bourse.image || "https://images.unsplash.com/photo-1523050854058-8df90110c9f1?auto=format&fit=crop&w=1200&q=80"} 
          alt={bourse.title} 
          className="w-full h-full object-cover opacity-30 mix-blend-overlay" 
        />
        
        <div className="absolute top-4 left-4 md:top-8 md:left-8 z-20">
          <Link href="/student/opportunites" className="inline-flex items-center gap-2 text-sm font-bold text-white bg-black/30 hover:bg-black/50 px-4 py-2 rounded-full backdrop-blur-sm transition-colors">
            <ArrowLeft className="w-4 h-4" /> Retour aux opportunités
          </Link>
        </div>

        <div className="absolute bottom-0 left-0 w-full p-6 md:p-10 bg-gradient-to-t from-canvas to-transparent">
          <div className="flex items-center gap-2 mb-3">
            <span className="text-[10px] md:text-xs uppercase font-bold text-white bg-primary px-3 py-1.5 rounded-full flex items-center gap-1 shadow-sm">
              <GraduationCap className="w-3 h-3" /> {bourse.type === 'bourse' ? "Bourse d'études" : bourse.type === 'stage' ? "Stage / Emploi" : "Événement"}
            </span>
          </div>
          <h1 className="font-display font-bold text-2xl md:text-5xl text-text-primary mb-2">
            {bourse.title}
          </h1>
          <p className="text-text-secondary font-medium text-sm md:text-base">Proposée par : <strong className="text-primary">{bourse.provider || "Non spécifié"}</strong></p>
        </div>
      </div>

      <div className="max-w-4xl mx-auto w-full px-4 md:px-8 pb-12 flex flex-col gap-8">
        
        {/* QUICK STATS */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <Card variant="standard" className="p-4 flex items-center gap-4 bg-surface border-border-soft">
            <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center text-primary flex-shrink-0">
              <DollarSign className="w-5 h-5" />
            </div>
            <div>
              <p className="text-[10px] uppercase font-bold text-text-secondary">Montant / Couverture</p>
              <p className="font-bold text-sm text-text-primary">{bourse.amountOrSalary || "Non précisé"}</p>
            </div>
          </Card>
          <Card variant="standard" className="p-4 flex items-center gap-4 bg-surface border-border-soft">
            <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center text-primary flex-shrink-0">
              <MapPin className="w-5 h-5" />
            </div>
            <div>
              <p className="text-[10px] uppercase font-bold text-text-secondary">Lieu de validité</p>
              <p className="font-bold text-sm text-text-primary">{bourse.location || "Non précisé"}</p>
            </div>
          </Card>
          <Card variant="standard" className="p-4 flex items-center gap-4 bg-error/10 border-error/20">
            <div className="w-10 h-10 rounded-full bg-error/20 flex items-center justify-center text-error flex-shrink-0">
              <Clock className="w-5 h-5" />
            </div>
            <div>
              <p className="text-[10px] uppercase font-bold text-error">Date limite de candidature</p>
              <p className="font-bold text-sm text-error">{bourse.deadline ? new Date(bourse.deadline).toLocaleDateString() : "Non précisée"}</p>
            </div>
          </Card>
        </div>

        {/* DESCRIPTION */}
        <section className="bg-surface p-6 md:p-8 rounded-2xl border border-border-soft shadow-sm">
          <h2 className="text-xl font-bold text-text-primary mb-4">À propos de cette opportunité</h2>
          <p className="text-text-secondary leading-relaxed mb-8 whitespace-pre-wrap">
            {bourse.description}
          </p>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            {bourse.criteria && bourse.criteria.length > 0 && (
              <div>
                <h3 className="font-bold text-text-primary mb-4 flex items-center gap-2">
                  <CheckCircle2 className="w-5 h-5 text-primary" /> Critères d'éligibilité
                </h3>
                <ul className="flex flex-col gap-3">
                  {bourse.criteria.map((crit: string, i: number) => (
                    <li key={i} className="flex items-start gap-2 text-sm text-text-secondary">
                      <div className="w-1.5 h-1.5 rounded-full bg-primary flex-shrink-0 mt-1.5" />
                      <span>{crit}</span>
                    </li>
                  ))}
                </ul>
              </div>
            )}
            
            {bourse.documents && bourse.documents.length > 0 && (
              <div>
                <h3 className="font-bold text-text-primary mb-4 flex items-center gap-2">
                  <AlertCircle className="w-5 h-5 text-gold" /> Pièces à fournir
                </h3>
                <ul className="flex flex-col gap-3">
                  {bourse.documents.map((doc: string, i: number) => (
                    <li key={i} className="flex items-start gap-2 text-sm text-text-secondary">
                      <div className="w-1.5 h-1.5 rounded-full bg-gold flex-shrink-0 mt-1.5" />
                      <span>{doc}</span>
                    </li>
                  ))}
                </ul>
              </div>
            )}
          </div>
        </section>

        {/* CTA */}
        {bourse.link && (
          <div className="flex justify-center pt-4">
            <a href={bourse.link} target="_blank" rel="noopener noreferrer">
              <Button size="lg" className="px-8 shadow-lg shadow-primary/20 flex items-center gap-2">
                Aller sur le site officiel <ExternalLink className="w-5 h-5" />
              </Button>
            </a>
          </div>
        )}
      </div>
    </div>
  );
}
