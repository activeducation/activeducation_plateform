'use client';
import { useEffect, useState, useCallback, use } from 'react';
import { useAuth } from '@/lib/auth';
import { useTheme } from '@/lib/theme';
import { api } from '@/lib/api';
import { useRouter } from 'next/navigation';
import {
  ArrowLeft, CheckCircle, XCircle, Loader2, Trophy, RefreshCw,
  Medal, Zap, Info, Sparkles, GripVertical
} from 'lucide-react';

interface Question {
  id: string;
  text: string;
  type: 'single' | 'multiple' | 'text' | 'ordering';
  options?: { id: string; text: string }[];
}

interface ExamData {
  id: string;
  title: string;
  description?: string;
  passing_score: number;
  badge_title?: string;
  badge_icon?: string;
  questions: Question[];
}

interface ExamResult {
  score: number;
  passed: boolean;
  badge_title?: string;
  badge_icon?: string;
  xp_reward: number;
  details: { question_id: string; correct: boolean }[];
}

export default function CourseExamPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const { user, loading: authLoading } = useAuth();
  const { t } = useTheme();
  const router = useRouter();
  const [exam, setExam] = useState<ExamData | null>(null);
  const [answers, setAnswers] = useState<Record<string, any>>({});
  const [submitting, setSubmitting] = useState(false);
  const [result, setResult] = useState<ExamResult | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);

  useEffect(() => {
    if (!user) return;
    api.get<ExamData>(`/elearning/courses/${id}/exam`)
      .then(d => { setExam(d); setLoading(false); })
      .catch(() => { setError(true); setLoading(false); });
  }, [user, id]);

  const handleSelect = (qId: string, optId: string) => {
    setAnswers(prev => ({ ...prev, [qId]: optId }));
  };

  const handleMultiSelect = (qId: string, optId: string) => {
    setAnswers(prev => {
      const current: string[] = prev[qId] || [];
      const next = current.includes(optId)
        ? current.filter(id => id !== optId)
        : [...current, optId];
      return { ...prev, [qId]: next };
    });
  };

  const handleTextChange = (qId: string, val: string) => {
    setAnswers(prev => ({ ...prev, [qId]: val }));
  };

  const moveOrder = (qId: string, from: number, to: number) => {
    setAnswers(prev => {
      const items: string[] = [...(prev[qId] || [])];
      const [moved] = items.splice(from, 1);
      items.splice(to, 0, moved);
      return { ...prev, [qId]: items };
    });
  };

  const submit = async () => {
    if (!exam) return;
    const questionIds = exam.questions.map(q => q.id);
    const allAnswered = questionIds.every(qId => answers[qId] !== undefined && answers[qId] !== '' && (!Array.isArray(answers[qId]) || answers[qId].length > 0));
    if (!allAnswered) {
      alert(t('Répondez à toutes les questions.'));
      return;
    }
    setSubmitting(true);
    try {
      const res = await api.post<ExamResult>(`/elearning/courses/${id}/exam/submit`, {
        answers: questionIds.map(qId => ({
          question_id: qId,
          answer: answers[qId],
        })),
      });
      api.invalidate();
      setResult(res);
    } catch {
      alert(t('Erreur lors de la soumission.'));
    }
    setSubmitting(false);
  };

  const reset = () => {
    setAnswers({});
    setResult(null);
  };

  if (authLoading) return null;
  if (!user) return null;

  if (loading) return <div className="min-h-[80vh] flex items-center justify-center"><div className="animate-spin w-8 h-8 border-2 border-brand-primary border-t-transparent rounded-full" /></div>;

  if (error) {
    return (
      <div className="min-h-[80vh] flex flex-col items-center justify-center px-6">
        <Info size={48} className="text-brand-text-tertiary mb-4" />
        <p className="font-semibold text-brand-text-primary">{t('Erreur de chargement')}</p>
        <p className="text-sm text-brand-text-tertiary mt-1 mb-6">{t('Impossible de charger l\'examen. Vérifie ta connexion.')}</p>
        <button onClick={() => window.location.reload()} className="mt-2 px-8 py-3 rounded-full bg-brand-primary text-white font-semibold">
          {t('Réessayer')}
        </button>
      </div>
    );
  }

  if (!exam) {
    return (
      <div className="min-h-[80vh] flex flex-col items-center justify-center px-6">
        <Info size={48} className="text-brand-text-tertiary mb-4" />
        <p className="font-semibold text-brand-text-primary">{t('Aucun examen pour ce cours.')}</p>
        <button onClick={() => router.back()} className="mt-6 px-8 py-3 rounded-full bg-brand-primary text-white font-semibold">
          {t('Retour')}
        </button>
      </div>
    );
  }

  if (result) {
    return (
      <div className="min-h-screen bg-brand-background flex flex-col items-center justify-center px-6 animate-fade-in">
        {result.passed ? (
          <div className="w-20 h-20 rounded-[28px] bg-gradient-to-br from-brand-xp-gold to-brand-xp-bar flex items-center justify-center mb-6 shadow-lg">
            <Trophy size={44} className="text-white" />
          </div>
        ) : (
          <div className="w-20 h-20 rounded-[28px] bg-brand-surface border-2 border-brand-border flex items-center justify-center mb-6">
            <RefreshCw size={44} className="text-brand-text-tertiary" />
          </div>
        )}
        <h1 className="text-2xl font-extrabold text-brand-text-primary text-center">
          {result.passed ? t('Félicitations !') : t('Pas encore réussi')}
        </h1>
        <p className="text-lg font-bold text-brand-primary mt-3">{t('Votre score :')} {result.score}%</p>

        <div className="w-full max-w-sm space-y-2 mt-6">
          {result.details.filter(d => d.correct !== undefined).map(d => (
            <div key={d.question_id} className={`flex items-center gap-2 px-4 py-2 rounded-xl text-sm ${
              d.correct ? 'bg-brand-success/10 text-brand-success' : 'bg-brand-error/10 text-brand-error'
            }`}>
              {d.correct ? <CheckCircle size={16} /> : <XCircle size={16} />}
              <span>{d.correct ? t('Correct') : t('Incorrect')}</span>
            </div>
          ))}
        </div>

        {result.passed && result.badge_title && (
          <div className="mt-6 bg-brand-xp-gold-surface rounded-2xl p-4 flex items-center gap-3 border border-brand-xp-gold/20">
            <Medal size={28} className="text-brand-xp-gold-dark" />
            <div>
              <p className="font-bold text-brand-text-primary text-sm">{result.badge_title}</p>
              <div className="flex items-center gap-1 mt-0.5">
                <Zap size={12} className="text-brand-xp-gold" />
                <span className="text-xs font-bold text-brand-xp-gold">+{result.xp_reward} {t('XP')}</span>
              </div>
            </div>
          </div>
        )}

        {!result.passed && (
          <p className="text-sm text-brand-text-tertiary text-center mt-4">
            {t('Il faut')} {exam.passing_score}% {t('pour réussir. Révise et réessaye !')}
          </p>
        )}

        <div className="flex gap-3 mt-8">
          {!result.passed && (
            <button onClick={reset}
              className="px-6 py-3 rounded-full border-2 border-brand-border text-brand-text-primary font-semibold text-sm flex items-center gap-2">
              <RefreshCw size={16} /> {t('Réessayer')}
            </button>
          )}
          <button onClick={() => router.back()}
            className={`px-6 py-3 rounded-full font-semibold text-sm flex items-center gap-2 ${
              result.passed
                ? 'bg-brand-primary text-white'
                : 'bg-brand-primary text-white'
            }`}>
            {result.passed ? t('Terminer') : t('Retour au cours')}
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-brand-background animate-fade-in">
      {/* Header */}
      <div className="sticky top-0 z-10 bg-white border-b border-brand-border px-4 py-3 flex items-center gap-3">
        <button onClick={() => router.back()}>
          <ArrowLeft size={20} className="text-brand-text-primary" />
        </button>
        <h1 className="font-bold text-brand-text-primary text-base truncate">{exam.title}</h1>
      </div>

      <div className="px-4 py-4 space-y-4 pb-24">
        {/* Passing info */}
        <div className="flex items-center gap-2 bg-brand-primary-surface rounded-xl px-4 py-3">
          <Medal size={16} className="text-brand-primary" />
          <p className="text-xs text-brand-primary-dark font-medium">
            {t('Obtenez')} {exam.passing_score}% {t('ou plus pour réussir et gagner votre badge.')}
          </p>
        </div>

        {/* Questions */}
        {exam.questions.map((q, qi) => (
          <div key={q.id}>
            <div className="flex items-start gap-2 mb-3">
              <span className="w-7 h-7 rounded-lg bg-brand-primary/10 flex items-center justify-center text-xs font-bold text-brand-primary flex-shrink-0">
                {qi + 1}
              </span>
              <div className="flex-1">
                <p className="text-sm font-semibold text-brand-text-primary">{q.text}</p>
                <span className="text-[10px] text-brand-text-tertiary font-medium mt-0.5 block">
                  {q.type === 'single' ? t('Choix unique') :
                   q.type === 'multiple' ? t('Choix multiples') :
                   q.type === 'text' ? t('Réponse libre') : t('Ordonnancement')}
                </span>
              </div>
            </div>

            <div className="space-y-2">
              {q.type === 'single' && q.options?.map(o => {
                const selected = answers[q.id] === o.id;
                return (
                  <button key={o.id} onClick={() => handleSelect(q.id, o.id)}
                    className={`w-full text-left px-4 py-3 rounded-xl border text-sm transition-all ${
                      selected
                        ? 'bg-brand-primary text-white border-brand-primary'
                        : 'bg-white text-brand-text-secondary border-brand-border hover:border-brand-primary/30'
                    }`}>
                    <div className="flex items-center gap-3">
                      <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center ${
                        selected ? 'border-white' : 'border-brand-border'
                      }`}>
                        {selected && <div className="w-2.5 h-2.5 rounded-full bg-white" />}
                      </div>
                      {o.text}
                    </div>
                  </button>
                );
              })}
              {q.type === 'multiple' && q.options?.map(o => {
                const selected = (answers[q.id] as string[] || []).includes(o.id);
                return (
                  <button key={o.id} onClick={() => handleMultiSelect(q.id, o.id)}
                    className={`w-full text-left px-4 py-3 rounded-xl border text-sm transition-all ${
                      selected
                        ? 'bg-brand-primary text-white border-brand-primary'
                        : 'bg-white text-brand-text-secondary border-brand-border hover:border-brand-primary/30'
                    }`}>
                    <div className="flex items-center gap-3">
                      <div className={`w-5 h-5 rounded border-2 flex items-center justify-center ${
                        selected ? 'border-white bg-white' : 'border-brand-border'
                      }`}>
                        {selected && <CheckCircle size={14} className="text-brand-primary" />}
                      </div>
                      {o.text}
                    </div>
                  </button>
                );
              })}
              {q.type === 'text' && (
                <textarea onChange={e => handleTextChange(q.id, e.target.value)}
                  placeholder={t("Écrivez votre réponse ici...")}
                  className="w-full px-4 py-3 rounded-xl border border-brand-border bg-white text-sm text-brand-text-primary placeholder:text-brand-text-tertiary/50 focus:outline-none focus:border-brand-primary/40 transition-all resize-none min-h-[100px]" />
              )}
              {q.type === 'ordering' && (
                <div className="space-y-2">
                  <p className="text-xs text-brand-text-tertiary font-medium">{t('Faites glisser pour réordonner :')}</p>
                  {(answers[q.id] as string[] || q.options?.map(o => o.id) || []).map((optId, idx) => {
                    const opt = q.options?.find(o => o.id === optId);
                    if (!opt) return null;
                    return (
                      <div key={opt.id}
                        className="flex items-center gap-3 px-4 py-3 rounded-xl bg-white border border-brand-border">
                        <button onClick={() => idx > 0 && moveOrder(q.id, idx, idx - 1)} className="text-brand-text-tertiary hover:text-brand-primary">
                          <span className="text-xs">▲</span>
                        </button>
                        <span className="text-sm text-brand-text-secondary flex-1">{opt.text}</span>
                        <button onClick={() => idx < (answers[q.id]?.length || 1) - 1 && moveOrder(q.id, idx, idx + 1)} className="text-brand-text-tertiary hover:text-brand-primary">
                          <span className="text-xs">▼</span>
                        </button>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          </div>
        ))}
      </div>

      {/* Bottom submit */}
      <div className="fixed bottom-0 left-0 right-0 bg-white/90 backdrop-blur-xl border-t border-brand-border p-4">
        <button onClick={submit} disabled={submitting}
          className={`w-full h-14 rounded-2xl font-bold text-base flex items-center justify-center gap-2 transition-all ${
            submitting
              ? 'bg-brand-border text-brand-text-tertiary cursor-not-allowed'
              : 'bg-brand-primary text-white shadow-lg'
          }`}>
          {submitting ? (
            <><Loader2 size={18} className="animate-spin" /> {t('Soumission...')}</>
          ) : (
            <><CheckCircle size={18} /> {t('Soumettre mes réponses')}</>
          )}
        </button>
      </div>
    </div>
  );
}
