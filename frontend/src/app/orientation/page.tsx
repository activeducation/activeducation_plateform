'use client';
import { useEffect, useState } from 'react';
import { useAuth } from '@/lib/auth';
import { useTheme } from '@/lib/theme';
import { api } from '@/lib/api';
import type { OrientationTest } from '@/lib/types';
import { getSectorIcon, getTestIcon, getTestGradient } from '@/lib/career-icons';
import { useRouter } from 'next/navigation';
import { Compass, Brain, ChevronRight, ListChecks, Clock, Wallet, TrendingUp } from 'lucide-react';

interface CareerSummary {
  id: string;
  name: string;
  sector_name: string;
  job_demand?: string | null;
  salary_avg_fcfa?: number | null;
  image_url?: string | null;
}

export default function OrientationPage() {
  const { user, loading: authLoading } = useAuth();
  const { t } = useTheme();
  const router = useRouter();
  const [tests, setTests] = useState<OrientationTest[]>([]);
  const [careers, setCareers] = useState<CareerSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [careersLoading, setCareersLoading] = useState(true);

  useEffect(() => {
    if (!user) return;
    api.get<OrientationTest[]>('/orientation/tests')
      .then(setTests)
      .catch(() => {})
      .finally(() => setLoading(false));
    api.get<CareerSummary[]>('/orientation/careers?limit=12')
      .then(setCareers)
      .catch(() => {})
      .finally(() => setCareersLoading(false));
  }, [user]);

  if (authLoading) return <div className="min-h-[80vh] flex items-center justify-center"><div className="animate-spin w-8 h-8 border-2 border-brand-primary border-t-transparent rounded-full" /></div>;
  if (!user) return null;

  const formatSalary = (avg?: number | null) => {
    if (!avg) return null;
    if (avg >= 1_000_000) return `${(avg / 1_000_000).toFixed(1)}M FCFA`;
    if (avg >= 1_000) return `${Math.round(avg / 1_000)}k FCFA`;
    return `${avg} FCFA`;
  };

  const demandLabel = (d?: string | null) => {
    if (d === 'high') return { label: t('Forte demande'), color: 'bg-green-100 text-green-700' };
    if (d === 'medium') return { label: t('Demande modérée'), color: 'bg-amber-100 text-amber-700' };
    return null;
  };

  return (
    <div className="animate-fade-in pb-4">
      {/* Hero */}
      <div className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-brand-category-economics via-brand-category-economics to-brand-category-economics/70 p-5 mb-5">
        <div className="absolute -top-6 -right-6 w-36 h-36 rounded-full bg-white/5" />
        <div className="relative z-10 flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-white/15 flex items-center justify-center border border-white/20">
            <Compass size={18} className="text-white" />
          </div>
          <div>
            <h1 className="text-white font-bold text-lg">{t('Orientation')}</h1>
            <p className="text-white/60 text-xs">{t('Découvre ta voie')}</p>
          </div>
        </div>
      </div>

      {/* Intro card */}
      <div className="bg-gradient-to-br from-brand-primary-surface to-white rounded-2xl border border-brand-primary/20 p-5 mb-5 shadow-card">
        <div className="w-12 h-12 rounded-xl bg-gradient-primary flex items-center justify-center mb-3">
          <Brain size={22} className="text-white" />
        </div>
        <h2 className="font-bold text-brand-text-primary text-lg mb-1">{t("Tests d'orientation")}</h2>
        <p className="text-sm text-brand-text-secondary leading-relaxed mb-4">
          {t("Explore tes centres d'intérêt, ta personnalité et tes aptitudes pour trouver les métiers et formations qui te correspondent.")}
        </p>
        <div className="flex items-center gap-2 text-xs text-brand-text-tertiary">
          <ListChecks size={14} />
          <span>{tests.length} {t('tests disponibles')}</span>
        </div>
      </div>

      {/* Test list */}
      <h2 className="text-sm font-bold text-brand-text-secondary uppercase tracking-wide mb-3">
        {t('Tests disponibles')}
      </h2>
      {loading ? (
        <div className="space-y-3">
          {[1,2,3].map(i => (
            <div key={i} className="bg-white rounded-xl border border-brand-border p-4 animate-pulse space-y-2">
              <div className="h-4 bg-brand-surface rounded w-3/4" />
              <div className="h-3 bg-brand-surface rounded w-full" />
            </div>
          ))}
        </div>
      ) : tests.length === 0 ? (
        <div className="text-center py-12">
          <div className="w-16 h-16 rounded-full bg-brand-surface mx-auto mb-4 flex items-center justify-center">
            <Compass size={24} className="text-brand-text-tertiary" />
          </div>
          <p className="font-semibold text-brand-text-secondary">{t('Aucun test disponible')}</p>
          <p className="text-sm text-brand-text-tertiary mt-1">{t('Reviens plus tard')}</p>
        </div>
      ) : (
        <div className="space-y-3">
          {tests.map(test => {
            const TestIcon = getTestIcon(test.type);
            const gradient = getTestGradient(test.type);
            return (
            <button key={test.id} onClick={() => router.push(`/orientation/test/${test.id}`)}
              className="w-full bg-white rounded-xl border border-brand-border p-4 text-left shadow-card hover:shadow-card-hover hover:border-brand-primary/30 transition-all group">
              <div className="flex items-start gap-3">
                <div className={`w-10 h-10 rounded-xl bg-gradient-to-br ${gradient} flex items-center justify-center flex-shrink-0`}>
                  <TestIcon size={18} className="text-white" />
                </div>
                <div className="flex-1 min-w-0">
                  <h3 className="font-bold text-brand-text-primary text-sm group-hover:text-brand-primary transition-colors">
                    {test.name}
                  </h3>
                  <p className="text-xs text-brand-text-tertiary mt-0.5 line-clamp-2">{test.description}</p>
                  <div className="flex items-center gap-2 mt-2">
                    <span className="text-[10px] font-semibold text-brand-text-tertiary bg-brand-surface px-2 py-0.5 rounded-full">
                      {test.questions?.length || 0} {t('questions')}
                    </span>
                    {test.duration_minutes && (
                      <span className="text-[10px] font-semibold text-brand-text-tertiary bg-brand-surface px-2 py-0.5 rounded-full flex items-center gap-1">
                        <Clock size={10} />
                        {test.duration_minutes} {t('min')}
                      </span>
                    )}
                  </div>
                </div>
                <div className="flex flex-col items-center justify-center gap-1">
                  <span className="text-[10px] font-bold text-brand-primary bg-brand-primary-surface px-2.5 py-1 rounded-lg">{t('Commencer')}</span>
                  <ChevronRight size={14} className="text-brand-text-tertiary" />
                </div>
              </div>
            </button>
          );
          })}
        </div>
      )}

      {/* Career catalog */}
      <div className="flex items-center justify-between mt-8 mb-3">
        <h2 className="text-sm font-bold text-brand-text-secondary uppercase tracking-wide">
          {t('Métiers qui matchent avec toi')}
        </h2>
        <span className="text-[10px] font-semibold text-brand-text-tertiary bg-brand-surface px-2 py-0.5 rounded-full">
          {careers.length} {t('métiers')}
        </span>
      </div>

      {careersLoading ? (
        <div className="space-y-2">
          {[1, 2, 3].map(i => (
            <div key={i} className="bg-white rounded-xl border border-brand-border p-3 animate-pulse flex items-center gap-3">
              <div className="w-12 h-12 rounded-xl bg-brand-surface flex-shrink-0" />
              <div className="flex-1 space-y-2">
                <div className="h-3 bg-brand-surface rounded w-2/3" />
                <div className="h-2 bg-brand-surface rounded w-1/2" />
              </div>
            </div>
          ))}
        </div>
      ) : careers.length === 0 ? (
        <div className="text-center py-10 bg-white rounded-xl border border-dashed border-brand-border">
          <div className="w-14 h-14 rounded-full bg-brand-surface mx-auto mb-3 flex items-center justify-center">
            <Compass size={22} className="text-brand-text-tertiary" />
          </div>
          <p className="font-semibold text-sm text-brand-text-secondary">{t('Aucun métier disponible')}</p>
          <p className="text-xs text-brand-text-tertiary mt-1">{t('Reviens plus tard')}</p>
        </div>
      ) : (
        <div className="space-y-2">
          {careers.map(career => {
            const demand = demandLabel(career.job_demand);
            const salary = formatSalary(career.salary_avg_fcfa);
            const SectorIcon = getSectorIcon(career.sector_name);
            return (
              <button
                key={career.id}
                onClick={() => router.push(`/orientation/career/${career.id}`)}
                className="w-full bg-white rounded-xl border border-brand-border p-3 text-left shadow-card hover:shadow-card-hover hover:border-brand-primary/40 active:scale-[.99] transition-all flex items-center gap-3"
              >
                <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-brand-primary-surface to-white border border-brand-primary/20 flex items-center justify-center text-brand-primary flex-shrink-0">
                  <SectorIcon size={22} strokeWidth={1.8} />
                </div>
                <div className="flex-1 min-w-0">
                  <h3 className="font-bold text-brand-text-primary text-sm truncate">
                    {career.name}
                  </h3>
                  <p className="text-[11px] text-brand-text-tertiary truncate">
                    {career.sector_name}
                  </p>
                  <div className="flex items-center gap-2 mt-1.5">
                    {salary && (
                      <span className="inline-flex items-center gap-1 text-[10px] font-semibold text-emerald-700 bg-emerald-50 px-1.5 py-0.5 rounded-full">
                        <Wallet size={9} /> {salary}
                      </span>
                    )}
                    {demand && (
                      <span className={`inline-flex items-center gap-1 text-[10px] font-semibold px-1.5 py-0.5 rounded-full ${demand.color}`}>
                        <TrendingUp size={9} /> {demand.label}
                      </span>
                    )}
                  </div>
                </div>
                <ChevronRight size={16} className="text-brand-text-tertiary flex-shrink-0" />
              </button>
            );
          })}
        </div>
      )}
    </div>
  );
}
