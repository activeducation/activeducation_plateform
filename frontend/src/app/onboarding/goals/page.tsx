'use client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Compass, Route, GraduationCap, TrendingUp, Briefcase, Rocket, Check } from 'lucide-react';
import { useTheme } from '@/lib/theme';
import OnboardingShell from '@/components/onboarding/OnboardingShell';

const goals = [
  { id: 'discover', icon: Compass, title: 'Découvrir des métiers', subtitle: 'Explorer différentes carrières' },
  { id: 'orientation', icon: Route, title: "M'orienter", subtitle: 'Clarifier mon projet professionnel' },
  { id: 'school', icon: GraduationCap, title: 'Choisir une formation', subtitle: 'Trouver la bonne école/filière' },
  { id: 'skills', icon: TrendingUp, title: 'Développer mes compétences', subtitle: 'Apprendre de nouvelles choses' },
  { id: 'career', icon: Briefcase, title: 'Préparer ma carrière', subtitle: 'Me préparer au monde du travail' },
  { id: 'entrepreneur', icon: Rocket, title: 'Créer mon entreprise', subtitle: 'Devenir entrepreneur' },
];

export default function OnboardingGoalsPage() {
  const { t } = useTheme();
  const router = useRouter();
  const [selected, setSelected] = useState<string | null>(null);

  return (
    <OnboardingShell
      variant="standard"
      step={3}
      title={t('Tes objectifs')}
      subtitle={t("Qu'est-ce qui t'intéresse le plus ?")}
      footer={
        <button
          onClick={() => selected && router.push('/onboarding/complete')}
          disabled={!selected}
          className={`w-full h-14 rounded-full font-bold text-base flex items-center justify-center transition-all ${
            selected
              ? 'bg-brand-primary text-white hover:opacity-90'
              : 'bg-brand-border text-brand-text-tertiary cursor-not-allowed'
          }`}
        >
          {t('Terminer')}
        </button>
      }
    >
      <ul className="grid grid-cols-1 md:grid-cols-2 gap-3">
        {goals.map((g) => {
          const isSelected = selected === g.id;
          return (
            <li key={g.id}>
              <button
                onClick={() => setSelected(g.id)}
                aria-pressed={isSelected}
                className={`w-full text-left p-4 rounded-2xl border-2 transition-all duration-200 flex items-center gap-4 ${
                  isSelected
                    ? 'bg-brand-primary/10 border-brand-primary'
                    : 'bg-white border-brand-border-light hover:border-brand-primary/50'
                }`}
              >
                <span
                  className={`w-12 h-12 rounded-xl flex items-center justify-center flex-shrink-0 ${
                    isSelected ? 'bg-brand-primary' : 'bg-brand-surface'
                  }`}
                  aria-hidden="true"
                >
                  <g.icon
                    size={22}
                    className={isSelected ? 'text-white' : 'text-brand-text-secondary'}
                  />
                </span>
                <span className="flex-1">
                  <span className="block font-semibold text-brand-text-primary text-sm">
                    {t(g.title)}
                  </span>
                  <span className="block text-xs text-brand-text-tertiary mt-1">{t(g.subtitle)}</span>
                </span>
                {isSelected && (
                  <span
                    className="w-7 h-7 rounded-full bg-brand-primary flex items-center justify-center flex-shrink-0"
                    aria-hidden="true"
                  >
                    <Check size={15} className="text-white" />
                  </span>
                )}
              </button>
            </li>
          );
        })}
      </ul>
    </OnboardingShell>
  );
}
