'use client';
import Link from 'next/link';
import { Rocket, ClipboardList, GraduationCap, Bot } from 'lucide-react';
import { useTheme } from '@/lib/theme';
import OnboardingShell from '@/components/onboarding/OnboardingShell';

const features = [
  { icon: ClipboardList, title: "Tests d'orientation", subtitle: 'Découvrez votre profil RIASEC' },
  { icon: GraduationCap, title: 'Écoles & Formations', subtitle: 'Explorez les opportunités locales' },
  { icon: Bot, title: 'AÏDA', subtitle: 'Conseillère IA disponible 24h/24' },
];

export default function OnboardingIntroPage() {
  const { t } = useTheme();

  const introText = `${t("Ton compagnon d'orientation. Découvre les métiers qui te correspondent.")}`;

  return (
    <OnboardingShell
      variant="intro"
      subtitle={t('Bienvenue sur')}
      title={t('ActivEducation')}
      aside={
        <div className="relative flex flex-col items-center gap-8">
          <div className="w-32 h-32 md:w-40 md:h-40 bg-brand-secondary-surface rounded-[36px] flex items-center justify-center shadow-card">
            <Rocket size={72} className="text-brand-secondary" aria-hidden="true" />
          </div>
          <ul className="w-full max-w-sm space-y-4">
            {features.map((f) => (
              <li key={f.title} className="flex items-center gap-4">
                <span className="w-12 h-12 rounded-xl bg-brand-primary/10 flex items-center justify-center flex-shrink-0">
                  <f.icon size={22} className="text-brand-primary" aria-hidden="true" />
                </span>
                <span>
                  <span className="block font-semibold text-brand-text-primary text-sm">
                    {t(f.title)}
                  </span>
                  <span className="block text-xs text-brand-text-tertiary mt-0.5">
                    {t(f.subtitle)}
                  </span>
                </span>
              </li>
            ))}
          </ul>
        </div>
      }
      footer={
        <>
          <Link
            href="/onboarding/profile"
            className="w-full h-14 rounded-full bg-brand-primary text-white font-bold text-base flex items-center justify-center hover:opacity-90 transition-opacity"
          >
            {t('Commencer')}
          </Link>
          <Link
            href="/login"
            className="text-brand-text-secondary text-sm font-medium text-center hover:text-brand-text-primary transition-colors"
          >
            {t("J'ai déjà un compte")}
          </Link>
        </>
      }
    >
      {introText}
    </OnboardingShell>
  );
}
