"use client";

import React from "react";
import { ArrowLeft, ArrowRight, Building2, MapPin, GraduationCap, CheckCircle2, Clock, Wallet, ShieldCheck, Briefcase } from "lucide-react";
import Link from "next/link";
import { AidaAssistant } from "@/components/student/AidaAssistant";
import { Card } from "@/components/ui/Card";

export default function FormationPage({ params }: { params: Promise<{ id: string }> }) {
  const unwrappedParams = React.use(params);
  
  // Mock data mapping
  const formationsDb: Record<string, any> = {
    "ul-cyber": {
      title: "Licence Pro Sécurité Informatique",
      domain: "Tech & Numérique",
      bannerImage: "https://images.unsplash.com/photo-1541339907198-e08756dedf3f?auto=format&fit=crop&w=1200&q=80",
      description: "Cette licence professionnelle vise à former des techniciens supérieurs et de futurs ingénieurs capables de sécuriser les infrastructures réseaux et de protéger les données des entreprises face aux cybermenaces.",
      level: "Licence (Bac+3)",
      duration: "3 ans (6 semestres)",
      admission: "Baccalauréat séries C, D, F2, E ou équivalent. Sélection sur dossier puis concours écrit.",
      status: "Diplôme National / Reconnu CAMES",
      program: [
        "Algorithmique et Programmation",
        "Réseaux et Télécommunications",
        "Cryptographie appliquée",
        "Administration système (Linux/Windows)",
        "Droit de l'informatique",
        "Audit de sécurité et Pentesting"
      ],
      jobs: ["Ingénieur Cybersécurité", "Administrateur Réseaux", "Analyste SOC"],
      schoolsList: [
        { name: "Université de Lomé (UL)", city: "Lomé, Togo" },
        { name: "Institut Africain d'Informatique (IAI)", city: "Lomé, Togo" },
        { name: "IPNET Institute of Technology", city: "Lomé, Togo" }
      ]
    },
    "iai-genie": {
      title: "Génie Logiciel",
      domain: "Tech & Numérique",
      bannerImage: "https://images.unsplash.com/photo-1517694712202-14dd9538aa97?auto=format&fit=crop&w=1200&q=80",
      description: "La filière Génie Logiciel prépare à la conception, au développement et à la maintenance d'applications informatiques complexes (Web, Mobile, Logiciels d'entreprise).",
      level: "Licence / Ingénieur (Bac+3 / Bac+5)",
      duration: "3 à 5 ans",
      admission: "Ouvert aux bacheliers scientifiques (C, D, E, F2, F3). Concours ou sélection sur dossier.",
      status: "Reconnu par l'État / CAMES",
      program: [
        "Programmation Orientée Objet (Java, C++)",
        "Génie Logiciel et UML",
        "Bases de données avancées",
        "Développement Web & Mobile",
        "Intelligence Artificielle"
      ],
      jobs: ["Data Analyst", "Ingénieur Cybersécurité", "Développeur Full-Stack"],
      schoolsList: [
        { name: "Institut Africain d'Informatique (IAI)", city: "Lomé, Togo" },
        { name: "EPL - Université de Lomé", city: "Lomé, Togo" },
        { name: "ESIG Global Success", city: "Lomé, Togo" }
      ]
    },
    "ul-eco": {
      title: "Licence Économie et Gestion",
      domain: "Économie & Finance",
      bannerImage: "https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?auto=format&fit=crop&w=1200&q=80",
      description: "Une formation théorique et pratique solide pour comprendre les mécanismes économiques mondiaux, la gestion des entreprises et les finances publiques.",
      level: "Licence (Bac+3)",
      duration: "3 ans",
      admission: "Baccalauréat séries G2, G3, C, D.",
      status: "Diplôme d'État",
      program: ["Microéconomie", "Macroéconomie", "Comptabilité générale", "Mathématiques financières", "Marketing"],
      jobs: ["Économiste", "Auditeur financier", "Entrepreneur"],
      schoolsList: [
        { name: "FASEG - Université de Lomé", city: "Lomé, Togo" },
        { name: "FASEG - Université de Kara", city: "Kara, Togo" },
        { name: "IAEC", city: "Lomé, Togo" }
      ]
    },
    "infa-agro": {
      title: "BTS Agriculture",
      domain: "Agro-industrie",
      bannerImage: "https://images.unsplash.com/photo-1625246333195-78d9c38ad449?auto=format&fit=crop&w=1200&q=80",
      description: "Formation pratique pour devenir un cadre agricole opérationnel. Ce BTS permet une insertion rapide dans un secteur clé de l'économie togolaise.",
      level: "BTS (Bac+2)",
      duration: "2 ans",
      admission: "Baccalauréat scientifique ou technique, ou diplôme de Brevet de Technicien (BT) agricole.",
      status: "Diplôme d'État",
      program: ["Agronomie générale", "Zootechnie", "Mécanisme agricole", "Gestion d'exploitation agricole", "Phytopathologie"],
      jobs: ["Ingénieur Agronome", "Chef d'exploitation", "Technicien agricole"],
      schoolsList: [
        { name: "Institut National de Formation Agricole (INFA) de Tové", city: "Kpalimé, Togo" },
        { name: "CFA d'Adidogomé", city: "Lomé, Togo" }
      ]
    },
    "eamau-archi": {
      title: "Diplôme d'Architecte",
      domain: "BTP & Architecture",
      bannerImage: "https://images.unsplash.com/photo-1503387762-592deb58ef4e?auto=format&fit=crop&w=1200&q=80",
      description: "Formation d'excellence préparant les futurs bâtisseurs et urbanistes capables de concevoir des espaces urbains durables en Afrique.",
      level: "Master / Diplôme d'Architecte (Bac+5)",
      duration: "5 ans",
      admission: "Concours (mathématiques, dessin, culture générale) ouvert aux Bac C, D, E, F4.",
      status: "Reconnu par l'UIA et le CAMES",
      program: ["Atelier d'Architecture", "Histoire de l'Art", "Statique et RDM", "Urbanisme", "CAO / DAO"],
      jobs: ["Architecte DPLG", "Urbaniste", "Chef de projet BTP"],
      schoolsList: [
        { name: "École Africaine des Métiers de l'Architecture et de l'Urbanisme (EAMAU)", city: "Lomé, Togo" },
        { name: "FORMATEC", city: "Lomé, Togo" }
      ]
    }
  };

  const formation = formationsDb[unwrappedParams.id] || {
    title: "Formation Inconnue",
    domain: "Domaine",
    bannerImage: "https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=1200&q=80",
    description: "Description de la formation introuvable.",
    level: "Bac+3",
    duration: "3 ans",
    admission: "Sur dossier",
    status: "Non communiqué",
    program: ["Module 1", "Module 2"],
    jobs: [],
    schoolsList: []
  };

  return (
    <div className="flex flex-col gap-6 -mt-4 md:-mt-8 -mx-4 md:-mx-8">
      
      {/* FULL WIDTH BANNER */}
      <div className="relative w-full h-[35dvh] md:h-[45dvh] bg-black overflow-hidden">
        <img 
          src={formation.bannerImage} 
          alt={formation.title} 
          className="w-full h-full object-cover opacity-60" 
        />
        
        <div className="absolute top-4 left-4 md:top-8 md:left-8 z-20">
          <Link href="/student/explorer" className="inline-flex items-center gap-2 text-sm font-bold text-white bg-black/40 hover:bg-black/60 px-4 py-2 rounded-full backdrop-blur-sm transition-colors">
            <ArrowLeft className="w-4 h-4" /> Retour à l'exploration
          </Link>
        </div>

        <div className="absolute bottom-0 left-0 w-full p-6 md:p-10 bg-gradient-to-t from-canvas via-canvas/80 to-transparent">
          <span className="text-[10px] md:text-xs uppercase font-bold text-primary bg-primary/10 backdrop-blur-md px-3 py-1.5 rounded-sm mb-3 inline-block">
            {formation.domain}
          </span>
          <h1 className="font-display font-bold text-3xl md:text-5xl text-text-primary mb-2">
            {formation.title}
          </h1>
        </div>
      </div>

      <div className="max-w-5xl mx-auto w-full px-4 md:px-8 pb-12 flex flex-col lg:flex-row gap-8">
        
        {/* MAIN COLUMN */}
        <div className="flex-1 flex flex-col gap-8">
          
          <section>
            <h2 className="text-xl font-bold text-text-primary mb-4">À propos de cette formation</h2>
            <p className="text-text-secondary leading-relaxed">
              {formation.description}
            </p>
          </section>

          {/* QUICK FACTS GRID */}
          <section className="grid grid-cols-2 md:grid-cols-3 gap-4">
            <Card variant="standard" className="p-4 flex flex-col gap-1 bg-surface-alt">
              <GraduationCap className="w-5 h-5 text-primary mb-1" />
              <span className="text-[10px] uppercase font-bold text-text-secondary">Niveau Visé</span>
              <span className="text-sm font-medium text-text-primary">{formation.level}</span>
            </Card>
            <Card variant="standard" className="p-4 flex flex-col gap-1 bg-surface-alt">
              <Clock className="w-5 h-5 text-primary mb-1" />
              <span className="text-[10px] uppercase font-bold text-text-secondary">Durée Moyenne</span>
              <span className="text-sm font-medium text-text-primary">{formation.duration}</span>
            </Card>
            <Card variant="standard" className="p-4 flex flex-col gap-1 bg-surface-alt">
              <ShieldCheck className="w-5 h-5 text-primary mb-1" />
              <span className="text-[10px] uppercase font-bold text-text-secondary">Nature du Diplôme</span>
              <span className="text-sm font-medium text-text-primary">{formation.status}</span>
            </Card>
          </section>

          <section>
            <h2 className="text-xl font-bold text-text-primary mb-4">Conditions d'admission (Générales)</h2>
            <div className="p-5 bg-surface border border-border-soft rounded-xl text-text-secondary text-sm leading-relaxed">
              {formation.admission}
            </div>
          </section>

          <section>
            <h2 className="text-xl font-bold text-text-primary mb-4">Programme indicatif</h2>
            <div className="flex flex-wrap gap-2">
              {formation.program.map((moduleItem: string, i: number) => (
                <span key={i} className="px-3 py-1.5 bg-surface border border-border-soft rounded-md text-sm font-medium text-text-secondary flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-primary" /> {moduleItem}
                </span>
              ))}
            </div>
          </section>

          <section className="mt-4">
            <h2 className="text-xl font-bold text-text-primary mb-4 flex items-center gap-2">
              <Building2 className="w-6 h-6 text-primary" />
              Établissements proposant cette formation
            </h2>
            <p className="text-sm text-text-secondary mb-6">
              Voici une liste d'écoles, universités et centres de formation partenaires ou reconnus offrant ce cursus.
            </p>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {formation.schoolsList.map((school: any, i: number) => (
                <Card key={i} variant="standard" className="p-4 hover:border-primary/30 cursor-pointer group">
                  <div className="flex gap-4 items-center">
                    <div className="w-12 h-12 rounded-lg bg-primary/10 text-primary flex items-center justify-center flex-shrink-0">
                      <Building2 className="w-6 h-6" />
                    </div>
                    <div>
                      <h3 className="font-bold text-text-primary text-sm group-hover:text-primary transition-colors">{school.name}</h3>
                      <div className="flex items-center gap-1 text-xs text-text-secondary mt-1">
                        <MapPin className="w-3 h-3" /> {school.city}
                      </div>
                    </div>
                  </div>
                </Card>
              ))}
            </div>
          </section>

        </div>

        {/* RIGHT COLUMN (AÏDA + Débouchés) */}
        <div className="w-full lg:w-96 flex flex-col gap-6">
          
          <AidaAssistant 
            title="Pourquoi cette formation peut vous convenir"
            message={`D'après les analyses de la plateforme, ce parcours fait écho à votre profil d'Investigateur. Les modules comme l'Algorithmique et la Programmation mobiliseront vos compétences analytiques.`}
            variant="floating"
            actionLabel="Ajouter à mon projet"
            actionHref="#"
          />

          <Card variant="standard" className="p-6">
            <h2 className="font-bold text-text-primary mb-4 flex items-center gap-2">
              <Briefcase className="w-5 h-5 text-gold-dark" />
              Débouchés professionnels
            </h2>
            <p className="text-xs text-text-secondary mb-4">
              Voici les métiers auxquels cette formation vous prépare directement :
            </p>
            
            <div className="flex flex-col gap-2">
              {formation.jobs.map((job: string, i: number) => (
                <div key={i} className="flex items-center gap-2 p-3 bg-surface-alt border border-border-soft rounded-md group cursor-pointer hover:border-gold/30 transition-colors">
                  <ArrowRight className="w-4 h-4 text-gold-dark" />
                  <span className="text-sm font-bold text-text-primary group-hover:text-gold-dark transition-colors">{job}</span>
                </div>
              ))}
            </div>
          </Card>

        </div>

      </div>
    </div>
  );
}
