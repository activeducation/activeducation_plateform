'use client';
import { useState, type ReactNode } from 'react';
import { Eye, EyeOff, Lock } from 'lucide-react';
import AuthTextField from './AuthTextField';

interface PasswordFieldProps {
  label: string;
  value: string;
  onChange: (v: string) => void;
  autoComplete?: 'current-password' | 'new-password';
  placeholder?: string;
  required?: boolean;
  error?: string;
}

export default function PasswordField({
  label,
  value,
  onChange,
  autoComplete = 'current-password',
  placeholder = '••••••••',
  required,
  error,
}: PasswordFieldProps) {
  const [show, setShow] = useState(false);

  const toggleButton: ReactNode = (
    <button
      type="button"
      onClick={() => setShow(!show)}
      aria-label={show ? 'Masquer le mot de passe' : 'Afficher le mot de passe'}
      aria-pressed={show}
      className="text-brand-text-tertiary hover:text-brand-text-secondary transition-colors"
    >
      {show ? <EyeOff size={18} /> : <Eye size={18} />}
    </button>
  );

  return (
    <AuthTextField
      label={label}
      icon={Lock}
      type={show ? 'text' : 'password'}
      value={value}
      onChange={onChange}
      autoComplete={autoComplete}
      placeholder={placeholder}
      required={required}
      error={error}
      rightAdornment={toggleButton}
    />
  );
}
