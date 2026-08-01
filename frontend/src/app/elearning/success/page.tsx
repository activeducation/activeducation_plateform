'use client';
import { useEffect, useState } from 'react';
import { useAuth } from '@/lib/auth';
import { useTheme } from '@/lib/theme';
import { api } from '@/lib/api';
import type { GamificationProfile, Achievement, Challenge } from '@/lib/types';
import { Trophy, ArrowLeft, Star, Flame, Award, Flashlight, Timer, Zap } from 'lucide-react';
import { useRouter } from 'next/navigation';

export default function SuccessPage() {
  const { user, loading: authLoading } = useAuth();
  const { t } = useTheme();
  const router = useRouter();
  const [profile, setProfile] = useState<GamificationProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!user) return;
    api.get<GamificationProfile>('/gamification/profile')
      .then(p => { setProfile(p); setLoading(false); })
      .catch(() => { setError(t('Impossible de charger.')); setLoading(false); });
  }, [user]);

  if (authLoading) return <div className="min-h-[80vh] flex items-center justify-center"><div className="animate-spin w-8 h-8 border-2 border-brand-primary border-t-transparent rounded-full" /></div>;
  if (!user) return null;

  const stats = profile?.stats;
  const achievements = profile?.achievements || [];
  const challenges = profile?.active_challenges || [];

  return (
    <div className="animate-fade-in">
      <button onClick={() => router.back()} className="flex items-center gap-1 text-brand-text-secondary text-sm mb-4">
        <ArrowLeft size={18} /> {t('Retour')}
      </button>

      {/* Hero */}
      <div className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-brand-secondary via-brand-secondary to-[#9333EA] p-5 mb-4">
        <div className="absolute -top-6 -right-6 w-36 h-36 rounded-full bg-white/5" />
        <div className="relative z-10">
          <div className="flex items-center gap-2 mb-1">
            <div className="w-10 h-10 rounded-xl bg-white/15 flex items-center justify-center border border-white/20">
              <Trophy size={20} className="text-white" />
            </div>
            <div>
              <h1 className="text-white font-bold text-lg">{t('Mes Succès')}</h1>
              <p className="text-white/60 text-xs">{t('Mes récompenses')}</p>
            </div>
          </div>
          {achievements.length > 0 && (
            <span className="mt-2 inline-block bg-white/15 text-white text-[10px] font-bold px-2 py-0.5 rounded">
              {achievements.length} {t('badge(s) obtenu(s)')}
            </span>
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
          {/* Mini Stats */}
          <div className="grid grid-cols-3 gap-3 mb-5">
            {[
              { icon: Zap, value: `${stats?.total_xp || 0}`, label: 'XP Total', color: 'text-brand-xp-bar' },
              { icon: Star, value: `${stats?.current_level || 1}`, label: 'Niveau', color: 'text-brand-xp-gold' },
              { icon: Flame, value: `${stats?.current_streak || 0}j`, label: 'Streak', color: 'text-brand-streak-fire' },
            ].map(s => (
              <div key={s.label} className="bg-white rounded-xl border border-brand-border p-3 text-center">
                <s.icon size={20} className={`mx-auto mb-1 ${s.color}`} />
                <p className="text-lg font-extrabold text-brand-text-primary">{s.value}</p>
                <p className="text-[10px] text-brand-text-tertiary uppercase tracking-wide">{t(s.label)}</p>
              </div>
            ))}
          </div>

          {/* Badges */}
          <div className="flex items-center gap-2 mb-3">
            <div className="w-7 h-7 rounded-lg bg-brand-xp-gold/10 flex items-center justify-center">
              <Award size={14} className="text-brand-xp-gold" />
            </div>
            <h2 className="font-bold text-brand-text-primary text-base">{t('Badges obtenus')}</h2>
            <span className="text-[10px] font-bold text-brand-xp-gold bg-brand-xp-gold-surface px-2 py-0.5 rounded">{achievements.length}</span>
          </div>

          {achievements.length === 0 ? (
            <div className="bg-white rounded-2xl border border-brand-border p-8 text-center mb-6">
              <div className="w-14 h-14 rounded-full bg-brand-surface mx-auto mb-3 flex items-center justify-center">
                <Trophy size={24} className="text-brand-text-tertiary" />
              </div>
              <p className="font-semibold text-brand-text-primary">{t('Aucun badge pour le moment')}</p>
              <p className="text-sm text-brand-text-tertiary mt-1">{t("Continue d'apprendre pour débloquer des badges.")}</p>
            </div>
          ) : (
            <div className="grid grid-cols-3 gap-3 mb-6">
              {achievements.map((a) => (
                <div key={a.id}
                  className="bg-white rounded-2xl border border-brand-border p-4 text-center hover:shadow-card-hover transition-all">
                  <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-brand-xp-gold to-brand-xp-bar mx-auto mb-2 flex items-center justify-center">
                    <Award size={20} className="text-white" />
                  </div>
                  <p className="text-[11px] font-semibold text-brand-text-primary leading-tight">{a.display_name || a.achievement_type}</p>
                </div>
              ))}
            </div>
          )}

          {/* Active Challenges */}
          {challenges.length > 0 && (
            <>
              <div className="flex items-center gap-2 mb-3">
                <div className="w-7 h-7 rounded-lg bg-brand-level-purple/10 flex items-center justify-center">
                  <Flashlight size={14} className="text-brand-level-purple" />
                </div>
                <h2 className="font-bold text-brand-text-primary text-base">{t('Défis actifs')}</h2>
              </div>
              <div className="space-y-3 pb-6">
                {challenges.map((c) => (
                  <div key={c.id}
                    className="bg-white rounded-2xl border border-brand-border p-4 flex items-center gap-3 hover:shadow-card-hover transition-all">
                    <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${
                      c.status === 'active' ? 'bg-brand-level-purple/10' : 'bg-brand-surface'
                    }`}>
                      {c.status === 'active'
                        ? <Flashlight size={18} className="text-brand-level-purple" />
                        : <Timer size={18} className="text-brand-text-tertiary" />
                      }
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-semibold text-brand-text-primary truncate">{c.title}</p>
                      <div className="flex items-center gap-1 mt-0.5">
                        <Zap size={11} className="text-brand-xp-gold" />
                        <span className="text-[10px] font-bold text-brand-xp-gold">+{c.points} {t('XP')}</span>
                      </div>
                    </div>
                    <div className="w-2 h-2 rounded-full bg-brand-success" />
                  </div>
                ))}
              </div>
            </>
          )}
        </>
      )}
    </div>
  );
}
