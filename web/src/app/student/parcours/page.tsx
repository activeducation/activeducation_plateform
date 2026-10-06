"use client";

import React, { useState, useEffect } from "react";
import { 
  Trophy, 
  CheckCircle2, 
  Lock, 
  Play,
  Compass,
  Star,
  FileText,
  Map,
  ArrowRight
} from "lucide-react";
import { Card } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import { AidaAssistant } from "@/components/student/AidaAssistant";
import { useRouter } from "next/navigation";

export default function ParcoursPage() {
  const router = useRouter();
  const [currentXp, setCurrentXp] = useState(0);
  const [level, setLevel] = useState(1);
  const [rankTitle, setRankTitle] = useState("Novice");
  
  // État des étapes
  const [hasOrientation, setHasOrientation] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchUserData = async () => {
      try {
        // Fetch XP
        const xpRes = await fetch("/api/user/xp");
        if (xpRes.ok) {
          const xpData = await xpRes.json();
          if (xpData.xp !== undefined) setCurrentXp(xpData.xp);
          if (xpData.level !== undefined) setLevel(xpData.level);
          if (xpData.rankTitle !== undefined) setRankTitle(xpData.rankTitle);
        }

        // Fetch Orientation Result (to unlock step 1)
        const orientationRes = await fetch("/api/orientation/result");
        if (orientationRes.ok) {
          const orientationData = await orientationRes.json();
          if (orientationData.result) {
            setHasOrientation(true);
          }
        } else {
          // Fallback to local storage if API fails
          const stored = localStorage.getItem("activ_orientation_results");
          if (stored) setHasOrientation(true);
        }
      } catch (e) {
        console.error(e);
      } finally {
        setIsLoading(false);
      }
    };

    fetchUserData();
  }, []);

  const roadmapSteps = [
    {
      id: 1,
      title: "Diagnostic de profil (AÏDA)",
      desc: "Passez le test d'orientation IA pour découvrir vos métiers et écoles.",
      status: hasOrientation ? "done" : "current",
      xp: 200,
      icon: Trophy,
      actionText: hasOrientation ? "Revoir mes résultats" : "Passer le test",
      actionLink: "/student/orientation"
    },
    {
      id: 2,
      title: "Exploration des Métiers",
      desc: "Découvrez le catalogue des cours et les métiers associés.",
      status: hasOrientation ? "current" : "locked",
      xp: 150,
      icon: Compass,
      actionText: "Explorer l'académie",
      actionLink: "/student/cours"
    },
    {
      id: 3,
      title: "Sélection de Formations",
      desc: "Explorez les opportunités et ajoutez des formations en favoris.",
      status: "locked",
      xp: 300,
      icon: Star,
      actionText: "Voir les opportunités",
      actionLink: "/student/opportunites"
    },
    {
      id: 4,
      title: "Création du CV avec AÏDA",
      desc: "Générez votre premier CV professionnel grâce à l'IA.",
      status: "locked",
      xp: 250,
      icon: FileText,
      actionText: "Créer mon CV",
      actionLink: "#"
    },
    {
      id: 5,
      title: "Inscription au Salon de l'Orientation",
      desc: "Participez à un événement d'orientation près de chez vous.",
      status: "locked",
      xp: 500,
      icon: Map,
      actionText: "Voir les événements",
      actionLink: "#"
    }
  ];

  if (isLoading) {
    return (
      <div className="min-h-[75vh] flex items-center justify-center">
        <div className="w-8 h-8 border-2 border-primary border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  const nextLevelXp = level * 1000;

  return (
    <div className="flex flex-col gap-8 max-w-4xl mx-auto pb-12">
      {/* HEADER & GAMIFICATION */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-end gap-6 bg-surface p-6 md:p-8 rounded-3xl border border-border-soft shadow-sm relative overflow-hidden">
        <div className="absolute -top-12 -right-12 w-48 h-48 bg-primary/5 rounded-full blur-3xl pointer-events-none" />
        <div className="absolute -bottom-12 -left-12 w-48 h-48 bg-gold/5 rounded-full blur-3xl pointer-events-none" />

        <div className="relative z-10">
          <h1 className="text-3xl font-display font-bold text-text-primary mb-2">Mon Parcours</h1>
          <p className="text-text-secondary">Suivez votre progression et accomplissez vos quêtes d'orientation pas à pas.</p>
        </div>
        
        <div className="relative z-10 w-full md:w-auto bg-surface-alt p-4 rounded-2xl border border-border-soft flex flex-col gap-3 min-w-[250px]">
          <div className="flex justify-between items-center">
            <span className="font-bold text-sm text-text-primary">Niveau {level}</span>
            <span className="text-xs font-bold text-primary uppercase bg-primary/10 px-2 py-1 rounded-sm">{rankTitle}</span>
          </div>
          <div className="w-full bg-border-soft h-3 rounded-full overflow-hidden">
            <div 
              className="bg-gold-dark h-full rounded-full transition-all duration-1000 ease-out" 
              style={{ width: `${Math.min((currentXp / nextLevelXp) * 100, 100)}%` }}
            />
          </div>
          <div className="flex justify-between items-center text-xs text-text-secondary font-medium">
            <span>{currentXp} XP</span>
            <span>{nextLevelXp} XP (Niv. {level + 1})</span>
          </div>
        </div>
      </div>

      {/* AÏDA ASSISTANT */}
      <AidaAssistant 
        title={hasOrientation ? "Étape suivante débloquée !" : "Commencez votre quête !"}
        message={hasOrientation 
          ? "Bravo d'avoir complété votre profil ! Il est temps d'explorer les métiers qui vous correspondent." 
          : "Votre première mission est de passer le test AÏDA pour que je puisse vous guider au mieux."}
        variant="inline"
      />

      {/* ROADMAP TIMELINE */}
      <div className="mt-4 flex flex-col gap-4 relative">
        <div className="absolute left-[27px] top-6 bottom-12 w-[2px] bg-border-strong hidden md:block" />

        {roadmapSteps.map((step) => {
          const isDone = step.status === "done";
          const isCurrent = step.status === "current";
          const isLocked = step.status === "locked";
          const Icon = step.icon;

          return (
            <div key={step.id} className="flex gap-4 md:gap-6 relative group">
              {/* STATUS INDICATOR (Desktop) */}
              <div className="hidden md:flex flex-col items-center z-10 pt-4">
                {isDone ? (
                  <div className="w-14 h-14 rounded-full bg-primary flex items-center justify-center border-4 border-canvas shadow-sm transition-transform group-hover:scale-110">
                    <CheckCircle2 className="w-6 h-6 text-white" />
                  </div>
                ) : isCurrent ? (
                  <div className="w-14 h-14 rounded-full bg-gold-dark flex items-center justify-center border-4 border-canvas shadow-md animate-pulse-soft">
                    <Play className="w-5 h-5 text-white ml-1" />
                  </div>
                ) : (
                  <div className="w-14 h-14 rounded-full bg-surface-alt flex items-center justify-center border-4 border-canvas shadow-sm">
                    <Lock className="w-5 h-5 text-text-tertiary" />
                  </div>
                )}
              </div>

              {/* CARD */}
              <Card 
                variant="standard" 
                className={`flex-1 p-5 md:p-6 transition-all duration-300 ${
                  isCurrent ? "border-gold-dark ring-2 ring-gold/20 shadow-md transform md:-translate-y-1" : 
                  isLocked ? "opacity-60 bg-surface/50 border-dashed" : 
                  "hover:border-primary/30"
                }`}
              >
                <div className="flex justify-between items-start mb-2">
                  <div className="flex items-center gap-3">
                    <div className="md:hidden">
                      {isDone ? <CheckCircle2 className="w-5 h-5 text-primary" /> : 
                       isCurrent ? <Play className="w-5 h-5 text-gold-dark" /> : 
                       <Lock className="w-5 h-5 text-text-tertiary" />}
                    </div>
                    <span className={`text-[10px] uppercase font-bold px-2 py-1 rounded-sm ${
                      isDone ? "bg-primary/10 text-primary" :
                      isCurrent ? "bg-gold/20 text-gold-dark" :
                      "bg-border-soft text-text-secondary"
                    }`}>
                      Étape {step.id}
                    </span>
                  </div>
                  <span className={`text-xs font-bold flex items-center gap-1 ${
                    isDone ? "text-primary" :
                    isCurrent ? "text-gold-dark" :
                    "text-text-tertiary"
                  }`}>
                    +{step.xp} XP
                  </span>
                </div>

                <div className="flex gap-4 items-start">
                  <div className={`p-3 rounded-xl hidden sm:block ${
                    isDone ? "bg-primary/5 text-primary" :
                    isCurrent ? "bg-gold/10 text-gold-dark" :
                    "bg-surface-alt text-text-tertiary"
                  }`}>
                    <Icon className="w-6 h-6" />
                  </div>
                  <div className="flex-1">
                    <h3 className={`font-bold text-lg mb-1 ${isLocked ? "text-text-secondary" : "text-text-primary"}`}>
                      {step.title}
                    </h3>
                    <p className={`text-sm ${isLocked ? "text-text-tertiary" : "text-text-secondary"}`}>
                      {step.desc}
                    </p>
                    
                    {(isCurrent || isDone) && step.actionLink !== "#" && (
                      <div className="mt-4 flex flex-wrap gap-3">
                        <Button 
                          variant={isCurrent ? "primary" : "secondary"}
                          className={isCurrent ? "bg-gold-dark hover:bg-gold-dark/90 text-white w-full sm:w-auto" : "w-full sm:w-auto"} 
                          onClick={() => router.push(step.actionLink)}
                        >
                          {step.actionText}
                          <ArrowRight className="w-4 h-4 ml-2" />
                        </Button>
                      </div>
                    )}
                  </div>
                </div>
              </Card>
            </div>
          );
        })}
      </div>
    </div>
  );
}
