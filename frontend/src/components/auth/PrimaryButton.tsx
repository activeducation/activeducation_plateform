'use client';
import { Loader2, type LucideIcon } from 'lucide-react';
import type { ButtonHTMLAttributes, ReactNode } from 'react';

interface PrimaryButtonProps extends Omit<ButtonHTMLAttributes<HTMLButtonElement>, 'children'> {
  loading?: boolean;
  icon?: LucideIcon;
  children: ReactNode;
}

export default function PrimaryButton({
  loading = false,
  disabled,
  icon: Icon,
  children,
  className = '',
  type = 'button',
  ...rest
}: PrimaryButtonProps) {
  const isDisabled = disabled || loading;

  return (
    <button
      type={type}
      disabled={isDisabled}
      className={`w-full h-12 rounded-xl bg-gradient-primary text-white font-semibold text-sm flex items-center justify-center gap-2 shadow-glow hover:opacity-90 disabled:opacity-50 disabled:cursor-not-allowed transition-all ${className}`}
      {...rest}
    >
      {loading ? (
        <>
          <Loader2 size={18} className="animate-spin" aria-hidden="true" />
          <span>{children}</span>
        </>
      ) : (
        <>
          {Icon && <Icon size={18} aria-hidden="true" />}
          <span>{children}</span>
        </>
      )}
    </button>
  );
}
