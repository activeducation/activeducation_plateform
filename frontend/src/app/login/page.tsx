'use client';
import { useState, useEffect } from 'react';
import { useAuth } from '@/lib/auth';
import { useRouter } from 'next/navigation';
import { useTheme } from '@/lib/theme';
import { School, Mail, GraduationCap, Bot, ClipboardList } from 'lucide-react';
import AuthShell from '@/components/auth/AuthShell';
import AuthTextField from '@/components/auth/AuthTextField';
import PasswordField from '@/components/auth/PasswordField';
import PrimaryButton from '@/components/auth/PrimaryButton';

const features = [
  { icon: ClipboardList, text: "Tests d'orientation RIASEC" },
  { icon: GraduationCap, text: 'Écoles & formations' },
  { icon: Bot, text: 'AÏDA, conseillère IA 24h/24' },
];

export default function LoginPage() {
  const { login, user, loading } = useAuth();
  const { t } = useTheme();
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (user) router.push('/');
  }, [user, router]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email.trim() || !password) return;
    setError('');
    setSubmitting(true);
    try {
      await login(email, password);
      router.push('/');
    } catch (err: any) {
      setError(err.message || 'Email ou mot de passe incorrect');
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
      heroIcon={School}
      heroLogo="/logo.jpeg"
      heroEyebrow={t('Découvre ta voie')}
      heroTitle="ActivEducation"
      heroSubtitle={t('Découvre ta voie, joue ton avenir')}
      heroAside={
        <ul className="space-y-4">
          {features.map((f) => (
            <li key={f.text} className="flex items-center gap-3 text-white/90">
              <span className="w-10 h-10 rounded-xl bg-white/15 backdrop-blur-sm flex items-center justify-center flex-shrink-0">
                <f.icon size={20} className="text-white" aria-hidden="true" />
              </span>
              <span className="text-sm md:text-base font-medium">{t(f.text)}</span>
            </li>
          ))}
        </ul>
      }
    >
      <form onSubmit={handleSubmit} className="space-y-4" noValidate>
        <div className="mb-2">
          <h2 className="text-2xl md:text-3xl font-bold text-brand-text-primary">
            {t('Connexion')}
          </h2>
          <p className="text-brand-text-secondary text-sm mt-1.5">
            {t('Bienvenue ! Connectez-vous pour continuer.')}
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

        <AuthTextField
          label={t('Adresse email')}
          icon={Mail}
          type="email"
          value={email}
          onChange={setEmail}
          autoComplete="email"
          inputMode="email"
          placeholder={t('vous@exemple.com')}
          required
        />

        <PasswordField
          label={t('Mot de passe')}
          value={password}
          onChange={setPassword}
          autoComplete="current-password"
          required
        />

        <div className="pt-2">
          <PrimaryButton type="submit" loading={submitting} disabled={!email.trim() || !password}>
            {t('Se connecter')}
          </PrimaryButton>
        </div>

        {/* ── Séparateur OU ── */}
        <div className="flex items-center gap-4 py-2" aria-hidden="true">
          <div className="flex-1 h-px bg-brand-border" />
          <span className="text-[11px] font-semibold text-brand-text-tertiary tracking-widest uppercase">
            {t('OU')}
          </span>
          <div className="flex-1 h-px bg-brand-border" />
        </div>

        <p className="text-center text-sm text-brand-text-secondary">
          {t('Pas encore de compte ? ')}
          <a
            href="/register"
            className="text-brand-primary font-bold hover:text-brand-primary-light transition-colors"
          >
            {t("S'inscrire")}
          </a>
        </p>
      </form>
    </AuthShell>
  );
}
