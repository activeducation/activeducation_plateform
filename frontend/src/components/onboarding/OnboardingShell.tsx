'use client';
import { type ReactNode } from 'react';
import { type LucideIcon } from 'lucide-react';
import ProgressSteps from './ProgressSteps';

interface OnboardingShellProps {
  /** Variante : 'standard' (header + progress + scroll + footer CTA), 'intro' (sans progress, layout 2 col xl), 'complete' (sans progress, 2 col xl avec illustration à gauche). */
  variant?: 'standard' | 'intro' | 'complete';
  /** Étape courante pour la barre de progression (1 à 4). Ignoré si variant != 'standard'. */
  step?: 1 | 2 | 3 | 4;
  /** Titre de la page. */
  title: string;
  /** Sous-titre sous le titre. */
  subtitle?: string;
  /** Icône optionnelle affichée à côté du titre (mobile uniquement — xl utilise la variante 2 col). */
  titleIcon?: LucideIcon;
  /** Contenu principal (scrollable). */
  children: ReactNode;
  /** Contenu du footer (bouton CTA principal, lien secondaire). */
  footer?: ReactNode;
  /** Contenu affiché à droite sur la variante 'complete' (ex. grand check animé). */
  aside?: ReactNode;
}

export default function OnboardingShell({
  variant = 'standard',
  step,
  title,
  subtitle,
  titleIcon: TitleIcon,
  children,
  footer,
  aside,
}: OnboardingShellProps) {
  if (variant === 'intro') {
    return (
      <div className="min-h-screen bg-brand-background flex flex-col">
        <div className="w-full max-w-5xl mx-auto px-6 md:px-8 pt-10 md:pt-16 pb-8 flex-1 flex flex-col">
          <div className="grid xl:grid-cols-2 gap-8 xl:gap-16 items-center flex-1">
            {aside && <div className="flex justify-center xl:justify-start">{aside}</div>}
            <div className="flex flex-col">
              {subtitle && (
                <p className="text-brand-secondary font-bold text-sm tracking-wide uppercase mb-1">
                  {subtitle}
                </p>
              )}
              <h1 className="text-3xl md:text-4xl xl:text-5xl font-extrabold text-brand-text-primary tracking-tight">
                {title}
              </h1>
              {typeof children === 'string' ? (
                <p className="text-brand-text-secondary text-base mt-4 leading-relaxed max-w-lg">
                  {children}
                </p>
              ) : (
                <div className="mt-6">{children}</div>
              )}
              {footer && <div className="mt-8 flex flex-col items-stretch gap-4">{footer}</div>}
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (variant === 'complete') {
    return (
      <div className="min-h-screen bg-brand-background flex flex-col">
        <div className="w-full max-w-5xl mx-auto px-6 md:px-8 pt-10 md:pt-16 pb-8 flex-1 flex flex-col">
          <div className="grid xl:grid-cols-2 gap-8 xl:gap-16 items-center flex-1">
            {aside && <div className="flex justify-center xl:justify-start">{aside}</div>}
            <div className="flex flex-col text-center xl:text-left">
              <h1 className="text-3xl md:text-4xl xl:text-5xl font-extrabold text-brand-text-primary tracking-tight">
                {title}
              </h1>
              {typeof children === 'string' ? (
                <p className="text-brand-text-secondary text-base mt-4 leading-relaxed max-w-lg mx-auto xl:mx-0">
                  {children}
                </p>
              ) : (
                <div className="mt-6">{children}</div>
              )}
              {footer && <div className="mt-8 flex flex-col items-stretch gap-4">{footer}</div>}
            </div>
          </div>
        </div>
      </div>
    );
  }

  // Variante 'standard'
  return (
    <div className="min-h-screen bg-brand-background flex flex-col">
      <div className="w-full max-w-2xl md:max-w-3xl mx-auto px-6 md:px-8 pt-6 md:pt-10 pb-4 flex-1 flex flex-col w-full">
        <header className="mb-6">
          {step && <ProgressSteps step={step} />}
          <div className={TitleIcon ? 'flex items-center gap-4' : ''}>
            {TitleIcon && (
              <div className="w-12 h-12 rounded-2xl bg-brand-primary/10 flex items-center justify-center flex-shrink-0 hidden md:flex">
                <TitleIcon size={24} className="text-brand-primary" aria-hidden="true" />
              </div>
            )}
            <div>
              <h1 className="text-2xl md:text-3xl font-extrabold text-brand-text-primary tracking-tight">
                {title}
              </h1>
              {subtitle && (
                <p className="text-brand-text-secondary text-sm md:text-base mt-1.5 leading-relaxed">
                  {subtitle}
                </p>
              )}
            </div>
          </div>
        </header>
        <main className="flex-1 pb-6">{children}</main>
        {footer && (
          <footer className="pt-4 pb-8 border-t border-brand-border-light md:border-0 md:pt-6">
            {footer}
          </footer>
        )}
      </div>
    </div>
  );
}
