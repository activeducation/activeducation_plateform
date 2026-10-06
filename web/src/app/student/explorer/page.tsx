"use client";

import React, { useState } from "react";
import { Search, Briefcase, GraduationCap, Building2, Map, Star, ArrowRight, MapPin } from "lucide-react";
import { AidaAssistant } from "@/components/student/AidaAssistant";
import { Card } from "@/components/ui/Card";
import { Input } from "@/components/ui/Input";

export default function ExplorerPage() {
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
            {[
              {
                id: "cybersecurite",
                title: "Ingénieur Cybersécurité",
                domain: "Tech & Numérique",
                recommended: true,
                desc: "Protège les systèmes informatiques et les données des entreprises contre les cyberattaques. Un métier très demandé en Afrique de l'Ouest.",
                image: "https://images.unsplash.com/photo-1550751827-4bd374c3f58b?auto=format&fit=crop&w=600&q=80"
              },
              {
                id: "agronome",
                title: "Ingénieur Agronome",
                domain: "Agro-industrie",
                recommended: false,
                desc: "Améliore les techniques de production agricole dans le respect de l'environnement. Secteur clé pour l'économie togolaise.",
                image: "https://images.unsplash.com/photo-1592982537447-7440770cbfc9?auto=format&fit=crop&w=600&q=80"
              },
              {
                id: "data-analyst",
                title: "Data Analyst",
                domain: "Tech & Numérique",
                recommended: false,
                desc: "Analyse les données massives pour aider les entreprises à prendre des décisions stratégiques et optimiser leurs processus.",
                image: "https://images.unsplash.com/photo-1551288049-bebda4e38f71?auto=format&fit=crop&w=600&q=80"
              },
              {
                id: "energies-renouvelables",
                title: "Technicien Énergies Renouvelables",
                domain: "Énergie",
                recommended: true,
                desc: "Conçoit, installe et maintient des panneaux solaires et autres systèmes d'énergie verte. Un marché en pleine explosion.",
                image: "https://images.unsplash.com/photo-1509391366360-2e959784a276?auto=format&fit=crop&w=600&q=80"
              },
              {
                id: "logistique",
                title: "Responsable Logistique",
                domain: "Transport",
                recommended: false,
                desc: "Gère les flux de marchandises (import/export). Essentiel au Togo grâce au Port Autonome de Lomé.",
                image: "https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?auto=format&fit=crop&w=600&q=80"
              },
              {
                id: "esante",
                title: "Spécialiste E-Santé",
                domain: "Santé",
                recommended: false,
                desc: "Allie compétences médicales et technologiques pour développer la télémédecine et l'accès aux soins à distance.",
                image: "https://images.unsplash.com/photo-1576091160550-2173dba999ef?auto=format&fit=crop&w=600&q=80"
              }
            ].map((metier) => (
              <a href={`/student/explorer/metier/${metier.id}`} key={metier.id} className="block outline-none">
                <Card variant="standard" className="flex flex-col h-full hover:border-primary/30 cursor-pointer group overflow-hidden">
                  {/* Image Banner */}
                  <div className="w-full h-40 overflow-hidden relative flex-shrink-0">
                    <div className="absolute inset-0 bg-black/10 group-hover:bg-transparent transition-colors z-10" />
                    <img src={metier.image} alt={metier.title} className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500" />
                  </div>
                  
                  {/* Content */}
                  <div className="p-5 flex flex-col flex-1">
                    <div className="flex justify-between items-start mb-3">
                      <span className="text-[10px] uppercase font-bold text-primary bg-primary/10 px-2 py-1 rounded-sm">
                        {metier.domain}
                      </span>
                      {metier.recommended && (
                        <span className="text-xs font-bold text-gold flex items-center gap-1">
                          <Star className="w-3 h-3 fill-gold" /> Recommandé
                        </span>
                      )}
                    </div>
                    <h3 className="font-bold text-lg text-text-primary mb-2">{metier.title}</h3>
                    <p className="text-sm text-text-secondary mb-6 line-clamp-2">
                      {metier.desc}
                    </p>
                    <div className="mt-auto pt-2 flex items-center text-xs font-bold text-primary group-hover:underline">
                      Voir la fiche métier <ArrowRight className="w-4 h-4 ml-1" />
                    </div>
                  </div>
                </Card>
              </a>
            ))}
          </>
        )}

        {activeTab === "etablissements" && (
          <>
            {[
              {
                id: "ul",
                title: "Université de Lomé (UL)",
                city: "Lomé, Togo",
                type: "Public",
                desc: "La plus grande université publique du Togo, offrant des formations dans presque tous les domaines avec de multiples facultés.",
                image: "https://images.unsplash.com/photo-1541339907198-e08756dedf3f?auto=format&fit=crop&w=600&q=80"
              },
              {
                id: "eamau",
                title: "EAMAU",
                city: "Lomé, Togo",
                type: "Public (Inter-états)",
                desc: "École Africaine des Métiers de l'Architecture et de l'Urbanisme. L'excellence pour les bâtisseurs de demain.",
                image: "https://images.unsplash.com/photo-1503387762-592deb58ef4e?auto=format&fit=crop&w=600&q=80"
              },
              {
                id: "iai",
                title: "IAI Togo",
                city: "Lomé, Togo",
                type: "Public (Inter-états)",
                desc: "L'Institut Africain d'Informatique forme l'élite des informaticiens et programmeurs de la sous-région.",
                image: "https://images.unsplash.com/photo-1517694712202-14dd9538aa97?auto=format&fit=crop&w=600&q=80"
              },
              {
                id: "uk",
                title: "Université de Kara (UK)",
                city: "Kara, Togo",
                type: "Public",
                desc: "La deuxième université publique du pays, réputée pour ses filières agronomiques, littéraires et économiques.",
                image: "https://images.unsplash.com/photo-1562774053-701939374585?auto=format&fit=crop&w=600&q=80"
              },
              {
                id: "ucao",
                title: "UCAO - UUT",
                city: "Lomé, Togo",
                type: "Privé Confessionnel",
                desc: "L'Université Catholique de l'Afrique de l'Ouest, offrant un cadre strict et d'excellentes formations technologiques et juridiques.",
                image: "https://images.unsplash.com/photo-1523050854058-8df90110c9f1?auto=format&fit=crop&w=600&q=80"
              },
              {
                id: "esig",
                title: "ESIG Global Success",
                city: "Lomé, Togo",
                type: "Privé",
                desc: "Institut d'enseignement supérieur privé très dynamique, spécialisé en gestion, commerce et technologies de l'information.",
                image: "https://images.unsplash.com/photo-1555949963-ff9fe0c870eb?auto=format&fit=crop&w=600&q=80"
              }
            ].map((school) => (
              <a href={`/student/explorer/etablissement/${school.id}`} key={school.id} className="block outline-none">
                <Card variant="standard" className="flex flex-col h-full hover:border-primary/30 cursor-pointer group overflow-hidden">
                  {/* Image Banner */}
                  <div className="w-full h-40 overflow-hidden relative flex-shrink-0">
                    <div className="absolute inset-0 bg-black/10 group-hover:bg-transparent transition-colors z-10" />
                    <img src={school.image} alt={school.title} className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500" />
                  </div>
                  
                  {/* Content */}
                  <div className="p-5 flex flex-col flex-1">
                    <div className="flex justify-between items-start mb-3">
                      <span className={`text-[10px] uppercase font-bold px-2 py-1 rounded-sm ${school.type.includes('Public') ? 'text-primary bg-primary/10' : 'text-gold-dark bg-gold/20'}`}>
                        {school.type}
                      </span>
                    </div>
                    <h3 className="font-bold text-lg text-text-primary mb-1">{school.title}</h3>
                    <p className="text-xs text-text-secondary mb-4 flex items-center gap-1">
                      <MapPin className="w-3 h-3" /> {school.city}
                    </p>
                    <p className="text-sm text-text-secondary mb-6 line-clamp-2">
                      {school.desc}
                    </p>
                    <div className="mt-auto pt-2 flex items-center text-xs font-bold text-primary group-hover:underline">
                      Découvrir l'établissement <ArrowRight className="w-4 h-4 ml-1" />
                    </div>
                  </div>
                </Card>
              </a>
            ))}
          </>
        )}

        {activeTab === "formations" && (
          <div className="col-span-full flex flex-col gap-6">
            
            <div className="mb-2 p-4 bg-primary/5 rounded-xl border border-primary/20 flex gap-4 items-start">
              <div className="w-8 h-8 rounded-full bg-primary flex items-center justify-center text-white flex-shrink-0 mt-1">
                <Star className="w-4 h-4" />
              </div>
              <div>
                <h3 className="font-bold text-primary text-sm mb-1">Analyse de vos correspondances</h3>
                <p className="text-sm text-text-secondary leading-relaxed">
                  AÏDA a réorganisé cette liste en analysant vos résultats <strong>RIASEC (Investigateur)</strong>, vos compétences déclarées en <strong>informatique</strong>, et votre niveau actuel (Terminale). Les formations affichant une <strong>Forte correspondance</strong> sont celles qui s'alignent le plus avec vos caractéristiques actuelles.
                </p>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {[
                {
                  id: "ul-cyber",
                  title: "Licence Pro Sécurité Informatique",
                  duration: "3 ans",
                  match: "Forte correspondance",
                  reason: "Correspond à vos intérêts d'investigation et vos compétences tech.",
                  tags: ["Tech", "Cybersécurité"]
                },
                {
                  id: "iai-genie",
                  title: "Génie Logiciel",
                  duration: "3 ans",
                  match: "Forte correspondance",
                  reason: "Excellent alignement avec votre souhait d'analyse et de technologie.",
                  tags: ["Tech", "Développement"]
                },
                {
                  id: "ul-eco",
                  title: "Licence Économie et Gestion",
                  duration: "3 ans",
                  match: "Correspondance partielle",
                  reason: "Correspond à votre trait 'Entreprenant', mais s'éloigne de vos intérêts Tech.",
                  tags: ["Économie", "Gestion"]
                },
                {
                  id: "infa-agro",
                  title: "BTS Agriculture",
                  duration: "2 ans",
                  match: "Exploration libre",
                  reason: "Domaine différent de vos préférences actuelles, mais très porteur au Togo.",
                  tags: ["Agriculture", "Nature"]
                },
                {
                  id: "eamau-archi",
                  title: "Diplôme d'Architecte",
                  duration: "5 ans",
                  match: "Exploration libre",
                  reason: "Exige des compétences en dessin et conception non détectées dans votre profil.",
                  tags: ["Architecture", "Art"]
                }
              ].map((formation) => (
                <a href={`/student/explorer/formation/${formation.id}`} key={formation.id} className="block outline-none">
                  <Card variant="standard" className="p-5 flex flex-col h-full hover:border-primary/30 cursor-pointer group">
                    <div className="flex justify-between items-start mb-4">
                      <span className={`text-[10px] uppercase font-bold px-2 py-1 rounded-sm flex items-center gap-1 ${
                        formation.match === "Forte correspondance" 
                          ? "text-gold-dark bg-gold/20" 
                          : formation.match === "Correspondance partielle"
                          ? "text-primary bg-primary/10"
                          : "text-text-secondary bg-surface-alt"
                      }`}>
                        {formation.match === "Forte correspondance" && <Star className="w-3 h-3 fill-gold-dark" />}
                        {formation.match}
                      </span>
                    </div>
                    
                    <h3 className="font-bold text-lg text-text-primary mb-1">{formation.title}</h3>
                    <div className="flex flex-col gap-1 mb-4">
                      <span className="text-xs text-text-secondary flex items-center gap-1">
                        <Map className="w-3 h-3" /> Durée moyenne : {formation.duration}
                      </span>
                    </div>

                    <div className="mb-6 bg-surface-alt p-3 rounded-lg border border-border-soft flex-1">
                      <p className="text-xs text-text-secondary italic">
                        <strong className="text-text-primary font-bold not-italic">AÏDA :</strong> {formation.reason}
                      </p>
                    </div>

                    <div className="mt-auto pt-2 flex items-center text-xs font-bold text-primary group-hover:underline">
                      Détails et admission <ArrowRight className="w-4 h-4 ml-1" />
                    </div>
                  </Card>
                </a>
              ))}
            </div>
          </div>
        )}

        {activeTab === "domaines" && (
          <>
            {[
              {
                id: "tech-numerique",
                title: "Tech & Numérique",
                image: "https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=600&q=80",
                desc: "Développement, Cybersécurité, IA, Réseaux. Le moteur de l'innovation."
              },
              {
                id: "agro-industrie",
                title: "Agro-industrie",
                image: "https://images.unsplash.com/photo-1625246333195-78d9c38ad449?auto=format&fit=crop&w=600&q=80",
                desc: "Agriculture moderne, transformation alimentaire. Un secteur clé de notre économie."
              },
              {
                id: "btp-architecture",
                title: "BTP & Architecture",
                image: "https://images.unsplash.com/photo-1541888086925-0c13d4b4776e?auto=format&fit=crop&w=600&q=80",
                desc: "Construction, urbanisme, génie civil. Pour bâtir les villes de demain."
              },
              {
                id: "economie-bleue",
                title: "Économie Bleue & Logistique",
                image: "https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?auto=format&fit=crop&w=600&q=80",
                desc: "Commerce international, activités portuaires, douanes, transport."
              },
              {
                id: "sante",
                title: "Santé & Action Sociale",
                image: "https://images.unsplash.com/photo-1579684385127-1ef15d508118?auto=format&fit=crop&w=600&q=80",
                desc: "Médecine, soins infirmiers, pharmacie. Des métiers dédiés à l'humain."
              },
              {
                id: "energies",
                title: "Énergies Renouvelables",
                image: "https://images.unsplash.com/photo-1466611653911-95081537e5b7?auto=format&fit=crop&w=600&q=80",
                desc: "Solaire, éolien, efficacité énergétique. Les défis de la transition."
              }
            ].map((domaine) => (
              <a href={`/student/explorer/domaine/${domaine.id}`} key={domaine.id} className="block outline-none">
                <Card variant="standard" className="flex flex-col h-full hover:border-primary/30 cursor-pointer group overflow-hidden">
                  <div className="w-full h-40 overflow-hidden relative flex-shrink-0">
                    <div className="absolute inset-0 bg-black/30 group-hover:bg-black/10 transition-colors z-10" />
                    <img src={domaine.image} alt={domaine.title} className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500" />
                    <div className="absolute bottom-4 left-4 z-20">
                      <h3 className="font-display font-bold text-xl text-white drop-shadow-md">{domaine.title}</h3>
                    </div>
                  </div>
                  <div className="p-4 flex flex-col flex-1">
                    <p className="text-sm text-text-secondary mb-4">
                      {domaine.desc}
                    </p>
                    <div className="mt-auto flex items-center text-xs font-bold text-primary group-hover:underline">
                      Explorer ce domaine <ArrowRight className="w-4 h-4 ml-1" />
                    </div>
                  </div>
                </Card>
              </a>
            ))}
          </>
        )}

        {/* End of tabs */}

      </div>
    </div>
  );
}
