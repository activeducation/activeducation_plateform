'use client';
import { useEffect, useState } from 'react';
import { useAuth } from '@/lib/auth';
import { useTheme } from '@/lib/theme';
import { api } from '@/lib/api';
import { useUnreadAnnouncementsCount } from '@/lib/use-announcements';
import type { GamificationProfile, Course, OrientationTest, School } from '@/lib/types';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import {
  BookOpen, Compass, Trophy, MessageCircleMore, Zap, Flame,
  ChevronRight, GraduationCap, Search, Bell, Bot,
  Briefcase, Megaphone, MapPin, School as SchoolIcon,
  FlaskConical, Code2, Users,
} from 'lucide-react';
import SectionHeader from '@/components/shared/section-header';

export default function HomePage() {
  const { user, loading: authLoading } = useAuth();
  const router = useRouter();
  const { t } = useTheme();
  const [profile, setProfile] = useState<GamificationProfile | null>(null);
  const [courses, setCourses] = useState<Course[]>([]);
  const [tests, setTests] = useState<OrientationTest[]>([]);
  const [schools, setSchools] = useState<School[]>([]);
  const [loading, setLoading] = useState(true);
  const unreadCount = useUnreadAnnouncementsCount();

  useEffect(() => {
    if (authLoading) return;
    if (!user) { router.replace('/onboarding'); return; }
    // On affiche la page tout de suite, le contenu se charge en streaming
    Promise.all([
      api.get<GamificationProfile>('/gamification/profile').catch(() => null),
      api.get<{ courses: any[] }>('/elearning/my-courses').then(r => r.courses.map(mc => ({ ...mc.course, progress_pct: mc.progress_pct }))).catch(() => []),
      api.get<OrientationTest[]>('/orientation/tests').catch(() => []),
      api.get<{ items: School[] }>('/schools').then(r => r.items).catch(() => []),
    ]).then(([p, c, t, s]) => {
      setProfile(p);
      setCourses(c);
      setTests(t);
      setSchools(s);
      setLoading(false);
    });
  }, [authLoading, user]);

  if (authLoading || !user) return (
    <div className="fixed inset-0 bg-brand-dark-bg flex flex-col items-center justify-center">
      <div className="w-20 h-20 rounded-2xl bg-gradient-to-br from-brand-primary to-brand-primary-dark flex items-center justify-center shadow-xl shadow-brand-primary/30 mb-5">
        <img src="/logo.jpeg" alt="" className="w-14 h-14 object-contain rounded-xl" loading="eager" />
      </div>
      <h1 className="text-xl font-bold text-white mb-3">ActivEducation</h1>
      <div className="w-7 h-7 border-2 border-white/30 border-t-white rounded-full animate-spin" />
    </div>
  );

  const stats = profile?.stats;
  const firstName = user.first_name || t('Explorer');
  const initials = (user.first_name?.[0] || user.email[0]).toUpperCase();

  return (
    <div className="space-y-5 pb-4 animate-fade-in">
      {/* ── Header simple (avatar + greeting + actions) ── */}
      <div className="flex items-center justify-between px-1">
        <div className="flex items-center gap-3">
          <Link href="/profil">
            <div className="w-10 h-10 rounded-full bg-gradient-to-br from-brand-primary to-brand-primary-light flex items-center justify-center text-white font-bold text-sm border-2 border-white shadow-card">
              {initials}
            </div>
          </Link>
          <div>
            <p className="text-xs text-brand-text-tertiary">Bonjour</p>
            <h1 className="text-lg font-extrabold text-brand-text-primary leading-tight">{firstName}</h1>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <button onClick={() => router.push('/search')}
            className="w-10 h-10 rounded-full bg-white border border-brand-border flex items-center justify-center text-brand-text-secondary shadow-card active:scale-95 transition-transform"
            aria-label={t('Rechercher')}>
            <Search size={18} />
          </button>
          <button onClick={() => router.push('/notifications')}
            className="relative w-10 h-10 rounded-full bg-white border border-brand-border flex items-center justify-center text-brand-text-secondary shadow-card active:scale-95 transition-transform"
            aria-label={t('Notifications')}>
            <Bell size={18} />
            {unreadCount > 0 && (
              <span className="absolute -top-1 -right-1 min-w-[18px] h-[18px] px-1 rounded-full bg-brand-error text-white text-[10px] font-bold flex items-center justify-center border-2 border-white">
                {unreadCount > 9 ? '9+' : unreadCount}
              </span>
            )}
          </button>
        </div>
      </div>

      {/* ── XP Card (blanche, séparée du hero) ── */}
      {loading ? (
        <div className="bg-white rounded-2xl border border-brand-border p-4 animate-pulse space-y-3 shadow-card">
          <div className="h-3 bg-brand-surface rounded w-1/3" />
          <div className="h-2 bg-brand-surface rounded-full" />
          <div className="flex gap-2">
            {[1,2,3].map(i => <div key={i} className="flex-1 h-12 bg-brand-surface rounded-lg" />)}
          </div>
        </div>
      ) : stats ? (
        <div className="relative overflow-hidden bg-white rounded-2xl border border-brand-border p-4 shadow-card">
          <div className="absolute -top-8 -right-8 w-32 h-32 rounded-full bg-brand-primary/5" />
          <div className="relative">
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-bold text-brand-text-primary">✦ {t('Niveau')} {stats.current_level} — {t('Éclaireur')}</span>
              <span className="text-xs font-extrabold text-brand-text-primary">{stats.total_xp} / {profile!.next_level_xp} XP</span>
            </div>
            <div className="h-2.5 bg-brand-surface rounded-full overflow-hidden">
              <div className="h-full bg-gradient-to-r from-[#34D399] to-[#10B981] rounded-full transition-all duration-700"
                style={{ width: `${Math.min(100, profile!.next_level_xp > 0 ? (stats.total_xp % profile!.next_level_xp) / profile!.next_level_xp * 100 : 0)}%` }} />
            </div>
            <div className="grid grid-cols-3 gap-2 mt-3">
              <div className="flex items-center gap-1.5 px-2 py-1.5 bg-brand-surface rounded-lg">
                <Flame size={12} className="text-brand-streak-fire" />
                <span className="text-[11px] font-bold text-brand-text-secondary">{stats.current_streak} j</span>
              </div>
              <div className="flex items-center gap-1.5 px-2 py-1.5 bg-brand-surface rounded-lg">
                <Trophy size={12} className="text-brand-xp-gold" />
                <span className="text-[11px] font-bold text-brand-text-secondary">Top 14%</span>
              </div>
              <div className="flex items-center gap-1.5 px-2 py-1.5 bg-brand-surface rounded-lg">
                <Zap size={12} className="text-brand-xp-bar" />
                <span className="text-[11px] font-bold text-brand-text-secondary">3/12</span>
              </div>
            </div>
          </div>
        </div>
      ) : null}

      {/* ── Suggestions (cards colorées, scroll horizontal) ── */}
      <div className="flex items-center justify-between px-1">
        <h2 className="text-sm font-bold text-brand-text-primary">Suggestions pour toi</h2>
        <Link href="/orientation" className="text-xs font-semibold text-brand-primary">Tout voir →</Link>
      </div>
      <div className="flex gap-3 overflow-x-auto pb-2 -mx-4 px-4 md:mx-0 md:px-0 md:overflow-visible md:grid md:grid-cols-2 lg:grid-cols-4 scrollbar-none">
        {tests.slice(0, 1).map(test => (
          <Link key={test.id} href={`/orientation/test/${test.id}`}
            className="flex-shrink-0 w-36 h-32 md:w-auto rounded-2xl bg-gradient-to-br from-brand-primary to-brand-primary-light p-3 text-white relative overflow-hidden flex flex-col justify-between">
            <div className="w-8 h-8 rounded-lg bg-white/20 grid place-items-center text-white">
              <FlaskConical size={18} strokeWidth={2} />
            </div>
            <div>
              <p className="text-sm font-bold leading-tight">Test RIASEC</p>
              <p className="text-[10px] opacity-80">5 min</p>
            </div>
          </Link>
        ))}
        <Link href="/cours"
          className="flex-shrink-0 w-36 h-32 md:w-auto rounded-2xl bg-gradient-to-br from-brand-secondary to-brand-secondary-dark p-3 text-white relative overflow-hidden flex flex-col justify-between">
          <div className="w-8 h-8 rounded-lg bg-white/20 grid place-items-center text-white">
            <Code2 size={18} strokeWidth={2} />
          </div>
          <div>
            <p className="text-sm font-bold leading-tight">Python</p>
            <p className="text-[10px] opacity-80">6 leçons</p>
          </div>
        </Link>
        <Link href="/mentors"
          className="flex-shrink-0 w-36 h-32 md:w-auto rounded-2xl bg-gradient-to-br from-brand-level-purple to-[#A855F7] p-3 text-white relative overflow-hidden flex flex-col justify-between">
          <div className="w-8 h-8 rounded-lg bg-white/20 grid place-items-center text-white">
            <Users size={18} strokeWidth={2} />
          </div>
          <div>
            <p className="text-sm font-bold leading-tight">Mentor</p>
            <p className="text-[10px] opacity-80">Aïcha</p>
          </div>
        </Link>
        <Link href="/orientation"
          className="flex-shrink-0 w-36 h-32 md:w-auto rounded-2xl bg-gradient-to-br from-brand-category-science to-[#06B6D4] p-3 text-white relative overflow-hidden flex flex-col justify-between">
          <div className="w-8 h-8 rounded-lg bg-white/20 grid place-items-center text-white">
            <Briefcase size={18} strokeWidth={2} />
          </div>
          <div>
            <p className="text-sm font-bold leading-tight">Métiers</p>
            <p className="text-[10px] opacity-80">14 carrières</p>
          </div>
        </Link>
      </div>

      {/* ── Reprendre (cover + cover emoji + progress) ── */}
      {courses.find(c => c.progress_pct != null && c.progress_pct > 0) && (
        <div>
          <h2 className="text-sm font-bold text-brand-text-primary mb-3 px-1">Reprendre où tu t'es arrêté</h2>
          {(() => {
            const c = courses.find(c => c.progress_pct != null && c.progress_pct > 0)!;
            return (
              <Link href={`/cours/${c.id}`}
                className="flex gap-3 bg-white rounded-2xl border border-brand-border p-3.5 shadow-card hover:shadow-card-hover transition-all">
                <div className="w-14 h-14 rounded-xl bg-gradient-to-br from-brand-category-technology to-[#A855F7] flex items-center justify-center text-white flex-shrink-0">
                  <Code2 size={28} strokeWidth={1.8} />
                </div>
                <div className="flex-1 min-w-0">
                  <h3 className="text-sm font-bold text-brand-text-primary leading-tight">{c.title}</h3>
                  <p className="text-[11px] text-brand-text-tertiary mt-0.5">Cours · En cours</p>
                  <div className="mt-2 h-1 bg-brand-surface rounded-full overflow-hidden">
                    <div className="h-full bg-gradient-to-r from-brand-primary to-brand-primary-light rounded-full transition-all"
                      style={{ width: `${c.progress_pct}%` }} />
                  </div>
                </div>
              </Link>
            );
          })()}
        </div>
      )}

      {/* ── Annonces ── */}
      <AnnouncementsSection />

      {/* ── Opportunités (logos colorés) ── */}
      <OpportunitiesSection />

      {/* ── AÏDA Card ── */}
      <Link href="/aida"
        className="block bg-white rounded-2xl border border-brand-border p-4 shadow-card hover:shadow-card-hover transition-all group">
        <div className="flex items-center gap-3 mb-3">
          <div className="relative">
            <div className="w-11 h-11 rounded-xl bg-gradient-primary flex items-center justify-center">
              <Bot className="text-white" size={22} />
            </div>
            <div className="absolute -right-0.5 -bottom-0.5 w-3.5 h-3.5 rounded-full border-2 border-white bg-brand-success" />
          </div>
          <div className="flex-1">
            <h3 className="font-extrabold text-brand-text-primary text-sm tracking-wide">AÏDA</h3>
            <p className="text-brand-success text-xs font-medium">{t('Ta conseillère IA · En ligne')}</p>
          </div>
          <div className="text-xs font-semibold text-brand-primary bg-brand-primary-surface px-3 py-1.5 rounded-lg">
            {t('Discuter →')}
          </div>
        </div>
        <div className="bg-brand-primary-surface rounded-2xl rounded-bl-sm px-3.5 py-2.5 flex items-center gap-2">
          <MessageCircleMore size={14} className="text-brand-primary-dark" />
          <p className="text-sm text-brand-primary-dark leading-relaxed flex-1">
            {t("Salut ! Je suis là pour t'aider à trouver ta voie. Pose-moi tes questions")}
          </p>
        </div>
        <div className="flex flex-wrap gap-2 mt-2.5">
          {[t('Quelles filières ?'), t('Métiers pour moi'), t('Écoles au Togo')].map(chip => (
            <span key={chip}
              className="text-xs font-medium text-brand-text-secondary bg-brand-surface px-3 py-1.5 rounded-full border border-brand-border-light">
              {chip}
            </span>
          ))}
        </div>
      </Link>

      {/* ── E-Learning Section ── */}
      <div className="flex items-center justify-between px-1 mb-3.5">
        <div className="flex items-center gap-2">
          <h2 className="font-bold text-brand-text-primary text-base">{t('Apprendre')}</h2>
          <span className="text-[10px] font-bold text-brand-level-purple bg-brand-level-purple/10 px-2 py-0.5 rounded">{t('E-Learning')}</span>
        </div>
        <Link href="/cours" className="flex items-center gap-0.5 text-xs font-medium text-brand-text-tertiary hover:text-brand-primary transition-colors">
          {t('Catalogue')} <ChevronRight size={12} />
        </Link>
      </div>
      {courses.length > 0 ? (
        <div className="flex gap-3 overflow-x-auto pb-2 -mx-4 px-4 md:mx-0 md:px-0 md:overflow-visible md:grid md:grid-cols-2 scrollbar-none">
          {courses.map(course => (
            <div key={course.id} className="flex-shrink-0 w-44 md:w-auto">
              <Link href={`/cours/${course.id}`}
                className="block bg-white rounded-2xl border border-brand-border overflow-hidden shadow-card hover:shadow-card-hover transition-all h-full">
              <div className="h-1 bg-gradient-to-r from-brand-primary to-brand-primary/40" />
              <div className="p-3.5 flex flex-col h-full">
                <div className="flex items-center justify-between mb-2.5">
                  <div className="w-8 h-8 rounded-lg bg-brand-primary/10 flex items-center justify-center">
                    <BookOpen size={14} className="text-brand-primary" />
                  </div>
                  <span className="text-[10px] font-bold text-brand-xp-gold-dark bg-brand-xp-gold-surface px-1.5 py-0.5 rounded">+{course.points_reward} {t('XP')}</span>
                </div>
                <h3 className="text-sm font-bold text-brand-text-primary leading-tight line-clamp-2 mb-auto">{course.title}</h3>
                {course.progress_pct != null && (
                  <div className="flex items-center gap-2 mt-2.5">
                    <div className="flex-1 h-1 bg-brand-primary/10 rounded-full overflow-hidden">
                      <div className="h-full bg-brand-primary rounded-full transition-all" style={{ width: `${course.progress_pct}%` }} />
                    </div>
                    <span className="text-xs font-bold text-brand-primary">{course.progress_pct}%</span>
                  </div>
                )}
              </div>
            </Link>
            </div>
          ))}
        </div>
      ) : (
        <Link href="/cours"
          className="flex items-center gap-3 bg-brand-primary-surface rounded-xl p-4 border border-brand-primary/20">
          <div className="w-10 h-10 rounded-xl bg-gradient-primary flex items-center justify-center">
            <BookOpen size={18} className="text-white" />
          </div>
          <div className="flex-1">
            <p className="font-bold text-sm text-brand-primary-dark">{t("Commencer l'apprentissage")}</p>
            <p className="text-xs text-brand-text-tertiary">{t('Explore nos cours disponibles')}</p>
          </div>
          <ChevronRight size={16} className="text-brand-primary" />
        </Link>
      )}

      {/* ── Schools Section ── */}
      <SectionHeader title={t('Établissements')} href="/ecoles" />
      {schools.length > 0 ? (
        <div className="flex gap-3 overflow-x-auto pb-2 -mx-4 px-4 md:mx-0 md:px-0 md:overflow-visible md:grid md:grid-cols-2 lg:grid-cols-3 scrollbar-none">
          {schools.slice(0, 6).map(school => (
            <div key={school.id} className="flex-shrink-0 w-36 md:w-auto">
              <button onClick={() => router.push(`/ecoles/${school.id}`)}
                className="w-full bg-white rounded-2xl border border-brand-border p-3.5 shadow-card hover:shadow-card-hover transition-all text-left">
              <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-brand-category-science/20 to-brand-category-economics/20 flex items-center justify-center mb-2.5">
                <SchoolIcon size={18} className="text-brand-category-science" />
              </div>
              <h4 className="text-sm font-bold text-brand-text-primary leading-tight truncate">{school.name}</h4>
              {school.city && (
                <p className="text-[11px] text-brand-text-tertiary mt-0.5 truncate">{school.city}</p>
              )}
            </button>
            </div>
          ))}
        </div>
      ) : loading ? (
        <div className="flex gap-3 overflow-x-auto pb-2 scrollbar-none">
          {[1,2,3].map(i => (
            <div key={i} className="flex-shrink-0 w-36 bg-white rounded-2xl border border-brand-border p-3.5 animate-pulse">
              <div className="w-10 h-10 rounded-xl bg-brand-surface mb-2.5" />
              <div className="h-3 bg-brand-surface rounded w-3/4 mb-1" />
              <div className="h-2 bg-brand-surface rounded w-1/2" />
            </div>
          ))}
        </div>
      ) : null}

      {/* ── Quick Access ── */}
      <div>
        <h2 className="text-sm font-bold text-brand-text-primary mb-3 px-1">Plus</h2>
        <div className="grid grid-cols-2 gap-3">
          {[
            { href: '/orientation', icon: Compass, label: t("Tests d'orientation"), sub: t('Explore tes aptitudes'), color: 'bg-brand-primary/10 text-brand-primary' },
            { href: '/cours', icon: BookOpen, label: t('E-Learning'), sub: t('Cours et vidéos'), color: 'bg-brand-category-technology/10 text-brand-category-technology' },
            { href: '/ecoles', icon: GraduationCap, label: t('Écoles'), sub: t('Universités & instituts'), color: 'bg-brand-category-economics/10 text-brand-category-economics' },
            { href: '/classement', icon: Trophy, label: t('Classement'), sub: t('Compare-toi'), color: 'bg-brand-xp-gold-surface text-brand-xp-gold-dark' },
          ].map(item => (
            <Link key={item.href} href={item.href}
              className="bg-white rounded-2xl border border-brand-border p-3.5 shadow-card hover:shadow-card-hover active:scale-[.99] transition-all">
              <div className={`w-10 h-10 rounded-xl flex items-center justify-center mb-2.5 ${item.color}`}>
                <item.icon size={18} />
              </div>
              <p className="text-sm font-bold text-brand-text-primary">{item.label}</p>
              <p className="text-[11px] text-brand-text-tertiary mt-0.5">{item.sub}</p>
            </Link>
          ))}
        </div>
      </div>
    </div>
  );
}

function OpportunitiesSection() {
  const { t } = useTheme();
  const [opps, setOpps] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  useEffect(() => {
    api.get<any[]>('/opportunities?limit=5')
      .then(d => { setOpps(d); setLoading(false); })
      .catch(() => setLoading(false));
  }, []);
  if (loading || opps.length === 0) return null;
  const typeLabels: Record<string, string> = { internship: t('Stage'), job: t('Emploi'), volunteer: t('Bénévole'), scholarship: t('Bourse') };
  const typeColors: Record<string, string> = {
    internship: 'bg-brand-primary/10 text-brand-primary',
    job: 'bg-brand-success/10 text-brand-success',
    volunteer: 'bg-brand-xp-gold/10 text-brand-xp-gold-dark',
    scholarship: 'bg-brand-secondary/10 text-brand-accent',
  };
  return (
    <div>
      <div className="flex items-center justify-between px-1 mb-2.5">
        <h3 className="font-bold text-brand-text-primary text-base">{t('Opportunités')}</h3>
        <Link href="/opportunities" className="text-xs font-semibold text-brand-primary flex items-center gap-0.5">
          {t('Voir tout')} <ChevronRight size={14} />
        </Link>
      </div>
      <div className="flex gap-3 overflow-x-auto pb-2 scrollbar-none">
        {opps.map(o => (
          <div key={o.id} className="flex-shrink-0 w-56 bg-white rounded-2xl border border-brand-border p-4">
            <span className={`inline-block text-[10px] font-bold px-2 py-0.5 rounded-md ${typeColors[o.opportunity_type] || 'bg-brand-surface text-brand-text-tertiary'}`}>
              {typeLabels[o.opportunity_type] || o.opportunity_type}
            </span>
            <p className="text-sm font-semibold text-brand-text-primary leading-tight mt-2.5 line-clamp-2">{o.title}</p>
            <p className="text-xs text-brand-text-secondary mt-1.5 line-clamp-1">{o.organization_name}</p>
            {o.location && (
              <div className="flex items-center gap-1 mt-2 text-[11px] text-brand-text-tertiary">
                <MapPin size={11} />
                <span className="truncate">{o.location}</span>
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}

function AnnouncementsSection() {
  const { t } = useTheme();
  const [announcements, setAnnouncements] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  useEffect(() => {
    api.get<any[]>('/announcements?audience=students&limit=3')
      .then(d => { setAnnouncements(d); setLoading(false); })
      .catch(() => setLoading(false));
  }, []);
  if (loading || announcements.length === 0) return null;
  return (
    <div>
      <div className="flex items-center gap-2.5 mb-3 px-1">
        <div className="w-[3px] h-5 rounded-full bg-brand-primary" />
        <h3 className="font-bold text-brand-text-primary text-base">{t('Annonces')}</h3>
      </div>
      <div className="space-y-2">
        {announcements.map(a => {
          const typeColor = a.type === 'warning' ? 'text-brand-warning' :
            a.type === 'promotion' ? 'text-brand-secondary' :
            a.type === 'update' ? 'text-brand-info' : 'text-brand-primary';
          const typeBg = a.type === 'warning' ? 'bg-brand-warning/6' :
            a.type === 'promotion' ? 'bg-brand-secondary/6' :
            a.type === 'update' ? 'bg-brand-info/6' : 'bg-brand-primary/6';
          const typeBorder = a.type === 'warning' ? 'border-brand-warning/15' :
            a.type === 'promotion' ? 'border-brand-secondary/15' :
            a.type === 'update' ? 'border-brand-info/15' : 'border-brand-primary/15';
          return (
            <div key={a.id} className={`rounded-2xl p-4 border ${typeBg} ${typeBorder}`}>
              <div className="flex gap-3.5">
                <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${typeBg}`}>
                  <Megaphone size={18} className={typeColor} />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-semibold text-brand-text-primary line-clamp-2">{a.title}</p>
                  <p className="text-xs text-brand-text-secondary mt-1 line-clamp-3">{a.content}</p>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
