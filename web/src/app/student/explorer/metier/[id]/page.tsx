"use client";

import React from "react";
import { ArrowLeft, CheckCircle2, Building2, MapPin, Sparkles, GraduationCap } from "lucide-react";
import Link from "next/link";
import { AidaAssistant } from "@/components/student/AidaAssistant";
import { Card } from "@/components/ui/Card";

export default function MetierPage({ params }: { params: Promise<{ id: string }> }) {
  const unwrappedParams = React.use(params);
  
  // Mock data mapping
  const metiersDb: Record<string, any> = {
    "cybersecurite": {
      title: "Ingénieur Cybersécurité",
      domain: "Tech & Numérique",
      bannerImage: "https://images.unsplash.com/photo-1555949963-ff9fe0c870eb?auto=format&fit=crop&w=1200&q=80",
      description: "L'ingénieur en cybersécurité est le bouclier numérique d'une entreprise. Il analyse les failles de sécurité, met en place des protections robustes, et intervient en cas d'attaque informatique pour protéger les données sensibles. Avec la digitalisation croissante des banques et institutions au Togo et dans la sous-région, c'est un métier d'avenir incontournable.",
      skills: ["Analyse de risques", "Réseaux informatiques", "Cryptographie", "Résolution de problèmes", "Veille technologique"],
      formations: [
        { name: "Licence Pro Sécurité Informatique", school: "Université de Lomé", duration: "3 ans" },
        { name: "Master Cybersécurité", school: "Institut Africain d'Informatique (IAI)", duration: "2 ans post-licence" }
      ],
      opportunities: ["Analyste SOC", "Auditeur de sécurité", "Consultant Cyber"]
    },
    "agronome": {
      title: "Ingénieur Agronome",
      domain: "Agro-industrie",
      bannerImage: "https://images.unsplash.com/photo-1592982537447-7440770cbfc9?auto=format&fit=crop&w=1200&q=80",
      description: "Spécialiste des sciences de la vie et de la terre, l'ingénieur agronome optimise la production agricole tout en préservant l'environnement. Le secteur agricole représentant une part majeure de l'économie togolaise, cet ingénieur est vital pour assurer la sécurité alimentaire et l'innovation agro-industrielle.",
      skills: ["Sciences du vivant", "Gestion de projet", "Conscience écologique", "Analyse de sols", "Techniques d'irrigation"],
      formations: [
        { name: "Diplôme d'Ingénieur Agronome", school: "École Supérieure d'Agronomie (ESA) de l'UL", duration: "5 ans" },
        { name: "Licence en Sciences Agronomiques", school: "Université de Kara", duration: "3 ans" }
      ],
      opportunities: ["Chef d'exploitation", "Conseiller agricole", "Directeur de coopérative"]
    },
    "data-analyst": {
      title: "Data Analyst",
      domain: "Tech & Numérique",
      bannerImage: "https://images.unsplash.com/photo-1551288049-bebda4e38f71?auto=format&fit=crop&w=1200&q=80",
      description: "Le Data Analyst traduit des chiffres en décisions stratégiques. Il recueille, nettoie et étudie de vastes ensembles de données pour aider les entreprises (startups, banques, télécoms) à mieux comprendre leurs clients et optimiser leurs opérations.",
      skills: ["Statistiques", "SQL / Python", "Data Visualisation (PowerBI, Tableau)", "Esprit de synthèse", "Sens business"],
      formations: [
        { name: "Licence en Statistique et Informatique Décisionnelle", school: "Université de Lomé", duration: "3 ans" },
        { name: "Formation intensive Data", school: "Centres de formation spécialisés", duration: "6 à 12 mois" }
      ],
      opportunities: ["Analyste de Données", "Business Analyst", "Data Consultant"]
    },
    "energies-renouvelables": {
      title: "Technicien Énergies Renouvelables",
      domain: "Énergie",
      bannerImage: "https://images.unsplash.com/photo-1509391366360-2e959784a276?auto=format&fit=crop&w=1200&q=80",
      description: "Face aux défis climatiques et énergétiques, ce technicien conçoit, installe et maintient des systèmes d'énergie verte (panneaux solaires, éoliennes, biomasse). C'est un marché en pleine explosion en Afrique de l'Ouest pour électrifier les zones rurales et urbaines.",
      skills: ["Électrotechnique", "Énergies solaires", "Maintenance industrielle", "Habilitations électriques", "Sens du terrain"],
      formations: [
        { name: "BTS Énergies Renouvelables", school: "Lycées Techniques / INFA de Tové", duration: "2 ans" },
        { name: "Licence Pro Énergies Renouvelables", school: "Université de Lomé", duration: "3 ans" }
      ],
      opportunities: ["Installateur Solaire", "Chef de chantier EnR", "Technicien de Maintenance"]
    },
    "logistique": {
      title: "Responsable Logistique",
      domain: "Transport",
      bannerImage: "https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?auto=format&fit=crop&w=1200&q=80",
      description: "Le chef d'orchestre des marchandises. Il gère l'ensemble des flux (stockage, transport, livraison) depuis le fournisseur jusqu'au client. Avec le Port Autonome de Lomé qui est un hub majeur de la sous-région, ce métier est essentiel et extrêmement recherché.",
      skills: ["Supply Chain", "Gestion des stocks", "Management d'équipe", "Réglementation douanière", "Logiciels ERP"],
      formations: [
        { name: "Licence Transport et Logistique", school: "Écoles de Commerce (Lomé)", duration: "3 ans" },
        { name: "Master Supply Chain Management", school: "Instituts Supérieurs Privés", duration: "2 ans post-licence" }
      ],
      opportunities: ["Supply Chain Manager", "Responsable d'Entrepôt", "Déclarant en douane"]
    },
    "esante": {
      title: "Spécialiste E-Santé",
      domain: "Santé",
      bannerImage: "https://images.unsplash.com/photo-1576091160550-2173dba999ef?auto=format&fit=crop&w=1200&q=80",
      description: "Ce professionnel évolue à la croisée du domaine médical et du numérique. Il conçoit, déploie ou gère des solutions de télémédecine, des applications de suivi de santé ou des bases de données médicales informatisées, facilitant l'accès aux soins pour tous.",
      skills: ["Connaissances médicales", "Gestion de projet IT", "Réglementation des données de santé", "Empathie", "Innovation"],
      formations: [
        { name: "Double compétence : Santé publique + Master Informatique", school: "FSS & FDS - Université de Lomé", duration: "Varie" },
        { name: "Formations certifiantes en Informatique Médicale", school: "Partenariats Internationaux", duration: "1 an" }
      ],
      opportunities: ["Chef de projet Télémédecine", "Consultant e-Santé", "Responsable SI Hospitalier"]
    }
  };

  const metier = metiersDb[unwrappedParams.id] || {
    title: "Titre du Métier",
    domain: "Domaine",
    bannerImage: "https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=1200&q=80",
    description: "Une description détaillée de ce métier et de ses enjeux, particulièrement dans le contexte togolais et africain. Ce professionnel joue un rôle clé dans son secteur.",
    skills: ["Compétence 1", "Compétence 2", "Compétence 3"],
    formations: [{ name: "Formation Type", school: "Établissement", duration: "3 ans" }],
    opportunities: ["Débouché 1", "Débouché 2"]
  };

  return (
    <div className="flex flex-col gap-6 -mt-4 md:-mt-8 -mx-4 md:-mx-8">
      
      {/* FULL WIDTH BANNER */}
      <div className="relative w-full h-[40dvh] md:h-[50dvh] bg-black overflow-hidden">
        <img 
          src={metier.bannerImage} 
          alt={metier.title} 
          className="w-full h-full object-cover opacity-60" 
        />
        
        <div className="absolute top-4 left-4 md:top-8 md:left-8 z-20">
          <Link href="/student/explorer" className="inline-flex items-center gap-2 text-sm font-bold text-white bg-black/40 hover:bg-black/60 px-4 py-2 rounded-full backdrop-blur-sm transition-colors">
            <ArrowLeft className="w-4 h-4" /> Retour à l'exploration
          </Link>
        </div>

        <div className="absolute bottom-0 left-0 w-full p-6 md:p-10 bg-gradient-to-t from-canvas via-canvas/80 to-transparent">
          <span className="text-[10px] md:text-xs uppercase font-bold text-primary bg-primary/10 backdrop-blur-md px-3 py-1.5 rounded-sm mb-3 inline-block">
            {metier.domain}
          </span>
          <h1 className="font-display font-bold text-3xl md:text-5xl text-text-primary mb-2">
            {metier.title}
          </h1>
        </div>
      </div>

      <div className="max-w-5xl mx-auto w-full px-4 md:px-8 pb-12 flex flex-col lg:flex-row gap-8">
        
        {/* MAIN COLUMN */}
        <div className="flex-1 flex flex-col gap-8">
          
          <section>
            <h2 className="text-xl font-bold text-text-primary mb-4">Description du métier</h2>
            <p className="text-text-secondary leading-relaxed">
              {metier.description}
            </p>
          </section>

          <section>
            <h2 className="text-xl font-bold text-text-primary mb-4">Compétences nécessaires</h2>
            <div className="flex flex-wrap gap-2">
              {metier.skills.map((skill: string, i: number) => (
                <span key={i} className="px-3 py-1.5 bg-surface border border-border-soft rounded-md text-sm font-medium text-text-secondary flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-primary" /> {skill}
                </span>
              ))}
            </div>
          </section>

          <section>
            <h2 className="text-xl font-bold text-text-primary mb-4">Débouchés & Opportunités</h2>
            <div className="flex flex-wrap gap-2">
              {metier.opportunities.map((opp: string, i: number) => (
                <span key={i} className="px-3 py-1.5 bg-gold/10 border border-gold/20 rounded-md text-sm font-bold text-gold-dark">
                  {opp}
                </span>
              ))}
            </div>
          </section>

        </div>

        {/* RIGHT COLUMN (AÏDA + Formations) */}
        <div className="w-full lg:w-96 flex flex-col gap-6">
          
          <AidaAssistant 
            title="Pourquoi AÏDA vous le recommande"
            message={`Cette suggestion s'appuie notamment sur vos intérêts pour la technologie (RIASEC : Investigateur) et votre préférence pour les activités d'analyse et de résolution de problèmes.`}
            variant="floating"
          />

          <Card variant="standard" className="p-6">
            <h2 className="font-bold text-text-primary mb-4 flex items-center gap-2">
              <GraduationCap className="w-5 h-5 text-primary" />
              Formations possibles
            </h2>
            
            <div className="flex flex-col gap-4">
              {metier.formations.map((form: any, i: number) => (
                <div key={i} className="flex flex-col gap-1 pb-4 border-b border-border-soft last:border-0 last:pb-0">
                  <h3 className="font-bold text-sm text-text-primary">{form.name}</h3>
                  <div className="flex flex-col gap-1 mt-1">
                    <span className="text-xs text-text-secondary flex items-center gap-1">
                      <Building2 className="w-3 h-3" /> {form.school}
                    </span>
                    <span className="text-xs text-text-secondary flex items-center gap-1">
                      <MapPin className="w-3 h-3" /> Lomé, Togo ({form.duration})
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </Card>

        </div>

      </div>
    </div>
  );
}
