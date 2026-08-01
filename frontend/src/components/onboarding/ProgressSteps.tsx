'use client';
import { useTheme } from '@/lib/theme';

interface ProgressStepsProps {
  /** Étape active (1-indexée, de 1 à 4). */
  step: 1 | 2 | 3 | 4;
  /** Nombre total d'étapes (défaut 4). */
  total?: number;
  /** Libellé localisé "Étape X sur Y" — si non fourni, utilise la traduction par défaut. */
  label?: string;
}

/**
 * Barre de progression pour le flow d'onboarding (4 étapes).
 *
 * - 4 segments horizontaux, segment actif en `bg-brand-secondary`, à venir en `bg-brand-border-light`.
 * - Le segment courant porte `aria-current="step"` et le container `role="progressbar"`.
 * - Le label est lu par les lecteurs d'écran (texte caché visuellement si `srOnly`).
 */
export default function ProgressSteps({ step, total = 4, label }: ProgressStepsProps) {
  const { t } = useTheme();
  const defaultLabel = label ?? t(`Étape ${step} sur ${total}`);
  return (
    <div
      role="progressbar"
      aria-valuemin={1}
      aria-valuemax={total}
      aria-valuenow={step}
      aria-label={defaultLabel}
      className="mb-6"
    >
      <div className="flex gap-2 mb-2" aria-hidden="true">
        {Array.from({ length: total }).map((_, i) => {
          const active = i + 1 <= step;
          return (
            <div
              key={i}
              aria-current={i + 1 === step ? 'step' : undefined}
              className={`h-1 flex-1 rounded-full transition-colors ${
                active ? 'bg-brand-secondary' : 'bg-brand-border-light'
              }`}
            />
          );
        })}
      </div>
      <span className="text-xs text-brand-text-tertiary">{defaultLabel}</span>
    </div>
  );
}
