'use client';

import React, { useState } from 'react';
import { Navbar } from '@/components/Navbar';
import { OrientationTest } from '@/components/orientation/OrientationTest';
import { OrientationResults } from '@/components/orientation/OrientationResults';
import { MatchResponse } from '@/lib/orientation';
import { Button } from '@/components/ui/Button';
import { Card } from '@/components/ui/Card';
import {
  Compass,
  Sparkles,
  ArrowRight,
  ShieldCheck,
  Clock,
  Layers,
  GraduationCap,
  Briefcase,
  AlertCircle,
} from 'lucide-react';

type OrientationStep = 'intro' | 'test' | 'loading' | 'results';

export default function OrientationPage() {
  const [step, setStep] = useState<OrientationStep>('intro');
  const [results, setResults] = useState<MatchResponse | null>(null);
  const [error, setError] = useState<string | null>(null);

  const handleStartTest = () => {
    setError(null);
    setStep('test');
  };

  const handleTestComplete = async (answers: Record<string, number>) => {
    setStep('loading');
    setError(null);

    try {
      const response = await fetch('/api/match', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          answers,
          studentContext: {
            schoolLevel: 'Terminale / Supérieur',
            city: 'Lomé',
          },
        }),
      });

      if (!response.ok) {
        throw new Error('Erreur lors du calcul de votre matching d’orientation.');
      }

      const data: MatchResponse = await response.json();
      setResults(data);
      setStep('results');
    } catch (err: unknown) {
      console.error('Erreur matching:', err);
      setError(
        err instanceof Error
          ? err.message
          : 'Impossible de contacter le service d’orientation. Veuillez réessayer.'
      );
      setStep('intro');
    }
  };

  return (
    <div className="flex flex-col min-h-[100dvh] bg-canvas text-text-primary">
      {/* NAVBAR */}
      <Navbar />

      {/* CONTENU PRINCIPAL */}
      <main className="flex-1 flex flex-col py-10 px-[clamp(1.5rem,5vw,3.5rem)] max-w-[1400px] w-full mx-auto">
        {/* ÉCRAN D'ACCUEIL / INTRO */}
        {step === 'intro' && (
          <div className="flex-1 flex flex-col items-center justify-center py-8">
            <div className="w-full max-w-4xl flex flex-col items-center text-center">
              {/* Badge d'en-tête */}
              <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-sm bg-primary-surface border border-primary/20 text-primary text-xs font-semibold uppercase tracking-wider mb-6">
                <Compass className="w-4 h-4" />
                <span>Orientation Scolaire & Professionnelle</span>
              </div>

              {/* Titre Principal */}
              <h1 className="font-display font-extrabold text-3xl md:text-5xl lg:text-6xl text-text-primary tracking-[-0.03em] leading-[1.12]">
                Découvrez votre Vocation et vos <br />
                <span className="text-primary">Filières d’Excellence au Togo.</span>
              </h1>

              {/* Descriptif */}
              <p className="mt-6 text-text-secondary text-base md:text-lg leading-relaxed max-w-[65ch]">
                Un test interactif rapide de 12 questions fondé sur le modèle scientifique de Holland (RIASEC).
                Notre intelligence d’orientation AÏDA révèle vos talents naturels, sélectionne 3 métiers porteurs et identifie les universités agréées au Togo faites pour vous.
              </p>

              {/* Message d'erreur éventuel */}
              {error && (
                <div className="mt-6 w-full max-w-md p-4 bg-red-50 border border-red-200 text-red-700 rounded-lg flex items-center gap-3 text-sm text-left">
                  <AlertCircle className="w-5 h-5 shrink-0" />
                  <span>{error}</span>
                </div>
              )}

              {/* Bouton CTA Principal */}
              <div className="mt-10 flex flex-col sm:flex-row items-center gap-4">
                <Button
                  type="button"
                  size="lg"
                  variant="primary"
                  onClick={handleStartTest}
                  className="w-full sm:w-auto flex items-center justify-center gap-3 shadow-sm px-8"
                >
                  <Sparkles className="w-5 h-5" />
                  <span>Démarrer le Test d’Orientation</span>
                  <ArrowRight className="w-5 h-5" />
                </Button>
              </div>

              {/* Grille des 4 Bénéfices / Piliers */}
              <div className="mt-16 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 w-full text-left">
                <Card variant="standard" className="p-6">
                  <div className="w-10 h-10 rounded-lg bg-primary-surface border border-primary/20 flex items-center justify-center text-primary mb-4">
                    <Layers className="w-5 h-5" />
                  </div>
                  <h3 className="font-bold text-base text-text-primary mb-1">
                    Format Ludique à Swiper
                  </h3>
                  <p className="text-xs text-text-secondary leading-relaxed">
                    Cartes interactives intuitives à glisser à droite ou à gauche pour une expérience captivante.
                  </p>
                </Card>

                <Card variant="standard" className="p-6">
                  <div className="w-10 h-10 rounded-lg bg-primary-surface border border-primary/20 flex items-center justify-center text-primary mb-4">
                    <Clock className="w-5 h-5" />
                  </div>
                  <h3 className="font-bold text-base text-text-primary mb-1">
                    90 Secondes Chrono
                  </h3>
                  <p className="text-xs text-text-secondary leading-relaxed">
                    12 questions étalonnées couvrant équitablement les 6 dimensions RIASEC sans superflu.
                  </p>
                </Card>

                <Card variant="standard" className="p-6">
                  <div className="w-10 h-10 rounded-lg bg-primary-surface border border-primary/20 flex items-center justify-center text-primary mb-4">
                    <Briefcase className="w-5 h-5" />
                  </div>
                  <h3 className="font-bold text-base text-text-primary mb-1">
                    Débouchés Réels au Togo
                  </h3>
                  <p className="text-xs text-text-secondary leading-relaxed">
                    Recommandations de métiers à forte employabilité avec salaires réels en Francs CFA.
                  </p>
                </Card>

                <Card variant="standard" className="p-6">
                  <div className="w-10 h-10 rounded-lg bg-primary-surface border border-primary/20 flex items-center justify-center text-primary mb-4">
                    <ShieldCheck className="w-5 h-5" />
                  </div>
                  <h3 className="font-bold text-base text-text-primary mb-1">
                    Établissements Agréés
                  </h3>
                  <p className="text-xs text-text-secondary leading-relaxed">
                    Sélection rigoureuse parmi les 111 universités et écoles homologuées MESR Togo et CAMES.
                  </p>
                </Card>
              </div>
            </div>
          </div>
        )}

        {/* ÉCRAN DE PASSATION DU TEST (SWIPE & QCM) */}
        {step === 'test' && (
          <div className="flex-1 flex flex-col items-center justify-center">
            <OrientationTest
              onComplete={handleTestComplete}
              onCancel={() => setStep('intro')}
            />
          </div>
        )}

        {/* ÉCRAN DE CHARGEMENT / ANALYSE IA AÏDA */}
        {step === 'loading' && (
          <div className="flex-1 flex flex-col items-center justify-center py-20">
            <div className="w-full max-w-md bg-surface border border-border-soft rounded-2xl p-10 flex flex-col items-center text-center shadow-sm">
              <div className="relative w-16 h-16 rounded-2xl bg-primary-surface border border-primary/30 flex items-center justify-center text-primary mb-6 animate-pulse">
                <Sparkles className="w-8 h-8 text-primary" />
              </div>

              <h2 className="font-display font-bold text-xl text-text-primary mb-2">
                AÏDA analyse votre profil...
              </h2>
              <p className="text-xs text-text-secondary leading-relaxed mb-6">
                Calcul des 6 dimensions RIASEC, déduction des aptitudes dominantes et matching avec les opportunités académiques au Togo.
              </p>

              {/* Étapes animées de validation */}
              <div className="w-full flex flex-col gap-2.5 text-xs text-left">
                <div className="p-2.5 rounded-md bg-canvas border border-border-soft flex items-center gap-2 text-text-primary">
                  <div className="w-2 h-2 rounded-full bg-primary animate-ping" />
                  <span>Calcul des coefficients de Holland...</span>
                </div>
                <div className="p-2.5 rounded-md bg-canvas border border-border-soft flex items-center gap-2 text-text-secondary">
                  <div className="w-2 h-2 rounded-full bg-primary" />
                  <span>Croisement avec le marché de l’emploi togolais...</span>
                </div>
                <div className="p-2.5 rounded-md bg-canvas border border-border-soft flex items-center gap-2 text-text-secondary">
                  <div className="w-2 h-2 rounded-full bg-primary" />
                  <span>Sélection des filières accréditées MESR / CAMES...</span>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* ÉCRAN DU DASHBOARD DE RÉSULTATS */}
        {step === 'results' && results && (
          <div className="flex-1 flex flex-col">
            <OrientationResults
              results={results}
              onRetake={() => setStep('intro')}
            />
          </div>
        )}
      </main>

      {/* FOOTER */}
      <footer className="mt-20 border-t border-primary/10 bg-surface py-12 px-[clamp(1.5rem,5vw,3.5rem)] text-sm text-text-secondary">
        <div className="max-w-[1400px] mx-auto flex flex-col md:flex-row items-center justify-between gap-6">
          <div className="flex items-center gap-2">
            <GraduationCap className="w-5 h-5 text-primary" />
            <span className="font-display font-bold text-text-primary">ActivEducation</span>
            <span>— Académie d’Excellence</span>
          </div>
          <div className="text-xs">
            © 2026 ActivEducation. Tous droits réservés.
          </div>
        </div>
      </footer>
    </div>
  );
}
