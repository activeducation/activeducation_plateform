'use client';
import { useEffect, useState } from 'react';
import { useAuth } from '@/lib/auth';
import { api } from '@/lib/api';
import type { CourseDetail, CourseModule, LessonSummary } from '@/lib/types';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import {
  ArrowLeft, Clock, BookOpen, ChevronDown, ChevronRight, Check, Lock,
  Play, Star, Medal, GraduationCap, FileText, MessageCircle, Trophy,
  Sparkles, Zap
} from 'lucide-react';
import { useState as useStateFn } from 'react';
import { useTheme } from '@/lib/theme';

const typeIcons: Record<string, { icon: any; color: string; label: string }> = {
  video: { icon: Play, color: 'text-blue-500 bg-blue-50', label: 'Vidéo' },
  article: { icon: FileText, color: 'text-emerald-500 bg-emerald-50', label: 'Article' },
  quiz: { icon: MessageCircle, color: 'text-amber-500 bg-amber-50', label: 'Quiz' },
  pdf: { icon: FileText, color: 'text-red-500 bg-red-50', label: 'PDF' },
  challenge: { icon: Trophy, color: 'text-purple-500 bg-purple-50', label: 'Challenge' },
};

export default function CourseDetailPage() {
  const { user, loading: authLoading } = useAuth();
  const { t } = useTheme();
  const params = useParams();
  const router = useRouter();
  const [course, setCourse] = useState<CourseDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [enrolling, setEnrolling] = useState(false);
  const [descriptionExpanded, setDescriptionExpanded] = useState(false);

  useEffect(() => {
    if (!user) return;
    api.get<CourseDetail>(`/elearning/courses/${params.id}`)
      .then(setCourse)
      .catch(() => setCourse(null))
      .finally(() => setLoading(false));
  }, [user, params.id]);

  const handleEnroll = async () => {
    setEnrolling(true);
    try {
      await api.post(`/elearning/courses/${params.id}/enroll`);
      const updated = await api.get<CourseDetail>(`/elearning/courses/${params.id}`);
      api.invalidate();
      setCourse(updated);
    } catch {
      console.warn('Echec inscription au cours');
    }
    setEnrolling(false);
  };

  if (authLoading || loading) return (
    <div className="min-h-[80vh] flex items-center justify-center">
      <div className="animate-spin w-8 h-8 border-2 border-brand-primary border-t-transparent rounded-full" />
    </div>
  );
  if (!user || !course) return null;

  const diffColor = course.difficulty === 'debutant' ? 'bg-brand-success/10 text-brand-success' :
    course.difficulty === 'intermediaire' ? 'bg-brand-secondary/10 text-brand-secondary-dark' :
    'bg-brand-error/10 text-brand-error';
  const diffLabel = course.difficulty === 'debutant' ? t('Débutant') :
    course.difficulty === 'intermediaire' ? t('Intermédiaire') : t('Avancé');

  const completedModules = course.modules.filter(m =>
    m.lessons.length > 0 && m.lessons.every(l => l.status === 'completed')
  ).length;
  const totalLessons = course.modules.reduce((a, m) => a + m.lessons.length, 0);
  const completedLessons = course.modules.reduce((a, m) =>
    a + m.lessons.filter(l => l.status === 'completed').length, 0);

  return (
    <div className="animate-fade-in pb-20">
      {/* Hero */}
      <div className="relative -mx-4 -mt-4 mb-5">
        <div className={`h-48 relative overflow-hidden ${course.thumbnail_url ? '' : 'bg-gradient-to-br from-brand-dark-bg via-brand-dark-bg to-brand-primary/60'}`}
          style={course.thumbnail_url ? { backgroundImage: `url(${course.thumbnail_url})`, backgroundSize: 'cover', backgroundPosition: 'center' } : {}}>
          {course.thumbnail_url && <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent" />}
          {!course.thumbnail_url && <div className="absolute -top-10 -right-10 w-40 h-40 rounded-full bg-white/5" />}
          {!course.thumbnail_url && <div className="absolute -bottom-5 -left-5 w-24 h-24 rounded-full bg-white/5" />}
          <button onClick={() => router.back()}
            className="absolute top-4 left-4 w-9 h-9 rounded-xl bg-black/30 flex items-center justify-center backdrop-blur-sm z-10">
            <ArrowLeft size={18} className="text-white" />
          </button>
          <div className="absolute bottom-4 left-4 right-4 flex items-center gap-2">
            <span className="text-[11px] font-bold text-white bg-black/30 px-2.5 py-1 rounded-md backdrop-blur-sm flex items-center gap-1.5">
              <BookOpen size={12} />
              {course.category}
            </span>
            {course.is_enrolled && (
              <span className="text-[11px] font-bold text-white bg-brand-success/60 px-2.5 py-1 rounded-md backdrop-blur-sm flex items-center gap-1">
                <Check size={11} />
                {t('Inscrit')}
              </span>
            )}
          </div>
        </div>
      </div>

      {/* Stats Strip */}
      <div className="flex items-center gap-0 bg-white rounded-xl border border-brand-border p-1 mb-4 shadow-card">
        {[
          { icon: Star, label: diffLabel, color: diffColor.split(' ')[1] },
          { icon: Clock, label: `${course.duration_minutes} min`, color: 'text-brand-text-tertiary' },
          { icon: Medal, label: `+${course.points_reward} XP`, color: 'text-brand-xp-gold-dark', bg: 'bg-brand-xp-gold-surface' },
          { icon: BookOpen, label: `${course.modules.length} modules`, color: 'text-brand-primary' },
        ].map((item, i) => (
          <div key={i} className={`flex-1 flex flex-col items-center py-2 gap-0.5 ${item.bg || ''} rounded-lg`}>
            <item.icon size={14} className={item.color} />
            <span className={`text-[11px] font-bold ${item.color}`}>{item.label}</span>
          </div>
        ))}
      </div>

      {/* Title */}
      <h1 className="text-xl font-bold text-brand-text-primary leading-tight mb-4">{course.title}</h1>

      {/* Description */}
      <div className="mb-5">
        <div className="flex items-center gap-2 mb-2.5">
          <div className="w-1 h-4 rounded-full bg-brand-primary" />
          <h3 className="font-bold text-sm text-brand-text-primary">{t('À propos')}</h3>
        </div>
        <div className={`overflow-hidden transition-all duration-500 ease-in-out ${descriptionExpanded ? 'max-h-[1000px]' : 'max-h-[4.5rem] line-clamp-3'}`}>
          <p className="text-sm text-brand-text-secondary leading-relaxed">{course.description}</p>
        </div>
        <button
          onClick={() => setDescriptionExpanded(!descriptionExpanded)}
          className="text-sm font-semibold text-brand-primary mt-1.5 hover:underline focus:outline-none"
        >
          {descriptionExpanded ? t('Voir moins') : t('Voir plus')}
        </button>
      </div>

      {/* Progress Banner (if enrolled) */}
      {course.is_enrolled && course.progress_pct != null && (
        <div className="bg-gradient-to-r from-brand-primary/[0.08] to-brand-primary/[0.04] rounded-xl border border-brand-primary/15 p-4 mb-5">
          <div className="flex items-center gap-3 mb-3">
            <div className="w-8 h-8 rounded-lg bg-brand-primary/10 flex items-center justify-center">
              <Zap size={15} className="text-brand-primary" />
            </div>
            <div className="flex-1">
              <p className="text-xs font-bold text-brand-primary">{t('Votre progression')}</p>
              <p className="text-[11px] text-brand-primary/70">
                {course.progress_pct === 100 ? t('Cours terminé') : t('Continuez votre apprentissage')}
              </p>
            </div>
            <span className="text-xl font-black text-brand-primary tracking-tight">{course.progress_pct}%</span>
          </div>
          <div className="h-2 bg-brand-primary/10 rounded-full overflow-hidden">
            <div className="h-full bg-brand-primary rounded-full transition-all duration-700"
              style={{ width: `${course.progress_pct}%` }} />
          </div>
        </div>
      )}

      {/* Programme */}
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-2">
          <BookOpen size={16} className="text-brand-primary" />
          <h2 className="font-bold text-brand-text-primary text-base">{t('Programme')}</h2>
        </div>
        {course.is_enrolled && (
          <span className="text-[11px] font-bold text-brand-primary bg-brand-primary-surface px-2 py-0.5 rounded">
            {completedModules}/{course.modules.length} {t('modules')}
          </span>
        )}
      </div>

      {/* Modules */}
      <div className="space-y-2.5">
        {course.modules.map((module, mi) => (
          <ModuleCard key={module.id} module={module} mi={mi} courseId={course.id} isEnrolled={!!course.is_enrolled} />
        ))}
      </div>

      {/* Bottom Action */}
      <div className="fixed bottom-16 left-0 right-0 bg-white/90 backdrop-blur-xl border-t border-brand-border px-4 py-3 lg:bottom-0 lg:left-16">
        <div className="max-w-lg mx-auto lg:max-w-4xl">
          {enrolling ? (
            <div className="h-12 rounded-xl bg-gradient-primary flex items-center justify-center">
              <div className="animate-spin w-5 h-5 border-2 border-white border-t-transparent rounded-full" />
            </div>
          ) : course.is_enrolled ? (
            <div className="flex items-center gap-3">
              {course.progress_pct != null && course.progress_pct < 100 && (
                <div className="flex-shrink-0">
                  <p className="text-[11px] font-bold text-brand-text-secondary">{course.progress_pct}% {t('complété')}</p>
                  <div className="w-16 h-1 bg-brand-primary/10 rounded-full mt-1">
                    <div className="h-full bg-brand-primary rounded-full" style={{ width: `${course.progress_pct}%` }} />
                  </div>
                </div>
              )}
              {course.progress_pct === 100 ? (
                <>
                  <button className="flex-1 h-12 rounded-xl bg-gradient-primary text-white font-semibold text-sm flex items-center justify-center gap-2 shadow-glow">
                    <GraduationCap size={16} />
                    {t('Certificat')}
                  </button>
                  <Link href={`/cours/${course.id}/exam`}
                    className="h-12 px-4 rounded-xl border border-brand-border flex items-center justify-center">
                    <Medal size={18} className="text-brand-text-tertiary" />
                  </Link>
                </>
              ) : (() => {
                const nextLessonId = firstIncompleteLesson(course.modules);
                return nextLessonId ? (
                  <Link href={`/lecon/${nextLessonId}`}
                    className="flex-1 h-12 rounded-xl bg-gradient-primary text-white font-semibold text-sm flex items-center justify-center gap-2 shadow-glow">
                    <Play size={16} />
                    {t('Continuer')}
                  </Link>
                ) : (
                  <button disabled
                    className="flex-1 h-12 rounded-xl bg-brand-surface text-brand-text-tertiary font-semibold text-sm flex items-center justify-center gap-2 cursor-not-allowed">
                    <Play size={16} />
                    {t('Continuer')}
                  </button>
                );
              })()}
            </div>
          ) : (
            <button onClick={handleEnroll}
              className="w-full h-12 rounded-xl bg-gradient-primary text-white font-semibold text-sm flex items-center justify-center gap-2 shadow-glow hover:opacity-90 transition-all">
              <BookOpen size={16} />
              {t("S'inscrire gratuitement")}
            </button>
          )}
          {!course.is_enrolled && (
            <p className="text-center text-[11px] font-semibold text-brand-xp-gold-dark mt-1.5 flex items-center justify-center gap-1">
              <Medal size={12} />
              {t('Gagnez')} +{course.points_reward} XP {t('en terminant ce cours')}
            </p>
          )}
        </div>
      </div>
    </div>
  );
}

function firstIncompleteLesson(modules: CourseModule[]): string | null {
  for (const m of modules) {
    if (m.is_locked) continue;
    for (const l of m.lessons) {
      if (l.status !== 'completed') return l.id;
    }
  }
  return null;
}

function ModuleCard({ module, mi, courseId, isEnrolled }: {
  module: CourseModule; mi: number; courseId: string; isEnrolled: boolean;
}) {
  const { t } = useTheme();
  const [expanded, setExpanded] = useStateFn(true);
  const isLocked = module.is_locked;
  const complete = module.lessons.length > 0 && module.lessons.every(l => l.status === 'completed');
  const color = 'text-brand-primary';
  const bgColor = 'bg-brand-primary';
  const totalInModule = module.lessons.length;
  const completedInModule = module.lessons.filter(l => l.status === 'completed').length;
  const progressPct = totalInModule > 0 ? Math.round((completedInModule / totalInModule) * 100) : 0;

  return (
    <div className={`bg-white rounded-2xl border overflow-hidden shadow-card transition-all ${
      isLocked ? 'border-brand-border-light opacity-70' : complete ? 'border-brand-success/30' : 'border-brand-border'
    }`}>
      <button onClick={() => setExpanded(!expanded)} className="w-full flex items-center gap-3 p-3.5">
        <div className={`w-9 h-9 rounded-xl flex items-center justify-center border-2 ${
          isLocked ? 'border-brand-border text-brand-text-tertiary' :
          complete ? 'border-brand-success/30 bg-brand-success/10 text-brand-success' :
          `${borderColor(color)} ${bgColor}/10 ${color}`
        }`}>
          {isLocked ? <Lock size={15} /> : complete ? <Check size={17} /> : <span className="text-sm font-bold">{mi + 1}</span>}
        </div>
        <div className="flex-1 text-left">
          <h4 className={`text-sm font-bold ${isLocked ? 'text-brand-text-tertiary' : 'text-brand-text-primary'}`}>{module.title}</h4>
          <p className="text-[11px] text-brand-text-tertiary mt-0.5">
            {isLocked ? `${module.lessons.length} ${t('leçons')}` : `${completedInModule}/${module.lessons.length} ${t('complétées')}`}
          </p>
        </div>
        <ChevronDown size={18} className={`text-brand-text-tertiary transition-transform ${expanded ? 'rotate-180' : ''}`} />
      </button>
      {!isLocked && progressPct > 0 && progressPct < 100 && (
        <div className="h-1 mx-3.5 mb-1 rounded-full bg-brand-surface overflow-hidden">
          <div className="h-full rounded-full bg-brand-primary transition-all" style={{ width: `${progressPct}%` }} />
        </div>
      )}

      {expanded && (
        <div className="animate-slide-down">
          <hr className="border-brand-border mx-3.5" />
          {module.lessons.map((lesson, li) => (
            <LessonRow key={lesson.id} lesson={lesson} li={li} isLast={li === module.lessons.length - 1}
              isLocked={isLocked} isEnrolled={isEnrolled} courseId={courseId} />
          ))}
        </div>
      )}
    </div>
  );
}

function LessonRow({ lesson, li, isLast, isLocked, isEnrolled, courseId }: {
  lesson: LessonSummary; li: number; isLast: boolean; isLocked: boolean; isEnrolled: boolean; courseId: string;
}) {
  const { t } = useTheme();
  const isAccessible = !isLocked || lesson.is_free;
  const isCompleted = lesson.status === 'completed';
  const isInProgress = lesson.status === 'in_progress';
  const typeCfg = typeIcons[lesson.lesson_type] || typeIcons.video;
  const TypeIcon = typeCfg.icon;
  const statusColor = isCompleted ? 'bg-brand-success' : isInProgress ? 'bg-brand-primary' : 'bg-brand-border';

  return (
    <Link href={isAccessible && isEnrolled ? `/lecon/${lesson.id}` : '#'} scroll={false}
      className={`flex items-center gap-3 px-3.5 py-2.5 transition-colors ${isAccessible ? 'hover:bg-brand-surface/50' : ''} ${!isLast ? '' : ''}`}>
      <div className="w-[3px] h-10 rounded-full flex-shrink-0" style={{ backgroundColor: statusColor }} />
      <div className={`w-7 h-7 rounded-full flex items-center justify-center flex-shrink-0 ${
        isCompleted ? 'bg-brand-success/10' : isInProgress ? 'bg-brand-primary/10' : 'bg-brand-surface'
      }`}>
        {isCompleted ? <Check size={13} className="text-brand-success" /> :
         isInProgress ? <Play size={12} className="text-brand-primary" fill="currentColor" /> :
         <div className="w-1.5 h-1.5 rounded-full bg-brand-text-tertiary" />}
      </div>
      <div className="flex-1 min-w-0">
        <p className={`text-sm font-medium truncate ${
          isAccessible ? 'text-brand-text-primary' : 'text-brand-text-tertiary'
        }`}>{lesson.title}</p>
        <div className="flex items-center gap-2 mt-0.5">
          <div className="flex items-center gap-1">
            <TypeIcon size={10} className={typeCfg.color.split(' ')[0]} />
            <span className="text-[10px] font-semibold text-brand-text-tertiary">{t(typeCfg.label)}</span>
          </div>
          <span className="text-[10px] text-brand-text-tertiary">·</span>
          <Clock size={9} className="text-brand-text-tertiary" />
          <span className="text-[10px] text-brand-text-tertiary">{lesson.duration_minutes} min</span>
          {lesson.is_free && isLocked && (
            <span className="text-[9px] font-bold text-brand-success bg-brand-success-light px-1.5 py-0.5 rounded">{t('Gratuit')}</span>
          )}
        </div>
      </div>
      {isAccessible ? <ChevronRight size={15} className="text-brand-text-tertiary flex-shrink-0" /> :
        <Lock size={13} className="text-brand-border flex-shrink-0" />}
    </Link>
  );
}

function borderColor(color: string) {
  return `border-${color.replace('text-', '')}`;
}
