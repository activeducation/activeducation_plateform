'use client';

import React from 'react';
import { motion, useMotionValue, useTransform } from 'framer-motion';
import { RiasecQuestion } from '@/lib/orientation';
import {
  Wrench,
  Brain,
  Palette,
  Users,
  Briefcase,
  FileCheck,
  Check,
  X,
  Compass,
} from 'lucide-react';

interface SwipeCardProps {
  question: RiasecQuestion;
  currentIndex: number;
  totalQuestions: number;
  onAnswer: (score: number) => void;
  isFront: boolean;
}

export function SwipeCard({
  question,
  currentIndex,
  totalQuestions,
  onAnswer,
  isFront,
}: SwipeCardProps) {
  const x = useMotionValue(0);
  const rotate = useTransform(x, [-250, 250], [-18, 18]);
  const opacity = useTransform(x, [-250, -150, 0, 150, 250], [0.4, 1, 1, 1, 0.4]);

  // Opacité des badges d'intention au swipe
  const likeOpacity = useTransform(x, [20, 100], [0, 1]);
  const passOpacity = useTransform(x, [-20, -100], [0, 1]);

  const handleDragEnd = (_: unknown, info: { offset: { x: number }; velocity: { x: number } }) => {
    const swipeThreshold = 100;
    const velocityThreshold = 400;

    if (info.offset.x > swipeThreshold || info.velocity.x > velocityThreshold) {
      onAnswer(5); // M'intéresse / Adhésion forte
    } else if (info.offset.x < -swipeThreshold || info.velocity.x < -velocityThreshold) {
      onAnswer(1); // Passer / Pas pour moi
    }
  };

  // Icône adaptée par dimension RIASEC
  const getDimensionIcon = () => {
    switch (question.dimension) {
      case 'R':
        return <Wrench className="w-4 h-4 text-primary" />;
      case 'I':
        return <Brain className="w-4 h-4 text-primary" />;
      case 'A':
        return <Palette className="w-4 h-4 text-primary" />;
      case 'S':
        return <Users className="w-4 h-4 text-primary" />;
      case 'E':
        return <Briefcase className="w-4 h-4 text-primary" />;
      case 'C':
        return <FileCheck className="w-4 h-4 text-primary" />;
      default:
        return <Compass className="w-4 h-4 text-primary" />;
    }
  };

  return (
    <motion.div
      style={{
        x: isFront ? x : 0,
        rotate: isFront ? rotate : 0,
        opacity: isFront ? opacity : 0.9,
      }}
      drag={isFront ? 'x' : false}
      dragConstraints={{ left: 0, right: 0 }}
      dragElastic={0.7}
      onDragEnd={isFront ? handleDragEnd : undefined}
      className={`relative w-full max-w-[540px] min-h-[420px] bg-surface rounded-2xl border border-border-soft p-8 md:p-10 flex flex-col justify-between select-none shadow-sm ${
        isFront ? 'cursor-grab active:cursor-grabbing' : 'pointer-events-none'
      }`}
    >
      {/* BADGES INTENTION FLOTTANTS PENDANT LE GLISSER */}
      {isFront && (
        <>
          <motion.div
            style={{ opacity: likeOpacity }}
            className="absolute top-6 right-6 border-2 border-primary text-primary px-4 py-1.5 rounded-md font-bold text-xs uppercase tracking-wider flex items-center gap-1.5 bg-surface/95 shadow-sm pointer-events-none z-30"
          >
            <Check className="w-4 h-4" />
            <span>M’intéresse</span>
          </motion.div>

          <motion.div
            style={{ opacity: passOpacity }}
            className="absolute top-6 left-6 border-2 border-text-tertiary text-text-secondary px-4 py-1.5 rounded-md font-bold text-xs uppercase tracking-wider flex items-center gap-1.5 bg-surface/95 shadow-sm pointer-events-none z-30"
          >
            <X className="w-4 h-4" />
            <span>Passer</span>
          </motion.div>
        </>
      )}

      {/* EN-TÊTE DE CARTE : COMPTEUR & DIMENSION */}
      <div>
        <div className="flex items-center justify-between gap-3 pb-6 border-b border-border-soft/80">
          <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-md bg-canvas border border-border-soft text-text-secondary text-xs font-semibold">
            {getDimensionIcon()}
            <span>{question.category} • {question.categoryFr}</span>
          </div>

          <span className="text-xs font-mono font-medium text-text-tertiary">
            {currentIndex + 1} / {totalQuestions}
          </span>
        </div>

        {/* CORPS DE LA QUESTION */}
        <div className="mt-8">
          <h2 className="text-xl md:text-2xl font-bold text-text-primary leading-snug tracking-[-0.01em]">
            « {question.text} »
          </h2>
          <p className="mt-4 text-sm text-text-secondary leading-relaxed">
            {question.subtext}
          </p>
        </div>
      </div>

      {/* PIED DE CARTE : CONSEIL GESTE */}
      <div className="pt-6 border-t border-border-soft/60 flex items-center justify-between text-xs text-text-tertiary font-mono">
        <span>← Glisser à gauche pour passer</span>
        <span>Glisser à droite pour aimer →</span>
      </div>
    </motion.div>
  );
}
