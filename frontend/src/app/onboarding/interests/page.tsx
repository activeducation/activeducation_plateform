'use client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  Monitor,
  FlaskConical,
  Briefcase,
  Heart,
  Palette,
  Trophy,
  Languages,
  Wrench,
  Sprout,
  GraduationCap,
} from 'lucide-react';
import { useTheme } from '@/lib/theme';
import OnboardingShell from '@/components/onboarding/OnboardingShell';

const interests = [
  { id: 'tech', icon: Monitor, title: 'Technologie', subtitle: 'Informatique, code, robotique' },
  { id: 'science', icon: FlaskConical, title: 'Sciences', subtitle: 'Physique, chimie, biologie' },
  { id: 'business', icon: Briefcase, title: 'Business', subtitle: 'Commerce, entrepreneuriat' },
  { id: 'health', icon: Heart, title: 'Santé', subtitle: 'Médecine, soins, bien-être' },
  { id: 'arts', icon: Palette, title: 'Arts & Design', subtitle: 'Créativité, design, médias' },
  { id: 'education', icon: GraduationCap, title: 'Éducation', subtitle: 'Enseignement, formation' },
  { id: 'sports', icon: Trophy, title: 'Sports', subtitle: 'Activité physique, compétition' },
  { id: 'languages', icon: Languages, title: 'Langues', subtitle: 'Communication multilingue' },
  { id: 'engineering', icon: Wrench, title: 'Ingénierie', subtitle: 'Construction, mécanique' },
  { id: 'agriculture', icon: Sprout, title: 'Agriculture', subtitle: 'Agro, environnement' },
];

export default function OnboardingInterestsPage() {
  const { t } = useTheme();
  const router = useRouter();
  const [selected, setSelected] = useState<Set<string>>(new Set());

  const toggle = (id: string) => {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const count = selected.size;
  const canContinue = count > 0;

  return (
    <OnboardingShell
      variant="standard"
      step={2}
      title={t('Tes intérêts')}
      subtitle={t("Choisis ce qui t'intéresse (plusieurs choix possibles)")}
      footer={
        <>
          {count > 0 && (
            <p className="text-center text-sm text-brand-secondary mb-3 font-medium">
              {count} {t('intérêt')}{count > 1 ? 's' : ''} {t('sélectionné')}{count > 1 ? 's' : ''}
            </p>
          )}
          <button
            onClick={() => canContinue && router.push('/onboarding/goals')}
            disabled={!canContinue}
            className={`w-full h-14 rounded-full font-bold text-base flex items-center justify-center transition-all ${
              canContinue
                ? 'bg-brand-primary text-white hover:opacity-90'
                : 'bg-brand-border text-brand-text-tertiary cursor-not-allowed'
            }`}
          >
            {t('Continuer')}
          </button>
        </>
      }
    >
      <ul className="grid grid-cols-2 md:grid-cols-3 xl:grid-cols-4 gap-3">
        {interests.map((item) => {
          const isSelected = selected.has(item.id);
          return (
            <li key={item.id}>
              <button
                onClick={() => toggle(item.id)}
                aria-pressed={isSelected}
                className={`w-full text-left p-4 rounded-2xl border-2 transition-all duration-200 ${
                  isSelected
                    ? 'bg-brand-primary/10 border-brand-primary'
                    : 'bg-white border-brand-border-light hover:border-brand-primary/50'
                }`}
              >
                <span
                  className={`w-10 h-10 rounded-xl flex items-center justify-center mb-3 ${
                    isSelected ? 'bg-brand-primary' : 'bg-brand-surface'
                  }`}
                  aria-hidden="true"
                >
                  <item.icon
                    size={20}
                    className={isSelected ? 'text-white' : 'text-brand-text-secondary'}
                  />
                </span>
                <span className="block font-semibold text-brand-text-primary text-sm">
                  {t(item.title)}
                </span>
                <span className="block text-xs text-brand-text-tertiary mt-1">
                  {t(item.subtitle)}
                </span>
              </button>
            </li>
          );
        })}
      </ul>
    </OnboardingShell>
  );
}
