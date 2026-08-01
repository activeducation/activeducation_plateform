'use client';
import { useEffect, useState, useRef } from 'react';
import { useAuth, useLogout } from '@/lib/auth';
import { useTheme } from '@/lib/theme';
import { api } from '@/lib/api';
import type { UserProfile } from '@/lib/types';
import { useRouter } from 'next/navigation';
import {
  Settings, LogOut, ChevronRight, Award, Flame, TrendingUp,
  BookOpen, Trophy, Star, Sparkles, Share2, Shield, School,
  Brain, GraduationCap, Medal, X, BadgeCheck,
} from 'lucide-react';

interface GamificationProfile {
  stats: {
    total_xp: number;
    current_level: number;
    current_streak: number;
    longest_streak: number;
    total_achievements: number;
    completed_challenges: number;
    leaderboard_rank: number | null;
  };
  achievements: Array<{
    id: string;
    achievement_type: string;
    achievement_data: Record<string, unknown>;
    earned_at: string;
  }>;
  active_challenges: Array<{
    id: string;
    challenge_id: string;
    title: string;
    description: string | null;
    points: number;
    status: string;
    score: number | null;
    completed_at: string | null;
  }>;
  next_level_xp: number;
  xp_to_next_level: number;
}

export default function ProfilePage() {
  const { user, loading: authLoading } = useAuth();
  const logout = useLogout();
  const { t } = useTheme();
  const router = useRouter();
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [gamification, setGamification] = useState<GamificationProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [showLogoutDialog, setShowLogoutDialog] = useState(false);

  useEffect(() => {
    if (!user) return;
    Promise.all([
      api.get<UserProfile>('/auth/me'),
      api.get<GamificationProfile>('/gamification/profile'),
    ]).then(([p, g]) => {
      setProfile(p);
      setGamification(g);
    }).catch(() => {}).finally(() => setLoading(false));
  }, [user]);

  if (authLoading) return <div className="min-h-[80vh] flex items-center justify-center"><div className="animate-spin w-8 h-8 border-2 border-brand-primary border-t-transparent rounded-full" /></div>;
  if (!user) return null;

  const displayName = profile?.display_name || t('Utilisateur');
  const initialsStr = (profile?.display_name?.[0] || user.email[0]).toUpperCase();
  const gs = gamification?.stats;
  const level = gs?.current_level ?? 1;
  const xp = gs?.total_xp ?? 0;
  const nextXp = gamification?.next_level_xp ?? 1000;
  const xpToNext = gamification?.xp_to_next_level ?? nextXp;
  const xpPct = nextXp > 0 ? ((nextXp - xpToNext) / nextXp) * 100 : 0;
  const streak = gs?.current_streak ?? 0;

  return (
    <div className="animate-fade-in pb-6">
      {/* Avatar + level card */}
      <div className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-brand-primary via-brand-primary to-[#1060CF] p-6 mb-5 text-center">
        <div className="absolute -top-8 -right-8 w-40 h-40 rounded-full bg-white/5" />
        <div className="absolute -bottom-6 -left-6 w-28 h-28 rounded-full bg-brand-secondary/10" />
        <div className="relative z-10">
          <div className="w-20 h-20 rounded-2xl bg-white/15 mx-auto mb-3 flex items-center justify-center border-2 border-white/30 shadow-lg overflow-hidden relative">
            {profile?.avatar_url && (
              <img src={profile.avatar_url} alt="" loading="lazy" className="absolute inset-0 w-full h-full object-cover"
                onError={(e) => { e.currentTarget.style.display = 'none'; }} />
            )}
            <span className="text-2xl font-bold text-white">{initialsStr}</span>
          </div>
          <h1 className="text-xl font-bold text-white">{displayName}</h1>
          <p className="text-white/60 text-xs mt-0.5">{user.email}</p>

          <div className="inline-flex items-center gap-1.5 mt-3 px-4 py-1.5 rounded-full bg-white/10 border border-white/20">
            <Sparkles size={14} className="text-yellow-300" />
            <span className="text-white font-semibold text-sm">{t('Niveau')} {level}</span>
          </div>
        </div>
      </div>

      {/* Gamification card */}
      <div className="bg-white rounded-2xl border border-brand-border overflow-hidden shadow-card mb-4">
        <div className="p-4 pb-3">
          <div className="flex items-center justify-between mb-2.5">
            <span className="text-xs text-brand-text-tertiary font-medium">{t('XP TOTAL')}</span>
            <span className="text-sm font-bold text-brand-text-primary">{xp.toLocaleString()} {t('XP')}</span>
          </div>
          <div className="h-2.5 rounded-full bg-brand-surface overflow-hidden">
            <div className="h-full rounded-full bg-gradient-to-r from-brand-primary to-brand-secondary transition-all duration-700"
              style={{ width: `${Math.min(xpPct, 100)}%` }} />
          </div>
          <p className="text-[11px] text-brand-text-tertiary mt-1.5 text-right">
            {xpToNext}{t(" XP jusqu'au niveau ")}{level + 1}
          </p>
        </div>

        <div className="grid grid-cols-3 border-t border-brand-border">
          {[
            { icon: Award, value: gs?.total_achievements ?? 0, label: t('Badges'), color: 'text-purple-500' },
            { icon: Flame, value: streak, label: t('Jours'), color: 'text-orange-500' },
            { icon: TrendingUp, value: gs?.completed_challenges ?? 0, label: t('Défis'), color: 'text-brand-success' },
          ].map(({ icon: Icon, value, label, color }) => (
            <div key={label} className="flex flex-col items-center py-2.5 border-r border-brand-border last:border-0">
              <Icon size={15} className={color} />
              <p className="text-sm font-bold text-brand-text-primary mt-0.5">{value}</p>
              <p className="text-[10px] text-brand-text-tertiary font-medium">{label}</p>
            </div>
          ))}
        </div>
      </div>

      {/* Recent achievements */}
      {gamification?.achievements && gamification.achievements.length > 0 && (
        <div className="bg-white rounded-2xl border border-brand-border p-4 shadow-card mb-4">
          <h3 className="font-bold text-sm text-brand-text-primary mb-3">{t('Derniers badges')}</h3>
          <div className="flex gap-3">
            {gamification.achievements.slice(0, 4).map(a => (
              <div key={a.id} className="flex flex-col items-center gap-1 flex-1">
                <div className="w-10 h-10 rounded-xl bg-brand-xp-gold-surface flex items-center justify-center">
                  <BadgeCheck size={18} className="text-brand-xp-gold-dark" />
                </div>
                <span className="text-[10px] text-brand-text-tertiary text-center leading-tight line-clamp-2">
                  {a.achievement_type.replace(/_/g, ' ')}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Quick access menu */}
      <div className="bg-white rounded-2xl border border-brand-border shadow-card overflow-hidden mb-4">
        <MenuItem icon={Brain} label={t("Tests d'orientation")} href="/orientation" />
        <MenuItem icon={GraduationCap} label={t('E-Learning')} href="/cours" />
        <MenuItem icon={School} label={t('Établissements')} href="/ecoles" />
      </div>

      <div className="bg-white rounded-2xl border border-brand-border shadow-card overflow-hidden mb-4">
        <MenuItem icon={Settings} label={t('Paramètres')} href="/parametres" />
        <MenuItem icon={Shield} label={t('Confidentialité')} href="/confidentialite" />
        <MenuItem icon={Share2} label={t("Partager l'app")} onClick={() => {
          if (navigator.share) {
            navigator.share({ title: 'ActivEducation', text: t('Découvre ta voie avec ActivEducation !'), url: window.location.origin });
          } else {
            navigator.clipboard.writeText(window.location.origin).then(() => alert(t('Lien copié !')));
          }
        }} />
      </div>

      {/* Logout */}
      <button onClick={() => setShowLogoutDialog(true)}
        className="w-full flex items-center justify-center gap-2 h-11 rounded-xl border border-red-200 bg-red-50 text-red-600 font-semibold text-sm hover:bg-red-100 transition-colors">
        <LogOut size={16} />
        {t('Déconnexion')}
      </button>

      {/* Logout confirmation dialog */}
      {showLogoutDialog && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40">
          <div className="bg-white rounded-2xl p-5 w-full max-w-xs shadow-xl animate-scale-in">
            <div className="text-center mb-4">
              <div className="w-12 h-12 rounded-full bg-red-50 mx-auto mb-3 flex items-center justify-center">
                <LogOut size={20} className="text-red-500" />
              </div>
              <h3 className="font-bold text-brand-text-primary text-sm">{t('Se déconnecter ?')}</h3>
              <p className="text-xs text-brand-text-tertiary mt-1">{t('Tu devras te reconnecter ensuite')}</p>
            </div>
            <div className="flex gap-2.5">
              <button onClick={() => setShowLogoutDialog(false)}
                className="flex-1 h-10 rounded-xl border border-brand-border bg-white text-sm font-semibold text-brand-text-primary">
                {t('Annuler')}
              </button>
              <button onClick={() => { setShowLogoutDialog(false); logout(); }}
                className="flex-1 h-10 rounded-xl bg-red-500 text-white text-sm font-semibold hover:bg-red-600 transition-colors">
                {t('Déconnexion')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function MenuItem({ icon: Icon, label, href, onClick }: {
  icon: any; label: string; href?: string; onClick?: () => void;
}) {
  const router = useRouter();
  return (
    <button onClick={() => { href ? router.push(href) : onClick?.(); }}
      className="w-full flex items-center gap-3 px-4 py-3.5 text-left hover:bg-brand-surface transition-colors border-b border-brand-border last:border-0">
      <div className="w-8 h-8 rounded-lg bg-brand-surface flex items-center justify-center flex-shrink-0">
        <Icon size={15} className="text-brand-text-secondary" />
      </div>
      <span className="flex-1 text-sm font-semibold text-brand-text-primary">{label}</span>
      <ChevronRight size={15} className="text-brand-text-tertiary" />
    </button>
  );
}
