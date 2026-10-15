"use client";

import React from "react";
import { ArrowLeft, MapPin, Calendar, Clock, Users, ExternalLink, Ticket, CheckCircle2 } from "lucide-react";
import Link from "next/link";
import { Card } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";

export default function EvenementPage({ params }: { params: Promise<{ id: string }> }) {
  const unwrappedParams = React.use(params);
  
  const evenementsDb: Record<string, any> = {
    "salon-orientation-lome": {
      title: "Salon de l'Orientation Universitaire de Lomé",
      organizer: "Ministère de l'Enseignement Supérieur",
      image: "https://images.unsplash.com/photo-1540575467063-178a50c2df87?auto=format&fit=crop&w=1200&q=80",
      description: "Le plus grand rendez-vous de l'orientation post-bac au Togo. Venez rencontrer les représentants de plus de 40 universités, grandes écoles et centres de formation technique. C'est l'occasion idéale pour poser vos questions, découvrir des filières méconnues et préparer votre dossier d'inscription.",
      dateFull: "Jeudi 15 Octobre 2026",
      time: "De 09:00 à 17:00",
      location: "CETEF Togo 2000 (Pavillon Oti), Lomé",
      type: "Présentiel",
      price: "Gratuit sur inscription",
      program: [
        "09h00 : Cérémonie d'ouverture",
        "10h00 - 12h00 : Conférence sur les métiers d'avenir (Tech & Agro)",
        "13h00 - 17h00 : Visite libre des stands et rencontres B2B",
        "15h00 : Atelier pratique de rédaction de CV"
      ],
      guests: ["Dr. Kossi (Université de Lomé)", "Mme. Mensah (Directrice RH Togocom)"]
    },
    "webinaire-aida-cv": {
      title: "Webinaire AÏDA : Réussir son CV d'étudiant",
      organizer: "L'équipe ActivEducation",
      image: "https://images.unsplash.com/photo-1516321318423-f06f85e504b3?auto=format&fit=crop&w=1200&q=80",
      description: "Vous n'avez pas encore d'expérience professionnelle et vous ne savez pas quoi mettre dans votre CV ? Ce webinaire est fait pour vous. Apprenez comment valoriser vos projets scolaires, votre engagement associatif et vos compétences douces (soft skills) pour décrocher votre premier stage.",
      dateFull: "Lundi 02 Novembre 2026",
      time: "15:00 - 16:30 (Heure de Lomé)",
      location: "En ligne (Lien Google Meet envoyé après inscription)",
      type: "En ligne (Webinaire)",
      price: "Gratuit",
      program: [
        "15h00 : Accueil et introduction",
        "15h10 : Les 5 règles d'or d'un CV junior",
        "15h40 : Étude de cas (Analyse de bons et mauvais CV)",
        "16h10 : Session Questions/Réponses en direct"
      ],
      guests: ["Coach AÏDA (Orientation)", "Expert RH Partenaire"]
    }
  };

  const evenement = evenementsDb[unwrappedParams.id] || {
    title: "Événement Non Trouvé",
    organizer: "Inconnu",
    image: "https://images.unsplash.com/photo-1540575467063-178a50c2df87?auto=format&fit=crop&w=1200&q=80",
    description: "Les informations pour cet événement ne sont pas disponibles.",
    dateFull: "N/A",
    time: "N/A",
    location: "N/A",
    type: "N/A",
    price: "N/A",
    program: [],
    guests: []
  };

  return (
    <div className="flex flex-col gap-6 -mt-4 md:-mt-8 -mx-4 md:-mx-8">
      
      {/* FULL WIDTH BANNER */}
      <div className="relative w-full h-[30dvh] md:h-[40dvh] bg-surface-alt overflow-hidden">
        <img 
          src={evenement.image} 
          alt={evenement.title} 
          className="w-full h-full object-cover" 
        />
        
        <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/40 to-black/10" />

        <div className="absolute top-4 left-4 md:top-8 md:left-8 z-20">
          <Link href="/student/opportunites" className="inline-flex items-center gap-2 text-sm font-bold text-white bg-black/30 hover:bg-black/50 px-4 py-2 rounded-full backdrop-blur-sm transition-colors">
            <ArrowLeft className="w-4 h-4" /> Retour aux opportunités
          </Link>
        </div>

        <div className="absolute bottom-0 left-0 w-full p-6 md:p-10 z-20">
          <div className="flex items-center gap-2 mb-3">
            <span className="text-[10px] md:text-xs uppercase font-bold text-primary bg-primary/10 backdrop-blur-md px-3 py-1.5 rounded-full flex items-center gap-1">
              <Calendar className="w-3 h-3" /> {evenement.type}
            </span>
          </div>
          <h1 className="font-display font-bold text-2xl md:text-5xl text-white mb-2 drop-shadow-md">
            {evenement.title}
          </h1>
          <p className="text-white/80 font-medium text-sm md:text-base">Organisé par : <strong>{evenement.organizer}</strong></p>
        </div>
      </div>

      <div className="max-w-5xl mx-auto w-full px-4 md:px-8 pb-12 flex flex-col lg:flex-row gap-8">
        
        {/* MAIN COLUMN */}
        <div className="flex-1 flex flex-col gap-8">
          
          <section className="bg-surface p-6 md:p-8 rounded-2xl border border-border-soft shadow-sm">
            <h2 className="text-xl font-bold text-text-primary mb-4">À propos de cet événement</h2>
            <p className="text-text-secondary leading-relaxed mb-8">
              {evenement.description}
            </p>

            <h3 className="font-bold text-text-primary mb-4 flex items-center gap-2">
              <CheckCircle2 className="w-5 h-5 text-primary" /> Programme
            </h3>
            <div className="flex flex-col gap-3">
              {evenement.program.map((item: string, i: number) => {
                const [time, desc] = item.includes(":") ? item.split(" : ") : ["", item];
                return (
                  <div key={i} className="flex gap-4 p-3 bg-surface-alt rounded-lg border border-border-soft items-center">
                    {time && <span className="font-display font-bold text-primary flex-shrink-0 w-16">{time}</span>}
                    <span className="text-sm text-text-secondary">{desc}</span>
                  </div>
                );
              })}
            </div>
          </section>

        </div>

        {/* SIDEBAR (TICKET INFO) */}
        <div className="w-full lg:w-80 flex flex-col gap-4">
          <Card variant="standard" className="p-6 border-primary/20 sticky top-24">
            <h3 className="font-bold text-text-primary mb-6 flex items-center gap-2">
              <Ticket className="w-5 h-5 text-primary" /> Informations Pratiques
            </h3>
            
            <div className="flex flex-col gap-5 mb-8">
              <div className="flex gap-3 items-start">
                <Calendar className="w-5 h-5 text-text-tertiary flex-shrink-0 mt-0.5" />
                <div>
                  <p className="text-[10px] uppercase font-bold text-text-secondary">Date</p>
                  <p className="font-bold text-sm text-text-primary">{evenement.dateFull}</p>
                </div>
              </div>
              
              <div className="flex gap-3 items-start">
                <Clock className="w-5 h-5 text-text-tertiary flex-shrink-0 mt-0.5" />
                <div>
                  <p className="text-[10px] uppercase font-bold text-text-secondary">Heure</p>
                  <p className="font-bold text-sm text-text-primary">{evenement.time}</p>
                </div>
              </div>

              <div className="flex gap-3 items-start">
                <MapPin className="w-5 h-5 text-text-tertiary flex-shrink-0 mt-0.5" />
                <div>
                  <p className="text-[10px] uppercase font-bold text-text-secondary">Lieu</p>
                  <p className="font-bold text-sm text-text-primary">{evenement.location}</p>
                </div>
              </div>

              <div className="flex gap-3 items-start">
                <Ticket className="w-5 h-5 text-text-tertiary flex-shrink-0 mt-0.5" />
                <div>
                  <p className="text-[10px] uppercase font-bold text-text-secondary">Tarif</p>
                  <p className="font-bold text-sm text-text-primary text-gold-dark">{evenement.price}</p>
                </div>
              </div>
            </div>

            <Button size="lg" className="w-full">
              Réserver ma place
            </Button>
          </Card>
        </div>

      </div>
    </div>
  );
}
