'use client';
import Link from 'next/link';
import { type LucideIcon } from 'lucide-react';
import type { ReactNode } from 'react';

interface AuthShellProps {
  /** Icône affichée dans le carré brand en haut du hero (mobile) et au centre du panneau droit (desktop).
   *  Ignorée si `heroLogo` est fourni. */
  heroIcon: LucideIcon;
  /** URL d'une image logo à afficher à la place de `heroIcon` (prend le pas). */
  heroLogo?: string;
  /** Petit label affiché au-dessus du titre (ex. "Découvre ta voie"). */
  heroEyebrow?: string;
  /** Titre brand affiché dans le hero. */
  heroTitle: string;
  /** Sous-titre affiché sous le titre du hero. */
  heroSubtitle: string;
  /** Contenu du panneau droit desktop (ex. liste de features, badges). */
  heroAside?: ReactNode;
  /** Formulaire à afficher dans le panneau gauche / bas mobile. */
  children: ReactNode;
  /** Lien secondaire en bas du formulaire (ex. "J'ai déjà un compte"). */
  footerLink?: { href: string; label: string };
}

export default function AuthShell({
  heroIcon: HeroIcon,
  heroLogo,
  heroEyebrow,
  heroTitle,
  heroSubtitle,
  heroAside,
  children,
  footerLink,
}: AuthShellProps) {
  return (
    <div className="min-h-screen flex flex-col md:flex-row bg-brand-background">
      {/* ── Panneau gauche : formulaire ── */}
      <div className="flex-1 md:flex md:items-center md:justify-center md:bg-brand-background order-2 md:order-1">
        <div className="w-full max-w-md mx-auto px-6 md:px-8 py-6 md:py-12">
          <div className="md:bg-white md:rounded-3xl md:shadow-card md:p-8">
            {children}
            {footerLink && (
              <p className="text-center text-sm text-brand-text-secondary mt-6">
                <Link
                  href={footerLink.href}
                  className="text-brand-primary font-semibold hover:text-brand-primary-light transition-colors"
                >
                  {footerLink.label}
                </Link>
              </p>
            )}
          </div>
        </div>
      </div>

      {/* ── Panneau droit : hero (visible md+) ── */}
      <div className="hidden md:flex md:flex-col md:justify-center md:items-center md:flex-1 bg-gradient-hero order-1 md:order-2 px-12 py-16">
        <div className="max-w-md w-full text-white">
          <div className="w-20 h-20 rounded-2xl bg-white/15 backdrop-blur-sm flex items-center justify-center mb-8 shadow-lg overflow-hidden">
            {heroLogo ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={heroLogo}
                alt={heroTitle}
                className="w-full h-full object-contain p-2"
              />
            ) : (
              <HeroIcon size={42} className="text-white" aria-hidden="true" />
            )}
          </div>
          {heroEyebrow && (
            <p className="text-white/80 text-sm font-semibold tracking-wide uppercase mb-3">
              {heroEyebrow}
            </p>
          )}
          <h1 className="text-4xl xl:text-5xl font-extrabold tracking-tight leading-tight">
            {heroTitle}
          </h1>
          <p className="text-white/80 text-lg mt-4 leading-relaxed">{heroSubtitle}</p>
          {heroAside && <div className="mt-10">{heroAside}</div>}
        </div>
      </div>

      {/* ── Hero compact mobile (visible <md) ── */}
      <div className="md:hidden order-1 bg-gradient-hero px-6 pt-12 pb-8">
        <div className="max-w-md mx-auto">
          <div className="w-12 h-12 rounded-xl bg-white/15 flex items-center justify-center mb-4 overflow-hidden">
            {heroLogo ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={heroLogo}
                alt={heroTitle}
                className="w-full h-full object-contain p-1.5"
              />
            ) : (
              <HeroIcon size={26} className="text-white" aria-hidden="true" />
            )}
          </div>
          <h1 className="text-2xl font-extrabold text-white tracking-tight">{heroTitle}</h1>
          <p className="text-white/75 text-sm mt-1.5 leading-relaxed">{heroSubtitle}</p>
        </div>
      </div>
    </div>
  );
}
