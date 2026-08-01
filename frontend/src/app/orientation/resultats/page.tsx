'use client';
import { useSyncExternalStore } from 'react';
import { useAuth } from '@/lib/auth';
import { useTheme } from '@/lib/theme';
import { AlertCircle, BarChart3, BriefcaseBusiness, ChevronRight, Compass } from 'lucide-react';
import { useRouter } from 'next/navigation';

interface Recommendation {
  id: string;
  name: string;
  description?: string;
  sector_name?: string;
  match_score?: number;
}

interface OrientationResult {
  dominant_traits: string[];
  recommendations: Recommendation[];
  interpretation?: {
    profile_summary?: string;
    advice?: string;
  };
}

let cachedResultJson: string | null = null;
let cachedResult: OrientationResult | null = null;

function getStoredResult(): OrientationResult | null {
  const savedResult = sessionStorage.getItem('orientation_test_result');
  if (savedResult === cachedResultJson) return cachedResult;

  cachedResultJson = savedResult;
  try {
    cachedResult = savedResult ? JSON.parse(savedResult) as OrientationResult : null;
  } catch {
    sessionStorage.removeItem('orientation_test_result');
    cachedResultJson = null;
    cachedResult = null;
  }
  return cachedResult;
}

const subscribeToResult = () => () => {};
const getServerResult = () => null;

export default function ResultsPage() {
  const { user, loading: authLoading } = useAuth();
  const { t } = useTheme();
  const router = useRouter();
  const result = useSyncExternalStore(subscribeToResult, getStoredResult, getServerResult);

  if (authLoading) return <div className="min-h-[80vh] flex items-center justify-center"><div className="animate-spin w-8 h-8 border-2 border-brand-primary border-t-transparent rounded-full" /></div>;
  if (!user) return null;

  if (!result) {
    return (
      <div className="animate-fade-in flex flex-col items-center justify-center min-h-[80vh] text-center">
        <div className="w-16 h-16 rounded-full bg-brand-primary-surface flex items-center justify-center mb-5">
          <AlertCircle size={30} className="text-brand-primary" />
        </div>
        <h1 className="text-xl font-bold text-brand-text-primary mb-2">{t('Résultat introuvable')}</h1>
        <p className="text-sm text-brand-text-tertiary max-w-sm mb-6">
          {t('Termine un test pour découvrir tes recommandations personnalisées.')}
        </p>
        <button onClick={() => router.push('/orientation')}
          className="inline-flex items-center gap-2 h-11 px-5 rounded-xl bg-gradient-primary text-white font-semibold shadow-glow">
          {t("Voir les tests d'orientation")} <ChevronRight size={18} />
        </button>
      </div>
    );
  }

  return (
    <div className="animate-fade-in max-w-3xl mx-auto pb-8">
      <div className="w-20 h-20 rounded-full bg-gradient-to-br from-brand-success to-brand-success/70 flex items-center justify-center mb-6 shadow-xl shadow-brand-success/20">
        <BarChart3 size={40} className="text-white" />
      </div>
      <h1 className="text-2xl font-bold text-brand-text-primary mb-2">{t('Tes recommandations')}</h1>
      {result.interpretation?.profile_summary && (
        <p className="text-brand-text-secondary mb-4 max-w-2xl">{result.interpretation.profile_summary}</p>
      )}

      {result.dominant_traits.length > 0 && (
        <div className="flex flex-wrap gap-2 mb-7">
          {result.dominant_traits.map((trait) => (
            <span key={trait} className="rounded-full bg-brand-primary-surface px-3 py-1 text-xs font-semibold text-brand-primary">
              {trait}
            </span>
          ))}
        </div>
      )}

      <h2 className="text-sm font-bold text-brand-text-secondary uppercase tracking-wide mb-3">
        {t('Métiers qui te correspondent')}
      </h2>
      {result.recommendations.length === 0 ? (
        <div className="rounded-xl border border-brand-border bg-white p-5 text-sm text-brand-text-tertiary">
          {t('Aucune recommandation précise n’a été trouvée pour le moment.')}
        </div>
      ) : (
        <div className="space-y-3">
          {result.recommendations.map((career) => (
            <button key={career.id} onClick={() => router.push(`/orientation/career/${career.id}`)}
              className="w-full rounded-xl border border-brand-border bg-white p-4 text-left shadow-card transition-all hover:border-brand-primary/40 hover:shadow-card-hover">
              <div className="flex items-center gap-3">
                <div className="flex h-11 w-11 flex-none items-center justify-center rounded-xl bg-brand-primary-surface text-brand-primary">
                  <BriefcaseBusiness size={21} />
                </div>
                <div className="min-w-0 flex-1">
                  <h3 className="font-bold text-brand-text-primary">{career.name}</h3>
                  {career.sector_name && <p className="text-xs text-brand-text-tertiary mt-0.5">{career.sector_name}</p>}
                  {career.description && <p className="text-sm text-brand-text-secondary mt-2 line-clamp-2">{career.description}</p>}
                </div>
                {typeof career.match_score === 'number' && (
                  <span className="rounded-lg bg-brand-success/10 px-2 py-1 text-xs font-bold text-brand-success">{Math.round(career.match_score)}%</span>
                )}
                <ChevronRight size={18} className="text-brand-text-tertiary" />
              </div>
            </button>
          ))}
        </div>
      )}

      <button onClick={() => router.push('/orientation')}
        className="mt-7 inline-flex items-center gap-2 text-sm font-semibold text-brand-primary">
        <Compass size={17} /> {t('Passer un autre test')}
      </button>
    </div>
  );
}
