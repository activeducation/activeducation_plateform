'use client';
import { useEffect, useState } from 'react';
import { useAuth } from '@/lib/auth';
import { api } from '@/lib/api';
import type { Course } from '@/lib/types';
import Link from 'next/link';
import { BookOpen, Search, Clock, ChevronRight, Flame, ArrowLeft, MapPin, Trophy, Star, Code2, Sigma, FlaskConical, Compass, HardHat } from 'lucide-react';
import { useRouter } from 'next/navigation';
import { useTheme } from '@/lib/theme';
import type { LucideIcon } from 'lucide-react';

const categories = ['Tous', 'Informatique', 'Mathématiques', 'Sciences', 'Orientation', 'Hackathons'];
const categoryIcons: Record<string, LucideIcon> = {
  'Informatique': Code2, 'Mathématiques': Sigma, 'Sciences': FlaskConical, 'Orientation': Compass, 'Hackathons': HardHat,
};

export default function CoursesPage() {
  const { user, loading: authLoading } = useAuth();
  const { t } = useTheme();
  const router = useRouter();
  const [courses, setCourses] = useState<Course[]>([]);
  const [myCourses, setMyCourses] = useState<Course[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [catIdx, setCatIdx] = useState(0);
  const [searchFocused, setSearchFocused] = useState(false);

  useEffect(() => {
    if (!user) return;
    Promise.all([
      api.get<Course[]>('/elearning/courses').catch(() => []),
      api.get<{ courses: any[] }>('/elearning/my-courses').then(r => r.courses.map(mc => ({ ...mc.course, progress_pct: mc.progress_pct }))).catch(() => []),
    ]).then(([all, mine]) => {
      setCourses(all);
      setMyCourses(mine);
      setLoading(false);
    });
  }, [user]);

  const filtered = courses.filter(c => {
    if (catIdx > 0 && !c.category.toLowerCase().includes(categories[catIdx].toLowerCase())) return false;
    if (search && !c.title.toLowerCase().includes(search.toLowerCase()) && !c.description.toLowerCase().includes(search.toLowerCase())) return false;
    return true;
  });

  if (authLoading) return <div className="min-h-[80vh] flex items-center justify-center"><div className="animate-spin w-8 h-8 border-2 border-brand-primary border-t-transparent rounded-full" /></div>;
  if (!user) return null;

  return (
    <div className="animate-fade-in">
      {/* Hero */}
      <div className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-brand-primary via-brand-primary to-[#1060CF] p-5 mb-4">
        <div className="absolute -top-6 -right-6 w-36 h-36 rounded-full bg-white/5" />
        <div className="absolute -bottom-4 -left-4 w-24 h-24 rounded-full bg-brand-secondary/15" />
        <div className="relative z-10">
          <div className="flex items-center gap-3 mb-3">
            <div className="w-10 h-10 rounded-xl bg-white/15 flex items-center justify-center border border-white/20">
              <BookOpen size={18} className="text-white" />
            </div>
            <div>
              <h1 className="text-white font-bold text-lg">{t('Bibliothèque')}</h1>
              <p className="text-white/60 text-sm">{myCourses.length > 0 ? `${myCourses.length} ${t('en cours')} · ` : ''}{courses.length} {t('cours disponibles')}</p>
            </div>
            {myCourses.length > 0 && (
              <div className="ml-auto bg-brand-xp-gold/15 rounded-lg px-2.5 py-1.5 border border-brand-xp-gold/20 flex items-center gap-1.5">
                <Flame size={12} className="text-brand-xp-gold" />
                <span className="text-xs font-bold text-brand-xp-gold">{myCourses.length}</span>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Search */}
      <div className={`mb-4 rounded-xl border-2 transition-all ${searchFocused ? 'border-brand-primary/40 shadow-glow' : 'border-brand-border'} bg-white`}>
        <div className="flex items-center px-4 h-12 gap-3">
          <Search size={18} className={searchFocused ? 'text-brand-primary' : 'text-brand-text-tertiary'} />
          <input value={search} onChange={e => setSearch(e.target.value)} onFocus={() => setSearchFocused(true)} onBlur={() => setSearchFocused(false)}
            placeholder={t('Rechercher un cours...')} className="flex-1 bg-transparent text-sm text-brand-text-primary placeholder:text-brand-text-tertiary/50 focus:outline-none" />
          {search && (
            <button onClick={() => setSearch('')} className="text-brand-text-tertiary hover:text-brand-text-secondary">
              <span className="text-lg leading-none">&times;</span>
            </button>
          )}
        </div>
      </div>

      {/* Quick Tabs */}
      <div className="grid grid-cols-3 gap-2 mb-4">
        {[
          { href: '/elearning/saga', icon: MapPin, label: t('Ma Saga'), color: 'text-brand-primary bg-brand-primary/10' },
          { href: '/elearning/success', icon: Trophy, label: t('Succès'), color: 'text-brand-xp-gold bg-brand-xp-gold-surface' },
          { href: '/classement', icon: Star, label: t('Classement'), color: 'text-brand-level-purple bg-brand-level-purple/10' },
        ].map(item => (
          <div key={item.label}>
            <Link href={item.href}
              className="flex flex-col items-center gap-1.5 bg-white rounded-xl border border-brand-border py-3 shadow-card hover:shadow-card-hover transition-all">
              <div className={`w-8 h-8 rounded-lg flex items-center justify-center ${item.color}`}>
                <item.icon size={15} />
              </div>
              <span className="text-xs font-semibold text-brand-text-secondary">{item.label}</span>
            </Link>
          </div>
        ))}
      </div>

      {/* Categories */}
      <div className="flex gap-2 overflow-x-auto pb-3 scrollbar-none mb-4">
        {categories.map((cat, i) => {
          const CatIcon = i > 0 ? categoryIcons[cat] : null;
          return (
            <button key={cat} onClick={() => setCatIdx(i)}
              className={`flex-shrink-0 flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-sm font-semibold transition-all ${
                i === catIdx
                  ? 'bg-brand-primary text-white shadow-md'
                  : 'bg-white text-brand-text-secondary border border-brand-border hover:border-brand-primary/30'
              }`}>
              {CatIcon && <CatIcon size={13} strokeWidth={2} />}
              {t(cat)}
            </button>
          );
        })}
      </div>

      {/* My Courses */}
      {myCourses.length > 0 && (
        <section className="mb-6">
          <div className="flex items-center gap-2 mb-3">
            <div className="w-7 h-7 rounded-lg bg-brand-primary/10 flex items-center justify-center">
              <BookOpen size={13} className="text-brand-primary" />
            </div>
            <h2 className="font-bold text-brand-text-primary text-lg">{t('Continuer')}</h2>
            <span className="text-[10px] font-bold text-brand-primary bg-brand-primary-surface px-2 py-0.5 rounded">{myCourses.length}</span>
          </div>
          <div className="flex gap-3 overflow-x-auto pb-1 scrollbar-none">
            {myCourses.map(course => (
              <div key={course.id} className="flex-shrink-0 w-44">
                <Link href={`/cours/${course.id}`}
                  className="block bg-white rounded-2xl border border-brand-border overflow-hidden shadow-card hover:shadow-card-hover transition-all h-full">
                  <div className={`relative h-20 ${course.thumbnail_url ? '' : 'bg-gradient-to-br from-brand-primary to-brand-primary/60'}`}
                    style={course.thumbnail_url ? { backgroundImage: `url(${course.thumbnail_url})`, backgroundSize: 'cover', backgroundPosition: 'center' } : {}}>
                    {!course.thumbnail_url && <div className="h-1 bg-gradient-to-r from-brand-primary to-brand-primary/40" />}
                    {!course.thumbnail_url && (
                      <div className="absolute inset-0 flex items-center justify-center">
                        <BookOpen size={20} className="text-white/70" />
                      </div>
                    )}
                    <span className="absolute top-1.5 right-1.5 text-xs font-bold text-white bg-brand-xp-gold rounded px-1.5 py-0.5">+{course.points_reward} XP</span>
                  </div>
                  <div className="p-3 flex flex-col flex-1">
                    <h3 className="text-base font-bold text-brand-text-primary leading-tight line-clamp-2 mb-auto">{course.title}</h3>
                    <div className="flex items-center gap-2 mt-2">
                      <div className="flex-1 h-1 bg-brand-primary/10 rounded-full overflow-hidden">
                        <div className="h-full bg-brand-primary rounded-full transition-all" style={{ width: `${course.progress_pct || 0}%` }} />
                      </div>
                      <span className="text-xs font-bold text-brand-primary">{course.progress_pct || 0}%</span>
                    </div>
                  </div>
                </Link>
              </div>
            ))}
          </div>
        </section>
      )}

      {/* Course Grid */}
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-2">
          <BookOpen size={16} className="text-brand-secondary" />
          <h2 className="font-bold text-brand-text-primary text-lg">
            {catIdx === 0 ? t('Tous les cours') : t(categories[catIdx])}
          </h2>
        </div>
        <span className="text-sm text-brand-text-tertiary">{filtered.length} {t('cours')}</span>
      </div>

      {loading ? (
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3">
          {[1,2,3,4].map(i => (
            <div key={i} className="bg-white rounded-2xl border border-brand-border overflow-hidden animate-pulse">
              <div className="h-24 bg-brand-surface" />
              <div className="p-3 space-y-2">
                <div className="h-3 bg-brand-surface rounded w-3/4" />
                <div className="h-2 bg-brand-surface rounded w-full" />
                <div className="h-2 bg-brand-surface rounded w-1/2" />
              </div>
            </div>
          ))}
        </div>
      ) : filtered.length === 0 ? (
        <div className="text-center py-12">
          <div className="w-16 h-16 rounded-full bg-brand-surface mx-auto mb-4 flex items-center justify-center">
            <Search size={24} className="text-brand-text-tertiary" />
          </div>
          <p className="font-semibold text-brand-text-secondary">{t('Aucun résultat')}</p>
          <p className="text-sm text-brand-text-tertiary mt-1">{t("Essaie avec d'autres mots-clés")}</p>
        </div>
      ) : (
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3 pb-4">
          {filtered.map(course => (
            <div key={course.id}>
              <Link href={`/cours/${course.id}`}
                className="block bg-white rounded-2xl border border-brand-border overflow-hidden shadow-card hover:shadow-card-hover transition-all group h-full">
              {/* Cover */}
              <div className={`relative h-24 ${course.thumbnail_url ? '' : 'bg-gradient-to-br from-brand-primary to-brand-primary/60'}`}
                style={course.thumbnail_url ? { backgroundImage: `url(${course.thumbnail_url})`, backgroundSize: 'cover', backgroundPosition: 'center' } : {}}>
                {!course.thumbnail_url && (
                <div className="absolute inset-0 flex items-center justify-center">
                  <BookOpen size={28} className="text-white/80" />
                </div>
                )}
                {/* Difficulty badge */}
                <span className={`absolute top-2 right-2 text-xs font-bold px-2 py-0.5 rounded-full ${
                  course.difficulty === 'debutant' ? 'bg-brand-success/80 text-white' :
                  course.difficulty === 'intermediaire' ? 'bg-brand-secondary/80 text-white' :
                  'bg-brand-error/80 text-white'
                }`}>
                  {course.difficulty === 'debutant' ? t('Débutant') : course.difficulty === 'intermediaire' ? t('Intermédiaire') : t('Avancé')}
                </span>
                {/* XP badge */}
                <span className="absolute bottom-2 left-2 bg-brand-xp-gold rounded-md px-2 py-0.5 flex items-center gap-1 shadow-md">
                  <span className="text-xs font-bold text-white">+{course.points_reward} XP</span>
                </span>
              </div>
              {/* Content */}
              <div className="p-3">
                <h3 className="text-base font-bold text-brand-text-primary leading-tight line-clamp-2 mb-1">{course.title}</h3>
                <p className="text-sm text-brand-text-tertiary line-clamp-2 leading-relaxed">{course.description}</p>
                <div className="flex items-center gap-1.5 mt-2.5 text-brand-text-tertiary">
                  <Clock size={11} />
                  <span className="text-xs">{course.duration_minutes} min</span>
                  <span className="ml-auto w-1.5 h-1.5 rounded-full bg-brand-success" />
                  <span className="text-xs text-brand-success font-semibold">{course.difficulty === 'debutant' ? t('Facile') : course.difficulty === 'intermediaire' ? t('Moyen') : t('Difficile')}</span>
                </div>
              </div>
            </Link>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
