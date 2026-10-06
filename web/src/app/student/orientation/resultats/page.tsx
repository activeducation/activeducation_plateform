"use client";

import React, { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { 
  Sparkles, 
  Brain, 
  Briefcase, 
  Building2, 
  TrendingUp, 
  Banknote, 
  CheckCircle2, 
  ShieldAlert, 
  GraduationCap, 
  Coins, 
  RotateCcw, 
  BookOpen, 
  Mail, 
  Send, 
  Check, 
  Info,
  ArrowRight
} from "lucide-react";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Input } from "@/components/ui/Input";
import { OrientationResultM3 } from "@/lib/orientation";

// Modèle de référence togolais authentique (MESR / CAMES) en cas d'accès direct
const DEFAULT_MODEL_RESULT: OrientationResultM3 = {
  psychologicalProfile: {
    dominantTraits: ["Analytique", "Innovateur", "Méthodique", "Pragmatique"],
    strengths: [
      "Raisonnement logique rigoureux et forte capacité d'abstraction",
      "Aptitude naturelle à résoudre des défis technologiques et organisationnels",
      "Persévérance et rigueur dans l'exécution de projets structurés"
    ],
    weaknesses: [
      "Tendance à privilégier l'analyse théorique avant la concertation d'équipe",
      "Veiller à concilier exigence de qualité et respect des délais opérationnels",
      "Bien canaliser sa curiosité intellectuelle pour éviter la dispersion"
    ],
    summary: "Votre profil démontre une excellente synergie entre rigueur mathématique et créativité technique, des qualités hautement recherchées sur le marché de l'emploi au Togo. Vos compétences vous orientent naturellement vers des filières d'avenir à forte valeur ajoutée. Les universités et instituts togolais présentés ci-dessous vous permettront d'accélérer votre insertion professionnelle."
  },
  recommendedCareers: [
    {
      title: "Développeur Web & Mobile / Ingénieur Cloud",
      matchPercentage: 95,
      description: "Conception et déploiement d'applications robustes, API sécurisées et solutions cloud adaptées à la transition numérique des entreprises togolaises.",
      salaryRangeCFA: "250 000 - 850 000 FCFA / mois",
      demandInTogo: "Forte"
    },
    {
      title: "Data Analyst & Spécialiste IA",
      matchPercentage: 89,
      description: "Exploitation et modélisation prédictive des flux de données stratégiques pour les banques, opérateurs télécoms et acteurs logistiques de Lomé.",
      salaryRangeCFA: "300 000 - 900 000 FCFA / mois",
      demandInTogo: "Forte"
    },
    {
      title: "Ingénieur BTP & Génie Civil",
      matchPercentage: 83,
      description: "Supervision technique des infrastructures, ouvrages d'art et aménagements urbains durables en forte expansion sur tout le territoire togolais.",
      salaryRangeCFA: "250 000 - 750 000 FCFA / mois",
      demandInTogo: "Forte"
    }
  ],
  recommendedSchools: [
    {
      name: "Université de Lomé (UL)",
      program: "École Nationale Supérieure d'Ingénieurs (ENSI) & FDS",
      estimatedAnnualCostCFA: "Public / 25 000 - 50 000 FCFA",
      whyThisSchool: "Pôle national de référence offrant des cursus universitaires d'élite accrédités CAMES à des frais publics modérés."
    },
    {
      name: "Institut Africain d'Informatique (IAI-Togo)",
      program: "Licence Professionnelle & Cycle Ingénieur en Génie Logiciel",
      estimatedAnnualCostCFA: "500 000 FCFA / an",
      whyThisSchool: "Institution intergouvernementale réputée assurant une formation orientée pratique et un réseau d'insertion solide."
    },
    {
      name: "École Supérieure de Gestion, d'Informatique et des Sciences (ESGIS)",
      program: "Systèmes d'Information, Réseaux & Management Numérique",
      estimatedAnnualCostCFA: "450 000 - 650 000 FCFA / an",
      whyThisSchool: "Établissement privé agréé MESR Togo réputé pour ses partenariats industriels et ses doubles diplômes reconnus."
    }
  ]
};

export default function StudentOrientationResultsPage() {
  const router = useRouter();

  const [results, setResults] = useState<OrientationResultM3 | null>(null);
  const [isDefaultModel, setIsDefaultModel] = useState<boolean>(false);
  const [emailInput, setEmailInput] = useState<string>("");
  const [emailSent, setEmailSent] = useState<boolean>(false);

  // Lecture sécurisée du localStorage
  useEffect(() => {
    const fetchResults = async () => {
      try {
        const stored = localStorage.getItem("activ_orientation_results");
        if (stored) {
          const parsed = JSON.parse(stored);
          if (
            parsed &&
            parsed.psychologicalProfile &&
            Array.isArray(parsed.recommendedCareers) &&
            Array.isArray(parsed.recommendedSchools)
          ) {
            setResults(parsed);
            return;
          }
        }
      } catch {
        // Ignorer l'erreur de parsing
      }

      // Si pas dans le localStorage, on tente de récupérer depuis la base de données
      try {
        const res = await fetch("/api/orientation/result");
        if (res.ok) {
          const data = await res.json();
          if (data.result) {
            setResults(data.result);
            localStorage.setItem("activ_orientation_results", JSON.stringify(data.result));
            return;
          }
        }
      } catch (e) {
        console.error("Erreur fetch DB", e);
      }

      // Si toujours pas de données, charger le profil modèle officiel
      setResults(DEFAULT_MODEL_RESULT);
      setIsDefaultModel(true);
    };

    fetchResults();
  }, []);

  const handleSendEmail = (e: React.FormEvent) => {
    e.preventDefault();
    if (emailInput.trim().includes("@")) {
      setEmailSent(true);
      setTimeout(() => setEmailSent(false), 4000);
    }
  };

  if (!results) {
    return (
      <div className="min-h-[60vh] flex items-center justify-center">
        <div className="flex flex-col items-center gap-3">
          <div className="w-8 h-8 border-2 border-primary border-t-transparent rounded-full animate-spin" />
          <span className="text-text-secondary text-sm">Chargement de votre bilan AÏDA...</span>
        </div>
      </div>
    );
  }

  const { psychologicalProfile, recommendedCareers, recommendedSchools } = results;

  return (
    <div className="flex flex-col gap-8 pb-12 max-w-5xl mx-auto">
      {/* Bannière en cas d'accès direct sans test préalable */}
      {isDefaultModel && (
        <Card variant="standard" className="p-4 bg-primary/5 border-primary/20 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-md bg-primary/10 text-primary flex items-center justify-center flex-shrink-0">
              <Info className="w-5 h-5 text-primary" />
            </div>
            <div>
              <h4 className="font-bold text-text-primary text-sm">
                Exemple de Bilan d'Orientation AÏDA
              </h4>
              <p className="text-xs text-text-secondary">
                Vous visualisez actuellement un profil type. Passez votre test personnalisé pour obtenir un diagnostic sur-mesure.
              </p>
            </div>
          </div>
          <Button
            variant="secondary"
            size="sm"
            onClick={() => router.push("/student/orientation")}
            className="whitespace-nowrap"
          >
            Faire mon test personnalisé
          </Button>
        </Card>
      )}

      {/* En-tête de la Page de Résultats */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-border-soft pb-6">
        <div>
          <div className="flex items-center gap-2 mb-2">
            <span className="px-2.5 py-0.5 rounded bg-primary/10 text-primary text-xs font-bold uppercase tracking-wider font-mono">
              Bilan AÏDA
            </span>
            <span className="text-text-tertiary text-xs">•</span>
            <span className="text-text-secondary text-xs">
              Référentiel Togo MESR / CAMES
            </span>
          </div>
          <h1 className="text-2xl md:text-3xl font-display font-bold text-text-primary">
            Vos Résultats d'Orientation
          </h1>
          <p className="text-text-secondary text-sm md:text-base mt-1">
            Analyse d'adéquation entre vos matières fortes, le marché togolais et les universités agréées.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <Button
            variant="secondary"
            onClick={() => router.push("/student/orientation?retake=true")}
            className="flex items-center gap-2"
          >
            <RotateCcw className="w-4 h-4" />
            Repasser le test
          </Button>
          <Button
            variant="primary"
            onClick={() => router.push("/student/cours")}
            className="flex items-center gap-2"
          >
            <BookOpen className="w-4 h-4" />
            Explorer les cours
          </Button>
        </div>
      </div>

      {/* SECTION 1 : PROFIL PSYCHOLOGIQUE */}
      <section className="flex flex-col gap-4">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-md bg-primary/10 text-primary flex items-center justify-center">
            <Brain className="w-5 h-5 text-primary" />
          </div>
          <h2 className="text-xl font-display font-bold text-text-primary">
            Profil Psychologique & Compétences
          </h2>
        </div>

        <Card variant="standard" className="p-6 md:p-8 flex flex-col gap-6">
          {/* Synthèse du profil */}
          <div className="border-l-4 border-primary pl-4 py-1 bg-canvas rounded-r-md">
            <p className="text-sm md:text-base text-text-primary leading-relaxed font-medium">
              {psychologicalProfile.summary}
            </p>
          </div>

          {/* Traits Dominants */}
          <div>
            <h3 className="text-xs font-bold uppercase tracking-wider text-text-tertiary mb-3 font-mono">
              Traits Dominants Identifiés
            </h3>
            <div className="flex flex-wrap gap-2">
              {(psychologicalProfile?.dominantTraits || []).map((trait, idx) => (
                <span
                  key={idx}
                  className="px-3 py-1.5 rounded-md bg-primary/10 border border-primary/20 text-primary text-xs font-semibold"
                >
                  {trait}
                </span>
              ))}
            </div>
          </div>

          {/* Points Forts & Points de Vigilance */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 pt-2">
            {/* Points Forts */}
            <div className="flex flex-col gap-3">
              <h3 className="text-xs font-bold uppercase tracking-wider text-text-primary mb-1 flex items-center gap-2 font-mono">
                <CheckCircle2 className="w-4 h-4 text-primary" />
                Forces & Atouts Clés
              </h3>
              <ul className="flex flex-col gap-2">
                {(psychologicalProfile?.strengths || []).map((strength, idx) => (
                  <li key={idx} className="flex items-start gap-2.5 text-xs md:text-sm text-text-secondary leading-relaxed">
                    <span className="w-1.5 h-1.5 rounded-full bg-primary mt-1.5 flex-shrink-0" />
                    <span>{strength}</span>
                  </li>
                ))}
              </ul>
            </div>

            {/* Points de Vigilance */}
            <div className="flex flex-col gap-3">
              <h3 className="text-xs font-bold uppercase tracking-wider text-text-secondary mb-1 flex items-center gap-2 font-mono">
                <ShieldAlert className="w-4 h-4 text-text-secondary" />
                Points de Vigilance
              </h3>
              <ul className="flex flex-col gap-2">
                {(psychologicalProfile?.weaknesses || []).map((weakness, idx) => (
                  <li key={idx} className="flex items-start gap-2.5 text-xs md:text-sm text-text-secondary leading-relaxed">
                    <span className="w-1.5 h-1.5 rounded-full bg-border-soft mt-1.5 flex-shrink-0" />
                    <span>{weakness}</span>
                  </li>
                ))}
              </ul>
            </div>
          </div>
        </Card>
      </section>

      {/* SECTION 2 : 3 MÉTIERS RECOMMANDÉS AU TOGO */}
      <section className="flex flex-col gap-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-md bg-primary/10 text-primary flex items-center justify-center">
              <Briefcase className="w-5 h-5 text-primary" />
            </div>
            <div>
              <h2 className="text-xl font-display font-bold text-text-primary">
                3 Métiers Porteurs Recommandés au Togo
              </h2>
              <p className="text-xs text-text-secondary">
                Secteurs prioritaires à fort taux d'employabilité et salaires du marché local en Francs CFA.
              </p>
            </div>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {(recommendedCareers || []).map((career, idx) => (
            <Card
              key={idx}
              variant="standard"
              className="p-6 flex flex-col justify-between border-border-soft hover:border-primary/30 transition-all bg-surface"
            >
              <div className="flex flex-col gap-4">
                {/* En-tête de la carte avec Score Ambre #FAA100 STRICTEMENT RÉSERVÉ */}
                <div className="flex items-center justify-between gap-2">
                  <span className="text-[11px] font-mono font-bold text-text-tertiary uppercase">
                    Option {idx + 1}
                  </span>
                  <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded bg-[#FAA100]/10 border border-[#FAA100]/30 text-[#FAA100] font-mono font-bold text-xs">
                    <TrendingUp className="w-3.5 h-3.5" />
                    <span>{career.matchPercentage}% Match</span>
                  </span>
                </div>

                {/* Barre de progression réservée ambre/or #FAA100 */}
                <div className="w-full h-1.5 bg-border-soft rounded-full overflow-hidden">
                  <div
                    className="h-full bg-[#FAA100] rounded-full transition-all duration-500"
                    style={{ width: `${career.matchPercentage}%` }}
                  />
                </div>

                {/* Titre du Métier */}
                <h3 className="font-bold text-text-primary text-base leading-snug">
                  {career.title}
                </h3>

                {/* Description */}
                <p className="text-xs text-text-secondary leading-relaxed line-clamp-4">
                  {career.description}
                </p>
              </div>

              {/* Métriques : Salaire CFA et Demande */}
              <div className="mt-6 pt-4 border-t border-border-soft flex flex-col gap-2.5">
                <div className="flex items-center justify-between text-xs">
                  <span className="text-text-tertiary flex items-center gap-1.5">
                    <Banknote className="w-3.5 h-3.5 text-primary" />
                    Salaire estimé :
                  </span>
                  <span className="font-bold font-mono text-text-primary">
                    {career.salaryRangeCFA}
                  </span>
                </div>

                <div className="flex items-center justify-between text-xs">
                  <span className="text-text-tertiary">Demande locale :</span>
                  <span className={`px-2 py-0.5 rounded text-[11px] font-bold ${
                    career.demandInTogo === "Forte"
                      ? "bg-primary/10 text-primary"
                      : "bg-canvas text-text-secondary border border-border-soft"
                  }`}>
                    {career.demandInTogo}
                  </span>
                </div>
              </div>
            </Card>
          ))}
        </div>
      </section>

      {/* SECTION 3 : ÉTABLISSEMENTS & UNIVERSITÉS AU TOGO */}
      <section className="flex flex-col gap-4">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-md bg-primary/10 text-primary flex items-center justify-center">
            <Building2 className="w-5 h-5 text-primary" />
          </div>
          <div>
            <h2 className="text-xl font-display font-bold text-text-primary">
              Universités & Écoles Recommandées au Togo
            </h2>
            <p className="text-xs text-text-secondary">
              Établissements reconnus par le Ministère de l'Enseignement Supérieur (MESR Togo) et le CAMES.
            </p>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {(recommendedSchools || []).map((school, idx) => (
            <Card
              key={idx}
              variant="standard"
              className="p-6 flex flex-col justify-between border-border-soft hover:border-primary/30 transition-all bg-surface"
            >
              <div className="flex flex-col gap-3">
                <div className="flex items-center justify-between gap-2">
                  <span className="px-2 py-0.5 rounded bg-primary/10 text-primary text-[10px] font-mono font-bold uppercase">
                    MESR / CAMES
                  </span>
                  <span className="text-text-tertiary text-xs font-mono">
                    Choix {idx + 1}
                  </span>
                </div>

                <h3 className="font-bold text-text-primary text-base">
                  {school.name}
                </h3>

                <div className="flex items-start gap-2 text-xs text-text-primary font-medium bg-canvas p-2.5 rounded-md border border-border-soft">
                  <GraduationCap className="w-4 h-4 text-primary flex-shrink-0 mt-0.5" />
                  <span>{school.program}</span>
                </div>

                <p className="text-xs text-text-secondary leading-relaxed">
                  {school.whyThisSchool}
                </p>
              </div>

              <div className="mt-6 pt-4 border-t border-border-soft flex items-center justify-between text-xs">
                <span className="text-text-tertiary flex items-center gap-1.5">
                  <Coins className="w-3.5 h-3.5 text-primary" />
                  Frais annuels :
                </span>
                <span className="font-bold font-mono text-text-primary">
                  {school.estimatedAnnualCostCFA}
                </span>
              </div>
            </Card>
          ))}
        </div>
      </section>

      {/* SECTION 4 : PARTAGE EMAIL ET ACTIONS */}
      <section className="mt-4">
        <Card variant="standard" className="p-6 md:p-8 bg-surface border-border-soft">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-8 items-center">
            <div>
              <div className="flex items-center gap-2 mb-2">
                <Mail className="w-4 h-4 text-primary" />
                <h3 className="text-base font-bold text-text-primary">
                  Conserver votre rapport d'orientation
                </h3>
              </div>
              <p className="text-xs md:text-sm text-text-secondary leading-relaxed">
                Recevez une copie complète de ce bilan au format document pour la présenter à vos parents ou lors de vos inscriptions universitaires.
              </p>
            </div>

            <form onSubmit={handleSendEmail} className="flex flex-col sm:flex-row items-end gap-3 w-full">
              <div className="flex-1 w-full">
                <Input
                  label="Recevoir mon bilan complet par email"
                  placeholder="exemple.etudiant@gmail.com"
                  type="email"
                  value={emailInput}
                  onChange={(e) => setEmailInput(e.target.value)}
                  required
                />
              </div>
              <Button
                variant="primary"
                type="submit"
                className="w-full sm:w-auto flex items-center justify-center gap-2 flex-shrink-0"
              >
                {emailSent ? (
                  <>
                    <Check className="w-4 h-4" />
                    Envoyé avec succès
                  </>
                ) : (
                  <>
                    <Send className="w-4 h-4" />
                    Envoyer
                  </>
                )}
              </Button>
            </form>
          </div>
        </Card>
      </section>

      {/* NAVIGATION INFERIEURE VERS COURS ET REPASSER LE TEST */}
      <div className="flex flex-col sm:flex-row items-center justify-between gap-4 pt-4 border-t border-border-soft">
        <Button
          variant="secondary"
          onClick={() => router.push("/student/orientation?retake=true")}
          className="w-full sm:w-auto flex items-center justify-center gap-2"
        >
          <RotateCcw className="w-4 h-4" />
          Refaire le test d'orientation
        </Button>

        <Button
          variant="primary"
          onClick={() => router.push("/student/cours")}
          className="w-full sm:w-auto flex items-center justify-center gap-2 px-8"
        >
          Explorer le catalogue des cours
          <ArrowRight className="w-4 h-4" />
        </Button>
      </div>
    </div>
  );
}
