'use client';
import { useEffect, useState } from 'react';
import { useAuth } from '@/lib/auth';
import { api } from '@/lib/api';
import type { LeaderboardEntry, GamificationProfile } from '@/lib/types';
import { Trophy, Medal, Flame, Dumbbell, ArrowLeft, Crown, Sparkles, Zap } from 'lucide-react';
import { useRouter } from 'next/navigation';
import { useTheme } from '@/lib/theme';

export default function LeaderboardPage() {
  const { user, loading: authLoading } = useAuth();
  const { t } = useTheme();
  const router = useRouter();
  const [entries, setEntries] = useState<LeaderboardEntry[]>([]);
  const [profile, setProfile] = useState<GamificationProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);

  useEffect(() => {
    if (!user) return;
    setLoading(true);
    setError(false);
    Promise.all([
      api.get<LeaderboardEntry[]>('/gamification/leaderboard'),
      api.get<GamificationProfile>('/gamification/profile').catch(() => null),
    ]).then(([e, p]) => {
      setEntries(e);
      setProfile(p);
    }).catch(() => setError(true)).finally(() => setLoading(false));
  }, [user]);

  if (authLoading) return <div className="min-h-[80vh] flex items-center justify-center"><div className="animate-spin w-8 h-8 border-2 border-brand-primary border-t-transparent rounded-full" /></div>;
  if (!user) return null;

  if (error) return (
    <div className="animate-fade-in pb-4">
      <div className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-brand-primary via-brand-primary to-[#1060CF] p-5 mb-5">
        <div className="absolute -top-6 -right-6 w-36 h-36 rounded-full bg-white/5" />
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-white/15 flex items-center justify-center border border-white/20">
            <Trophy size={18} className="text-white" />
          </div>
          <h1 className="text-white font-bold text-lg">{t('Classement')}</h1>
        </div>
      </div>
      <div className="text-center py-16">
        <div className="w-16 h-16 rounded-full bg-brand-surface mx-auto mb-4 flex items-center justify-center">
          <Trophy size={24} className="text-brand-text-tertiary" />
        </div>
        <p className="font-semibold text-brand-text-secondary">{t('Oups !')}</p>
        <p className="text-sm text-brand-text-tertiary mt-1">{t('Impossible de charger le classement')}</p>
        <button onClick={() => window.location.reload()}
          className="mt-4 inline-flex items-center gap-2 h-10 px-5 rounded-xl bg-gradient-primary text-white text-xs font-semibold hover:opacity-90 transition-all">
          {t('Réessayer')}
        </button>
      </div>
    </div>
  );

  const podium = entries.slice(0, 3);
  const rest = entries.slice(3);
  const myRank = profile?.stats.leaderboard_rank;

  return (
    <div className="animate-fade-in pb-4">
      {/* Hero */}
      <div className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-brand-primary via-brand-primary to-[#1060CF] p-5 mb-5">
        <div className="absolute -top-6 -right-6 w-36 h-36 rounded-full bg-white/5" />
        <div className="absolute -bottom-4 -left-4 w-24 h-24 rounded-full bg-brand-secondary/15" />
        <div className="relative z-10 flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-white/15 flex items-center justify-center border border-white/20">
            <Trophy size={18} className="text-white" />
          </div>
          <div>
            <h1 className="text-white font-bold text-lg">{t('Classement')}</h1>
            <p className="text-white/60 text-xs">{t('Les meilleurs apprenants')}</p>
          </div>
        </div>
      </div>

      {/* Podium */}
      <div className="bg-white rounded-2xl border border-brand-border p-5 shadow-card mb-4">
        <div className="flex items-end justify-center gap-3">
          {podium.length > 1 && (
            <PodiumTile entry={podium[1]} rank={2} color="text-gray-400" borderColor="border-gray-300" barGradient="from-gray-300/40" height="h-24" />
          )}
          {podium.length > 0 && (
            <PodiumTile entry={podium[0]} rank={1} color="text-brand-xp-gold" borderColor="border-brand-xp-gold" barGradient="from-brand-xp-gold/30" height="h-32" isFirst />
          )}
          {podium.length > 2 && (
            <PodiumTile entry={podium[2]} rank={3} color="text-amber-700" borderColor="border-amber-400" barGradient="from-amber-400/30" height="h-20" />
          )}
        </div>
      </div>

      {/* My Rank */}
      {myRank && (
        <div className="bg-gradient-to-r from-brand-primary/[0.08] to-brand-primary-surface rounded-xl border border-brand-primary/20 p-4 mb-4 flex items-center gap-3">
          <div className="w-11 h-11 rounded-xl bg-brand-primary flex items-center justify-center text-white font-bold text-base">
            #{myRank}
          </div>
          <div className="flex-1">
            <p className="font-bold text-sm text-brand-text-primary">{t('Mon classement')}</p>
            <p className="text-xs text-brand-text-tertiary">
              {t('Niveau')} {profile?.stats.current_level} · {profile?.stats.total_xp} XP
            </p>
          </div>
          <div className={`px-3 py-1.5 rounded-lg text-xs font-bold inline-flex items-center gap-1 ${
            myRank <= 3 ? 'bg-brand-xp-gold-surface text-brand-xp-gold-dark' : 'bg-brand-primary-surface text-brand-primary'
          }`}>
            {myRank <= 3 ? <><Crown size={12} /> {t('Top 3')}</> : myRank <= 10 ? <><Flame size={12} /> {t('Top 10')}</> : <><Zap size={12} /> #{myRank}</>}
          </div>
        </div>
      )}

      {/* Leaderboard List */}
      <div className="flex items-center justify-between mb-3">
        <h2 className="font-bold text-brand-text-primary">{t('Classement général')}</h2>
        <span className="text-xs text-brand-text-tertiary">{entries.length} {t('participants')}</span>
      </div>

      <div className="grid grid-cols-[24px_1fr_40px_60px] gap-2 px-1 mb-2 text-[10px] font-semibold text-brand-text-tertiary uppercase tracking-wider">
        <span />
        <span>{t('Participant')}</span>
        <span className="text-center">{t('Niv.')}</span>
        <span className="text-right">XP</span>
      </div>

      <div className="space-y-1.5">
        {entries.length <= 3 ? (
          <p className="text-center text-sm text-brand-text-tertiary py-8">{t('Pas assez de participants')}</p>
        ) : (
          rest.map((entry, i) => {
            const rank = i + 4;
            return (
              <div key={entry.user_id}
                className="flex items-center gap-2 bg-white rounded-xl border border-brand-border p-3 shadow-card">
                <div className="w-6 text-center">
                  <span className="text-sm font-bold text-brand-text-tertiary">{rank}</span>
                </div>
                <div className={`w-9 h-9 rounded-xl flex items-center justify-center text-white text-xs font-bold flex-shrink-0 ${avatarColor(entry.display_name)} overflow-hidden relative`}>
                  {entry.avatar_url && (
                    <img src={entry.avatar_url} alt="" loading="lazy" className="absolute inset-0 w-full h-full object-cover"
                      onError={(e) => { e.currentTarget.style.display = 'none'; }} />
                  )}
                  {initials(entry.display_name)}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-semibold text-brand-text-primary truncate">{entry.display_name}</p>
                </div>
                <div className="px-2 py-1 rounded bg-brand-level-purple/10 text-xs font-bold text-brand-level-purple">
                  {entry.current_level}
                </div>
                <div className="w-[60px] text-right text-sm font-bold text-brand-xp-gold-dark">
                  {entry.total_xp}
                </div>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
}

function PodiumTile({ entry, rank, color, borderColor, barGradient, height, isFirst }: {
  entry: LeaderboardEntry; rank: number; color: string; borderColor: string; barGradient: string; height: string; isFirst?: boolean;
}) {
  const { t } = useTheme();
  return (
    <div className="flex-1 flex flex-col items-center gap-1.5">
      <div className={`w-${isFirst ? '12' : '10'} h-${isFirst ? '12' : '10'} rounded-full border-2 ${borderColor} flex items-center justify-center ${avatarColor(entry.display_name)} bg-opacity-20 overflow-hidden relative`}>
        {entry.avatar_url && (
          <img src={entry.avatar_url} alt="" loading="lazy" className="absolute inset-0 w-full h-full object-cover rounded-full"
            onError={(e) => { e.currentTarget.style.display = 'none'; }} />
        )}
        <span className={`font-bold ${isFirst ? 'text-base' : 'text-sm'} ${color}`}>{initials(entry.display_name)}</span>
      </div>
      <p className={`text-xs font-bold text-brand-text-primary truncate max-w-[80px] text-center`}>
        {entry.display_name.split(' ')[0]}
      </p>
      <p className="text-[10px] text-brand-text-tertiary">{t('Niv.')} {entry.current_level}</p>
      <div className={`w-${isFirst ? '10' : '8'} ${height} rounded-t-lg bg-gradient-to-t ${barGradient} to-transparent flex items-start justify-center pt-2`}>
        <span className={`font-black ${isFirst ? 'text-base' : 'text-xs'} ${color}`}>#{rank}</span>
      </div>
    </div>
  );
}

const avatarColors = [
  'bg-brand-category-science',
  'bg-brand-category-arts',
  'bg-brand-category-technology',
  'bg-brand-category-economics',
  'bg-brand-primary',
  'bg-brand-secondary',
];

function avatarColor(name: string): string {
  const index = name.split('').reduce((acc, c) => acc + c.charCodeAt(0), 0);
  return avatarColors[index % avatarColors.length];
}

function initials(name: string): string {
  return name.split(' ').map(s => s[0]).join('').toUpperCase().slice(0, 2) || '?';
}
