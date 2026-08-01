'use client';
import { useId, type ReactNode } from 'react';
import { type LucideIcon } from 'lucide-react';

interface AuthTextFieldProps {
  label: string;
  icon: LucideIcon;
  value: string;
  onChange: (v: string) => void;
  type?: 'text' | 'email' | 'password' | 'tel';
  autoComplete?: string;
  placeholder?: string;
  required?: boolean;
  error?: string;
  inputMode?: 'text' | 'email' | 'tel' | 'numeric' | 'search' | 'url';
  rightAdornment?: ReactNode;
  containerClassName?: string;
}

export default function AuthTextField({
  label,
  icon: Icon,
  value,
  onChange,
  type = 'text',
  autoComplete,
  placeholder,
  required,
  error,
  inputMode,
  rightAdornment,
  containerClassName = '',
}: AuthTextFieldProps) {
  const reactId = useId();
  const id = `field-${reactId}`;
  const errorId = error ? `${id}-error` : undefined;
  // Padding gauche : on garde 10 (40px) pour les icônes de 18px et 9 (36px) pour 16px.
  const iconSize = 18;
  const paddingLeft = iconSize >= 18 ? 'pl-11' : 'pl-9';

  return (
    <div className={containerClassName}>
      <label
        htmlFor={id}
        className="block text-sm font-medium text-brand-text-secondary mb-1.5"
      >
        {label}
      </label>
      <div className="relative">
        <Icon
          size={iconSize}
          aria-hidden="true"
          className="absolute left-3.5 top-1/2 -translate-y-1/2 text-brand-text-tertiary pointer-events-none"
        />
        <input
          id={id}
          type={type}
          value={value}
          onChange={(e) => onChange(e.target.value)}
          placeholder={placeholder}
          required={required}
          autoComplete={autoComplete}
          inputMode={inputMode}
          aria-invalid={!!error}
          aria-describedby={errorId}
          className={`w-full ${paddingLeft} pr-${rightAdornment ? '11' : '4'} h-12 rounded-xl border ${
            error
              ? 'border-brand-error focus:ring-brand-error/20 focus:border-brand-error'
              : 'border-brand-border'
          } bg-white text-brand-text-primary placeholder:text-brand-text-tertiary/50 outline-none focus:ring-2 focus:ring-brand-primary/20 focus:border-brand-primary transition-all text-sm`}
        />
        {rightAdornment && (
          <div className="absolute right-3 top-1/2 -translate-y-1/2">
            {rightAdornment}
          </div>
        )}
      </div>
      {error && (
        <p id={errorId} className="text-xs text-brand-error mt-1.5" role="alert">
          {error}
        </p>
      )}
    </div>
  );
}
