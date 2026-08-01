'use client';
import { useState, useEffect, useMemo } from 'react';
import { useAuth } from '@/lib/auth';
import { useRouter } from 'next/navigation';
import { useTheme } from '@/lib/theme';
import {
  Sparkles,
  Mail,
  UserCircle,
  UserRound,
  CheckCircle,
  Circle,
} from 'lucide-react';
import AuthShell from '@/components/auth/AuthShell';
import AuthTextField from '@/components/auth/AuthTextField';
import PasswordField from '@/components/auth/PasswordField';
import PrimaryButton from '@/components/auth/PrimaryButton';

export default function RegisterPage() {
  const { register, user, loading } = useAuth();
  const { t } = useTheme();
  const router = useRouter();
  const [form, setForm] = useState({
    email: '',
    password: '',
    firstName: '',
    lastName: '',
    confirmPassword: '',
  });
  const [acceptTerms, setAcceptTerms] = useState(false);
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (user) router.push('/');
  }, [user, router]);

  const set = (k: keyof typeof form) => (v: string) => setForm((f) => ({ ...f, [k]: v }));

  const passwordChecks = useMemo(
    () => [
      { label: t('8+ caractères'), check: form.password.length >= 8 },
      { label: t('Majuscule (A-Z)'), check: /[A-Z]/.test(form.password) },
      { label: t('Minuscule (a-z)'), check: /[a-z]/.test(form.password) },
      { label: t('Chiffre (0-9)'), check: /[0-9]/.test(form.password) },
      {
        label: t('Caractère spécial (!@#%&*)'),
        check: /[!@#%&*()_\-+=<>?/[\]{}|;:',.<>~`^$]/.test(form.password),
      },
    ],
    [form.password, t],
  );

  const isPasswordValid = passwordChecks.every((c) => c.check);
  const passwordsMatch = form.password === form.confirmPassword;
  const canSubmit =
    form.email.trim() &&
    form.password &&
    isPasswordValid &&
    passwordsMatch &&
    acceptTerms &&
    form.firstName.trim().length >= 2 &&
    form.lastName.trim().length >= 2;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!canSubmit) return;
    if (!acceptTerms) {
      setError("Veuillez accepter les conditions d'utilisation");
      return;
    }
    if (!passwordsMatch) {
      setError('Les mots de passe ne correspondent pas');
      return;
    }
    setError('');
    setSubmitting(true);
    try {
      const payload = {
        email: form.email,
        password: form.password,
        firstName: form.firstName,
        lastName: form.lastName,
      };
      await register(payload);
      router.push('/');
    } catch (err: any) {
      setError(err.message || "Erreur lors de l'inscription");
    }
    setSubmitting(false);
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-brand-dark-bg">
        <div
          role="status"
          aria-label="Chargement"
          className="animate-spin w-8 h-8 border-2 border-white border-t-transparent rounded-full"
        />
      </div>
    );
  }

  return (
    <AuthShell
      heroIcon={Sparkles}
      heroEyebrow={t('Bienvenue')}
      heroTitle="ActivEducation"
      heroSubtitle={t('Rejoins-nous. Construis ton avenir.')}
      heroAside={
        <div className="space-y-4 text-white/90">
          <p className="text-base font-medium">
            {t('Quelques minutes suffisent pour créer ton compte et démarrer ton parcours.')}
          </p>
          <ul className="space-y-2 text-sm text-white/80">
            <li className="flex items-center gap-2">
              <span className="w-1.5 h-1.5 rounded-full bg-brand-secondary" aria-hidden="true" />
              {t('100% gratuit pour les élèves')}
            </li>
            <li className="flex items-center gap-2">
              <span className="w-1.5 h-1.5 rounded-full bg-brand-secondary" aria-hidden="true" />
              {t('Conseils IA 24h/24 avec AÏDA')}
            </li>
            <li className="flex items-center gap-2">
              <span className="w-1.5 h-1.5 rounded-full bg-brand-secondary" aria-hidden="true" />
              {t('Tests validés scientifiquement (RIASEC)')}
            </li>
          </ul>
        </div>
      }
    >
      <form onSubmit={handleSubmit} className="space-y-4" noValidate>
        <div className="mb-2">
          <h2 className="text-2xl md:text-3xl font-bold text-brand-text-primary">
            {t('Inscription')}
          </h2>
          <p className="text-brand-text-secondary text-sm mt-1.5">
            {t('Crée ton compte pour commencer.')}
          </p>
        </div>

        {error && (
          <div
            role="alert"
            className="p-3.5 rounded-xl bg-brand-error-light text-brand-error text-sm font-medium animate-slide-down flex items-center gap-2"
          >
            <span className="w-1.5 h-1.5 rounded-full bg-brand-error flex-shrink-0" aria-hidden="true" />
            {error}
          </div>
        )}

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <AuthTextField
            label={t('Prénom')}
            icon={UserCircle}
            value={form.firstName}
            onChange={set('firstName')}
            autoComplete="given-name"
            placeholder={t('Jean')}
            containerClassName="w-full"
          />
          <AuthTextField
            label={t('Nom')}
            icon={UserRound}
            value={form.lastName}
            onChange={set('lastName')}
            autoComplete="family-name"
            placeholder={t('Dupont')}
            containerClassName="w-full"
          />
        </div>

        <AuthTextField
          label={t('Email')}
          icon={Mail}
          type="email"
          value={form.email}
          onChange={set('email')}
          autoComplete="email"
          inputMode="email"
          placeholder={t('vous@exemple.com')}
          required
        />

        <div>
          <PasswordField
            label={t('Mot de passe')}
            value={form.password}
            onChange={set('password')}
            autoComplete="new-password"
            required
          />
          {form.password.length > 0 && !isPasswordValid && (
            <ul
              className="mt-2.5 p-3 rounded-xl bg-brand-surface border border-brand-border space-y-1.5"
              aria-label={t('Critères de sécurité du mot de passe')}
            >
              {passwordChecks.map((c, i) => (
                <li key={i} className="flex items-center gap-2 text-xs">
                  {c.check ? (
                    <CheckCircle size={13} className="text-brand-success flex-shrink-0" aria-hidden="true" />
                  ) : (
                    <Circle size={13} className="text-brand-text-tertiary flex-shrink-0" aria-hidden="true" />
                  )}
                  <span className={c.check ? 'text-brand-success font-medium' : 'text-brand-text-tertiary'}>
                    {c.label}
                  </span>
                </li>
              ))}
            </ul>
          )}
        </div>

        <div>
          <PasswordField
            label={t('Confirmer le mot de passe')}
            value={form.confirmPassword}
            onChange={set('confirmPassword')}
            autoComplete="new-password"
            required
          />
          {form.confirmPassword.length > 0 && !passwordsMatch && (
            <p className="text-xs text-brand-error mt-1.5" role="alert">
              {t('Les mots de passe ne correspondent pas')}
            </p>
          )}
        </div>

        <label className="flex items-start gap-3 cursor-pointer pt-1">
          <input
            type="checkbox"
            checked={acceptTerms}
            onChange={(e) => setAcceptTerms(e.target.checked)}
            className="mt-0.5 w-4 h-4 rounded border-brand-border text-brand-primary focus:ring-brand-primary/20"
          />
          <span className="text-xs text-brand-text-secondary leading-relaxed">
            {t("J'accepte les")}{' '}
            <a href="#" className="text-brand-primary font-semibold hover:underline">
              {t("conditions d'utilisation")}
            </a>{' '}
            {t('et la')}{' '}
            <a href="#" className="text-brand-primary font-semibold hover:underline">
              {t('politique de confidentialité')}
            </a>
          </span>
        </label>

        <div className="pt-2">
          <PrimaryButton type="submit" loading={submitting} disabled={!canSubmit}>
            {t('Créer mon compte')}
          </PrimaryButton>
        </div>

        <div className="flex items-center gap-4 py-2" aria-hidden="true">
          <div className="flex-1 h-px bg-brand-border" />
          <span className="text-[11px] font-semibold text-brand-text-tertiary tracking-widest uppercase">
            {t('OU')}
          </span>
          <div className="flex-1 h-px bg-brand-border" />
        </div>

        <p className="text-center text-sm text-brand-text-secondary">
          {t('Déjà un compte ? ')}
          <a
            href="/login"
            className="text-brand-primary font-bold hover:text-brand-primary-light transition-colors"
          >
            {t('Se connecter')}
          </a>
        </p>
      </form>
    </AuthShell>
  );
}
