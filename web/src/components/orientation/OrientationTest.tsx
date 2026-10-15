'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { AnimatePresence, motion } from 'framer-motion';
import { RIASEC_QUESTIONS } from '@/lib/orientation';
import { SwipeCard } from './SwipeCard';
import { Button } from '@/components/ui/Button';
import {
  Check,
  X,
  RotateCcw,
  Sparkles,
  ShieldCheck,
} from 'lucide-react';

interface OrientationTestProps {
  onComplete: (answers: Record<string, number>) => void;
  onCancel?: () => void;
}

export function OrientationTest({ onComplete, onCancel }: OrientationTestProps) {
  const [currentIndex, setCurrentIndex] = useState(0);
  const [answers, setAnswers] = useState<Record<string, number>>({});
  const [direction, setDirection] = useState<'left' | 'right' | null>(null);

  const total = RIASEC_QUESTIONS.length;
  const currentQuestion = RIASEC_QUESTIONS[currentIndex];
  const nextQuestion = currentIndex + 1 < total ? RIASEC_QUESTIONS[currentIndex + 1] : null;
  const thirdQuestion = currentIndex + 2 < total ? RIASEC_QUESTIONS[currentIndex + 2] : null;

  const progressPercent = Math.round((currentIndex / total) * 100);

  const handleAnswer = useCallback(
    (score: number) => {
      if (!currentQuestion) return;

      const newAnswers = {
        ...answers,
        [currentQuestion.id]: score,
      };
      setAnswers(newAnswers);
      setDirection(score >= 3 ? 'right' : 'left');

      if (currentIndex + 1 >= total) {
        onComplete(newAnswers);
      } else {
        setCurrentIndex((prev) => prev + 1);
      }
    },
    [answers, currentIndex, currentQuestion, total, onComplete]
  );

  const handlePrevious = () => {
    if (currentIndex > 0) {
      setCurrentIndex((prev) => prev - 1);
    }
  };

  // Raccourcis clavier (Flèche gauche = Passer, Flèche droite = M'intéresse, Touches 1-5)
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'ArrowLeft') {
        e.preventDefault();
        handleAnswer(1);
      } else if (e.key === 'ArrowRight') {
        e.preventDefault();
        handleAnswer(5);
      } else if (['1', '2', '3', '4', '5'].includes(e.key)) {
        e.preventDefault();
        handleAnswer(parseInt(e.key, 10));
      } else if (e.key === 'Backspace' || e.key === 'z') {
        if (currentIndex > 0) handlePrevious();
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [currentIndex, handleAnswer]);

  return (
    <div className="w-full max-w-2xl mx-auto flex flex-col items-center gap-8 py-4">
      {/* BARRE DE PROGRESSION DU TEST (Primaire #3133DD) */}
      <div className="w-full bg-surface border border-border-soft p-5 rounded-xl flex flex-col gap-2.5 shadow-sm">
        <div className="flex items-center justify-between text-xs">
          <div className="flex items-center gap-3">
            <span className="font-semibold text-text-primary flex items-center gap-1.5">
              <Sparkles className="w-3.5 h-3.5 text-primary" />
              <span>Test d’Orientation RIASEC</span>
            </span>
            {onCancel && (
              <button
                type="button"
                onClick={onCancel}
                className="text-[11px] text-text-tertiary hover:text-text-secondary transition-colors underline"
              >
                Quitter
              </button>
            )}
          </div>
          <span className="font-mono text-primary font-bold">
            Question {Math.min(currentIndex + 1, total)} sur {total} ({progressPercent}%)
          </span>
        </div>

        {/* Jauge de progression */}
        <div className="w-full h-2 bg-canvas rounded-full overflow-hidden border border-border-soft/60">
          <div
            className="h-full bg-primary transition-all duration-300 ease-out"
            style={{ width: `${progressPercent}%` }}
          />
        </div>
      </div>

      {/* PILE DE CARTES INTERACTIVES (CARD STACK) */}
      <div className="relative w-full flex items-center justify-center min-h-[440px] px-2">
        <AnimatePresence mode="popLayout">
          {/* Troisième carte en arrière-plan */}
          {thirdQuestion && (
            <motion.div
              key={thirdQuestion.id}
              initial={{ scale: 0.9, y: 24, opacity: 0.5 }}
              animate={{ scale: 0.9, y: 24, opacity: 0.5 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.2 }}
              className="absolute inset-0 flex items-center justify-center pointer-events-none"
            >
              <SwipeCard
                question={thirdQuestion}
                currentIndex={currentIndex + 2}
                totalQuestions={total}
                onAnswer={() => {}}
                isFront={false}
              />
            </motion.div>
          )}

          {/* Deuxième carte */}
          {nextQuestion && (
            <motion.div
              key={nextQuestion.id}
              initial={{ scale: 0.95, y: 12, opacity: 0.8 }}
              animate={{ scale: 0.95, y: 12, opacity: 0.8 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.2 }}
              className="absolute inset-0 flex items-center justify-center pointer-events-none"
            >
              <SwipeCard
                question={nextQuestion}
                currentIndex={currentIndex + 1}
                totalQuestions={total}
                onAnswer={() => {}}
                isFront={false}
              />
            </motion.div>
          )}

          {/* Première carte (active) */}
          {currentQuestion && (
            <motion.div
              key={currentQuestion.id}
              initial={{ scale: 0.95, y: 10, opacity: 0 }}
              animate={{ scale: 1, y: 0, opacity: 1 }}
              exit={{
                x: direction === 'right' ? 450 : -450,
                opacity: 0,
                rotate: direction === 'right' ? 15 : -15,
              }}
              transition={{ duration: 0.22, ease: [0.33, 1, 0.68, 1] }}
              className="w-full flex items-center justify-center"
            >
              <SwipeCard
                question={currentQuestion}
                currentIndex={currentIndex}
                totalQuestions={total}
                onAnswer={handleAnswer}
                isFront={true}
              />
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {/* CONTRÔLES D'ACTION ACCESSIBLES (BOUTONS & ÉCHELLE LIKERT) */}
      <div className="w-full max-w-[540px] flex flex-col items-center gap-5">
        {/* BOUTONS PRINCIPAUX PASSER / M'INTÉRESSE */}
        <div className="w-full flex items-center justify-between gap-4">
          <Button
            type="button"
            variant="secondary"
            onClick={() => handleAnswer(1)}
            className="flex-1 flex items-center justify-center gap-2 py-3.5 border-border-soft hover:border-text-secondary"
          >
            <X className="w-4 h-4 text-text-secondary" />
            <span>Passer</span>
          </Button>

          {/* Bouton retour en arrière */}
          <button
            type="button"
            disabled={currentIndex === 0}
            onClick={handlePrevious}
            title="Revenir à la question précédente"
            className="p-3 rounded-md border border-border-soft bg-surface text-text-secondary hover:text-primary hover:border-primary/40 disabled:opacity-30 disabled:pointer-events-none transition-colors"
          >
            <RotateCcw className="w-4 h-4" />
          </button>

          <Button
            type="button"
            variant="primary"
            onClick={() => handleAnswer(5)}
            className="flex-1 flex items-center justify-center gap-2 py-3.5 shadow-sm"
          >
            <Check className="w-4 h-4 text-white" />
            <span>M’intéresse</span>
          </Button>
        </div>

        {/* ÉCHELLE LIKERT RAPIDE DE NOTATION (1 À 5) */}
        <div className="w-full bg-surface border border-border-soft rounded-xl p-4 flex flex-col gap-2.5">
          <div className="flex items-center justify-between text-[11px] font-mono text-text-tertiary">
            <span>Pas du tout</span>
            <span className="text-text-secondary font-semibold">Échelle de préférence</span>
            <span>Passionnément</span>
          </div>

          <div className="grid grid-cols-5 gap-2">
            {[1, 2, 3, 4, 5].map((level) => (
              <button
                key={level}
                type="button"
                onClick={() => handleAnswer(level)}
                className="py-2.5 rounded-md border border-border-soft bg-canvas text-text-primary text-xs font-mono font-bold hover:border-primary hover:text-primary hover:bg-surface transition-all focus:outline-none focus:ring-2 focus:ring-primary/40"
              >
                {level}
              </button>
            ))}
          </div>
        </div>

        {/* MENTION DE CONFORMITÉ TOGO */}
        <div className="flex items-center gap-2 text-xs text-text-tertiary">
          <ShieldCheck className="w-3.5 h-3.5 text-primary shrink-0" />
          <span>Calibré selon le modèle de Holland et le marché de l’enseignement supérieur togolais</span>
        </div>
      </div>
    </div>
  );
}
