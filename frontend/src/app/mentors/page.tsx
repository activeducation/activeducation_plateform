'use client';
import { useEffect, useState } from 'react';
import { useAuth } from '@/lib/auth';
import { api } from '@/lib/api';
import { useRouter } from 'next/navigation';
import { Users, Search, GraduationCap } from 'lucide-react';
import { useTheme } from '@/lib/theme';
import EntityCard from '@/components/cards/EntityCard';

interface Mentor {
  id: string;
  full_name: string;
  specialty: string;
  expertise_areas?: string[];
  bio?: string;
  avatar_url?: string;
  years_experience?: number;
  is_verified: boolean;
  hourly_rate?: number;
  available_slots?: string[];
  location?: string;
  company?: string;
  profession?: string;
  availability?: 'available' | 'limited' | 'unavailable';
  current_mentees?: number;
  max_mentees?: number;
  rating_avg: number;
  rating_count: number;
}

export default function MentorsPage() {
  const { user, loading: authLoading } = useAuth();
  const router = useRouter();
  const { t } = useTheme();
  const [mentors, setMentors] = useState<Mentor[]>([]);
  const [search, setSearch] = useState('');
  const [selectedSpecialty, setSelectedSpecialty] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!user) return;
    const params = new URLSearchParams();
    if (selectedSpecialty) params.set('specialty', selectedSpecialty);
    params.set('limit', '50');
    api.get<Mentor[]>(`/mentors?${params}`)
      .then(setMentors)
      .catch(() => {})
      .finally(() => setLoading(false));
  }, [user, selectedSpecialty]);

  const filtered = mentors.filter(m =>
    (m.full_name ?? '').toLowerCase().includes(search.toLowerCase()) ||
    (m.specialty ?? '').toLowerCase().includes(search.toLowerCase())
  );

  const specialtyFilters = [
    { label: t('Tous'), value: null },
    { label: t('Informatique'), value: 'Informatique' },
    { label: t('Médecine'), value: 'Médecine' },
    { label: t('Commerce'), value: 'Commerce' },
    { label: t('Ingénierie'), value: 'Ingénierie' },
    { label: t('Droit'), value: 'Droit' },
    { label: t('Marketing'), value: 'Marketing' },
    { label: t('Finance'), value: 'Finance' },
  ];

  if (authLoading) return <div className="min-h-[80vh] flex items-center justify-center"><div className="animate-spin w-8 h-8 border-2 border-brand-primary border-t-transparent rounded-full" /></div>;
  if (!user) return null;

  const availabilityMeta: Record<string, { label: string; bg: string; color: string }> = {
    available: { label: t('Disponible'), bg: 'bg-brand-success/10', color: 'text-brand-success-dark' },
    limited: { label: t('Bientôt complet'), bg: 'bg-brand-warning/10', color: 'text-brand-warning-dark' },
    unavailable: { label: t('Complet'), bg: 'bg-brand-error/10', color: 'text-brand-error-dark' },
  };

  return (
    <div className="animate-fade-in pb-4">
      {/* Hero */}
      <div className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-brand-category-arts via-brand-category-arts to-brand-category-arts/70 p-5 mb-5">
        <div className="absolute -top-6 -right-6 w-36 h-36 rounded-full bg-white/5" />
        <div className="relative z-10 flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-white/15 flex items-center justify-center border border-white/20">
            <Users size={18} className="text-white" />
          </div>
          <div>
            <h1 className="text-white font-bold text-lg">{t('Mentors')}</h1>
            <p className="text-white/60 text-xs">{mentors.length} {t('mentors disponibles')}</p>
          </div>
        </div>
      </div>

      {/* Search */}
      <div className="relative mb-3">
        <Search size={15} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-brand-text-tertiary" />
        <input type="text" placeholder={t('Rechercher un mentor...')}
          value={search} onChange={e => setSearch(e.target.value)}
          className="w-full h-10 pl-9 pr-4 rounded-xl bg-white border border-brand-border text-sm outline-none focus:border-brand-primary transition-colors" />
      </div>

      {/* Specialty filter chips */}
      <div className="flex gap-2 overflow-x-auto pb-3 scrollbar-none">
        {specialtyFilters.map(f => (
          <button key={f.label} onClick={() => setSelectedSpecialty(f.value)}
            className={`flex-shrink-0 h-8 px-4 rounded-full text-xs font-semibold transition-all ${
              selectedSpecialty === f.value
                ? 'bg-brand-primary text-white'
                : 'bg-white text-brand-text-secondary border border-brand-border hover:border-brand-primary/30'
            }`}>
            {f.label}
          </button>
        ))}
      </div>

      {/* CTA */}
      <div className="bg-gradient-to-r from-brand-category-arts/10 to-transparent rounded-xl border border-brand-category-arts/15 p-4 mb-5">
        <p className="text-sm text-brand-text-secondary mb-3">{t('Tu veux devenir mentor et accompagner des élèves ?')}</p>
        <button onClick={() => router.push('/mentors/apply')}
          className="inline-flex items-center gap-2 h-9 px-4 rounded-xl bg-gradient-primary text-white text-xs font-semibold hover:opacity-90 transition-all">
          <GraduationCap size={14} />
          {t('Postuler')}
        </button>
      </div>

      {/* List */}
      {loading ? (
        <div className="space-y-3">
          {[1,2,3].map(i => (
            <div key={i} className="bg-white rounded-xl border border-brand-border p-4 animate-pulse space-y-2">
              <div className="flex gap-3">
                <div className="w-12 h-12 rounded-xl bg-brand-surface" />
                <div className="flex-1 space-y-2">
                  <div className="h-4 bg-brand-surface rounded w-3/4" />
                  <div className="h-3 bg-brand-surface rounded w-1/2" />
                </div>
              </div>
            </div>
          ))}
        </div>
      ) : filtered.length === 0 ? (
        <div className="text-center py-12">
          <div className="w-16 h-16 rounded-full bg-brand-surface mx-auto mb-4 flex items-center justify-center">
            <Users size={24} className="text-brand-text-tertiary" />
          </div>
          <p className="font-semibold text-brand-text-secondary">{t('Aucun mentor trouvé')}</p>
          <p className="text-sm text-brand-text-tertiary mt-1">{t('Essaie un autre terme')}</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3 pb-4">
          {filtered.map(mentor => {
            const initials = mentor.full_name.split(' ').map(s => s[0]).join('').toUpperCase().slice(0, 2);
            const slotsLeft = (mentor.max_mentees || 0) - (mentor.current_mentees || 0);
            const availability = mentor.availability ? availabilityMeta[mentor.availability] : null;
            const subtitle = [mentor.profession || mentor.specialty, mentor.company].filter(Boolean).join(' · ');
            return (
              <EntityCard
                key={mentor.id}
                type="mentor"
                id={mentor.id}
                avatarUrl={mentor.avatar_url}
                bannerUrl={mentor.avatar_url}
                initials={initials}
                title={mentor.full_name}
                subtitle={subtitle}
                location={mentor.location}
                rating={{ avg: mentor.rating_avg, count: mentor.rating_count }}
                yearsExperience={mentor.years_experience}
                availability={
                  availability
                    ? { kind: mentor.availability!, label: availability.label }
                    : undefined
                }
                slotsLeft={slotsLeft}
                hourlyRate={mentor.hourly_rate}
                isVerified={mentor.is_verified}
                ctaPrimaryLabel={t('Voir plus')}
                onViewMore={(id) => router.push(`/mentors/${id}`)}
                t={t}
              />
            );
          })}
        </div>
      )}
    </div>
  );
}
