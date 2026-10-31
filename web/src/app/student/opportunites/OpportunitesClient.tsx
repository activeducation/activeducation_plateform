"use client";

import React, { useState, useMemo } from "react";
import { 
  Briefcase, 
  GraduationCap, 
  Calendar, 
  MapPin, 
  Clock, 
  ChevronRight, 
  Search,
  X
} from "lucide-react";
import { Card } from "@/components/ui/Card";
import { Input } from "@/components/ui/Input";
import { Button } from "@/components/ui/Button";
import { AidaAssistant } from "@/components/student/AidaAssistant";
import Link from "next/link";

interface OpportunityItem {
  id: string;
  type: string;
  title: string;
  provider: string | null;
  description: string | null;
  location: string | null;
  amountOrSalary: string | null;
  deadline: string | Date | null;
  eventDate: string | Date | null;
  image: string | null;
  isRecommended: boolean;
  isPublished: boolean;
  link?: string | null;
}

export default function OpportunitesClient({ initialOpportunities }: { initialOpportunities: OpportunityItem[] }) {
  const [activeTab, setActiveTab] = useState<"bourses" | "stages" | "evenements">("bourses");
  const [searchQuery, setSearchQuery] = useState("");

  const filteredOpportunities = useMemo(() => {
    if (!searchQuery.trim()) return initialOpportunities;
    const q = searchQuery.toLowerCase().trim();
    return initialOpportunities.filter(item => {
      const titleMatch = item.title?.toLowerCase().includes(q);
      const providerMatch = item.provider?.toLowerCase().includes(q);
      const locationMatch = item.location?.toLowerCase().includes(q);
      const descMatch = item.description?.toLowerCase().includes(q);
      return titleMatch || providerMatch || locationMatch || descMatch;
    });
  }, [initialOpportunities, searchQuery]);

  const bourses = useMemo(() => filteredOpportunities.filter(o => o.type === 'bourse'), [filteredOpportunities]);
  const stages = useMemo(() => filteredOpportunities.filter(o => o.type === 'stage'), [filteredOpportunities]);
  const evenements = useMemo(() => filteredOpportunities.filter(o => o.type === 'evenement'), [filteredOpportunities]);

  const allBoursesCount = useMemo(() => initialOpportunities.filter(o => o.type === 'bourse').length, [initialOpportunities]);
  const allStagesCount = useMemo(() => initialOpportunities.filter(o => o.type === 'stage').length, [initialOpportunities]);
  const allEvenementsCount = useMemo(() => initialOpportunities.filter(o => o.type === 'evenement').length, [initialOpportunities]);

  return (
    <div className="flex flex-col gap-8 animate-fade-in">
      
      {/* HEADER */}
      <div>
        <h1 className="text-3xl font-display font-bold text-text-primary mb-2">Bourses & Opportunités</h1>
        <p className="text-text-secondary">Découvrez les bourses d'études officielles à jour, offres de stages et événements pour booster votre avenir.</p>
      </div>

      <AidaAssistant 
        title="Ma sélection pour vous"
        message="Nos agents IA viennent d'actualiser les bourses d'études officielles pour l'Afrique et l'international (France Excellence Eiffel, Chevening, Mastercard Foundation, DAAD, IsDB, Erasmus Mundus). Consultez les critères et dates limites de candidature."
        variant="inline"
      />

      {/* TABS & SEARCH */}
      <div className="flex flex-col md:flex-row gap-4 justify-between items-start md:items-center">
        <div className="flex bg-surface-alt p-1 rounded-lg border border-border-soft overflow-x-auto w-full md:w-auto">
          <button
            onClick={() => setActiveTab("bourses")}
            className={`flex items-center gap-2 px-4 py-2 text-sm font-bold rounded-md whitespace-nowrap transition-colors ${
              activeTab === "bourses"
                ? "bg-surface text-primary shadow-sm"
                : "text-text-secondary hover:text-text-primary"
            }`}
          >
            <GraduationCap className="w-4 h-4" /> Bourses d'études ({searchQuery ? bourses.length : allBoursesCount})
          </button>
          <button
            onClick={() => setActiveTab("stages")}
            className={`flex items-center gap-2 px-4 py-2 text-sm font-bold rounded-md whitespace-nowrap transition-colors ${
              activeTab === "stages"
                ? "bg-surface text-primary shadow-sm"
                : "text-text-secondary hover:text-text-primary"
            }`}
          >
            <Briefcase className="w-4 h-4" /> Stages & Emplois ({searchQuery ? stages.length : allStagesCount})
          </button>
          <button
            onClick={() => setActiveTab("evenements")}
            className={`flex items-center gap-2 px-4 py-2 text-sm font-bold rounded-md whitespace-nowrap transition-colors ${
              activeTab === "evenements"
                ? "bg-surface text-primary shadow-sm"
                : "text-text-secondary hover:text-text-primary"
            }`}
          >
            <Calendar className="w-4 h-4" /> Événements ({searchQuery ? evenements.length : allEvenementsCount})
          </button>
        </div>

        <div className="flex gap-2 w-full md:w-auto">
          <div className="relative flex-1 md:w-72">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-text-tertiary" />
            <Input 
              placeholder="Rechercher par pays, organisme..." 
              className="pl-9 pr-8"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
            {searchQuery && (
              <button 
                onClick={() => setSearchQuery("")}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-text-tertiary hover:text-text-primary"
                title="Effacer la recherche"
              >
                <X className="w-4 h-4" />
              </button>
            )}
          </div>
        </div>
      </div>

      {/* CONTENT */}
      <div>
        {activeTab === "bourses" && (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {bourses.length === 0 && (
              <div className="col-span-2 p-8 text-center text-text-secondary bg-surface border border-border-soft rounded-xl">
                Aucune bourse ne correspond à votre recherche "{searchQuery}".
              </div>
            )}
            {bourses.map((bourse) => {
              const bgImg = bourse.image || "https://images.unsplash.com/photo-1523050854058-8df90110c9f1?auto=format&fit=crop&w=800&q=80";
              return (
                <Link href={`/student/opportunites/bourse/${bourse.id}`} key={bourse.id} className="block outline-none">
                  <Card variant="standard" className="p-0 overflow-hidden flex flex-col group cursor-pointer hover:border-primary/40 h-full transition-all">
                    <div className="h-44 bg-surface-alt relative overflow-hidden">
                      <img 
                        src={bgImg} 
                        alt={bourse.title} 
                        className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500" 
                      />
                      <div className="absolute inset-0 bg-gradient-to-t from-black/50 via-transparent to-black/20 pointer-events-none" />
                      {bourse.isRecommended && (
                        <div className="absolute top-3 right-3 z-10 bg-gold text-white text-[10px] font-bold px-2.5 py-1 rounded-sm uppercase tracking-wide shadow-sm">
                          Recommandé
                        </div>
                      )}
                    </div>
                    <div className="p-5 flex flex-col flex-1">
                      <div className="mb-2">
                        <span className="text-[11px] font-bold uppercase tracking-wider text-primary">
                          {bourse.provider || "Bourse Internationale"}
                        </span>
                        <h3 className="font-bold text-lg text-text-primary mt-1 group-hover:text-primary transition-colors line-clamp-2">
                          {bourse.title}
                        </h3>
                      </div>
                      <p className="text-sm text-text-secondary mb-4 line-clamp-2">{bourse.description}</p>
                      
                      <div className="flex flex-col gap-2 mt-auto pt-3 border-t border-border-soft">
                        <div className="flex items-center gap-2 text-xs text-text-secondary">
                          <MapPin className="w-4 h-4 text-primary flex-shrink-0" />
                          <span className="font-medium">{bourse.location || "Non précisé"}</span>
                        </div>
                        {bourse.deadline && (
                          <div className="flex items-center gap-2 text-xs text-text-secondary">
                            <Clock className="w-4 h-4 text-gold flex-shrink-0" />
                            <span>Clôture : <strong className="text-text-primary">{new Date(bourse.deadline).toLocaleDateString('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' })}</strong></span>
                          </div>
                        )}
                        {bourse.amountOrSalary && (
                          <div className="text-xs font-semibold text-text-primary line-clamp-1 bg-surface-alt px-2.5 py-1 rounded mt-1">
                            {bourse.amountOrSalary}
                          </div>
                        )}
                      </div>

                      <div className="mt-4 pt-3 flex items-center justify-between text-sm font-bold text-primary">
                        <span>Voir les critères & postuler</span>
                        <ChevronRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
                      </div>
                    </div>
                  </Card>
                </Link>
              );
            })}
          </div>
        )}

        {activeTab === "stages" && (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {stages.length === 0 && (
              <div className="col-span-2 flex flex-col gap-4">
                <div className="p-8 bg-surface border border-border-soft rounded-xl text-center flex flex-col items-center justify-center">
                  <div className="w-16 h-16 bg-surface-alt rounded-full flex items-center justify-center mb-4">
                    <Briefcase className="w-8 h-8 text-text-tertiary" />
                  </div>
                  <h3 className="font-bold text-text-primary mb-2">Offres de stages & alternances</h3>
                  <p className="text-sm text-text-secondary max-w-md mx-auto">
                    Cette section regroupera bientôt les opportunités de stages de nos entreprises partenaires filtrées selon vos formations favorites.
                  </p>
                </div>
              </div>
            )}
            {stages.map((stage) => (
              <Link href={`/student/opportunites/bourse/${stage.id}`} key={stage.id} className="block outline-none">
                <Card variant="standard" className="p-5 flex flex-col gap-4 hover:border-primary/30 cursor-pointer">
                  <div className="flex justify-between items-start">
                    <div className="w-12 h-12 bg-primary/10 rounded-xl flex items-center justify-center text-primary">
                      <Briefcase className="w-6 h-6" />
                    </div>
                    {stage.amountOrSalary && (
                      <span className="text-sm font-bold text-success bg-success/10 px-2 py-1 rounded">
                        {stage.amountOrSalary}
                      </span>
                    )}
                  </div>
                  <div>
                    <h3 className="font-bold text-lg text-text-primary">{stage.title}</h3>
                    <p className="text-sm font-medium text-text-secondary">{stage.provider}</p>
                  </div>
                  <p className="text-sm text-text-secondary line-clamp-2">{stage.description}</p>
                  <div className="flex items-center gap-4 text-xs text-text-tertiary mt-2">
                    <span className="flex items-center gap-1"><MapPin className="w-3 h-3" /> {stage.location}</span>
                    {stage.deadline && <span className="flex items-center gap-1"><Clock className="w-3 h-3" /> {new Date(stage.deadline).toLocaleDateString()}</span>}
                  </div>
                </Card>
              </Link>
            ))}
          </div>
        )}

        {activeTab === "evenements" && (
          <div className="flex flex-col gap-4">
            {evenements.length === 0 && (
              <div className="p-8 text-center text-text-secondary bg-surface border border-border-soft rounded-xl">
                Aucun événement à venir pour le moment.
              </div>
            )}
            {evenements.map((evt) => {
              const evtDate = evt.eventDate ? new Date(evt.eventDate) : new Date();
              const month = evtDate.toLocaleString('fr-FR', { month: 'short' });
              const day = evtDate.getDate();
              
              return (
                <Link href={`/student/opportunites/bourse/${evt.id}`} key={evt.id} className="block outline-none">
                  <Card variant="standard" className="p-5 flex flex-col md:flex-row gap-6 hover:border-primary/30 cursor-pointer group">
                    <div className="flex-shrink-0 w-full md:w-32 h-32 bg-primary/10 rounded-lg flex flex-col items-center justify-center text-primary">
                      <span className="text-sm font-bold uppercase">{month}</span>
                      <span className="text-4xl font-display font-bold">{day}</span>
                    </div>
                    <div className="flex flex-col flex-1 justify-center">
                      <div className="flex justify-between items-start">
                        <div>
                          <h3 className="font-bold text-lg text-text-primary mb-1 group-hover:text-primary transition-colors">{evt.title}</h3>
                          <p className="text-sm text-text-secondary mb-3 line-clamp-2">{evt.description}</p>
                        </div>
                      </div>
                      <div className="flex flex-wrap gap-4 mt-auto">
                        <div className="flex items-center gap-1 text-xs text-text-secondary">
                          <MapPin className="w-4 h-4" /> {evt.location || "En ligne"}
                        </div>
                        <div className="flex items-center gap-1 text-xs text-text-secondary">
                          <Clock className="w-4 h-4" /> {evtDate.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}
                        </div>
                      </div>
                    </div>
                    <div className="flex items-center justify-center md:justify-end md:pl-4 border-t md:border-t-0 md:border-l border-border-soft pt-4 md:pt-0 mt-4 md:mt-0">
                      <Button variant="secondary">
                        Voir plus
                      </Button>
                    </div>
                  </Card>
                </Link>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
