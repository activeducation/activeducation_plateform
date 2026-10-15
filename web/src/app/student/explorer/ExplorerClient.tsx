"use client";

import React, { useState } from "react";
import { Search, Briefcase, GraduationCap, Building2, Map, Star, ArrowRight, MapPin } from "lucide-react";
import { AidaAssistant } from "@/components/student/AidaAssistant";
import { Card } from "@/components/ui/Card";
import { Input } from "@/components/ui/Input";

export default function ExplorerClient({ 
  initialCareers, 
  initialPrograms, 
  initialSchools, 
  initialDomains 
}: { 
  initialCareers: any[], 
  initialPrograms: any[], 
  initialSchools: any[], 
  initialDomains: any[] 
}) {
  const [activeTab, setActiveTab] = useState("metiers");

  const categories = [
    { id: "metiers", label: "Métiers", icon: Briefcase },
    { id: "formations", label: "Formations", icon: GraduationCap },
    { id: "etablissements", label: "Établissements", icon: Building2 },
    { id: "domaines", label: "Domaines", icon: Map },
  ];

  return (
    <div className="flex flex-col gap-8">
      
      {/* HEADER & SEARCH */}
      <div className="flex flex-col gap-6 bg-surface p-6 md:p-8 rounded-2xl border border-border-soft shadow-sm relative overflow-hidden">
        <div className="absolute top-0 right-0 w-64 h-64 bg-primary/5 rounded-full blur-3xl -translate-y-1/2 translate-x-1/2 pointer-events-none" />
        
        <div className="relative z-10">
          <h1 className="font-display font-bold text-3xl md:text-4xl text-text-primary mb-2">
            Explorer librement
          </h1>
          <p className="text-text-secondary text-sm md:text-base max-w-2xl">
            Découvrez des métiers, des écoles et des opportunités au Togo et partout ailleurs. 
            Vous n'êtes jamais prisonnier de vos recommandations.
          </p>
        </div>

        <div className="relative z-10 w-full max-w-3xl mt-2 flex items-center">
          <div className="absolute left-4 text-text-secondary">
            <Search className="w-5 h-5" />
          </div>
          <input 
            type="text" 
            placeholder="Que souhaitez-vous découvrir ? (Ex: Cybersécurité, Université de Lomé...)"
            className="w-full h-14 pl-12 pr-4 rounded-xl border border-border-soft bg-canvas focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary text-base shadow-sm transition-all"
          />
          <button className="absolute right-2 px-4 py-2 bg-primary text-white text-sm font-bold rounded-lg hover:bg-primary/90 transition-colors">
            Rechercher
          </button>
        </div>
      </div>

      {/* AIDA CONTEXTUAL INTERVENTION */}
      <AidaAssistant 
        title="Conseil d'AÏDA"
        message="D'après vos récents intérêts pour les technologies de l'information, je vous ai pré-filtré quelques domaines d'avenir. Vous pouvez explorer les métiers de l'analyse de données et de l'intelligence artificielle ci-dessous."
      />

      {/* CATEGORIES / TABS */}
      <div className="flex gap-2 overflow-x-auto pb-2 scrollbar-hide">
        {categories.map((cat) => {
          const Icon = cat.icon;
          const isActive = activeTab === cat.id;
          return (
            <button
              key={cat.id}
              onClick={() => setActiveTab(cat.id)}
              className={`flex items-center gap-2 px-4 py-2.5 rounded-lg text-sm font-bold transition-all whitespace-nowrap ${
                isActive 
                  ? "bg-primary text-white shadow-sm" 
                  : "bg-surface border border-border-soft text-text-secondary hover:border-primary/30 hover:text-text-primary"
              }`}
            >
              <Icon className="w-4 h-4" />
              {cat.label}
            </button>
          );
        })}
      </div>

      
      {/* CONTENT GRID */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        
        {activeTab === "metiers" && (
          <>
            {initialCareers.length > 0 ? initialCareers.map((item) => (
              <a href={`/student/explorer/metier/${item.slug}`} key={item.id} className="group block outline-none">
                <Card variant="interactive" className="h-full overflow-hidden flex flex-col p-0">
                  <div className="h-40 relative overflow-hidden bg-surface-alt">
                    <img 
                      src={item.bannerImage || "https://images.unsplash.com/photo-1550751827-4bd374c3f58b?auto=format&fit=crop&w=600&q=80"} 
                      alt={item.title} 
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500" 
                    />
                    <div className="absolute top-3 left-3 bg-white/90 backdrop-blur-sm px-2 py-1 rounded text-[10px] font-bold text-primary uppercase shadow-sm">
                      Métier
                    </div>
                  </div>
                  <div className="p-5 flex flex-col flex-1">
                    <h3 className="font-bold text-lg text-text-primary mb-2 group-hover:text-primary transition-colors">{item.title}</h3>
                    <p className="text-sm text-text-secondary line-clamp-3 mb-4">{item.description}</p>
                    <div className="mt-auto flex items-center justify-between text-sm font-bold text-primary group-hover:underline">
                      Découvrir <ArrowRight className="w-4 h-4" />
                    </div>
                  </div>
                </Card>
              </a>
            )) : <p className="text-text-secondary col-span-full">Aucun métier trouvé.</p>}
          </>
        )}

        {activeTab === "formations" && (
          <>
            {initialPrograms.length > 0 ? initialPrograms.map((item) => (
              <a href={`/student/explorer/formation/${item.slug}`} key={item.id} className="group block outline-none">
                <Card variant="interactive" className="h-full overflow-hidden flex flex-col p-0">
                  <div className="h-40 relative overflow-hidden bg-surface-alt">
                    <img 
                      src={item.bannerImage || "https://images.unsplash.com/photo-1541339907198-e08756dedf3f?auto=format&fit=crop&w=600&q=80"} 
                      alt={item.title} 
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500" 
                    />
                    <div className="absolute top-3 left-3 bg-white/90 backdrop-blur-sm px-2 py-1 rounded text-[10px] font-bold text-primary uppercase shadow-sm">
                      Formation
                    </div>
                  </div>
                  <div className="p-5 flex flex-col flex-1">
                    <h3 className="font-bold text-lg text-text-primary mb-1 group-hover:text-primary transition-colors">{item.title}</h3>
                    <p className="text-xs font-bold text-text-tertiary mb-3">{item.level || 'Non précisé'}</p>
                    <p className="text-sm text-text-secondary line-clamp-3 mb-4">{item.description}</p>
                    <div className="mt-auto flex items-center justify-between text-sm font-bold text-primary group-hover:underline">
                      Voir programme <ArrowRight className="w-4 h-4" />
                    </div>
                  </div>
                </Card>
              </a>
            )) : <p className="text-text-secondary col-span-full">Aucune formation trouvée.</p>}
          </>
        )}

        {activeTab === "etablissements" && (
          <>
            {initialSchools.length > 0 ? initialSchools.map((item) => (
              <a href={`/student/explorer/etablissement/${item.slug}`} key={item.id} className="group block outline-none">
                <Card variant="interactive" className="h-full overflow-hidden flex flex-col p-0">
                  <div className="h-40 relative overflow-hidden bg-surface-alt">
                    <img 
                      src={item.bannerImage || "https://images.unsplash.com/photo-1562774053-701939374585?auto=format&fit=crop&w=600&q=80"} 
                      alt={item.name} 
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500" 
                    />
                    <div className="absolute top-3 left-3 bg-white/90 backdrop-blur-sm px-2 py-1 rounded text-[10px] font-bold text-primary uppercase shadow-sm flex items-center gap-1">
                      <Building2 className="w-3 h-3" /> École
                    </div>
                  </div>
                  <div className="p-5 flex flex-col flex-1">
                    <h3 className="font-bold text-lg text-text-primary mb-1 group-hover:text-primary transition-colors">{item.name}</h3>
                    <p className="text-xs text-text-tertiary mb-3 flex items-center gap-1"><MapPin className="w-3 h-3" /> {item.city || "Localisation inconnue"}</p>
                    <p className="text-sm text-text-secondary line-clamp-3 mb-4">{item.description}</p>
                    <div className="mt-auto flex items-center justify-between text-sm font-bold text-primary group-hover:underline">
                      Visiter le campus <ArrowRight className="w-4 h-4" />
                    </div>
                  </div>
                </Card>
              </a>
            )) : <p className="text-text-secondary col-span-full">Aucun établissement trouvé.</p>}
          </>
        )}

        {activeTab === "domaines" && (
          <>
            {initialDomains.length > 0 ? initialDomains.map((item) => (
              <a href={`/student/explorer/domaine/${item.slug}`} key={item.id} className="group block outline-none">
                <Card variant="interactive" className="h-full overflow-hidden flex flex-col p-0">
                  <div className="h-40 relative overflow-hidden bg-black">
                    <img 
                      src={item.bannerImage || "https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=600&q=80"} 
                      alt={item.title} 
                      className="w-full h-full object-cover opacity-60 group-hover:scale-105 group-hover:opacity-80 transition-all duration-500" 
                    />
                    <div className="absolute bottom-4 left-4 right-4">
                      <span className="text-[10px] font-bold text-white/90 uppercase mb-1 block drop-shadow-md">Secteur</span>
                      <h3 className="font-bold text-xl text-white drop-shadow-md">{item.title}</h3>
                    </div>
                  </div>
                </Card>
              </a>
            )) : <p className="text-text-secondary col-span-full">Aucun domaine trouvé.</p>}
          </>
        )}
      </div>
    </div>
  );
}
