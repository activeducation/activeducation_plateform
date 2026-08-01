'use client';
import { useEffect, useState, useRef, useCallback } from 'react';
import { useAuth } from '@/lib/auth';
import { useTheme } from '@/lib/theme';
import { api } from '@/lib/api';
import type { School } from '@/lib/types';
import { useRouter } from 'next/navigation';
import {
  Search, Settings, GraduationCap, WifiOff, RefreshCw, Building2,
} from 'lucide-react';
import EntityCard from '@/components/cards/EntityCard';

export default function SchoolsPage() {
  const { user, loading: authLoading } = useAuth();
  const { t } = useTheme();
  const router = useRouter();
  const [schools, setSchools] = useState<School[]>([]);
  const [search, setSearch] = useState('');
  const [selectedType, setSelectedType] = useState<string | null>(null);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);
  const [refreshing, setRefreshing] = useState(false);
  const listRef = useRef<HTMLDivElement>(null);
  const touchStartY = useRef(0);
  const [pullDistance, setPullDistance] = useState(0);

  const loadSchools = useCallback((p: number, append: boolean) => {
    const params = new URLSearchParams();
    if (search) params.set('search', search);
    if (selectedType) params.set('type', selectedType);
    params.set('page', String(p));
    params.set('per_page', '15');
    const fetcher = append ? (v: boolean) => {} : setLoading;
    fetcher(true);
    setError(false);
    api.get<{ items: School[]; total: number }>(`/schools?${params}`)
      .then(data => {
        setSchools(prev => append ? [...prev, ...data.items] : data.items);
        setTotal(data.total);
      })
      .catch(() => setError(true))
      .finally(() => { fetcher(false); setRefreshing(false); });
  }, [search, selectedType]);

  useEffect(() => {
    if (!user) return;
    setPage(1);
    loadSchools(1, false);
  }, [user, search, selectedType, loadSchools]);

  const handleRefresh = () => {
    setRefreshing(true);
    setPage(1);
    loadSchools(1, false);
  };

  const typeFilters = [
    { label: t('Toutes'), value: null },
    { label: t('Université'), value: 'university' },
    { label: t('Grande École'), value: 'grande_ecole' },
    { label: t('Institut'), value: 'institut' },
    { label: t('Centre de Formation'), value: 'centre_formation' },
  ];

  const hasMore = schools.length < total;

  const handleTouchStart = (e: React.TouchEvent) => {
    touchStartY.current = e.touches[0].clientY;
  };
  const handleTouchMove = (e: React.TouchEvent) => {
    const scrollTop = listRef.current?.scrollTop ?? 0;
    if (scrollTop > 0) return;
    const dist = e.touches[0].clientY - touchStartY.current;
    if (dist > 0) setPullDistance(Math.min(dist * 0.4, 60));
  };
  const handleTouchEnd = () => {
    if (pullDistance > 40) handleRefresh();
    setPullDistance(0);
  };

  if (authLoading) return <div className="min-h-[80vh] flex items-center justify-center"><div className="animate-spin w-8 h-8 border-2 border-brand-primary border-t-transparent rounded-full" /></div>;
  if (!user) return null;

  return (
    <div className="min-h-screen bg-brand-background" style={{ backgroundColor: '#FBF8FF' }}>
      {/* Header */}
      <div className="px-4 pt-6 pb-4 text-center relative">
        <button onClick={() => router.push('/parametres')}
          className="absolute right-4 top-6 w-9 h-9 rounded-lg bg-brand-surface flex items-center justify-center">
          <Settings size={17} className="text-brand-text-secondary" />
        </button>
        <h1 className="text-[22px] font-extrabold text-brand-text-primary">{t('Annuaire des Ecoles')}</h1>
        <p className="text-sm mt-0.5">
          <span className="font-bold text-brand-primary">ACTIV</span>
          <span className="font-bold text-brand-secondary">EDUCATION</span>
        </p>
      </div>

      {/* Search */}
      <div className="px-4 mb-3">
        <div className="relative">
          <Search size={15} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-brand-text-tertiary" />
          <input type="text" placeholder={t('Rechercher une ecole, un BTS...')}
            value={search} onChange={e => setSearch(e.target.value)}
            className="w-full h-10 pl-9 pr-4 rounded-xl bg-brand-surface border border-brand-border text-sm outline-none focus:border-brand-primary transition-colors" />
        </div>
      </div>

      {/* Pull-to-refresh indicator */}
      {pullDistance > 0 && (
        <div className="flex justify-center" style={{ height: pullDistance }}>
          <div className={`animate-spin w-5 h-5 border-2 border-brand-primary border-t-transparent rounded-full ${refreshing ? '' : 'opacity-50'}`}
            style={{ marginTop: pullDistance / 2 }} />
        </div>
      )}

      {/* Filter pills */}
      <div className="flex gap-2 overflow-x-auto px-4 pb-3 scrollbar-none"
        ref={listRef}
        onTouchStart={handleTouchStart}
        onTouchMove={handleTouchMove}
        onTouchEnd={handleTouchEnd}>
        {typeFilters.map(f => (
          <button key={f.label} onClick={() => setSelectedType(f.value)}
            className={`flex-shrink-0 h-8 px-4 rounded-full text-xs font-semibold transition-all ${
              selectedType === f.value
                ? 'bg-brand-primary text-white'
                : 'bg-white text-brand-text-secondary border border-brand-border hover:border-brand-primary/30'
            }`}>
            {f.label}
          </button>
        ))}
      </div>

      {/* Content */}
      {loading ? (
        <div className="px-4 md:px-0 grid grid-cols-1 md:grid-cols-2 gap-3">
          {[1,2,3].map(i => (
            <div key={i} className="bg-white rounded-xl border border-brand-border overflow-hidden animate-pulse">
              <div className="h-24 bg-brand-surface" />
              <div className="p-4 space-y-2">
                <div className="h-4 bg-brand-surface rounded w-3/4" />
                <div className="h-3 bg-brand-surface rounded w-1/2" />
              </div>
            </div>
          ))}
        </div>
      ) : error ? (
        <div className="text-center py-16 px-4">
          <div className="w-16 h-16 rounded-full bg-brand-surface mx-auto mb-4 flex items-center justify-center">
            <WifiOff size={24} className="text-brand-text-tertiary" />
          </div>
          <p className="font-semibold text-brand-text-secondary">{t('Impossible de charger les ecoles.')}</p>
          <p className="text-sm text-brand-text-tertiary mt-1">{t('Verifiez votre connexion.')}</p>
          <button onClick={handleRefresh}
            className="mt-4 h-10 px-6 rounded-xl bg-brand-primary text-white text-sm font-semibold flex items-center gap-2 mx-auto hover:opacity-90 transition-all">
            <RefreshCw size={15} />
            {t('Reessayer')}
          </button>
        </div>
      ) : schools.length === 0 ? (
        <div className="text-center py-16 px-4">
          <div className="w-16 h-16 rounded-full bg-brand-surface mx-auto mb-4 flex items-center justify-center">
            <Building2 size={24} className="text-brand-text-tertiary" />
          </div>
          <p className="font-semibold text-brand-text-secondary">{t('Aucune ecole trouvee')}</p>
          <p className="text-sm text-brand-text-tertiary mt-1">{t('Essaie un autre terme')}</p>
        </div>
      ) : (
        <div className="px-4 md:px-0 grid grid-cols-1 md:grid-cols-2 gap-3 pb-4">
          {schools.map(school => (
            <EntityCard
              key={school.id}
              type="school"
              id={school.id}
              bannerUrl={school.logo_url}
              avatarUrl={school.logo_url}
              initials={(school.name ?? '?').slice(0, 1).toUpperCase()}
              title={school.name}
              subtitle={school.city ? `${school.city}${school.country ? `, ${school.country}` : ''}` : undefined}
              description={school.description}
              tuition={school.tuition_range}
              students={school.student_count}
              accreditations={school.accreditations}
              isPublic={school.is_public}
              schoolType={school.type}
              ctaPrimaryLabel={t('Voir filieres')}
              ctaSecondaryLabel={t('Details')}
              onViewMore={(id) => router.push(`/ecoles/${id}`)}
              t={t}
            />
          ))}
          {hasMore && (
            <button onClick={() => { const next = page + 1; setPage(next); loadSchools(next, true); }}
              className="w-full h-11 rounded-xl border border-brand-border bg-white text-sm font-semibold text-brand-primary hover:bg-brand-primary-surface transition-colors">
              {t('Charger plus')}
            </button>
          )}
        </div>
      )}
    </div>
  );
}
