'use client';
import { useRouter } from 'next/navigation';
import { useTheme } from '@/lib/theme';
import { ArrowLeft, Shield, Lock, Eye, Trash2, FileText } from 'lucide-react';

export default function ConfidentialitePage() {
  const { t } = useTheme();
  const router = useRouter();

  const sections = [
    {
      icon: Shield,
      title: 'Protection des données',
      text: 'Tes données personnelles sont stockées de manière sécurisée et ne sont jamais partagées avec des tiers sans ton consentement explicite. Nous utilisons le chiffrement SSL/TLS pour toutes les communications.',
    },
    {
      icon: Eye,
      title: 'Collecte de données',
      text: 'Nous collectons uniquement les informations nécessaires à ton parcours d\'orientation : profil scolaire, centres d\'intérêt, résultats aux tests, progression e-learning. Ces données servent à personnaliser tes recommandations.',
    },
    {
      icon: Lock,
      title: 'Sécurité du compte',
      text: 'Ton mot de passe est chiffré et jamais stocké en clair. Tu peux à tout moment modifier ton mot de passe ou demander la suppression de ton compte depuis ce menu.',
    },
    {
      icon: Trash2,
      title: 'Suppression des données',
      text: 'Tu peux demander la suppression complète de ton compte et de toutes tes données à tout moment. Contacte-nous à support@activeducation.com pour toute demande.',
    },
    {
      icon: FileText,
      title: 'Cookies',
      text: 'Nous utilisons uniquement des cookies techniques nécessaires au fonctionnement de l\'application (session, authentification). Aucun cookie publicitaire ou de tracking tiers n\'est utilisé.',
    },
  ];

  return (
    <div className="min-h-screen bg-brand-background pb-8">
      <div className="bg-gradient-hero px-6 pt-12 pb-8">
        <button onClick={() => router.back()} className="w-9 h-9 rounded-full bg-white/10 flex items-center justify-center mb-5">
          <ArrowLeft size={18} className="text-white" />
        </button>
        <h1 className="text-[28px] font-extrabold text-white tracking-tight">{t('Confidentialité')}</h1>
        <p className="text-white/70 text-sm mt-1.5">{t('Comment nous protégeons tes données')}</p>
      </div>

      <div className="px-4 -mt-4 space-y-3">
        {sections.map((s) => (
          <div key={s.title} className="bg-white rounded-2xl border border-brand-border shadow-card p-4">
            <div className="flex items-center gap-3 mb-3">
              <div className="w-8 h-8 rounded-lg bg-brand-primary/10 flex items-center justify-center flex-shrink-0">
                <s.icon size={16} className="text-brand-primary" />
              </div>
              <h2 className="font-bold text-brand-text-primary text-sm">{t(s.title)}</h2>
            </div>
            <p className="text-sm text-brand-text-secondary leading-relaxed">{t(s.text)}</p>
          </div>
        ))}

        <div className="bg-brand-primary/5 rounded-2xl border border-brand-primary/20 p-4 text-center">
          <p className="text-xs text-brand-text-tertiary">
            {t('Dernière mise à jour : juillet 2026')}
          </p>
        </div>
      </div>
    </div>
  );
}
