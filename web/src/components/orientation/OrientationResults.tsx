'use client';

import React from 'react';
import { MatchResponse, RiasecDimension } from '@/lib/orientation';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import {
  GraduationCap,
  Building2,
  Briefcase,
  TrendingUp,
  CheckCircle2,
  Award,
  Sparkles,
  RotateCcw,
  ArrowRight,
  MapPin,
  Banknote,
  Compass,
  ShieldCheck,
} from 'lucide-react';

interface OrientationResultsProps {
  results: MatchResponse;
  onRetake: () => void;
}

export function OrientationResults({ results, onRetake }: OrientationResultsProps) {
  const { profile, careers, institutions } = results;

  const riasecLabels: Record<RiasecDimension, string> = {
    R: 'Réaliste',
    I: 'Investigateur',
    A: 'Artistique',
    S: 'Social',
    E: 'Entreprenant',
    C: 'Conventionnel',
  };

  const scores = profile.scores as Record<string, number> | undefined;

  return (
    <div className="w-full max-w-6xl mx-auto flex flex-col gap-12 py-6">
      {/* SECTION 1 : EN-TÊTE DU PROFIL PSYCHOLOGIQUE */}
      <section className="bg-surface border border-border-soft rounded-2xl p-8 md:p-12 shadow-sm relative overflow-hidden">
        <div className="flex flex-col gap-6">
          {/* Badge d'archétype Holland */}
          <div className="flex flex-wrap items-center justify-between gap-4">
            <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-sm bg-primary-surface border border-primary/20 text-primary text-xs font-mono font-bold tracking-wider uppercase">
              <Sparkles className="w-4 h-4 text-primary" />
              <span>Profil Holland : {profile.code}</span>
            </div>

            <div className="flex items-center gap-2 text-xs text-text-tertiary font-mono">
              <ShieldCheck className="w-4 h-4 text-primary" />
              <span>Diagnostic validé par AÏDA ActivEducation</span>
            </div>
          </div>

          {/* Titre et description */}
          <div>
            <h1 className="font-display font-extrabold text-2xl md:text-4xl text-text-primary tracking-[-0.02em] leading-tight">
              {profile.title}
            </h1>
            <p className="mt-4 text-text-secondary text-base md:text-lg leading-relaxed max-w-[85ch]">
              {profile.description}
            </p>
          </div>

          {/* Points forts et Conseil stratégique */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 pt-6 border-t border-border-soft">
            <div className="flex flex-col gap-3">
              <span className="text-xs uppercase font-mono tracking-wider font-bold text-text-secondary">
                Vos Principaux Atouts
              </span>
              <div className="flex flex-col gap-2">
                {profile.strengths.map((strength, idx) => (
                  <div key={idx} className="flex items-start gap-2.5 text-sm text-text-primary">
                    <CheckCircle2 className="w-4 h-4 text-primary shrink-0 mt-0.5" />
                    <span>{strength}</span>
                  </div>
                ))}
              </div>
            </div>

            <div className="flex flex-col gap-3 bg-canvas border border-border-soft rounded-xl p-5">
              <span className="text-xs uppercase font-mono tracking-wider font-bold text-primary flex items-center gap-1.5">
                <Compass className="w-4 h-4" />
                <span>Recommandation Stratégique AÏDA</span>
              </span>
              <p className="text-sm text-text-secondary leading-relaxed">
                {profile.advice}
              </p>
            </div>
          </div>

          {/* Jauges RIASEC (Scores en Ambre #FAA100 strict) */}
          {scores && (
            <div className="pt-6 border-t border-border-soft">
              <span className="text-xs uppercase font-mono tracking-wider font-bold text-text-secondary block mb-4">
                Répartition des Dimensions RIASEC
              </span>
              <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-4">
                {(['R', 'I', 'A', 'S', 'E', 'C'] as RiasecDimension[]).map((dim) => {
                  const scoreVal = Math.round(scores[dim] ?? scores[riasecLabels[dim]] ?? 50);
                  return (
                    <div
                      key={dim}
                      className="bg-canvas border border-border-soft rounded-lg p-3.5 flex flex-col gap-2"
                    >
                      <div className="flex items-center justify-between text-xs">
                        <span className="font-bold text-text-primary">{dim}</span>
                        {/* AMBRE STRICTEMENT RÉSERVÉ AUX SCORES */}
                        <span className="font-mono font-bold text-[#FAA100]">
                          {scoreVal}%
                        </span>
                      </div>
                      <div className="text-[11px] text-text-secondary truncate">
                        {riasecLabels[dim]}
                      </div>
                      <div className="w-full h-1.5 bg-border-soft/60 rounded-full overflow-hidden">
                        <div
                          className="h-full bg-[#FAA100] rounded-full transition-all duration-500"
                          style={{ width: `${scoreVal}%` }}
                        />
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}
        </div>
      </section>

      {/* SECTION 2 : 3 MÉTIERS PORTEURS AU TOGO */}
      <section className="flex flex-col gap-6">
        <div className="flex flex-col md:flex-row md:items-end justify-between gap-2">
          <div>
            <div className="inline-flex items-center gap-2 text-xs font-mono font-bold text-primary uppercase tracking-wider mb-2">
              <Briefcase className="w-4 h-4" />
              <span>Opportunités Professionnelles</span>
            </div>
            <h2 className="font-display font-bold text-2xl md:text-3xl text-text-primary">
              Vos 3 Métiers d’Avenir au Togo
            </h2>
          </div>
          <p className="text-sm text-text-secondary max-w-md">
            Sélectionnés selon vos aptitudes dominantes et les besoins prioritaires du marché ouest-africain.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {careers.map((career, idx) => (
            <Card
              key={career.id || idx}
              variant="standard"
              className="p-6 md:p-7 flex flex-col justify-between border-border-soft hover:border-primary/30 transition-all shadow-sm"
            >
              <div className="flex flex-col gap-4">
                {/* En-tête de carte : Secteur & Score Ambre */}
                <div className="flex items-center justify-between gap-2">
                  <span className="px-2.5 py-1 rounded-sm text-[11px] font-semibold bg-canvas border border-border-soft text-text-secondary truncate">
                    {career.sector}
                  </span>

                  {/* SCORE DE CORRESPONDANCE EN AMBRE #FAA100 STRICT */}
                  <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-sm bg-[#FAA100]/10 border border-[#FAA100]/40 text-[#FAA100] font-mono font-bold text-xs">
                    <TrendingUp className="w-3.5 h-3.5" />
                    <span>{career.matchScore ?? 92 - idx * 4}% Match</span>
                  </span>
                </div>

                {/* Titre du métier */}
                <h3 className="font-bold text-lg text-text-primary leading-snug">
                  {career.title}
                </h3>

                {/* Salaire indicatif FCFA */}
                <div className="flex items-center gap-2 text-xs font-mono text-text-secondary bg-canvas/80 p-2.5 rounded-md border border-border-soft/60">
                  <Banknote className="w-4 h-4 text-primary shrink-0" />
                  <span className="font-semibold text-text-primary">{career.salary}</span>
                </div>

                {/* Description */}
                <p className="text-xs text-text-secondary leading-relaxed line-clamp-4">
                  {career.description}
                </p>

                {/* Compétences requises */}
                <div className="pt-3 border-t border-border-soft/60 flex flex-col gap-2">
                  <span className="text-[11px] uppercase font-mono tracking-wider text-text-tertiary font-medium">
                    Compétences Clés
                  </span>
                  <div className="flex flex-wrap gap-1.5">
                    {career.requiredSkills.slice(0, 4).map((skill, sIdx) => (
                      <span
                        key={sIdx}
                        className="px-2 py-0.5 rounded-sm bg-canvas text-text-secondary border border-border-soft text-[11px]"
                      >
                        {skill}
                      </span>
                    ))}
                  </div>
                </div>
              </div>

              {/* Écoles associées */}
              <div className="mt-6 pt-4 border-t border-border-soft/80 flex items-center justify-between text-xs text-text-tertiary">
                <span className="truncate">Demande : <strong className="text-text-primary font-medium">{career.demand}</strong></span>
                <span className="text-primary font-semibold flex items-center gap-1">
                  Débouché UEMOA
                </span>
              </div>
            </Card>
          ))}
        </div>
      </section>

      {/* SECTION 3 : 3 ÉTABLISSEMENTS AGRÉÉS AU TOGO */}
      <section className="flex flex-col gap-6">
        <div className="flex flex-col md:flex-row md:items-end justify-between gap-2">
          <div>
            <div className="inline-flex items-center gap-2 text-xs font-mono font-bold text-primary uppercase tracking-wider mb-2">
              <GraduationCap className="w-4 h-4" />
              <span>Formations Supérieures Agréées</span>
            </div>
            <h2 className="font-display font-bold text-2xl md:text-3xl text-text-primary">
              Vos 3 Établissements Recommandés au Togo
            </h2>
          </div>
          <p className="text-sm text-text-secondary max-w-md">
            Universités et grandes écoles officielles accréditées par le Ministère de l’Enseignement Supérieur (MESR Togo) et le CAMES.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {institutions.map((inst, idx) => (
            <Card
              key={inst.id || idx}
              variant="standard"
              className="p-6 md:p-7 flex flex-col justify-between border-border-soft hover:border-primary/30 transition-all shadow-sm"
            >
              <div className="flex flex-col gap-4">
                {/* En-tête d'établissement : Ville & Statut */}
                <div className="flex items-center justify-between gap-2">
                  <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-sm text-[11px] font-semibold bg-canvas border border-border-soft text-text-secondary">
                    <MapPin className="w-3.5 h-3.5 text-primary" />
                    <span>{inst.city}</span>
                  </span>

                  <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-sm bg-primary-surface text-primary border border-primary/20 text-[11px] font-mono font-bold">
                    <Award className="w-3.5 h-3.5" />
                    <span>{inst.accreditation}</span>
                  </span>
                </div>

                {/* Nom officiel */}
                <div className="flex items-start gap-2.5">
                  <Building2 className="w-5 h-5 text-primary shrink-0 mt-1" />
                  <h3 className="font-bold text-base text-text-primary leading-snug">
                    {inst.name}
                  </h3>
                </div>

                {/* Filières recommandées */}
                <div className="flex flex-col gap-2 pt-3 border-t border-border-soft/60">
                  <span className="text-[11px] uppercase font-mono tracking-wider text-text-tertiary font-medium">
                    Filières d’Excellence
                  </span>
                  <ul className="flex flex-col gap-1.5 text-xs text-text-secondary">
                    {inst.programs.slice(0, 3).map((program, pIdx) => (
                      <li key={pIdx} className="flex items-start gap-2">
                        <span className="w-1.5 h-1.5 rounded-full bg-primary shrink-0 mt-1.5" />
                        <span className="leading-tight">{program}</span>
                      </li>
                    ))}
                  </ul>
                </div>
              </div>

              {/* Conditions d'admission */}
              <div className="mt-6 pt-4 border-t border-border-soft/80 text-[11px] text-text-tertiary">
                <span>Admission : <strong className="text-text-secondary font-medium">{inst.admissionLevel}</strong></span>
              </div>
            </Card>
          ))}
        </div>
      </section>

      {/* BOUTONS D'ACTION ET ORIENTATION COMPLÉMENTAIRE */}
      <section className="bg-canvas border border-border-soft rounded-2xl p-8 flex flex-col sm:flex-row items-center justify-between gap-6">
        <div className="flex flex-col gap-1 text-center sm:text-left">
          <h4 className="font-bold text-base text-text-primary">
            Prêt à démarrer votre préparation académique ?
          </h4>
          <p className="text-xs text-text-secondary">
            Consultez nos cours certifiants et développez dès aujourd’hui vos compétences cibles.
          </p>
        </div>

        <div className="flex items-center gap-4 w-full sm:w-auto">
          <Button
            type="button"
            variant="secondary"
            onClick={onRetake}
            className="flex-1 sm:flex-initial flex items-center justify-center gap-2"
          >
            <RotateCcw className="w-4 h-4" />
            <span>Repasser le test</span>
          </Button>

          <a href="/#catalogue" className="flex-1 sm:flex-initial">
            <Button
              type="button"
              variant="primary"
              className="w-full flex items-center justify-center gap-2 shadow-sm"
            >
              <span>Explorer les Cours</span>
              <ArrowRight className="w-4 h-4" />
            </Button>
          </a>
        </div>
      </section>
    </div>
  );
}
