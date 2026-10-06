"use client";

import React from "react";
import { ArrowLeft, MapPin, Building2, Wifi, BookOpen, GraduationCap, Briefcase, Star, Users, CheckCircle2 } from "lucide-react";
import Link from "next/link";
import { Card } from "@/components/ui/Card";

export default function EtablissementPage({ params }: { params: Promise<{ id: string }> }) {
  const unwrappedParams = React.use(params);
  
  // Mock data mapping
  const schoolsDb: Record<string, any> = {
    "ul": {
      title: "Université de Lomé (UL)",
      type: "Public",
      city: "Lomé, Togo",
      bannerImage: "https://images.unsplash.com/photo-1541339907198-e08756dedf3f?auto=format&fit=crop&w=1200&q=80",
      description: "Créée en 1970, l'Université de Lomé est le plus grand pôle d'enseignement supérieur et de recherche du Togo. Elle offre un environnement d'apprentissage dynamique avec de multiples facultés, écoles et instituts couvrant la quasi-totalité des domaines du savoir.",
      insertionRate: "72%",
      rating: "4.1",
      reviewsCount: 1245,
      facilities: ["Bibliothèque Universitaire (BU)", "Campus numérique", "Restaurant universitaire", "Centres médico-sociaux", "Terrains de sport"],
      formations: [
        { id: "ul-cyber", title: "Licence Pro Sécurité Informatique", level: "Bac+3" },
        { id: "ul-eco", title: "Licence Économie et Gestion", level: "Bac+3" },
        { id: "ul-med", title: "Doctorat en Médecine", level: "Bac+7" }
      ]
    },
    "eamau": {
      title: "EAMAU",
      type: "Public (Inter-états)",
      city: "Lomé, Togo",
      bannerImage: "https://images.unsplash.com/photo-1503387762-592deb58ef4e?auto=format&fit=crop&w=1200&q=80",
      description: "L'École Africaine des Métiers de l'Architecture et de l'Urbanisme est une institution d'enseignement supérieur inter-états. Elle forme l'élite des architectes, urbanistes et gestionnaires urbains pour 14 pays d'Afrique francophone.",
      insertionRate: "89%",
      rating: "4.7",
      reviewsCount: 342,
      facilities: ["Ateliers de maquettes", "Salles DAO/CAO", "Bibliothèque spécialisée", "Laboratoire d'essais des matériaux"],
      formations: [
        { id: "eamau-archi", title: "Diplôme d'Architecte", level: "Bac+5" },
        { id: "eamau-urb", title: "Master Urbanisme", level: "Bac+5" }
      ]
    },
    "iai": {
      title: "IAI Togo",
      type: "Public (Inter-états)",
      city: "Lomé, Togo",
      bannerImage: "https://images.unsplash.com/photo-1517694712202-14dd9538aa97?auto=format&fit=crop&w=1200&q=80",
      description: "L'Institut Africain d'Informatique, Représentation du Togo, est reconnu pour l'excellence de ses formations en informatique. Ses diplômés sont parmi les plus recherchés par les banques, télécoms et startups de la sous-région.",
      insertionRate: "94%",
      rating: "4.5",
      reviewsCount: 512,
      facilities: ["Salles machines haute performance", "Connexion Fibre Optique", "Incubateur de startups", "Certifications internationales (Cisco, Oracle)"],
      formations: [
        { id: "iai-genie", title: "Génie Logiciel", level: "Bac+3 / Bac+5" },
        { id: "iai-sr", title: "Réseaux et Systèmes", level: "Bac+3" }
      ]
    }
  };

  const school = schoolsDb[unwrappedParams.id] || {
    title: "Établissement",
    type: "Type non spécifié",
    city: "Ville, Pays",
    bannerImage: "https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=1200&q=80",
    description: "Cet établissement n'a pas encore renseigné sa description détaillée sur ActivEducation.",
    insertionRate: "Non communiqué",
    rating: "0.0",
    reviewsCount: 0,
    facilities: ["Infrastructures non communiquées"],
    formations: []
  };

  return (
    <div className="flex flex-col gap-6 -mt-4 md:-mt-8 -mx-4 md:-mx-8">
      
      {/* FULL WIDTH BANNER */}
      <div className="relative w-full h-[35dvh] md:h-[45dvh] bg-black overflow-hidden">
        <img 
          src={school.bannerImage} 
          alt={school.title} 
          className="w-full h-full object-cover opacity-50" 
        />
        
        <div className="absolute top-4 left-4 md:top-8 md:left-8 z-20">
          <Link href="/student/explorer" className="inline-flex items-center gap-2 text-sm font-bold text-white bg-black/40 hover:bg-black/60 px-4 py-2 rounded-full backdrop-blur-sm transition-colors">
            <ArrowLeft className="w-4 h-4" /> Retour à l'exploration
          </Link>
        </div>

        <div className="absolute bottom-0 left-0 w-full p-6 md:p-10 bg-gradient-to-t from-canvas via-canvas/80 to-transparent flex flex-col md:flex-row md:items-end justify-between gap-4">
          <div>
            <span className={`text-[10px] md:text-xs uppercase font-bold px-3 py-1.5 rounded-sm mb-3 inline-block backdrop-blur-md ${school.type.includes('Public') ? 'text-primary bg-primary/20' : 'text-gold-dark bg-gold/20'}`}>
              {school.type}
            </span>
            <h1 className="font-display font-bold text-3xl md:text-5xl text-text-primary mb-2">
              {school.title}
            </h1>
            <div className="flex items-center gap-2 text-text-secondary font-medium">
              <MapPin className="w-5 h-5 text-primary" />
              <span className="text-lg">{school.city}</span>
            </div>
          </div>
          
          <div className="flex gap-4">
            <div className="bg-surface/90 backdrop-blur-md px-4 py-3 rounded-xl border border-border-soft flex flex-col items-center">
              <span className="text-xs text-text-secondary font-bold uppercase mb-1">Insertion Pro</span>
              <span className="text-xl font-display font-bold text-gold-dark">{school.insertionRate}</span>
            </div>
            <div className="bg-surface/90 backdrop-blur-md px-4 py-3 rounded-xl border border-border-soft flex flex-col items-center">
              <span className="text-xs text-text-secondary font-bold uppercase mb-1">Avis (Global)</span>
              <div className="flex items-center gap-1 text-xl font-display font-bold text-primary">
                {school.rating} <Star className="w-4 h-4 fill-primary" />
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-5xl mx-auto w-full px-4 md:px-8 pb-12 flex flex-col lg:flex-row gap-8">
        
        {/* MAIN COLUMN */}
        <div className="flex-1 flex flex-col gap-8">
          
          <section>
            <h2 className="text-xl font-bold text-text-primary mb-4">À propos de l'établissement</h2>
            <p className="text-text-secondary leading-relaxed">
              {school.description}
            </p>
          </section>

          <section>
            <h2 className="text-xl font-bold text-text-primary mb-4 flex items-center gap-2">
              <GraduationCap className="w-6 h-6 text-primary" />
              Formations proposées
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {school.formations.length > 0 ? school.formations.map((form: any, i: number) => (
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
                  Aucune formation n'a été spécifiquement rattachée à cet établissement pour le moment.
                </div>
              )}
            </div>
          </section>

        </div>

        {/* RIGHT COLUMN (Infrastructures) */}
        <div className="w-full lg:w-80 flex flex-col gap-6">
          
          <Card variant="standard" className="p-6">
            <h2 className="font-bold text-text-primary mb-4 flex items-center gap-2">
              <Building2 className="w-5 h-5 text-primary" />
              Infrastructures
            </h2>
            <div className="flex flex-col gap-3">
              {school.facilities.map((fac: string, i: number) => (
                <div key={i} className="flex items-start gap-3">
                  <CheckCircle2 className="w-4 h-4 text-primary flex-shrink-0 mt-0.5" />
                  <span className="text-sm text-text-secondary leading-tight">{fac}</span>
                </div>
              ))}
            </div>
          </Card>

          <Card variant="standard" className="p-6 bg-primary/5 border-primary/20">
            <h2 className="font-bold text-text-primary mb-2 flex items-center gap-2">
              <Users className="w-5 h-5 text-primary" />
              Parole d'étudiants
            </h2>
            <div className="flex items-end gap-2 mb-2">
              <span className="text-3xl font-display font-bold text-text-primary">{school.rating}</span>
              <span className="text-sm text-text-secondary mb-1">/ 5</span>
            </div>
            <div className="flex gap-1 mb-3">
              {[1, 2, 3, 4, 5].map((star) => (
                <Star key={star} className={`w-4 h-4 ${star <= Math.round(school.rating) ? 'fill-primary text-primary' : 'fill-border-soft text-border-soft'}`} />
              ))}
            </div>
            <p className="text-xs text-text-secondary">
              Basé sur <strong>{school.reviewsCount} avis</strong> certifiés. Note agrégée incluant la qualité des cours, la vie étudiante et l'insertion professionnelle.
            </p>
          </Card>

        </div>

      </div>
    </div>
  );
}
