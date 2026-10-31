"use client";

import React, { useState, useMemo } from "react";
import { 
  Search, 
  Briefcase, 
  GraduationCap, 
  Building2, 
  Map, 
  ArrowRight, 
  MapPin, 
  TrendingUp,
  Target,
  Sparkles,
  X
} from "lucide-react";
import Link from "next/link";
import { AidaAssistant } from "@/components/student/AidaAssistant";
import { Card } from "@/components/ui/Card";

export default function ExplorerClient({ 
  initialDomains, 
  initialCareers, 
  initialPrograms, 
  initialSchools 
}: { 
  initialDomains: any[], 
  initialCareers: any[], 
  initialPrograms: any[], 
  initialSchools: any[] 
}) {
  // Ordre strict demandé : 1. Domaines, 2. Métiers, 3. Formations, 4. Établissements
  const [activeTab, setActiveTab] = useState<"domaines" | "metiers" | "formations" | "etablissements">("domaines");
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedDomainFilter, setSelectedDomainFilter] = useState<string>("all");

  const categories = [
    { id: "domaines", label: "Domaines", icon: Map, count: initialDomains.length },
    { id: "metiers", label: "Métiers", icon: Briefcase, count: initialCareers.length },
    { id: "formations", label: "Formations", icon: GraduationCap, count: initialPrograms.length },
    { id: "etablissements", label: "Établissements", icon: Building2, count: initialSchools.length },
  ] as const;

  // Filtrage intelligent selon l'onglet actif et la recherche
  const filteredDomains = useMemo(() => {
    if (!searchQuery.trim()) return initialDomains;
    const q = searchQuery.toLowerCase();
    return initialDomains.filter(d => 
      d.title.toLowerCase().includes(q) || 
      (d.description && d.description.toLowerCase().includes(q))
    );
  }, [initialDomains, searchQuery]);

  const filteredCareers = useMemo(() => {
    let list = initialCareers;
    if (selectedDomainFilter !== "all") {
      list = list.filter(c => c.domainSlug === selectedDomainFilter);
    }
    if (!searchQuery.trim()) return list;
    const q = searchQuery.toLowerCase();
    return list.filter(c => 
      c.title.toLowerCase().includes(q) || 
      (c.description && c.description.toLowerCase().includes(q)) ||
      (c.domainTitle && c.domainTitle.toLowerCase().includes(q)) ||
      (Array.isArray(c.skills) && c.skills.some((s: string) => s.toLowerCase().includes(q)))
    );
  }, [initialCareers, selectedDomainFilter, searchQuery]);

  const filteredPrograms = useMemo(() => {
    let list = initialPrograms;
    if (selectedDomainFilter !== "all") {
      list = list.filter(p => p.domainSlug === selectedDomainFilter);
    }
    if (!searchQuery.trim()) return list;
    const q = searchQuery.toLowerCase();
    return list.filter(p => 
      p.title.toLowerCase().includes(q) || 
      (p.schoolName && p.schoolName.toLowerCase().includes(q)) ||
      (p.level && p.level.toLowerCase().includes(q)) ||
      (p.domainTitle && p.domainTitle.toLowerCase().includes(q))
    );
  }, [initialPrograms, selectedDomainFilter, searchQuery]);

  const filteredSchools = useMemo(() => {
    if (!searchQuery.trim()) return initialSchools;
    const q = searchQuery.toLowerCase();
    return initialSchools.filter(s => 
      s.name.toLowerCase().includes(q) || 
      (s.city && s.city.toLowerCase().includes(q)) ||
      (s.type && s.type.toLowerCase().includes(q)) ||
      (s.description && s.description.toLowerCase().includes(q))
    );
  }, [initialSchools, searchQuery]);

  return (
    <div className="flex flex-col gap-8">
      
      {/* HEADER & SEARCH */}
      <div className="flex flex-col gap-6 bg-surface p-6 md:p-8 rounded-2xl border border-border-soft shadow-sm relative overflow-hidden">
        <div className="absolute top-0 right-0 w-64 h-64 bg-primary/5 rounded-full blur-3xl -translate-y-1/2 translate-x-1/2 pointer-events-none" />
        
        <div className="relative z-10">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-primary/10 text-primary text-xs font-bold uppercase tracking-wider mb-3">
            <Sparkles className="w-3.5 h-3.5" />
            Parcours d'Orientation
          </div>
          <h1 className="font-display font-bold text-3xl md:text-4xl text-text-primary mb-2">
            Explorer librement
          </h1>
          <p className="text-text-secondary text-sm md:text-base max-w-2xl">
            Du grand domaine d'intérêt jusqu'à votre futur métier, trouvez les formations 
            d'excellence et les universités reconnues au Togo et dans la sous-région.
          </p>
        </div>

        {/* SEARCH BAR */}
        <div className="relative z-10 w-full max-w-3xl mt-2 flex items-center">
          <div className="absolute left-4 text-text-secondary">
            <Search className="w-5 h-5" />
          </div>
          <input 
            type="text" 
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder={
              activeTab === "domaines" 
                ? "Rechercher un domaine d'études (ex: Tech, Santé, Droit, BTP...)" 
                : activeTab === "metiers"
                ? "Rechercher un métier (ex: Développeur, Juriste, Médecin...)"
                : activeTab === "formations"
                ? "Rechercher une formation (ex: Licence Génie Logiciel, Master Droit...)"
                : "Rechercher une école ou université (ex: Université de Lomé, IAI, ESA...)"
            }
            className="w-full h-14 pl-12 pr-28 rounded-xl border border-border-soft bg-canvas focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary text-base shadow-sm transition-all"
          />
          {searchQuery && (
            <button 
              onClick={() => setSearchQuery("")}
              className="absolute right-20 text-text-tertiary hover:text-text-primary p-2 transition-colors"
              title="Effacer la recherche"
            >
              <X className="w-4 h-4" />
            </button>
          )}
          <button 
            type="button"
            className="absolute right-2 px-4 py-2 bg-primary text-white text-sm font-bold rounded-lg hover:bg-primary/90 transition-colors"
          >
            Filtrer
          </button>
        </div>
      </div>

      {/* AIDA CONTEXTUAL INTERVENTION */}
      <AidaAssistant 
        title="Conseil d'AÏDA pour votre exploration"
        message="Commencez par choisir un Domaine d'activité pour découvrir ses métiers d'avenir. Cliquez ensuite sur un métier pour voir les formations requises et les universités togolaises qui les dispensent."
        variant="inline"
        actionLabel="Poser une question à AÏDA"
        actionPrompt="Bonjour AÏDA ! Quel domaine me conseilles-tu d'explorer pour trouver les métiers les plus recherchés et les meilleures écoles à Lomé ?"
      />

      {/* CATEGORIES / TABS */}
      <div className="flex flex-col gap-4">
        <div className="flex gap-2 overflow-x-auto pb-2 scrollbar-hide border-b border-border-soft">
          {categories.map((cat) => {
            const Icon = cat.icon;
            const isActive = activeTab === cat.id;
            return (
              <button
                key={cat.id}
                onClick={() => {
                  setActiveTab(cat.id);
                  setSelectedDomainFilter("all");
                }}
                className={`flex items-center gap-2.5 px-5 py-3 rounded-xl text-sm font-bold transition-all whitespace-nowrap ${
                  isActive 
                    ? "bg-primary text-white shadow-sm" 
                    : "bg-surface border border-border-soft text-text-secondary hover:border-primary/30 hover:text-text-primary"
                }`}
              >
                <Icon className="w-4 h-4" />
                <span>{cat.label}</span>
                <span className={`text-xs px-2 py-0.5 rounded-full ${
                  isActive ? "bg-white/20 text-white" : "bg-surface-alt text-text-tertiary"
                }`}>
                  {cat.count}
                </span>
              </button>
            );
          })}
        </div>

        {/* DOMAIN SUB-FILTER (Quand on est sur Métiers ou Formations) */}
        {(activeTab === "metiers" || activeTab === "formations") && (
          <div className="flex items-center gap-2 overflow-x-auto py-1 scrollbar-hide">
            <span className="text-xs font-bold text-text-tertiary uppercase whitespace-nowrap mr-1">
              Filtrer par secteur :
            </span>
            <button
              onClick={() => setSelectedDomainFilter("all")}
              className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-colors whitespace-nowrap ${
                selectedDomainFilter === "all"
                  ? "bg-primary/10 text-primary border border-primary/30"
                  : "bg-surface border border-border-soft text-text-secondary hover:border-primary/20"
              }`}
            >
              Tous les domaines ({initialDomains.length})
            </button>
            {initialDomains.map(d => (
              <button
                key={d.slug}
                onClick={() => setSelectedDomainFilter(d.slug)}
                className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-colors whitespace-nowrap ${
                  selectedDomainFilter === d.slug
                    ? "bg-primary/10 text-primary border border-primary/30"
                    : "bg-surface border border-border-soft text-text-secondary hover:border-primary/20"
                }`}
              >
                {d.title}
              </button>
            ))}
          </div>
        )}
      </div>

      
      {/* CONTENT GRIDS */}
      <div>
        
        {/* 1. DOMAINES (PREMIER ONGLETPAR DÉFAUT) */}
        {activeTab === "domaines" && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredDomains.length > 0 ? filteredDomains.map((item) => (
              <Link 
                href={`/student/explorer/domaine/${item.slug}`} 
                key={item.id} 
                className="group block outline-none"
              >
                <Card variant="interactive" className="h-full overflow-hidden flex flex-col p-0">
                  <div className="h-44 relative overflow-hidden bg-black">
                    <img 
                      src={item.bannerImage || "https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=600&q=80"} 
                      alt={item.title} 
                      className="w-full h-full object-cover opacity-75 group-hover:scale-105 group-hover:opacity-90 transition-all duration-500" 
                    />
                    <div className="absolute top-3 left-3 bg-white/95 backdrop-blur-sm px-2.5 py-1 rounded-md text-[10px] font-bold text-primary uppercase shadow-sm flex items-center gap-1.5">
                      <Map className="w-3 h-3" /> Secteur d'activité
                    </div>
                    {item.growth && (
                      <div className="absolute top-3 right-3 bg-primary text-white px-2 py-0.5 rounded text-[10px] font-bold flex items-center gap-1 shadow-sm">
                        <TrendingUp className="w-3 h-3" /> {item.growth}
                      </div>
                    )}
                    <div className="absolute bottom-3 left-4 right-4">
                      <h3 className="font-bold text-xl text-white drop-shadow-md leading-tight">
                        {item.title}
                      </h3>
                    </div>
                  </div>

                  <div className="p-5 flex flex-col flex-1 justify-between gap-4">
                    <p className="text-sm text-text-secondary line-clamp-2">
                      {item.description || "Explorez les opportunités professionnelles, les cursus recommandés et les débouchés dans ce domaine."}
                    </p>

                    {/* METRICS & COUNTS */}
                    <div className="grid grid-cols-2 gap-2 pt-3 border-t border-border-soft">
                      <div className="flex items-center gap-2 p-2 rounded-lg bg-surface-alt">
                        <Briefcase className="w-4 h-4 text-primary shrink-0" />
                        <span className="text-xs font-bold text-text-primary">
                          {item.careersCount || 0} métier{(item.careersCount || 0) > 1 ? "s" : ""}
                        </span>
                      </div>
                      <div className="flex items-center gap-2 p-2 rounded-lg bg-surface-alt">
                        <GraduationCap className="w-4 h-4 text-gold-dark shrink-0" />
                        <span className="text-xs font-bold text-text-primary">
                          {item.programsCount || 0} formation{(item.programsCount || 0) > 1 ? "s" : ""}
                        </span>
                      </div>
                    </div>

                    <div className="flex items-center justify-between text-sm font-bold text-primary group-hover:underline pt-2">
                      <span>Voir les métiers du domaine</span>
                      <ArrowRight className="w-4 h-4 transition-transform group-hover:translate-x-1" />
                    </div>
                  </div>
                </Card>
              </Link>
            )) : (
              <div className="col-span-full py-12 text-center text-text-secondary">
                Aucun domaine ne correspond à votre recherche.
              </div>
            )}
          </div>
        )}

        {/* 2. MÉTIERS (DEUXIÈME ONGLET) */}
        {activeTab === "metiers" && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredCareers.length > 0 ? filteredCareers.map((item) => {
              const skillsList = Array.isArray(item.skills) ? item.skills : [];

              return (
                <Link 
                  href={`/student/explorer/metier/${item.slug}`} 
                  key={item.id} 
                  className="group block outline-none"
                >
                  <Card variant="interactive" className="h-full overflow-hidden flex flex-col p-0">
                    <div className="h-44 relative overflow-hidden bg-surface-alt">
                      <img 
                        src={item.bannerImage || "https://images.unsplash.com/photo-1517694712202-14dd9538aa97?auto=format&fit=crop&w=600&q=80"} 
                        alt={item.title} 
                        className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500" 
                      />
                      <div className="absolute top-3 left-3 bg-white/95 backdrop-blur-sm px-2.5 py-1 rounded-md text-[10px] font-bold text-primary uppercase shadow-sm flex items-center gap-1">
                        <Briefcase className="w-3 h-3" />
                        {item.domainTitle || "Métier"}
                      </div>
                    </div>

                    <div className="p-5 flex flex-col flex-1">
                      <h3 className="font-bold text-lg text-text-primary mb-2 group-hover:text-primary transition-colors leading-snug">
                        {item.title}
                      </h3>
                      <p className="text-sm text-text-secondary line-clamp-2 mb-3 min-h-[40px]">
                        {item.description || "Découvrez les missions, les compétences et les cursus universitaires pour accéder à ce métier."}
                      </p>

                      {skillsList.length > 0 && (
                        <div className="flex flex-wrap gap-1.5 mb-4">
                          {skillsList.slice(0, 3).map((skill: string, idx: number) => (
                            <span key={idx} className="text-[11px] font-medium bg-surface-alt border border-border-soft px-2 py-0.5 rounded text-text-secondary">
                              {skill}
                            </span>
                          ))}
                          {skillsList.length > 3 && (
                            <span className="text-[11px] font-medium text-text-tertiary self-center">
                              +{skillsList.length - 3}
                            </span>
                          )}
                        </div>
                      )}

                      <div className="mt-auto pt-3 border-t border-border-soft flex items-center justify-between text-xs">
                        <span className="text-text-secondary font-medium flex items-center gap-1">
                          <GraduationCap className="w-3.5 h-3.5 text-primary" />
                          <strong className="text-text-primary">{item.programsCount || 1}</strong> formation{(item.programsCount || 1) > 1 ? "s" : ""} liée{(item.programsCount || 1) > 1 ? "s" : ""}
                        </span>
                        <span className="text-primary font-bold group-hover:underline flex items-center gap-1">
                          Voir formations <ArrowRight className="w-3.5 h-3.5" />
                        </span>
                      </div>
                    </div>
                  </Card>
                </Link>
              );
            }) : (
              <div className="col-span-full py-12 text-center text-text-secondary">
                Aucun métier ne correspond à votre recherche.
              </div>
            )}
          </div>
        )}

        {/* 3. FORMATIONS (TROISIÈME ONGLET) */}
        {activeTab === "formations" && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredPrograms.length > 0 ? filteredPrograms.map((item) => (
              <Link 
                href={`/student/explorer/formation/${item.slug}`} 
                key={item.id} 
                className="group block outline-none"
              >
                <Card variant="interactive" className="h-full overflow-hidden flex flex-col p-0">
                  <div className="h-44 relative overflow-hidden bg-surface-alt">
                    <img 
                      src={item.bannerImage || "https://images.unsplash.com/photo-1541339907198-e08756dedf3f?auto=format&fit=crop&w=600&q=80"} 
                      alt={item.title} 
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500" 
                    />
                    <div className="absolute top-3 left-3 bg-white/95 backdrop-blur-sm px-2.5 py-1 rounded-md text-[10px] font-bold text-primary uppercase shadow-sm">
                      {item.level || "Diplôme supérieur"}
                    </div>
                    {item.duration && (
                      <div className="absolute top-3 right-3 bg-black/60 backdrop-blur-sm text-white px-2 py-0.5 rounded text-[10px] font-bold">
                        {item.duration}
                      </div>
                    )}
                  </div>

                  <div className="p-5 flex flex-col flex-1">
                    <h3 className="font-bold text-lg text-text-primary mb-2 group-hover:text-primary transition-colors leading-snug">
                      {item.title}
                    </h3>

                    {/* ÉCOLE QUI DISPENSE */}
                    <div className="flex items-center gap-2 p-2.5 rounded-lg bg-surface-alt mb-3">
                      <Building2 className="w-4 h-4 text-primary shrink-0" />
                      <div className="min-w-0 flex-1">
                        <p className="text-xs font-bold text-text-primary truncate">
                          {item.schoolName}
                        </p>
                        <p className="text-[11px] text-text-secondary flex items-center gap-1 truncate">
                          <MapPin className="w-3 h-3" /> {item.schoolCity}
                        </p>
                      </div>
                    </div>

                    <p className="text-sm text-text-secondary line-clamp-2 mb-4">
                      {item.description || "Consultez le cursus, les conditions d'admission et les débouchés professionnels."}
                    </p>

                    <div className="mt-auto pt-3 border-t border-border-soft flex items-center justify-between text-xs font-bold text-primary group-hover:underline">
                      <span>Voir le cursus & l'école</span>
                      <ArrowRight className="w-4 h-4 transition-transform group-hover:translate-x-1" />
                    </div>
                  </div>
                </Card>
              </Link>
            )) : (
              <div className="col-span-full py-12 text-center text-text-secondary">
                Aucune formation ne correspond à votre recherche.
              </div>
            )}
          </div>
        )}

        {/* 4. ÉTABLISSEMENTS (QUATRIÈME ONGLET) */}
        {activeTab === "etablissements" && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredSchools.length > 0 ? filteredSchools.map((item) => (
              <Link 
                href={`/student/explorer/etablissement/${item.slug}`} 
                key={item.id} 
                className="group block outline-none"
              >
                <Card variant="interactive" className="h-full overflow-hidden flex flex-col p-0">
                  <div className="h-44 relative overflow-hidden bg-surface-alt">
                    <img 
                      src={item.bannerImage || "https://images.unsplash.com/photo-1562774053-701939374585?auto=format&fit=crop&w=600&q=80"} 
                      alt={item.name} 
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500" 
                    />
                    <div className="absolute top-3 left-3 bg-white/95 backdrop-blur-sm px-2.5 py-1 rounded-md text-[10px] font-bold text-primary uppercase shadow-sm flex items-center gap-1">
                      <Building2 className="w-3 h-3" /> {item.type || "Établissement"}
                    </div>
                    {item.insertionRate && (
                      <div className="absolute top-3 right-3 bg-success text-white px-2 py-0.5 rounded text-[10px] font-bold">
                        {item.insertionRate} insertion
                      </div>
                    )}
                  </div>

                  <div className="p-5 flex flex-col flex-1">
                    <h3 className="font-bold text-lg text-text-primary mb-1 group-hover:text-primary transition-colors leading-snug">
                      {item.name}
                    </h3>
                    <p className="text-xs text-text-secondary mb-3 flex items-center gap-1">
                      <MapPin className="w-3.5 h-3.5 text-primary" /> {item.city || "Lomé, Togo"}
                    </p>
                    <p className="text-sm text-text-secondary line-clamp-2 mb-4">
                      {item.description || "Découvrez le campus, les infrastructures et les filières dispensées."}
                    </p>

                    <div className="mt-auto pt-3 border-t border-border-soft flex items-center justify-between text-xs">
                      <span className="text-text-secondary font-medium">
                        <strong className="text-text-primary">{item.programsCount || 0}</strong> formation{(item.programsCount || 0) > 1 ? "s" : ""}
                      </span>
                      <span className="text-primary font-bold group-hover:underline flex items-center gap-1">
                        Visiter le campus <ArrowRight className="w-3.5 h-3.5" />
                      </span>
                    </div>
                  </div>
                </Card>
              </Link>
            )) : (
              <div className="col-span-full py-12 text-center text-text-secondary">
                Aucun établissement ne correspond à votre recherche.
              </div>
            )}
          </div>
        )}

      </div>
    </div>
  );
}
