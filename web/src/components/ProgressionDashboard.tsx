"use client";

import React, { useState } from 'react';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { StudentProgression } from '@/types';
import {
  Flame,
  Trophy,
  Award,
  CheckCircle2,
  Sparkles,
  Zap,
  GraduationCap,
  Lock,
  TrendingUp,
} from 'lucide-react';

interface ProgressionDashboardProps {
  initialProgression: StudentProgression;
}

export function ProgressionDashboard({ initialProgression }: ProgressionDashboardProps) {
  const [progression, setProgression] = useState<StudentProgression>(initialProgression);
  const [claimedReward, setClaimedReward] = useState(false);

  const xpProgressPercentage = Math.min(
    100,
    Math.round((progression.currentXp / progression.nextLevelXp) * 100)
  );

  const handleClaimBonus = () => {
    if (!claimedReward) {
      setProgression((prev) => ({
        ...prev,
        currentXp: Math.min(prev.nextLevelXp, prev.currentXp + 50),
      }));
      setClaimedReward(true);
    }
  };

  return (
    <div className="flex flex-col gap-8 w-full" id="progression">
      {/* SECTION HEADER */}
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-6 pb-6 border-b border-primary/10">
        <div>
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-sm bg-gold-surface text-gold-dark border border-gold/30 text-xs font-semibold uppercase tracking-wider mb-2">
            <Trophy className="w-3.5 h-3.5 text-gold-dark" />
            <span>Tableau de Bord Gamifié</span>
          </div>
          <h2 className="text-2xl md:text-3xl font-bold tracking-tight text-text-primary">
            Progression de l’Étudiant
          </h2>
          <p className="mt-1 text-text-secondary text-sm md:text-base max-w-[65ch]">
            Suivi d’apprentissage en temps réel, accumulation d’expérience et déblocage de certifications académiques.
          </p>
        </div>

        {/* Student Profile Pill */}
        <div className="flex items-center gap-3 bg-surface p-2.5 px-4 rounded-lg border border-primary/10 shadow-sm">
          <div className="w-10 h-10 rounded-sm bg-gold-surface border border-gold/40 flex items-center justify-center text-gold-dark font-bold font-display">
            AD
          </div>
          <div>
            <div className="text-sm font-bold text-text-primary">
              {progression.student.fullName}
            </div>
            <div className="text-xs text-text-secondary">
              {progression.student.schoolLevel} • {progression.student.location}
            </div>
          </div>
        </div>
      </div>

      {/* TOP KPI ROW (BENTO STYLE) */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {/* Card 1: Level & XP - Gamification Card */}
        <Card variant="gamification" interactive={true} className="p-6 flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-gold-dark uppercase tracking-wider">
              Niveau Actuel
            </span>
            <div className="p-2 rounded-sm bg-gold/15 text-gold-dark">
              <Zap className="w-4 h-4" />
            </div>
          </div>
          <div className="my-3">
            <div className="text-3xl font-extrabold font-display text-dark-base">
              Niveau {progression.currentLevel}
            </div>
            <p className="text-xs font-medium text-text-secondary mt-0.5">
              {progression.levelTitle}
            </p>
          </div>
          <div className="text-xs font-mono font-bold text-gold-dark flex items-center gap-1">
            <TrendingUp className="w-3.5 h-3.5" />
            <span>Rang #{progression.leaderboardRank} de la promotion</span>
          </div>
        </Card>

        {/* Card 2: Streak Metric - Gamification Card */}
        <Card variant="gamification" interactive={true} className="p-6 flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-gold-dark uppercase tracking-wider">
              Série d’Assiduité
            </span>
            <div className="p-2 rounded-sm bg-gold text-white shadow-gold animate-pulse">
              <Flame className="w-4 h-4" />
            </div>
          </div>
          <div className="my-3">
            <div className="flex items-baseline gap-2">
              <span className="text-3xl font-extrabold font-mono text-dark-base">
                {progression.dailyStreak}
              </span>
              <span className="text-sm font-semibold text-gold-dark">jours consécutifs</span>
            </div>
            <p className="text-xs text-text-secondary mt-0.5">
              Record personnel : {progression.longestStreak} jours
            </p>
          </div>
          <div className="text-xs text-gold-dark font-medium flex items-center gap-1.5">
            <span className="w-2 h-2 rounded-sm bg-gold"></span>
            <span>Activité validée aujourd’hui</span>
          </div>
        </Card>

        {/* Card 3: Lessons Completed */}
        <Card variant="standard" interactive={true} className="p-6 flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-text-secondary uppercase tracking-wider">
              Leçons Validées
            </span>
            <div className="p-2 rounded-sm bg-primary-surface text-primary">
              <CheckCircle2 className="w-4 h-4" />
            </div>
          </div>
          <div className="my-3">
            <div className="flex items-baseline gap-2">
              <span className="text-3xl font-extrabold font-mono text-text-primary">
                {progression.completedLessonsCount}
              </span>
              <span className="text-sm font-medium text-text-secondary">
                / {progression.totalLessonsCount} leçons
              </span>
            </div>
            <p className="text-xs text-text-secondary mt-0.5">
              Taux de complétion global
            </p>
          </div>
          <div className="w-full bg-surface-alt rounded-sm h-2 overflow-hidden">
            <div
              className="h-full bg-primary rounded-sm transition-all duration-500"
              style={{
                width: `${Math.round(
                  (progression.completedLessonsCount / progression.totalLessonsCount) * 100
                )}%`,
              }}
            />
          </div>
        </Card>

        {/* Card 4: Total XP Points */}
        <Card variant="gamification" interactive={true} className="p-6 flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-gold-dark uppercase tracking-wider">
              Score d’Expérience
            </span>
            <div className="p-2 rounded-sm bg-gold/15 text-gold-dark">
              <Sparkles className="w-4 h-4" />
            </div>
          </div>
          <div className="my-3">
            <div className="text-3xl font-extrabold font-mono text-dark-base">
              {progression.currentXp}{' '}
              <span className="text-sm font-bold text-gold-dark">XP</span>
            </div>
            <p className="text-xs text-text-secondary mt-0.5">
              Objectif palier : {progression.nextLevelXp} XP
            </p>
          </div>
          <div className="text-xs font-mono font-bold text-gold-dark">
            +{progression.nextLevelXp - progression.currentXp} XP requis
          </div>
        </Card>
      </div>

      {/* DETAILED PROGRESSION BAR & ACTIONS BANNER */}
      <Card variant="gamification" className="p-6 md:p-8">
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-6">
          <div className="flex-1">
            <div className="flex items-center justify-between mb-2">
              <div className="flex items-center gap-2">
                <span className="font-display font-bold text-base md:text-lg text-dark-base">
                  Progression vers le Niveau {progression.currentLevel + 1}
                </span>
                <span className="px-2 py-0.5 rounded-sm bg-white/70 text-gold-dark text-xs font-mono font-bold border border-gold/30">
                  {xpProgressPercentage}%
                </span>
              </div>
              <span className="font-mono font-bold text-sm md:text-base text-gold-dark">
                {progression.currentXp} / {progression.nextLevelXp} XP
              </span>
            </div>

            {/* Custom XP Progress Track per DESIGN.md §4 */}
            <div className="h-3.5 bg-surface-alt rounded-sm overflow-hidden border border-gold/20 p-0.5 shadow-inner">
              <div
                className="h-full bg-gradient-to-r from-[#34D399] to-[#10B981] rounded-sm transition-all duration-700 relative"
                style={{ width: `${xpProgressPercentage}%` }}
              >
                <div className="absolute inset-0 bg-white/20 animate-pulse" />
              </div>
            </div>

            <div className="flex justify-between items-center text-xs text-text-secondary mt-2">
              <span>{progression.completedLessonsCount} sur {progression.totalLessonsCount} leçons terminées</span>
              <span className="font-mono font-medium text-gold-dark">
                Encore {progression.nextLevelXp - progression.currentXp} XP pour débloquer le Niveau {progression.currentLevel + 1}
              </span>
            </div>
          </div>

          <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3">
            <Button
              variant="gamification"
              onClick={handleClaimBonus}
              disabled={claimedReward}
              className="text-xs md:text-sm whitespace-nowrap"
            >
              {claimedReward ? 'XP Journalier Réclamé (+50 XP)' : 'Valider ma progression (+50 XP)'}
            </Button>
          </div>
        </div>
      </Card>

      {/* TWO-COLUMN DETAIL: ACHIEVEMENTS & COMPLETED LESSONS */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
        {/* Left Column: Achievements & Badges (5 cols) */}
        <div className="lg:col-span-5 flex flex-col gap-4">
          <div className="flex items-center justify-between">
            <h3 className="font-bold text-lg text-text-primary flex items-center gap-2">
              <Award className="w-5 h-5 text-gold" />
              <span>Badges & Accomplissements</span>
            </h3>
            <span className="text-xs font-mono font-bold text-gold-dark bg-gold-surface px-2.5 py-1 rounded-sm border border-gold/30">
              3 débloqués / 4
            </span>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-1 gap-3">
            {progression.achievements.map((ach) => (
              <div
                key={ach.id}
                className={`
                  p-4 rounded-lg border transition-all duration-normal flex items-start gap-4
                  ${
                    ach.isUnlocked
                      ? 'bg-surface border-gold/40 shadow-gold'
                      : 'bg-surface/50 border-primary/10 opacity-50 grayscale'
                  }
                `}
              >
                <div
                  className={`
                    w-12 h-12 rounded-sm flex items-center justify-center shrink-0 border-2
                    ${
                      ach.isUnlocked
                        ? 'bg-gold-surface border-gold text-gold-dark shadow-sm'
                        : 'bg-surface-alt border-text-tertiary/30 text-text-tertiary'
                    }
                  `}
                >
                  {ach.isUnlocked ? (
                    ach.iconName === 'award' ? (
                      <Award className="w-6 h-6" />
                    ) : ach.iconName === 'flame' ? (
                      <Flame className="w-6 h-6" />
                    ) : ach.iconName === 'trophy' ? (
                      <Trophy className="w-6 h-6" />
                    ) : (
                      <Sparkles className="w-6 h-6" />
                    )
                  ) : (
                    <Lock className="w-5 h-5" />
                  )}
                </div>

                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between gap-1">
                    <h4 className="font-bold text-sm text-text-primary truncate">
                      {ach.title}
                    </h4>
                    {ach.isUnlocked && ach.unlockedAt && (
                      <span className="text-[11px] font-mono text-gold-dark shrink-0">
                        {ach.unlockedAt}
                      </span>
                    )}
                  </div>
                  <p className="text-xs text-text-secondary mt-1 line-clamp-2">
                    {ach.description}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Right Column: Completed Lessons Activity Log (7 cols) */}
        <div className="lg:col-span-7 flex flex-col gap-4">
          <div className="flex items-center justify-between">
            <h3 className="font-bold text-lg text-text-primary flex items-center gap-2">
              <GraduationCap className="w-5 h-5 text-primary" />
              <span>Dernières Leçons Terminées</span>
            </h3>
            <span className="text-xs font-mono text-text-secondary">
              14 leçons au total
            </span>
          </div>

          <div className="bg-surface rounded-lg border border-primary/10 divide-y divide-primary/10 overflow-hidden shadow-card">
            {progression.recentCompletedLessons.map((lesson) => (
              <div
                key={lesson.id}
                className="p-4 flex items-center justify-between gap-4 hover:bg-surface-alt/50 transition-colors"
              >
                <div className="flex items-center gap-3.5 min-w-0">
                  <div className="w-8 h-8 rounded-sm bg-primary-surface text-primary flex items-center justify-center shrink-0">
                    <CheckCircle2 className="w-4 h-4" />
                  </div>
                  <div className="min-w-0">
                    <h5 className="font-semibold text-sm text-text-primary truncate">
                      {lesson.title}
                    </h5>
                    <div className="flex items-center gap-2 text-xs text-text-secondary mt-0.5">
                      <span className="truncate">{lesson.courseTitle}</span>
                      <span>•</span>
                      <span className="shrink-0">{lesson.completedAgo}</span>
                    </div>
                  </div>
                </div>

                <div className="shrink-0 flex items-center gap-2">
                  <span className="px-2.5 py-1 rounded-sm bg-gold-surface text-gold-dark font-mono font-bold text-xs border border-gold/25">
                    +{lesson.xpEarned} XP
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
