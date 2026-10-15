'use client';

import React, { useState, useEffect } from 'react';
import { Navbar } from '@/components/Navbar';
import { OrientationTest } from '@/components/orientation/OrientationTest';
import { OrientationResults } from '@/components/orientation/OrientationResults';
import { MatchResponse } from '@/lib/orientation';
import { Button } from '@/components/ui/Button';
import { Card } from '@/components/ui/Card';
import { Input } from '@/components/ui/Input';
import { createClient } from '@/utils/supabase/client';
import type { User } from '@supabase/supabase-js';
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
  Lock,
  CheckCircle2,
  Loader2,
  RotateCcw,
} from 'lucide-react';

type OrientationStep = 'intro' | 'test' | 'loading' | 'auth_gate' | 'results';

export default function OrientationPage() {
  const [step, setStep] = useState<OrientationStep>('intro');
  const [results, setResults] = useState<MatchResponse | null>(null);
  const [savedAnswers, setSavedAnswers] = useState<Record<string, number> | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [currentUser, setCurrentUser] = useState<User | null>(null);

  // États pour l'étape d'authentification (auth_gate)
  const [authTab, setAuthTab] = useState<'register' | 'login'>('register');
  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [authLoading, setAuthLoading] = useState(false);
  const [authError, setAuthError] = useState<string | null>(null);
  const [authSuccessMessage, setAuthSuccessMessage] = useState<string | null>(null);

  // Vérifier si une session existe déjà au chargement et restaurer des résultats en attente si applicable
  useEffect(() => {
    const supabase = createClient();
    supabase.auth.getUser().then(({ data: { user } }) => {
      if (user) {
        setCurrentUser(user);
        if (typeof window !== 'undefined') {
          const pendingResultsStr = sessionStorage.getItem('activeducation_pending_orientation_results');
          const pendingAnswersStr = sessionStorage.getItem('activeducation_pending_orientation_answers');
          if (pendingResultsStr) {
            try {
              const parsedResults: MatchResponse = JSON.parse(pendingResultsStr);
              const parsedAnswers: Record<string, number> = pendingAnswersStr ? JSON.parse(pendingAnswersStr) : {};
              setResults(parsedResults);
              setSavedAnswers(parsedAnswers);
              setStep('results');
              // Sauvegarde en base en tâche de fond
              fetch('/api/orientation/save', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ answers: parsedAnswers, results: parsedResults }),
              }).catch(console.error);

              sessionStorage.removeItem('activeducation_pending_orientation_results');
              sessionStorage.removeItem('activeducation_pending_orientation_answers');
            } catch (e) {
              console.error('Erreur restauration session orientation:', e);
            }
          }
        }
      }
    });
  }, []);

  const handleStartTest = () => {
    setError(null);
    setStep('test');
  };

  const handleTestComplete = async (answers: Record<string, number>) => {
    setStep('loading');
    setError(null);
    setSavedAnswers(answers);

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

      // Vérifier si l'utilisateur est déjà connecté
      const supabase = createClient();
      const { data: { user } } = await supabase.auth.getUser();

      if (user) {
        // Utilisateur déjà authentifié : affichage direct des résultats et sauvegarde
        setCurrentUser(user);
        setStep('results');
        fetch('/api/orientation/save', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ answers, results: data }),
        }).catch(console.error);
      } else {
        // Visiteur non connecté : stockage temporaire et affichage de la porte d'authentification
        if (typeof window !== 'undefined') {
          sessionStorage.setItem('activeducation_pending_orientation_results', JSON.stringify(data));
          sessionStorage.setItem('activeducation_pending_orientation_answers', JSON.stringify(answers));
        }
        setStep('auth_gate');
      }
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

  // Traitement de l'inscription via Supabase
  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    setAuthLoading(true);
    setAuthError(null);
    setAuthSuccessMessage(null);

    if (!fullName.trim()) {
      setAuthError('Veuillez renseigner votre nom complet.');
      setAuthLoading(false);
      return;
    }

    if (password.length < 6) {
      setAuthError('Le mot de passe doit comporter au moins 6 caractères.');
      setAuthLoading(false);
      return;
    }

    try {
      const supabase = createClient();
      const { data, error: signUpError } = await supabase.auth.signUp({
        email: email.trim(),
        password,
        options: {
          data: {
            full_name: fullName.trim(),
            role: 'STUDENT',
          },
        },
      });

      if (signUpError) {
        throw signUpError;
      }

      // Si la session est immédiatement disponible
      if (data.session) {
        localStorage.setItem('activeducation_session', 'true');
        setCurrentUser(data.user);

        // Sauvegarder les résultats en base
        if (results && savedAnswers) {
          await fetch('/api/orientation/save', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ answers: savedAnswers, results }),
          }).catch(console.error);
        }

        if (typeof window !== 'undefined') {
          sessionStorage.removeItem('activeducation_pending_orientation_results');
          sessionStorage.removeItem('activeducation_pending_orientation_answers');
        }

        setStep('results');
        window.scrollTo({ top: 0, behavior: 'smooth' });
      } else if (data.user) {
        // Confirmation d'email requise par le projet Supabase
        setAuthSuccessMessage(
          'Compte créé avec succès ! Un e-mail de confirmation vous a été envoyé. Veuillez cliquer sur le lien pour valider votre inscription.'
        );
      }
    } catch (err: unknown) {
      console.error('Erreur inscription:', err);
      setAuthError(
        err instanceof Error
          ? err.message
          : "Une erreur est survenue lors de l'inscription. Veuillez réessayer."
      );
    } finally {
      setAuthLoading(false);
    }
  };

  // Traitement de la connexion via Supabase
  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setAuthLoading(true);
    setAuthError(null);
    setAuthSuccessMessage(null);

    try {
      const supabase = createClient();
      const { data, error: signInError } = await supabase.auth.signInWithPassword({
        email: email.trim(),
        password,
      });

      if (signInError) {
        setAuthError('Adresse e-mail ou mot de passe incorrect.');
        setAuthLoading(false);
        return;
      }

      if (data.user) {
        localStorage.setItem('activeducation_session', 'true');
        setCurrentUser(data.user);

        // Sauvegarder les résultats en base
        if (results && savedAnswers) {
          await fetch('/api/orientation/save', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ answers: savedAnswers, results }),
          }).catch(console.error);
        }

        if (typeof window !== 'undefined') {
          sessionStorage.removeItem('activeducation_pending_orientation_results');
          sessionStorage.removeItem('activeducation_pending_orientation_answers');
        }

        setStep('results');
        window.scrollTo({ top: 0, behavior: 'smooth' });
      }
    } catch (err: unknown) {
      console.error('Erreur connexion:', err);
      setAuthError("Impossible de vous connecter. Veuillez vérifier vos identifiants.");
    } finally {
      setAuthLoading(false);
    }
  };

  const handleRetake = () => {
    setResults(null);
    setSavedAnswers(null);
    setError(null);
    setStep('intro');
    if (typeof window !== 'undefined') {
      sessionStorage.removeItem('activeducation_pending_orientation_results');
      sessionStorage.removeItem('activeducation_pending_orientation_answers');
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
                    Sélection rigoureuse parmi les universités et écoles homologuées MESR Togo et CAMES.
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

        {/* ÉCRAN DE DEMANDE D'INSCRIPTION / CONNEXION (AUTH GATE) */}
        {step === 'auth_gate' && (
          <div className="flex-1 flex flex-col items-center justify-center py-6">
            <div className="w-full max-w-4xl flex flex-col gap-8">
              {/* En-tête de déblocage */}
              <div className="text-center max-w-2xl mx-auto flex flex-col items-center">
                <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-sm bg-primary-surface border border-primary/20 text-primary text-xs font-semibold uppercase tracking-wider mb-4">
                  <Sparkles className="w-4 h-4" />
                  <span>Diagnostic AÏDA complété avec succès</span>
                </div>
                <h1 className="font-display font-bold text-2xl md:text-4xl text-text-primary tracking-[-0.02em]">
                  Votre Bilan d'Orientation est Prêt !
                </h1>
                <p className="mt-3 text-text-secondary text-sm md:text-base leading-relaxed">
                  Pour découvrir vos 3 métiers d'avenir au Togo, vos universités homologuées et débloquer vos 200 XP de bienvenue, connectez-vous ou créez votre compte gratuitement.
                </p>
              </div>

              <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
                {/* Colonne gauche : Teaser et Bénéfices du Bilan (5 cols) */}
                <div className="lg:col-span-5 flex flex-col gap-4">
                  <Card variant="standard" className="p-6 flex flex-col gap-5 border-border-soft bg-surface">
                    <div className="flex items-center justify-between pb-3 border-b border-border-soft">
                      <span className="text-xs font-mono font-bold uppercase text-text-tertiary">
                        Statut du test
                      </span>
                      <span className="inline-flex items-center gap-1.5 text-xs font-bold text-primary bg-primary-surface px-2.5 py-1 rounded-sm border border-primary/20">
                        <CheckCircle2 className="w-3.5 h-3.5" />
                        12 / 12 questions validées
                      </span>
                    </div>

                    <div className="flex flex-col gap-4">
                      <div className="flex items-start gap-3">
                        <div className="w-9 h-9 rounded-md bg-primary-surface border border-primary/20 text-primary flex items-center justify-center shrink-0">
                          <Compass className="w-5 h-5" />
                        </div>
                        <div>
                          <h4 className="text-sm font-bold text-text-primary">Profil Holland RIASEC</h4>
                          <p className="text-xs text-text-secondary mt-0.5">
                            Vos dimensions psychologiques et vos talents dominants ont été calculés.
                          </p>
                        </div>
                      </div>

                      <div className="flex items-start gap-3">
                        <div className="w-9 h-9 rounded-md bg-primary-surface border border-primary/20 text-primary flex items-center justify-center shrink-0">
                          <Briefcase className="w-5 h-5" />
                        </div>
                        <div>
                          <h4 className="text-sm font-bold text-text-primary">3 Métiers d'avenir au Togo</h4>
                          <p className="text-xs text-text-secondary mt-0.5">
                            Filières à forte employabilité avec salaires réels en Francs CFA.
                          </p>
                        </div>
                      </div>

                      <div className="flex items-start gap-3">
                        <div className="w-9 h-9 rounded-md bg-primary-surface border border-primary/20 text-primary flex items-center justify-center shrink-0">
                          <GraduationCap className="w-5 h-5" />
                        </div>
                        <div>
                          <h4 className="text-sm font-bold text-text-primary">3 Établissements agréés</h4>
                          <p className="text-xs text-text-secondary mt-0.5">
                            Sélection parmi les universités et grandes écoles reconnues MESR Togo / CAMES.
                          </p>
                        </div>
                      </div>

                      <div className="flex items-start gap-3">
                        <div className="w-9 h-9 rounded-md bg-[#FAA100]/10 border border-[#FAA100]/30 text-[#FAA100] flex items-center justify-center shrink-0">
                          <Sparkles className="w-5 h-5" />
                        </div>
                        <div>
                          <h4 className="text-sm font-bold text-text-primary">+200 XP de bienvenue</h4>
                          <p className="text-xs text-text-secondary mt-0.5">
                            Points d'expérience crédités pour démarrer votre parcours sur ActivEducation.
                          </p>
                        </div>
                      </div>
                    </div>

                    {/* Bannière Verrouillée */}
                    <div className="mt-2 p-3.5 rounded-lg bg-canvas border border-border-soft flex items-center gap-3">
                      <div className="w-8 h-8 rounded-full bg-surface border border-border-soft flex items-center justify-center text-text-secondary shrink-0">
                        <Lock className="w-4 h-4 text-primary" />
                      </div>
                      <div className="text-xs">
                        <span className="font-bold text-text-primary block">Rapport complet sécurisé</span>
                        <span className="text-text-secondary">Déblocage immédiat et 100% gratuit.</span>
                      </div>
                    </div>

                    <div className="pt-2 text-center">
                      <button
                        type="button"
                        onClick={handleRetake}
                        className="text-xs text-text-tertiary hover:text-text-secondary inline-flex items-center gap-1.5 transition-colors"
                      >
                        <RotateCcw className="w-3.5 h-3.5" />
                        <span>Recommencer le questionnaire</span>
                      </button>
                    </div>
                  </Card>
                </div>

                {/* Colonne droite : Formulaire Inscription / Connexion (7 cols) */}
                <div className="lg:col-span-7">
                  <Card variant="standard" className="p-6 md:p-8 border-border-soft bg-surface shadow-sm">
                    {/* Onglets Créer un compte / Se connecter */}
                    <div className="flex items-center p-1 bg-canvas border border-border-soft rounded-lg mb-6">
                      <button
                        type="button"
                        onClick={() => { setAuthTab('register'); setAuthError(null); }}
                        className={`flex-1 py-2 text-xs md:text-sm font-bold rounded-md transition-all ${
                          authTab === 'register'
                            ? 'bg-primary text-white shadow-sm'
                            : 'text-text-secondary hover:text-text-primary'
                        }`}
                      >
                        Créer un compte
                      </button>
                      <button
                        type="button"
                        onClick={() => { setAuthTab('login'); setAuthError(null); }}
                        className={`flex-1 py-2 text-xs md:text-sm font-bold rounded-md transition-all ${
                          authTab === 'login'
                            ? 'bg-primary text-white shadow-sm'
                            : 'text-text-secondary hover:text-text-primary'
                        }`}
                      >
                        Se connecter
                      </button>
                    </div>

                    {/* Messages d'erreur ou de succès */}
                    {authError && (
                      <div className="mb-5 p-3.5 bg-red-50 border border-red-200 text-red-700 rounded-lg flex items-center gap-3 text-xs md:text-sm">
                        <AlertCircle className="w-4 h-4 shrink-0" />
                        <span>{authError}</span>
                      </div>
                    )}

                    {authSuccessMessage && (
                      <div className="mb-5 p-3.5 bg-green-50 border border-green-200 text-green-800 rounded-lg flex items-center gap-3 text-xs md:text-sm">
                        <CheckCircle2 className="w-4 h-4 shrink-0 text-green-600" />
                        <span>{authSuccessMessage}</span>
                      </div>
                    )}

                    {authTab === 'register' ? (
                      <form onSubmit={handleRegister} className="flex flex-col gap-4">
                        <Input
                          label="Nom complet"
                          type="text"
                          required
                          placeholder="Ex: Jean Kossi"
                          value={fullName}
                          onChange={(e) => setFullName(e.target.value)}
                          disabled={authLoading}
                        />

                        <Input
                          label="Adresse Email"
                          type="email"
                          required
                          placeholder="votre.email@exemple.com"
                          value={email}
                          onChange={(e) => setEmail(e.target.value)}
                          disabled={authLoading}
                        />

                        <Input
                          label="Mot de passe"
                          type="password"
                          required
                          placeholder="Minimum 6 caractères"
                          value={password}
                          onChange={(e) => setPassword(e.target.value)}
                          disabled={authLoading}
                        />

                        <Button
                          type="submit"
                          variant="primary"
                          size="lg"
                          disabled={authLoading}
                          className="w-full mt-2 flex items-center justify-center gap-2 h-12 shadow-sm"
                        >
                          {authLoading ? (
                            <>
                              <Loader2 className="w-4 h-4 animate-spin" />
                              <span>Création du compte...</span>
                            </>
                          ) : (
                            <>
                              <Sparkles className="w-4 h-4" />
                              <span>Débloquer mon Bilan d'Orientation</span>
                              <ArrowRight className="w-4 h-4" />
                            </>
                          )}
                        </Button>

                        <p className="text-[11px] text-text-tertiary text-center mt-2">
                          En créant votre compte, vous acceptez les conditions d'utilisation d'ActivEducation Togo.
                        </p>

                        <div className="pt-4 border-t border-border-soft text-center text-xs text-text-secondary">
                          Vous avez déjà un compte ?{' '}
                          <button
                            type="button"
                            onClick={() => { setAuthTab('login'); setAuthError(null); }}
                            className="text-primary font-bold hover:underline"
                          >
                            Se connecter
                          </button>
                        </div>
                      </form>
                    ) : (
                      <form onSubmit={handleLogin} className="flex flex-col gap-4">
                        <Input
                          label="Adresse Email"
                          type="email"
                          required
                          placeholder="votre.email@exemple.com"
                          value={email}
                          onChange={(e) => setEmail(e.target.value)}
                          disabled={authLoading}
                        />

                        <Input
                          label="Mot de passe"
                          type="password"
                          required
                          placeholder="••••••••"
                          value={password}
                          onChange={(e) => setPassword(e.target.value)}
                          disabled={authLoading}
                        />

                        <Button
                          type="submit"
                          variant="primary"
                          size="lg"
                          disabled={authLoading}
                          className="w-full mt-2 flex items-center justify-center gap-2 h-12 shadow-sm"
                        >
                          {authLoading ? (
                            <>
                              <Loader2 className="w-4 h-4 animate-spin" />
                              <span>Connexion en cours...</span>
                            </>
                          ) : (
                            <>
                              <span>Se connecter et voir mes résultats</span>
                              <ArrowRight className="w-4 h-4" />
                            </>
                          )}
                        </Button>

                        <div className="pt-4 border-t border-border-soft text-center text-xs text-text-secondary">
                          Pas encore de compte ?{' '}
                          <button
                            type="button"
                            onClick={() => { setAuthTab('register'); setAuthError(null); }}
                            className="text-primary font-bold hover:underline"
                          >
                            Créer un compte gratuit
                          </button>
                        </div>
                      </form>
                    )}
                  </Card>
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
              onRetake={handleRetake}
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
