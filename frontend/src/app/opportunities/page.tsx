'use client';
import { useEffect, useState } from 'react';
import { useAuth } from '@/lib/auth';
import { api } from '@/lib/api';
import { Briefcase, MapPin, ArrowLeft, ChevronRight, Loader2 } from 'lucide-react';
import { useRouter } from 'next/navigation';
import { useTheme } from '@/lib/theme';

interface Opportunity {
  id: string;
  title: string;
  opportunity_type: string;
  organization_name: string;
  organization_logo?: string;
  location?: string;
  remote_type?: string;
  application_deadline?: string;
  is_featured?: boolean;
}

const oppLabels: Record<string, string> = {
  internship: 'Stage', job: 'Emploi', volunteer: 'Bénévole', scholarship: 'Bourse',
};
const oppColors: Record<string, string> = {
  internship: 'bg-brand-primary/10 text-brand-primary',
  job: 'bg-brand-success/10 text-brand-success',
  volunteer: 'bg-brand-xp-gold/10 text-brand-xp-gold-dark',
  scholarship: 'bg-brand-secondary/10 text-brand-accent',
};

export default function OpportunitiesPage() {
  const { user, loading: authLoading } = useAuth();
  const router = useRouter();
  const { t } = useTheme();
  const [opportunities, setOpportunities] = useState<Opportunity[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState(0);
  const [hasMore, setHasMore] = useState(true);

  const pageSize = 20;

  const load = async (p: number) => {
    try {
      const data = await api.get<Opportunity[]>(`/opportunities?limit=${pageSize}&offset=${p * pageSize}`);
      if (p === 0) setOpportunities(data);
      else setOpportunities(prev => [...prev, ...data]);
      setHasMore(data.length === pageSize);
      setError(null);
    } catch {
      setError(t('Impossible de charger les opportunités.'));
    }
    setLoading(false);
    setLoadingMore(false);
  };

  useEffect(() => {
    if (!user) return;
    load(0);
  }, [user]);

  if (authLoading) return <div className="min-h-[80vh] flex items-center justify-center"><div className="animate-spin w-8 h-8 border-2 border-brand-primary border-t-transparent rounded-full" /></div>;
  if (!user) return null;

  return (
    <div className="animate-fade-in">
      <button onClick={() => router.back()} className="flex items-center gap-1 text-brand-text-secondary text-sm mb-4">
        <ArrowLeft size={18} /> {t('Retour')}
      </button>

      {/* Hero */}
      <div className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-brand-primary via-brand-primary to-[#1060CF] p-5 mb-4">
        <div className="absolute -top-6 -right-6 w-36 h-36 rounded-full bg-white/5" />
        <div className="relative z-10">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-white/15 flex items-center justify-center border border-white/20">
              <Briefcase size={18} className="text-white" />
            </div>
            <div>
              <h1 className="text-white font-bold text-lg">{t('Toutes les opportunités')}</h1>
              <p className="text-white/60 text-xs">{opportunities.length} {t('disponible')}{opportunities.length > 1 ? 's' : ''}</p>
            </div>
          </div>
        </div>
      </div>

      {error && !loading && opportunities.length === 0 ? (
        <div className="text-center py-12">
          <p className="font-semibold text-brand-text-primary">{t('Erreur')}</p>
          <p className="text-sm text-brand-text-tertiary mt-1">{error}</p>
          <button onClick={() => { setLoading(true); load(0); }}
            className="mt-4 px-6 py-3 rounded-full bg-brand-primary text-white font-semibold text-sm">
            {t('Réessayer')}
          </button>
        </div>
      ) : loading ? (
        <div className="flex items-center justify-center py-12">
          <div className="animate-spin w-8 h-8 border-2 border-brand-primary border-t-transparent rounded-full" />
        </div>
      ) : opportunities.length === 0 ? (
        <div className="text-center py-12">
          <div className="w-16 h-16 rounded-full bg-brand-surface mx-auto mb-4 flex items-center justify-center">
            <Briefcase size={24} className="text-brand-text-tertiary" />
          </div>
          <p className="font-semibold text-brand-text-primary">{t('Aucune opportunité disponible')}</p>
        </div>
      ) : (
        <div className="space-y-3 pb-6">
          {opportunities.map((opp) => (
            <div key={opp.id}
              className="bg-white rounded-2xl border border-brand-border p-4 hover:shadow-card-hover transition-all">
              <span className={`inline-block text-[10px] font-bold px-2 py-0.5 rounded-md mb-2 ${oppColors[opp.opportunity_type] || 'bg-brand-surface text-brand-text-tertiary'}`}>
                {t(oppLabels[opp.opportunity_type] || opp.opportunity_type)}
              </span>
              <p className="text-sm font-semibold text-brand-text-primary leading-tight">{opp.title}</p>
              <div className="flex items-center gap-1.5 mt-1">
                {opp.organization_logo && (
                  <img src={opp.organization_logo} alt="" loading="lazy" className="w-4 h-4 rounded object-cover"
                    onError={(e) => { e.currentTarget.style.display = 'none'; }} />
                )}
                <p className="text-xs text-brand-text-secondary">{opp.organization_name}</p>
              </div>
              {opp.location && (
                <div className="flex items-center gap-1 mt-2 text-[11px] text-brand-text-tertiary">
                  <MapPin size={11} />
                  <span>{opp.location}</span>
                </div>
              )}
            </div>
          ))}
          {hasMore && (
            <button onClick={() => { const next = page + 1; setPage(next); setLoadingMore(true); load(next); }}
              disabled={loadingMore}
              className="w-full py-3 rounded-2xl border border-brand-border text-brand-primary font-semibold text-sm hover:bg-brand-primary-surface transition-all disabled:opacity-50">
              {loadingMore ? <span className="inline-flex items-center gap-2"><span className="animate-spin w-4 h-4 border-2 border-brand-primary border-t-transparent rounded-full" />{t('Chargement...')}</span> : t('Charger plus')}
            </button>
          )}
        </div>
      )}
    </div>
  );
}
