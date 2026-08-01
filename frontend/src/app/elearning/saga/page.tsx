'use client';
import { useEffect, useState } from 'react';
import { useAuth } from '@/lib/auth';
import { useTheme } from '@/lib/theme';
import { api } from '@/lib/api';
import type { Course, GamificationProfile } from '@/lib/types';
import Link from 'next/link';
import {
  Map, Clock, Trophy, BookOpen, ChevronRight, ArrowLeft,
  Flame, Star, CheckCircle, Play
} from 'lucide-react';
import { useRouter } from 'next/navigation';

export default function SagaPage() {
  const { user, loading: authLoading } = useAuth();
  const { t } = useTheme();
  const router = useRouter();
  const [courses, setCourses] = useState<Course[]>([]);
  const [profile, setProfile] = useState<GamificationProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!user) return;
    Promise.all([
      api.get<GamificationProfile>('/gamification/profile').catch(() => null),
      api.get<{ courses: any[] }>('/elearning/my-courses')
        .then(r => r.courses.map((mc: any) => ({ ...mc.course, progress_pct: mc.progress_pct })))
        .catch(() => []),
    ]).then(([p, c]) => {
      setProfile(p);
      setCourses(c as Course[]);
      setLoading(false);
    }).catch(() => {
      setError(t('Impossible de charger ta saga.'));
      setLoading(false);
    });
  }, [user]);

  if (authLoading) return <div className="min-h-[80vh] flex items-center justify-center"><div className="animate-spin w-8 h-8 border-2 border-brand-primary border-t-transparent rounded-full" /></div>;
  if (!user) return null;

  const stats = profile?.stats;
  const sorted = [...courses].sort((a, b) => (a.progress_pct || 0) - (b.progress_pct || 0));

  return (
    <div className="animate-fade-in">
      {/* Back */}
      <button onClick={() => router.back()} className="flex items-center gap-1 text-brand-text-secondary text-sm mb-4">
        <ArrowLeft size={18} /> {t('Retour')}
      </button>

      {/* Hero */}
      <div className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-brand-primary via-brand-primary to-[#1060CF] p-5 mb-4">
        <div className="absolute -top-6 -right-6 w-36 h-36 rounded-full bg-white/5" />
        <div className="relative z-10">
          <div className="flex items-center gap-2 mb-2">
            <div className="w-10 h-10 rounded-xl bg-white/15 flex items-center justify-center border border-white/20">
              <Map size={20} className="text-white" />
            </div>
            <h1 className="text-white font-bold text-lg">{t('Ma Saga')}</h1>
          </div>
          {profile && stats && (
            <div className="bg-white/10 backdrop-blur-sm rounded-xl p-4 border border-white/20 mt-3">
              <div className="flex items-center gap-1 mb-1">
                <Star size={14} className="text-brand-xp-gold" />
                <span className="text-white font-bold text-sm">{t('Niveau')} {stats.current_level}</span>
              </div>
              <div className="flex items-center justify-between text-[10px] text-white/60 mb-2">
                <span>{t('Progression vers')} {t('Niveau')} {stats.current_level + 1}</span>
                <span className="text-brand-xp-gold font-semibold">{stats.total_xp} / {profile.next_level_xp} {t('XP')}</span>
              </div>
              <div className="h-2 bg-white/10 rounded-full overflow-hidden">
                <div className="h-full bg-gradient-to-r from-brand-xp-gold to-brand-xp-bar rounded-full transition-all"
                  style={{ width: `${Math.min((stats.total_xp / profile.next_level_xp) * 100, 100)}%` }} />
              </div>
            </div>
          )}
        </div>
      </div>

      {error ? (
        <div className="text-center py-12">
          <div className="w-16 h-16 rounded-full bg-red-50 mx-auto mb-4 flex items-center justify-center">
            <span className="text-red-400 text-2xl">!</span>
          </div>
          <p className="font-semibold text-brand-text-primary">{t('Oups !')}</p>
          <p className="text-sm text-brand-text-tertiary mt-1">{error}</p>
          <button onClick={() => window.location.reload()}
            className="mt-4 px-6 py-3 rounded-full bg-brand-primary text-white font-semibold text-sm">
            {t('Réessayer')}
          </button>
        </div>
      ) : loading ? (
        <div className="flex items-center justify-center py-12">
          <div className="animate-spin w-8 h-8 border-2 border-brand-primary border-t-transparent rounded-full" />
        </div>
      ) : (
        <>
          {/* Stats Row */}
          <div className="grid grid-cols-4 gap-2 mb-5">
            {[
              { icon: Flame, value: stats ? `${stats.current_streak}j` : '0', label: 'Streak', color: 'text-brand-streak-fire' },
              { icon: Trophy, value: stats ? `${stats.total_achievements}` : '0', label: 'Succès', color: 'text-brand-xp-gold' },
              { icon: BookOpen, value: `${courses.length}`, label: 'Cours', color: 'text-brand-primary' },
              { icon: Star, value: stats?.leaderboard_rank ? `#${stats.leaderboard_rank}` : '—', label: 'Rang', color: 'text-brand-level-purple' },
            ].map(s => (
              <div key={s.label} className="bg-white rounded-xl border border-brand-border p-3 text-center">
                <s.icon size={18} className={`mx-auto mb-1 ${s.color}`} />
                <p className="text-xs font-bold text-brand-text-primary">{s.value}</p>
                <p className="text-[9px] text-brand-text-tertiary uppercase tracking-wide">{t(s.label)}</p>
              </div>
            ))}
          </div>

          {/* Section Title */}
          <div className="flex items-center gap-2 mb-4">
            <div className="w-7 h-7 rounded-lg bg-brand-primary/10 flex items-center justify-center">
              <Map size={14} className="text-brand-primary" />
            </div>
            <h2 className="font-bold text-brand-text-primary text-base">{t('Ma progression')}</h2>
            <span className="text-[10px] font-bold text-brand-primary bg-brand-primary-surface px-2 py-0.5 rounded">{courses.length} {t('cours')}</span>
          </div>

          {sorted.length === 0 ? (
            <div className="text-center py-12">
              <div className="w-16 h-16 rounded-full bg-brand-surface mx-auto mb-4 flex items-center justify-center">
                <Map size={24} className="text-brand-text-tertiary" />
              </div>
              <p className="font-semibold text-brand-text-primary">{t('Aucun cours en cours')}</p>
              <p className="text-sm text-brand-text-tertiary mt-1">{t('Inscris-toi à un cours pour commencer ton parcours')}</p>
              <Link href="/cours"
                className="mt-4 inline-flex px-6 py-3 rounded-full bg-brand-primary text-white font-semibold text-sm">
                {t('Explorer les cours')}
              </Link>
            </div>
          ) : (
            <div className="space-y-0 pb-6">
              {sorted.map((course, i) => (
                <div key={course.id}>
                  {i > 0 && <div className="w-0.5 h-6 bg-brand-border mx-auto" />}
                  <Link href={`/cours/${course.id}`}
                    className="flex items-start gap-3 bg-white rounded-2xl border border-brand-border p-4 hover:shadow-card-hover transition-all">
                    <div className="flex flex-col items-center">
                      <div className={`w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold
                        ${course.progress_pct === 100 ? 'bg-brand-success text-white' :
                          course.progress_pct && course.progress_pct > 0 ? 'bg-brand-primary text-white' :
                          'bg-brand-surface text-brand-text-tertiary border border-brand-border'}`}>
                        {course.progress_pct === 100 ? <CheckCircle size={16} /> :
                         course.progress_pct && course.progress_pct > 0 ? <Play size={14} /> :
                         i + 1}
                      </div>
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <div className="w-6 h-6 rounded-md bg-brand-primary/10 flex items-center justify-center">
                          <BookOpen size={12} className="text-brand-primary" />
                        </div>
                        <p className="text-sm font-semibold text-brand-text-primary truncate">{course.title}</p>
                      </div>
                      <div className="flex items-center gap-2 text-[10px] text-brand-text-tertiary">
                        <Clock size={11} />
                        <span>{course.duration_minutes}{t('min')}</span>
                        <span className={`px-1.5 py-0.5 rounded font-semibold ${
                          course.progress_pct === 100 ? 'bg-brand-success/10 text-brand-success' :
                          course.progress_pct && course.progress_pct > 0 ? 'bg-brand-primary/10 text-brand-primary' :
                          'bg-brand-surface text-brand-text-tertiary'
                        }`}>
                          {course.progress_pct === 100 ? t('Terminé') :
                           course.progress_pct ? `${course.progress_pct}%` : t('À commencer')}
                        </span>
                      </div>
                    </div>
                    <ChevronRight size={16} className="text-brand-text-tertiary flex-shrink-0 mt-2" />
                  </Link>
                </div>
              ))}
            </div>
          )}
        </>
      )}
    </div>
  );
}
