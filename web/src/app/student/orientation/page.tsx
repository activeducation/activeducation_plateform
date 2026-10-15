"use client";

import React, { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { motion, AnimatePresence } from "framer-motion";
import { 
  Sparkles, 
  Cpu, 
  BookOpen, 
  Briefcase, 
  Activity, 
  Palette, 
  Wrench, 
  Binary, 
  Feather, 
  Leaf, 
  Globe, 
  LineChart, 
  Terminal, 
  ArrowRight, 
  ArrowLeft, 
  CheckCircle2, 
  Check, 
  Compass, 
  MapPin, 
  Coins 
} from "lucide-react";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Input } from "@/components/ui/Input";

// Options des 4 questions
const INTEREST_OPTIONS = [
  {
    id: "sciences-tech",
    label: "Sciences & Nouvelles Technologies",
    description: "Informatique, intelligence artificielle, mathématiques appliquées et systèmes cloud",
    icon: Cpu,
  },
  {
    id: "lettres-langues",
    label: "Lettres, Langues & Communication",
    description: "Littérature, journalisme d'investigation, diplomatie et langues étrangères",
    icon: BookOpen,
  },
  {
    id: "economie-gestion",
    label: "Économie, Gestion & Entrepreneuriat",
    description: "Finance d'entreprise, comptabilité, gestion de projets et développement commercial",
    icon: Briefcase,
  },
  {
    id: "sante-bio",
    label: "Santé, Biologie & Sciences Médicales",
    description: "Médecine générale, pharmacologie, recherche biomédicale et agronomie durable",
    icon: Activity,
  },
  {
    id: "arts-design",
    label: "Arts, Design & Création Numérique",
    description: "Design UI/UX, architecture d'intérieur, infographie et multimédia",
    icon: Palette,
  },
  {
    id: "ingenierie-btp",
    label: "Bâtiment, Industrie & Ingénierie",
    description: "Génie civil, énergies renouvelables, électromécanique et logistique portuaire",
    icon: Wrench,
  },
];

const SUBJECT_OPTIONS = [
  {
    id: "maths-physique",
    label: "Mathématiques & Physique-Chimie",
    description: "Calcul vectoriel, analyse formelle, modélisation et sciences expérimentales",
    icon: Binary,
  },
  {
    id: "francais-philo",
    label: "Français, Philosophie & Littérature",
    description: "Rhétorique, synthèse de texte, réflexion critique et expression écrite",
    icon: Feather,
  },
  {
    id: "svt",
    label: "Sciences de la Vie et de la Terre (SVT)",
    description: "Biologie cellulaire, écosystèmes, géologie et physiologie humaine",
    icon: Leaf,
  },
  {
    id: "anglais-langues",
    label: "Anglais & Langues Étrangères",
    description: "Communication internationale, fluidité orale et rédactionnelle",
    icon: Globe,
  },
  {
    id: "histoire-geo",
    label: "Histoire-Géographie & Économie",
    description: "Compréhension géopolitique, démographie et dynamiques économiques",
    icon: LineChart,
  },
  {
    id: "informatique-tech",
    label: "Informatique & Technologies",
    description: "Algorithmique, programmation, bureautique avancée et culture web",
    icon: Terminal,
  },
];

const BUDGET_OPTIONS = [
  {
    id: "faible",
    value: "Faible",
    title: "Moins de 200 000 FCFA / an",
    subtitle: "Accès prioritaire aux universités publiques nationales, instituts d'État et bourses d'études.",
    badge: "Budget Public",
  },
  {
    id: "moyen",
    value: "Moyen",
    title: "200 000 à 600 000 FCFA / an",
    subtitle: "Accès aux instituts conventionnés, écoles privées agréées et filières professionnalisantes.",
    badge: "Budget Intermédiaire",
  },
  {
    id: "eleve",
    value: "Élevé",
    title: "Plus de 600 000 FCFA / an",
    subtitle: "Accès illimité aux grandes écoles de référence, doubles diplômes et certifications internationales.",
    badge: "Budget Confortable",
  },
];

const MOBILITY_OPTIONS = [
  {
    id: "lome",
    value: "Grand Lomé & Région Maritime",
    title: "Grand Lomé & Région Maritime",
    subtitle: "Capitale économique, siège des universités nationales et des instituts supérieurs",
  },
  {
    id: "kara",
    value: "Région de la Kara & Nord Togo",
    title: "Région de la Kara & Nord Togo",
    subtitle: "Université de Kara et pôles de développement technologique et agronomique du Nord",
  },
  {
    id: "plateaux-centrale",
    value: "Région des Plateaux & Centrale",
    title: "Région des Plateaux & Centrale",
    subtitle: "Kpalimé, Sokodé, Atakpamé et instituts régionaux de formation professionnelle",
  },
  {
    id: "savanes",
    value: "Région des Savanes",
    title: "Région des Savanes",
    subtitle: "Dapaong, Mango et filières d'excellence transfrontalières",
  },
  {
    id: "totale",
    value: "Mobilité Totale (Partout au Togo)",
    title: "Mobilité Totale (Partout au Togo)",
    subtitle: "Prêt à s'installer dans toute ville universitaire togolaise selon l'offre de formation",
  },
];

const ANALYSIS_STEPS = [
  "Validation des compétences scolaires et matières dominantes",
  "Croisement avec les secteurs prioritaires du marché togolais",
  "Sélection des universités et instituts agréés selon votre budget",
  "Génération du bilan d'orientation personnalisé par l'IA AÏDA",
];

export default function StudentOrientationPage() {
  const router = useRouter();
  const [generationError, setGenerationError] = useState('');

  const [currentStep, setCurrentStep] = useState<number>(0);
  const [selectedInterests, setSelectedInterests] = useState<string[]>([]);
  const [selectedSubjects, setSelectedSubjects] = useState<string[]>([]);
  const [otherSubject, setOtherSubject] = useState<string>("");
  const [selectedBudget, setSelectedBudget] = useState<string>("");
  const [selectedMobility, setSelectedMobility] = useState<string>("");
  const [currentCity, setCurrentCity] = useState<string>("");

  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const [activeAnalysisStep, setActiveAnalysisStep] = useState<number>(0);
  const [isCheckingPrevious, setIsCheckingPrevious] = useState<boolean>(true);

  // Vérifier s'il y a déjà un résultat enregistré dans la DB (sauf si on force le test)
  useEffect(() => {
    const checkPreviousResult = async () => {
      // Si l'utilisateur clique sur "Repasser le test", on aura un paramètre ?retake=true
      const urlParams = new URLSearchParams(window.location.search);
      if (urlParams.get("retake") === "true") {
        setIsCheckingPrevious(false);
        return;
      }

      try {
        const res = await fetch("/api/orientation/result");
        if (res.ok) {
          const data = await res.json();
          if (data.result) {
            // Un résultat existe, on sauvegarde dans localStorage (pour persistance locale)
            router.replace("/student/orientation/resultats");
            return;
          }
        }
      } catch (e) {
        console.error("Erreur check résultat", e);
      }
      setIsCheckingPrevious(false);
    };
    checkPreviousResult();
  }, [router]);

  // Animation séquentielle des étapes d'analyse AÏDA
  useEffect(() => {
    if (!isSubmitting) return;

    const interval = setInterval(() => {
      setActiveAnalysisStep((prev) => {
        if (prev < ANALYSIS_STEPS.length - 1) return prev + 1;
        return prev;
      });
    }, 600);

    return () => clearInterval(interval);
  }, [isSubmitting]);

  const toggleInterest = (label: string) => {
    setSelectedInterests((prev) =>
      prev.includes(label) ? prev.filter((item) => item !== label) : [...prev, label]
    );
  };

  const toggleSubject = (label: string) => {
    setSelectedSubjects((prev) =>
      prev.includes(label) ? prev.filter((item) => item !== label) : [...prev, label]
    );
  };

  const handleNext = () => {
    if (currentStep < 3) {
      setCurrentStep((prev) => prev + 1);
    } else {
      handleSubmit();
    }
  };

  const handlePrev = () => {
    if (currentStep > 0) {
      setCurrentStep((prev) => prev - 1);
    }
  };

  const handleSubmit = async () => {
    setIsSubmitting(true);
    setGenerationError('');

    const trimmedOther = otherSubject.trim();
    const effectiveStrongSubjects =
      selectedSubjects.length > 0
        ? selectedSubjects
        : trimmedOther.length > 0
        ? [trimmedOther]
        : ["Mathématiques & Physique-Chimie"];

    const payload = {
      answers: {
        interests: selectedInterests.length > 0 ? selectedInterests : ["Sciences & Nouvelles Technologies"],
        strongSubjects: effectiveStrongSubjects,
        otherSubject: trimmedOther,
        budget: selectedBudget || "Moyen",
        mobility: selectedMobility || "Grand Lomé & Région Maritime",
        currentCity: currentCity.trim() || "Lomé",
      },
    };

    try {
      const response = await fetch('/api/orientation/generate', {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(payload),
        signal: AbortSignal.timeout(40_000),
      });
      const data = await response.json();
      if (!response.ok) throw new Error(data.error || 'La génération a échoué.');
      router.push('/student/orientation/resultats');
    } catch (error) {
      setIsSubmitting(false);
      setGenerationError(error instanceof Error ? error.message : 'Réessayez plus tard.');
    }
  };

  const isCurrentStepValid = () => {
    switch (currentStep) {
      case 0:
        return selectedInterests.length > 0;
      case 1:
        return selectedSubjects.length > 0 || otherSubject.trim().length > 0;
      case 2:
        return selectedBudget !== "";
      case 3:
        return selectedMobility !== "";
      default:
        return false;
    }
  };

  const progressPercent = ((currentStep + 1) / 4) * 100;

  // ÉCRAN DE CHARGEMENT : AÏDA ANALYSE VOTRE PROFIL
  if (isSubmitting) {
    return (
      <div className="min-h-[75vh] flex items-center justify-center p-4">
        <Card variant="standard" className="w-full max-w-2xl p-8 md:p-12 text-center border-border-soft bg-surface shadow-sm">
          <div className="flex flex-col items-center">
            {/* Icône animée Royal Blue */}
            <div className="relative mb-6">
              <motion.div
                animate={{ scale: [1, 1.15, 1], rotate: [0, 5, -5, 0] }}
                transition={{ duration: 2.2, repeat: Infinity, ease: "easeInOut" }}
                className="w-20 h-20 rounded-2xl bg-primary/10 border border-primary/20 flex items-center justify-center text-primary"
              >
                <Sparkles className="w-10 h-10 text-primary" />
              </motion.div>
              <span className="absolute -bottom-2 px-3 py-0.5 rounded-full bg-primary text-white text-[11px] font-bold tracking-wide uppercase">
                AÏDA
              </span>
            </div>

            <h2 className="text-2xl md:text-3xl font-display font-bold text-text-primary mb-3">
              AÏDA analyse votre profil...
            </h2>
            <p className="text-text-secondary text-sm md:text-base max-w-lg mb-8 leading-relaxed">
              Croisement de vos compétences scolaires avec les filières porteuses et le référentiel des universités accréditées au Togo.
            </p>

            {/* Étapes animées de l'analyse */}
            <div className="w-full max-w-md flex flex-col gap-3 text-left">
              {ANALYSIS_STEPS.map((stepText, idx) => {
                const isPassed = activeAnalysisStep > idx;
                const isCurrent = activeAnalysisStep === idx;

                return (
                  <motion.div
                    key={idx}
                    initial={{ opacity: 0, y: 8 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: idx * 0.15 }}
                    className={`flex items-center gap-3 p-3 rounded-md border text-sm transition-all duration-200 ${
                      isPassed
                        ? "bg-primary/5 border-primary/20 text-primary font-medium"
                        : isCurrent
                          ? "bg-canvas border-primary/40 text-text-primary font-semibold shadow-sm"
                          : "bg-surface border-border-soft/60 text-text-tertiary"
                    }`}
                  >
                    <div className="flex-shrink-0">
                      {isPassed ? (
                        <CheckCircle2 className="w-4 h-4 text-primary" />
                      ) : (
                        <div
                          className={`w-4 h-4 rounded-full border flex items-center justify-center text-[10px] ${
                            isCurrent
                              ? "border-primary text-primary animate-pulse"
                              : "border-border-soft text-text-tertiary"
                          }`}
                        >
                          {idx + 1}
                        </div>
                      )}
                    </div>
                    <span className="flex-1">{stepText}</span>
                  </motion.div>
                );
              })}
            </div>

            {/* Barre de progression réservée ambre/or #FAA100 */}
            <div className="w-full max-w-md mt-8">
              <div className="w-full h-2 bg-border-soft rounded-full overflow-hidden">
                <motion.div
                  className="h-full bg-[#FAA100] rounded-full"
                  initial={{ width: "10%" }}
                  animate={{ width: "95%" }}
                  transition={{ duration: 2.2, ease: "easeInOut" }}
                />
              </div>
              <p className="text-[12px] text-text-tertiary mt-2">
                Génération en cours • Togo MESR / CAMES
              </p>
            </div>
          </div>
        </Card>
      </div>
    );
  }

  // ÉCRAN DE CHARGEMENT : VÉRIFICATION INITIALE
  if (isCheckingPrevious) {
    return (
      <div className="min-h-[75vh] flex items-center justify-center p-4">
        <div className="flex flex-col items-center gap-3">
          <div className="w-8 h-8 border-2 border-primary border-t-transparent rounded-full animate-spin" />
          <span className="text-text-secondary text-sm">Vérification de votre dossier...</span>
        </div>
      </div>
    );
  }

  return (<>
    {generationError && <p role="alert" className="p-4 text-error">{generationError}</p>}
    <div className="min-h-[80vh] flex flex-col justify-between max-w-4xl mx-auto py-4">
      {/* En-tête et Barre de Progression */}
      <div className="mb-8">
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <span className="px-2.5 py-1 rounded bg-primary/10 text-primary text-xs font-bold font-mono">
              Étape {currentStep + 1} sur 4
            </span>
            <span className="text-text-secondary text-xs hidden sm:inline">
              Test d'Orientation AÏDA
            </span>
          </div>
          <span className="text-xs font-bold font-mono text-[#FAA100]">
            {Math.round(progressPercent)}% complété
          </span>
        </div>

        {/* Barre de progression (or/ambre #FAA100) */}
        <div className="w-full h-1.5 bg-border-soft rounded-full overflow-hidden">
          <motion.div
            className="h-full bg-[#FAA100] rounded-full"
            initial={false}
            animate={{ width: `${progressPercent}%` }}
            transition={{ ease: [0.33, 1, 0.68, 1] as const, duration: 0.3 }}
          />
        </div>
      </div>

      {/* Zone Centrale du Questionnaire */}
      <div className="flex-1 relative">
        <AnimatePresence mode="wait">
          {currentStep === 0 && (
            <motion.div
              key="step-0"
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              transition={{ ease: [0.33, 1, 0.68, 1] as const, duration: 0.25 }}
              className="flex flex-col gap-6"
            >
              <div>
                <h1 className="text-2xl md:text-3xl font-display font-bold text-text-primary mb-2">
                  Quels sont vos principaux centres d'intérêt ?
                </h1>
                <p className="text-text-secondary text-sm md:text-base">
                  Sélectionnez un ou plusieurs domaines qui stimulent votre curiosité au quotidien.
                </p>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {INTEREST_OPTIONS.map((opt) => {
                  const isSelected = selectedInterests.includes(opt.label);
                  const IconComp = opt.icon;

                  return (
                    <Card
                      key={opt.id}
                      variant="standard"
                      interactive={true}
                      onClick={() => toggleInterest(opt.label)}
                      className={`p-5 transition-all text-left flex items-start gap-4 ${
                        isSelected
                          ? "border-primary bg-primary/5 ring-1 ring-primary/30"
                          : "border-border-soft hover:border-text-tertiary"
                      }`}
                    >
                      <div
                        className={`w-10 h-10 rounded-md flex items-center justify-center flex-shrink-0 transition-colors ${
                          isSelected ? "bg-primary text-white" : "bg-canvas text-text-secondary"
                        }`}
                      >
                        <IconComp className="w-5 h-5" />
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center justify-between gap-2 mb-1">
                          <h3 className="font-bold text-text-primary text-sm leading-snug">
                            {opt.label}
                          </h3>
                          {isSelected && (
                            <div className="w-5 h-5 rounded-full bg-primary text-white flex items-center justify-center flex-shrink-0">
                              <Check className="w-3 h-3 stroke-[3]" />
                            </div>
                          )}
                        </div>
                        <p className="text-xs text-text-secondary leading-relaxed line-clamp-2">
                          {opt.description}
                        </p>
                      </div>
                    </Card>
                  );
                })}
              </div>
            </motion.div>
          )}

          {currentStep === 1 && (
            <motion.div
              key="step-1"
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              transition={{ ease: [0.33, 1, 0.68, 1] as const, duration: 0.25 }}
              className="flex flex-col gap-6"
            >
              <div>
                <h1 className="text-2xl md:text-3xl font-display font-bold text-text-primary mb-2">
                  Quelles sont vos matières fortes ou préférées ?
                </h1>
                <p className="text-text-secondary text-sm md:text-base">
                  Indiquez les disciplines dans lesquelles vous obtenez vos meilleurs résultats ou éprouvez le plus d'aisance.
                </p>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {SUBJECT_OPTIONS.map((opt) => {
                  const isSelected = selectedSubjects.includes(opt.label);
                  const IconComp = opt.icon;

                  return (
                    <Card
                      key={opt.id}
                      variant="standard"
                      interactive={true}
                      onClick={() => toggleSubject(opt.label)}
                      className={`p-5 transition-all text-left flex items-start gap-4 ${
                        isSelected
                          ? "border-primary bg-primary/5 ring-1 ring-primary/30"
                          : "border-border-soft hover:border-text-tertiary"
                      }`}
                    >
                      <div
                        className={`w-10 h-10 rounded-md flex items-center justify-center flex-shrink-0 transition-colors ${
                          isSelected ? "bg-primary text-white" : "bg-canvas text-text-secondary"
                        }`}
                      >
                        <IconComp className="w-5 h-5" />
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center justify-between gap-2 mb-1">
                          <h3 className="font-bold text-text-primary text-sm leading-snug">
                            {opt.label}
                          </h3>
                          {isSelected && (
                            <div className="w-5 h-5 rounded-full bg-primary text-white flex items-center justify-center flex-shrink-0">
                              <Check className="w-3 h-3 stroke-[3]" />
                            </div>
                          )}
                        </div>
                        <p className="text-xs text-text-secondary leading-relaxed line-clamp-2">
                          {opt.description}
                        </p>
                      </div>
                    </Card>
                  );
                })}
              </div>

              {/* Champ Input personnalisé */}
              <div className="pt-2">
                <Input
                  label="Autre matière spécifique (facultatif)"
                  placeholder="Ex: Dessin technique, Espagnol, Sciences économiques, Électronique..."
                  value={otherSubject}
                  onChange={(e) => setOtherSubject(e.target.value)}
                />
              </div>
            </motion.div>
          )}

          {currentStep === 2 && (
            <motion.div
              key="step-2"
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              transition={{ ease: [0.33, 1, 0.68, 1] as const, duration: 0.25 }}
              className="flex flex-col gap-6"
            >
              <div>
                <h1 className="text-2xl md:text-3xl font-display font-bold text-text-primary mb-2">
                  Quel est votre budget annuel prévisionnel pour vos études ?
                </h1>
                <p className="text-text-secondary text-sm md:text-base">
                  Cette information permet à AÏDA de cibler des établissements publics ou privés parfaitement réalistes pour vous.
                </p>
              </div>

              <div className="flex flex-col gap-4">
                {BUDGET_OPTIONS.map((opt) => {
                  const isSelected = selectedBudget === opt.value;

                  return (
                    <Card
                      key={opt.id}
                      variant="standard"
                      interactive={true}
                      onClick={() => setSelectedBudget(opt.value)}
                      className={`p-6 transition-all text-left flex items-start gap-5 ${
                        isSelected
                          ? "border-primary bg-primary/5 ring-1 ring-primary/30"
                          : "border-border-soft hover:border-text-tertiary"
                      }`}
                    >
                      <div
                        className={`w-12 h-12 rounded-lg flex items-center justify-center flex-shrink-0 transition-colors ${
                          isSelected ? "bg-primary text-white" : "bg-canvas text-text-secondary"
                        }`}
                      >
                        <Coins className="w-6 h-6" />
                      </div>
                      <div className="flex-1">
                        <div className="flex items-center justify-between gap-3 mb-1">
                          <h3 className="font-bold text-text-primary text-base">
                            {opt.title}
                          </h3>
                          <span className="px-2.5 py-0.5 rounded bg-canvas border border-border-soft text-[11px] font-bold text-text-secondary">
                            {opt.badge}
                          </span>
                        </div>
                        <p className="text-xs md:text-sm text-text-secondary leading-relaxed">
                          {opt.subtitle}
                        </p>
                      </div>
                    </Card>
                  );
                })}
              </div>
            </motion.div>
          )}

          {currentStep === 3 && (
            <motion.div
              key="step-3"
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              transition={{ ease: [0.33, 1, 0.68, 1] as const, duration: 0.25 }}
              className="flex flex-col gap-6"
            >
              <div>
                <h1 className="text-2xl md:text-3xl font-display font-bold text-text-primary mb-2">
                  Quelle est votre zone de mobilité géographique au Togo ?
                </h1>
                <p className="text-text-secondary text-sm md:text-base">
                  Précisez où vous envisagez d'effectuer vos études supérieures.
                </p>
              </div>

              <div className="flex flex-col gap-3">
                {MOBILITY_OPTIONS.map((opt) => {
                  const isSelected = selectedMobility === opt.value;

                  return (
                    <Card
                      key={opt.id}
                      variant="standard"
                      interactive={true}
                      onClick={() => setSelectedMobility(opt.value)}
                      className={`p-4 transition-all text-left flex items-start gap-4 ${
                        isSelected
                          ? "border-primary bg-primary/5 ring-1 ring-primary/30"
                          : "border-border-soft hover:border-text-tertiary"
                      }`}
                    >
                      <div
                        className={`w-9 h-9 rounded-md flex items-center justify-center flex-shrink-0 transition-colors ${
                          isSelected ? "bg-primary text-white" : "bg-canvas text-text-secondary"
                        }`}
                      >
                        <MapPin className="w-4 h-4" />
                      </div>
                      <div className="flex-1">
                        <h3 className="font-bold text-text-primary text-sm mb-0.5">
                          {opt.title}
                        </h3>
                        <p className="text-xs text-text-secondary">
                          {opt.subtitle}
                        </p>
                      </div>
                    </Card>
                  );
                })}
              </div>

              {/* Champ Input de la ville actuelle */}
              <div className="pt-2">
                <Input
                  label="Votre ville de résidence actuelle"
                  placeholder="Ex: Lomé, Kara, Kpalimé, Sokodé, Atakpamé, Dapaong..."
                  value={currentCity}
                  onChange={(e) => setCurrentCity(e.target.value)}
                />
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {/* Barre d'Actions Inférieure */}
      <div className="mt-10 pt-6 border-t border-border-soft flex items-center justify-between">
        {currentStep > 0 ? (
          <Button
            variant="secondary"
            onClick={handlePrev}
            className="flex items-center gap-2"
          >
            <ArrowLeft className="w-4 h-4" />
            Retour
          </Button>
        ) : (
          <div />
        )}

        <Button
          variant="primary"
          onClick={handleNext}
          disabled={!isCurrentStepValid()}
          className="flex items-center gap-2 px-6"
        >
          {currentStep === 3 ? (
            <>
              <Sparkles className="w-4 h-4" />
              Analyser mon profil
            </>
          ) : (
            <>
              Continuer
              <ArrowRight className="w-4 h-4" />
            </>
          )}
        </Button>
      </div>
    </div>
  </>);

}
