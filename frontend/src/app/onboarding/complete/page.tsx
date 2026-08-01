'use client';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import { Check, ClipboardList, GraduationCap, Bot, Trophy } from 'lucide-react';
import { useTheme } from '@/lib/theme';
import OnboardingShell from '@/components/onboarding/OnboardingShell';

export default function OnboardingCompletePage() {
  const { t } = useTheme();
  const [scale, setScale] = useState(0);

  useEffect(() => {
    const timer = setTimeout(() => setScale(1), 50);
    return () => clearTimeout(timer);
  }, []);

  const features = [
    { icon: ClipboardList, text: "10 tests d'orientation" },
    { icon: GraduationCap, text: '50+ cours e-learning' },
    { icon: Bot, text: 'AÏDA, ta conseillère IA' },
    { icon: Trophy, text: 'Gamification & badges' },
  ];

  return (
    <OnboardingShell
      variant="complete"
      title={t('Tout est prêt !')}
      aside={
        <div
          className="w-40 h-40 md:w-48 md:h-48 rounded-[40px] flex items-center justify-center"
          style={{
            transform: `scale(${scale})`,
            transition: 'transform 0.8s cubic-bezier(0.34, 1.56, 0.64, 1)',
            background: 'linear-gradient(135deg, #3133DD, #5052E0)',
            boxShadow: '0 12px 32px rgba(49,51,221,0.4)',
          }}
          aria-hidden="true"
        >
          <Check size={88} className="text-white" />
        </div>
      }
      footer={
        <>
          <Link
            href="/register"
            className="w-full h-14 rounded-full bg-brand-primary text-white font-bold text-base flex items-center justify-center hover:opacity-90 transition-opacity"
          >
            {t('Créer mon compte')}
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
      <p className="text-brand-text-secondary text-base leading-relaxed max-w-lg mx-auto xl:mx-0">
        {t("Profil prêt. Crée ton compte et démarre ton parcours d'orientation.")}
      </p>
      <ul className="mt-6 space-y-3 max-w-md mx-auto xl:mx-0">
        {features.map((f) => (
          <li
            key={f.text}
            className="flex items-center gap-3 p-3 rounded-xl bg-brand-surface border border-brand-border-light"
          >
            <span className="w-9 h-9 rounded-lg bg-brand-primary/10 flex items-center justify-center flex-shrink-0">
              <f.icon size={18} className="text-brand-primary" aria-hidden="true" />
            </span>
            <span className="text-brand-text-primary text-sm font-medium">{t(f.text)}</span>
          </li>
        ))}
      </ul>
    </OnboardingShell>
  );
}
