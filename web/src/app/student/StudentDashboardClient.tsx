"use client";

import React, { useState, useEffect } from "react";
import { AidaAssistant } from "@/components/student/AidaAssistant";
import { Card } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import { useRouter } from "next/navigation";
import { Trophy, Compass, Star, ArrowRight } from "lucide-react";

export default function StudentDashboardClient({ 
  initialUser, 
  initialOrientation 
}: { 
  initialUser: any, 
  initialOrientation: any 
}) {
  const router = useRouter();
  const userName = initialUser?.fullName || initialUser?.email?.split('@')[0] || "Étudiant";
  const currentXp = initialUser?.xpPoints || 0;
  const level = initialUser?.level || 1;
  
  let rankTitle = "Novice";
  if (level >= 10) rankTitle = "Expert";
  else if (level >= 6) rankTitle = "Explorateur";
  else if (level >= 3) rankTitle = "Apprenti";

  const hasOrientation = !!initialOrientation;
  const topCareer = initialOrientation?.results?.recommendedCareers?.[0]?.title || null;

  const nextLevelXp = level * 1000;
  const progressPercent = Math.min((currentXp / nextLevelXp) * 100, 100);

  return (
    <div className="flex flex-col gap-8 pb-12">
      
      {/* HEADER */}
      <div className="flex flex-col gap-2">
        <h1 className="font-display font-bold text-3xl text-text-primary">
          Tableau de bord
        </h1>
        <p className="text-text-secondary">
          Bonjour <span className="font-bold text-text-primary">{userName}</span>, ravi de vous revoir. Continuons à construire votre avenir !
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
        
        {/* MAIN COLUMN */}
        <div className="lg:col-span-8 flex flex-col gap-8">
          
          <section className="flex flex-col gap-4">
            <h2 className="text-lg font-bold text-text-primary">Votre recommandation AÏDA</h2>
            
            {!hasOrientation ? (
              <AidaAssistant 
                title="L'aventure commence ici !"
                message="Votre profil d'orientation est encore vierge. Passez notre test IA exclusif pour découvrir les filières, les écoles au Togo et les métiers qui correspondent parfaitement à votre personnalité et à vos moyens."
                actionLabel="Passer le test d'orientation"
                actionHref="/student/orientation"
              />
            ) : (
              <AidaAssistant 
                title="Profil Complété !"
                message={`L'IA a identifié que vous aviez un fort potentiel pour le domaine : ${topCareer || 'Innovateur'}. Votre prochaine étape est d'explorer les cours liés à ce domaine.`}
                actionLabel="Revoir mes résultats"
                actionHref="/student/orientation?retake=true"
              />
            )}
          </section>

          <section className="flex flex-col gap-4">
            <h2 className="text-lg font-bold text-text-primary">Raccourcis</h2>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <Card 
                variant="standard" 
                className="p-5 flex flex-col justify-between gap-4 hover:border-primary/30 transition-colors cursor-pointer group"
                onClick={() => router.push('/student/cours')}
              >
                <div>
                  <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center mb-3">
                    <Compass className="w-5 h-5 text-primary" />
                  </div>
                  <h3 className="font-bold text-text-primary mb-1">Explorer l'Académie</h3>
                  <p className="text-sm text-text-secondary">Consultez les formations et modules E-learning.</p>
                </div>
                <div className="flex items-center text-xs font-bold text-primary opacity-0 group-hover:opacity-100 transition-opacity">
                  Y aller <ArrowRight className="w-3 h-3 ml-1" />
                </div>
              </Card>

              <Card 
                variant="standard" 
                className="p-5 flex flex-col justify-between gap-4 hover:border-gold/30 transition-colors cursor-pointer group"
                onClick={() => router.push('/student/opportunites')}
              >
                <div>
                  <div className="w-10 h-10 rounded-full bg-gold/10 flex items-center justify-center mb-3">
                    <Star className="w-5 h-5 text-gold-dark" />
                  </div>
                  <h3 className="font-bold text-text-primary mb-1">Opportunités & Stages</h3>
                  <p className="text-sm text-text-secondary">Trouvez des stages ou des bourses au Togo.</p>
                </div>
                <div className="flex items-center text-xs font-bold text-gold-dark opacity-0 group-hover:opacity-100 transition-opacity">
                  Y aller <ArrowRight className="w-3 h-3 ml-1" />
                </div>
              </Card>
            </div>
          </section>
        </div>

        {/* SIDEBAR COLUMN (GAMIFICATION) */}
        <div className="lg:col-span-4 flex flex-col gap-6">
          <Card variant="standard" className="p-6 relative overflow-hidden border-border-strong bg-gradient-to-b from-surface to-surface-alt">
            {/* Background decorations */}
            <div className="absolute -top-10 -right-10 w-32 h-32 bg-gold/10 rounded-full blur-2xl pointer-events-none" />
            
            <div className="relative z-10">
              <div className="flex items-center gap-3 mb-6">
                <div className="w-10 h-10 rounded-full bg-gold-dark flex items-center justify-center shadow-md">
                  <Trophy className="w-5 h-5 text-white" />
                </div>
                <div>
                  <h2 className="font-bold text-text-primary leading-tight">Mon Profil</h2>
                  <p className="text-xs text-text-secondary uppercase tracking-wider">Statistiques</p>
                </div>
              </div>

              <div className="flex flex-col gap-5">
                <div className="flex justify-between items-end">
                  <div className="flex flex-col">
                    <span className="text-sm text-text-secondary">Niveau Actuel</span>
                    <span className="text-3xl font-display font-bold text-primary">{level}</span>
                  </div>
                  <div className="flex flex-col text-right">
                    <span className="text-sm text-text-secondary">Rang</span>
                    <span className="text-sm font-bold text-gold-dark uppercase">{rankTitle}</span>
                  </div>
                </div>

                <div className="flex flex-col gap-2">
                  <div className="flex justify-between text-xs font-bold">
                    <span className="text-text-primary">{currentXp} XP</span>
                    <span className="text-text-tertiary">{nextLevelXp} XP</span>
                  </div>
                  <div className="w-full bg-canvas h-3 rounded-full overflow-hidden border border-border-soft">
                    <div 
                      className="bg-primary h-full rounded-full transition-all duration-1000 ease-out" 
                      style={{ width: `${progressPercent}%` }}
                    />
                  </div>
                  <p className="text-xs text-text-secondary text-center mt-1">
                    Plus que <span className="font-bold text-text-primary">{nextLevelXp - currentXp} XP</span> avant le niveau {level + 1} !
                  </p>
                </div>

                <Button 
                  variant="outline" 
                  className="w-full mt-2 text-xs py-2"
                  onClick={() => router.push('/student/parcours')}
                >
                  Voir ma feuille de route
                </Button>
              </div>
            </div>
          </Card>
        </div>

      </div>
    </div>
  );
}
