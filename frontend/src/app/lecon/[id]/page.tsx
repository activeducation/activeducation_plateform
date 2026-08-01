'use client';
import { useEffect, useState } from 'react';
import { useAuth } from '@/lib/auth';
import { useTheme } from '@/lib/theme';
import { api } from '@/lib/api';
import type { LessonDetail } from '@/lib/types';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import {
  ArrowLeft, Clock, CheckCircle, Play, FileText, MessageCircle,
  Trophy, Lock, Sparkles, Zap, ChevronRight, Medal
} from 'lucide-react';

const typeConfig: Record<string, { icon: any; label: string; color: string }> = {
  video: { icon: Play, label: 'Vidéo', color: 'text-blue-500 bg-blue-50' },
  article: { icon: FileText, label: 'Article', color: 'text-emerald-500 bg-emerald-50' },
  quiz: { icon: MessageCircle, label: 'Quiz', color: 'text-amber-500 bg-amber-50' },
  pdf: { icon: FileText, label: 'PDF', color: 'text-red-500 bg-red-50' },
  challenge: { icon: Trophy, label: 'Challenge', color: 'text-purple-500 bg-purple-50' },
};

export default function LessonPage() {
  const { user, loading: authLoading } = useAuth();
  const { t } = useTheme();
  const params = useParams();
  const router = useRouter();
  const [lesson, setLesson] = useState<LessonDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [completing, setCompleting] = useState(false);
  const [completed, setCompleted] = useState(false);
  const [points, setPoints] = useState(0);
  const [quizScore, setQuizScore] = useState(0);
  const [quizDone, setQuizDone] = useState(false);
  const [quizAnswers, setQuizAnswers] = useState<Record<string, string>>({});

  useEffect(() => {
    if (!user) return;
    api.get<LessonDetail>(`/elearning/lessons/${params.id}`)
      .then(setLesson)
      .catch(() => router.push('/cours'))
      .finally(() => setLoading(false));
  }, [user, params.id, router]);

  const handleComplete = async () => {
    setCompleting(true);
    try {
      const res = await api.post<{ points_earned: number; course_progress_pct?: number }>(
        `/elearning/lessons/${params.id}/complete`,
        lesson?.lesson_type === 'quiz' ? { score: quizScore, answers: quizAnswers } : undefined
      );
      setPoints(res.points_earned);
      setCompleted(true);
    } catch {}
    setCompleting(false);
  };

  if (authLoading || loading) return (
    <div className="min-h-[80vh] flex items-center justify-center">
      <div className="animate-spin w-8 h-8 border-2 border-brand-primary border-t-transparent rounded-full" />
    </div>
  );
  if (!user || !lesson) return null;

  const cfg = typeConfig[lesson.lesson_type] || typeConfig.video;
  const Icon = cfg.icon;
  const isQuiz = lesson.lesson_type === 'quiz';
  const canComplete = !isQuiz || quizDone;
  const wasCompleted = lesson.status === 'completed';

  if (completed) {
    return <LessonCompletedView points={lesson.points_reward} onBack={() => router.back()} />;
  }

  return (
    <div className="animate-fade-in pb-24">
      {/* Header */}
      <div className="bg-white border-b border-brand-border mb-4">
        <div className="flex items-center gap-2 px-1 pt-1 pb-0">
          <button onClick={() => router.back()}
            className="w-9 h-9 rounded-xl bg-brand-surface flex items-center justify-center">
            <ArrowLeft size={18} className="text-brand-text-primary" />
          </button>
          <div className={`flex items-center gap-1.5 px-2.5 py-1 rounded-lg ${cfg.color}`}>
            <Icon size={12} />
            <span className="text-xs font-semibold">{t(cfg.label)}</span>
          </div>
        </div>
        <div className="px-4 pb-4 pt-2">
          <div className="flex items-start justify-between gap-2">
            <h1 className="font-bold text-brand-text-primary text-base leading-tight">{lesson.title}</h1>
            {wasCompleted && (
              <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-brand-success/10 text-brand-success text-xs font-semibold whitespace-nowrap">
                <CheckCircle size={12} />
                {t('Complété')}
              </span>
            )}
          </div>
          <div className="flex items-center gap-3 mt-2">
            <Clock size={12} className="text-brand-text-tertiary" />
            <span className="text-xs text-brand-text-tertiary">{lesson.duration_minutes} {t('min')}</span>
            <Medal size={12} className="text-brand-secondary" />
            <span className="text-xs font-semibold text-brand-secondary-dark">{lesson.points_reward} {t('pts')}</span>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="space-y-4">
        {lesson.lesson_type === 'video' && (() => {
          const videoUrl = (lesson.content?.data as any)?.video_url || (lesson.content?.data as any)?.url;
          return videoUrl ? (
            <div className="rounded-xl overflow-hidden bg-black shadow-card">
              <video src={videoUrl} controls className="w-full max-h-80 outline-none" />
            </div>
          ) : (
            <div className="bg-gradient-to-br from-brand-dark-bg to-brand-primary/60 rounded-xl h-48 flex items-center justify-center relative overflow-hidden">
              <div className="absolute inset-0 opacity-[0.04]" style={{
                backgroundImage: 'radial-gradient(circle at 24px 24px, white 1px, transparent 1px)',
                backgroundSize: '24px 24px'
              }} />
              <button className="h-10 px-5 rounded-full bg-white/20 backdrop-blur-sm flex items-center gap-2 border border-white/30 hover:bg-white/30 transition-all">
                <Play size={18} className="text-white" fill="white" />
                <span className="text-white text-sm font-semibold">{t('Lire la vidéo')}</span>
              </button>
            </div>
          );
        })()}

        {lesson.lesson_type === 'article' && lesson.content?.data && (
          <div className="bg-white rounded-xl border border-brand-border p-4 shadow-card">
            <MarkdownRenderer content={(lesson.content.data as any).body || (lesson.content.data as any).content || ''} />
          </div>
        )}

        {lesson.lesson_type === 'pdf' && (
          <div className="bg-gradient-to-br from-brand-error-light to-white rounded-xl border border-brand-error/15 p-6 text-center">
            <div className="w-14 h-14 rounded-full bg-brand-error/10 flex items-center justify-center mx-auto mb-3">
              <FileText size={26} className="text-brand-error" />
            </div>
            <h3 className="font-bold text-brand-text-primary mb-1">{t('Document PDF')}</h3>
            <p className="text-sm text-brand-text-tertiary mb-4">{t('Ouvrez le PDF pour consulter le contenu')}</p>
            <button className="inline-flex items-center gap-2 h-10 px-5 rounded-xl bg-gradient-primary text-white text-sm font-semibold shadow-glow hover:opacity-90 transition-all">
              <FileText size={14} />
              {t('Ouvrir le PDF')}
            </button>
          </div>
        )}

        {lesson.lesson_type === 'challenge' && (() => {
          const challengeData = (lesson.content?.data as Record<string, unknown>) || {};
          const desc = (challengeData.description || challengeData.instructions || '') as string;
          const objectives = desc.split('\n').filter(Boolean);
          return (
            <>
              {objectives.length > 0 && (
                <div className="bg-white rounded-xl border border-brand-border p-4 shadow-card">
                  <h4 className="text-xs font-bold text-brand-text-tertiary uppercase tracking-wider mb-2">{t('Objectifs')}</h4>
                  <ol className="space-y-1.5">
                    {objectives.map((obj, i) => (
                      <li key={i} className="flex items-start gap-2 text-sm text-brand-text-secondary">
                        <span className="w-5 h-5 rounded-full bg-brand-primary/10 text-brand-primary text-xs font-bold flex items-center justify-center flex-shrink-0 mt-0.5">{i + 1}</span>
                        {obj}
                      </li>
                    ))}
                  </ol>
                </div>
              )}
              <div className="bg-gradient-to-br from-brand-category-technology via-brand-category-technology to-brand-primary-indigo rounded-xl p-6 text-center text-white">
                <div className="w-14 h-14 rounded-full bg-white/15 flex items-center justify-center mx-auto mb-3">
                  <Trophy size={26} />
                </div>
                <h3 className="font-bold text-lg mb-1">{t('Challenge')}</h3>
                <p className="text-white/80 text-sm mb-4">{t('Relevez le défi et gagnez des points')}</p>
                <button className="inline-flex items-center gap-2 h-10 px-5 rounded-xl bg-white/20 backdrop-blur-sm text-white text-sm font-semibold border border-white/30 hover:bg-white/30 transition-all">
                  <Trophy size={14} />
                  {t('Soumettre ma solution')}
                </button>
              </div>
            </>
          );
        })()}

        {lesson.lesson_type === 'quiz' && !quizDone && (
          <QuizWidget
            questions={(lesson.content?.data as any)?.questions || []}
            onComplete={(score: number, answers: Record<string, string>) => {
              setQuizScore(score);
              setQuizAnswers(answers);
              setQuizDone(true);
            }}
          />
        )}

        {quizDone && (
          <div className="text-center py-8">
            <div className={`w-16 h-16 rounded-full mx-auto mb-3 flex items-center justify-center ${quizScore >= 60 ? 'bg-brand-success/10' : 'bg-brand-error/10'}`}>
              {quizScore >= 60 ? <Trophy size={28} className="text-brand-success" /> : <Sparkles size={28} className="text-brand-error" />}
            </div>
            <h3 className="font-bold text-brand-text-primary">{t('Quiz terminé')}</h3>
            <p className={`text-lg font-bold mt-1 ${quizScore >= 60 ? 'text-brand-success' : 'text-brand-error'}`}>{t('Score :')} {quizScore}%</p>
            <p className="text-sm text-brand-text-tertiary mt-2">{t('Validez la leçon pour enregistrer votre résultat.')}</p>
          </div>
        )}
      </div>

      {/* Bottom Complete */}
      <div className="fixed bottom-16 left-0 right-0 bg-white/90 backdrop-blur-xl border-t border-brand-border px-4 py-3 lg:bottom-0 lg:left-16">
        <div className="max-w-lg mx-auto lg:max-w-4xl">
          {completing ? (
            <div className="h-12 rounded-xl bg-gradient-primary flex items-center justify-center">
              <div className="animate-spin w-5 h-5 border-2 border-white border-t-transparent rounded-full" />
            </div>
          ) : (
            <button onClick={handleComplete} disabled={!canComplete}
              className={`w-full h-12 rounded-xl font-semibold text-sm flex items-center justify-center gap-2 transition-all ${
                canComplete
                  ? 'bg-gradient-primary text-white shadow-glow hover:opacity-90'
                  : 'bg-brand-surface text-brand-text-tertiary cursor-not-allowed'
              }`}>
              <CheckCircle size={16} />
              {isQuiz && !canComplete ? t('Terminez le quiz d\'abord') : t('Valider cette leçon')}
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

function LessonCompletedView({ points, onBack }: { points: number; onBack: () => void }) {
  const { t } = useTheme();
  return (
    <div className="min-h-[80vh] flex items-center justify-center animate-fade-in">
      <div className="text-center max-w-sm">
        <div className="w-24 h-24 rounded-full bg-gradient-to-br from-brand-success to-brand-success/70 flex items-center justify-center mx-auto mb-6 shadow-xl shadow-brand-success/20">
          <Trophy size={44} className="text-white" />
        </div>
        <h2 className="text-xl font-bold text-brand-success mb-5">{t('Leçon validée !')}</h2>
        <div className="bg-white rounded-xl border border-brand-border p-5 shadow-card mb-8">
          <div className="flex items-center justify-center gap-3">
            <Medal size={24} className="text-brand-secondary" />
            <span className="text-lg font-bold text-brand-secondary-dark">+{points} {t('points')}</span>
          </div>
        </div>
        <button onClick={onBack}
          className="inline-flex items-center gap-2 h-12 px-6 rounded-xl bg-gradient-primary text-white font-semibold text-sm shadow-glow hover:opacity-90 transition-all">
          <ArrowLeft size={16} />
          {t('Retour au cours')}
        </button>
      </div>
    </div>
  );
}

function renderInline(text: string) {
  const parts = text.split(/(\*\*[^*]+\*\*)/g);
  return parts.map((part, i) => {
    if (part.startsWith('**') && part.endsWith('**')) {
      return <strong key={i}>{part.slice(2, -2)}</strong>;
    }
    return part;
  });
}

function MarkdownRenderer({ content }: { content: string }) {
  const lines = content.split('\n');
  return (
    <div className="prose prose-sm max-w-none">
      {lines.map((line, i) => {
        if (line.startsWith('# ')) return <h1 key={i} className="text-lg font-bold text-brand-text-primary mb-2 mt-4 first:mt-0">{renderInline(line.slice(2))}</h1>;
        if (line.startsWith('## ')) return <h2 key={i} className="text-base font-bold text-brand-text-primary mb-1.5 mt-3">{renderInline(line.slice(3))}</h2>;
        if (line.startsWith('### ')) return <h3 key={i} className="text-sm font-bold text-brand-text-primary mb-1 mt-2">{renderInline(line.slice(4))}</h3>;
        if (line.startsWith('- ') || line.startsWith('* ')) return (
          <div key={i} className="flex items-start gap-2 mb-1.5">
            <div className="w-1.5 h-1.5 rounded-full bg-brand-primary mt-2 flex-shrink-0" />
            <p className="text-sm text-brand-text-secondary">{renderInline(line.slice(2))}</p>
          </div>
        );
        if (line.trim() === '') return <div key={i} className="h-2" />;
        return <p key={i} className="text-sm text-brand-text-secondary leading-relaxed mb-1">{renderInline(line)}</p>;
      })}
    </div>
  );
}

function QuizWidget({ questions, onComplete }: {
  questions: any[];
  onComplete: (score: number, answers: Record<string, string>) => void;
}) {
  const { t } = useTheme();
  const [current, setCurrent] = useState(0);
  const [answers, setAnswers] = useState<Record<string, string>>({});
  const q = questions[current];

  const select = (val: string) => {
    const key = String(q.id);
    const updated = { ...answers, [key]: val };
    setAnswers(updated);
    if (current < questions.length - 1) {
      setCurrent(current + 1);
    } else {
      // Calculate score
      let correct = 0;
      for (const q of questions) {
        const correctVal = q.correct_option !== undefined ? q.options[q.correct_option]?.value || q.correct_option.toString() : null;
        const key = String(q.id);
        if (correctVal && updated[key] === correctVal) correct++;
      }
      onComplete(Math.round((correct / questions.length) * 100), updated);
    }
  };

  if (!q) return null;

  return (
    <div className="bg-white rounded-xl border border-brand-border p-4 shadow-card">
      <div className="flex items-center justify-between mb-3">
        <span className="text-xs font-semibold text-brand-primary">{t('Question')} {current + 1}/{questions.length}</span>
        <div className="flex gap-1">
            {questions.map((_, i) => (
            <div key={i} className={`w-2 h-2 rounded-full ${answers[String(questions[i].id)] ? 'bg-brand-primary' : 'bg-brand-border'}`} />
          ))}
        </div>
      </div>
      <div className="h-1.5 bg-brand-surface rounded-full mb-4 overflow-hidden">
        <div className="h-full bg-brand-primary rounded-full transition-all duration-300" style={{ width: `${((current + 1) / questions.length) * 100}%` }} />
      </div>
      <h3 className="font-semibold text-brand-text-primary mb-3">{q.question || q.text}</h3>
      <div className="space-y-2">
        {(q.options || []).map((opt: any, i: number) => {
          const val = opt.value !== undefined ? opt.value.toString() : opt.id?.toString() || i.toString();
          const selected = answers[String(q.id)] === val;
          return (
            <button key={i} onClick={() => select(val)}
              className={`w-full p-3 rounded-xl text-left text-sm transition-all ${
                selected
                  ? 'bg-brand-primary text-white shadow-md'
                  : 'bg-brand-surface text-brand-text-secondary hover:bg-brand-primary/5 border border-brand-border'
              }`}>
              {opt.text || opt.label}
            </button>
          );
        })}
      </div>
    </div>
  );
}
