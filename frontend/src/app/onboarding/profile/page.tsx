'use client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useTheme } from '@/lib/theme';
import OnboardingShell from '@/components/onboarding/OnboardingShell';

const levels = ['6ème', '5ème', '4ème', '3ème', 'Seconde', 'Première', 'Terminale', 'Étudiant(e)'];
const schoolTypes = ['Collège', 'Lycée', 'Université', 'Institut de formation', 'École professionnelle'];

export default function OnboardingProfilePage() {
  const { t } = useTheme();
  const router = useRouter();
  const [selectedLevel, setSelectedLevel] = useState<string | null>(null);
  const [selectedType, setSelectedType] = useState<string | null>(null);
  const canContinue = !!selectedLevel && !!selectedType;

  return (
    <OnboardingShell
      variant="standard"
      step={1}
      title={t('Ton profil')}
      subtitle={t('Parle-nous de ton parcours scolaire')}
      footer={
        <button
          onClick={() => canContinue && router.push('/onboarding/interests')}
          disabled={!canContinue}
          className={`w-full h-14 rounded-full font-bold text-base flex items-center justify-center transition-all ${
            canContinue
              ? 'bg-brand-primary text-white hover:opacity-90'
              : 'bg-brand-border text-brand-text-tertiary cursor-not-allowed'
          }`}
        >
          {t('Continuer')}
        </button>
      }
    >
      <section className="mb-8">
        <h2 className="font-semibold text-brand-text-primary text-sm mb-3">{t('Ton niveau')}</h2>
        <div className="flex flex-wrap gap-2">
          {levels.map((l) => {
            const active = selectedLevel === l;
            return (
              <button
                key={l}
                onClick={() => setSelectedLevel(l)}
                aria-pressed={active}
                className={`px-4 py-2.5 rounded-full text-sm font-medium transition-all duration-200 ${
                  active
                    ? 'bg-brand-primary text-white shadow-glow'
                    : 'bg-brand-surface text-brand-text-secondary border border-brand-border-light hover:border-brand-primary/50'
                }`}
              >
                {t(l)}
              </button>
            );
          })}
        </div>
      </section>

      <section className="mb-8">
        <h2 className="font-semibold text-brand-text-primary text-sm mb-3">
          {t("Type d'établissement")}
        </h2>
        <div className="flex flex-wrap gap-2">
          {schoolTypes.map((st) => {
            const active = selectedType === st;
            return (
              <button
                key={st}
                onClick={() => setSelectedType(st)}
                aria-pressed={active}
                className={`px-4 py-2.5 rounded-full text-sm font-medium transition-all duration-200 ${
                  active
                    ? 'bg-brand-primary text-white shadow-glow'
                    : 'bg-brand-surface text-brand-text-secondary border border-brand-border-light hover:border-brand-primary/50'
                }`}
              >
                {t(st)}
              </button>
            );
          })}
        </div>
      </section>
    </OnboardingShell>
  );
}
