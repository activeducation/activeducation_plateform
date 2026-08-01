'use client';
import { useEffect, useState } from 'react';
import { useAuth } from '@/lib/auth';
import { useTheme } from '@/lib/theme';
import { api } from '@/lib/api';
import type { OrientationTest, Question } from '@/lib/types';
import { useParams, useRouter } from 'next/navigation';
import {
  ArrowLeft, ArrowRight, X, Brain, Sparkles,
  BookOpen, Rocket, Palette, Diamond, Smile, Target,
  Frown, Meh, Laugh, Angry,
} from 'lucide-react';

const intensityIcons = [Frown, Angry, Meh, Smile, Laugh];

const sectionIcons = [
  Target, Brain, Diamond, Smile, BookOpen, Rocket, ArrowRight, Palette
];

/**
 * The orientation API serializes its Pydantic aliases (question_text,
 * option_value, ...), whereas the web app uses camel-case domain objects.
 * Normalize once when loading so the rendering code stays independent of the
 * API serialization format.
 */
function normalizeTest(payload: OrientationTest): OrientationTest {
  const rawTest = payload as unknown as { questions?: Array<Record<string, unknown>> };

  return {
    ...payload,
    questions: (rawTest.questions ?? []).map((rawQuestion) => {
      const rawOptions: Array<Record<string, unknown>> = Array.isArray(rawQuestion.options)
        ? rawQuestion.options as Array<Record<string, unknown>>
        : [];
      const rawType = String(rawQuestion.type ?? rawQuestion.question_type ?? 'likert');

      return {
        id: String(rawQuestion.id),
        text: String(rawQuestion.text ?? rawQuestion.question_text ?? ''),
        type: rawType
          .replace(/([a-z])([A-Z])/g, '$1_$2')
          .replace(/-/g, '_')
          .toLowerCase(),
        options: rawOptions.map((rawOption) => ({
          id: String(rawOption.id),
          text: String(rawOption.text ?? rawOption.option_text ?? ''),
          value: (rawOption.value ?? rawOption.option_value ?? rawOption.id) as string | number,
          emoji: typeof rawOption.emoji === 'string' ? rawOption.emoji : undefined,
        })),
        section_title: typeof rawQuestion.section_title === 'string'
          ? rawQuestion.section_title
          : undefined,
        slider_left_label: typeof rawQuestion.slider_left_label === 'string'
          ? rawQuestion.slider_left_label
          : undefined,
        slider_right_label: typeof rawQuestion.slider_right_label === 'string'
          ? rawQuestion.slider_right_label
          : undefined,
      };
    }),
  };
}

export default function TestExecutionPage() {
  const { user, loading: authLoading } = useAuth();
  const { t } = useTheme();
  const params = useParams();
  const router = useRouter();
  const [test, setTest] = useState<OrientationTest | null>(null);
  const [loading, setLoading] = useState(true);
  const [current, setCurrent] = useState(0);
  const [answers, setAnswers] = useState<Record<string, any>>({});
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (!user) return;
    api.get<OrientationTest>(`/orientation/tests/${params.id}`)
      .then((payload) => setTest(normalizeTest(payload)))
      .catch(() => router.push('/orientation'))
      .finally(() => setLoading(false));
  }, [user, params.id, router]);

  const q = test?.questions[current];
  const progress = test ? ((current + 1) / test.questions.length) * 100 : 0;
  const isLast = test ? current === test.questions.length - 1 : false;
  const answered = q ? answers[q.id] !== undefined : false;

  const handleAnswer = (value: any) => {
    const updated = { ...answers, [q!.id]: value };
    setAnswers(updated);
    if (!isLast) {
      setTimeout(() => setCurrent(current + 1), 200);
    }
  };

  const handleSubmit = async () => {
    if (!test) return;
    setSubmitting(true);
    try {
      const result = await api.post(`/orientation/sessions/${test.id}/submit`, { responses: answers });
      sessionStorage.setItem('orientation_test_result', JSON.stringify(result));
      router.push('/orientation/resultats');
    } catch {
      // Keep the user on the test when submission fails so they can retry.
    }
    setSubmitting(false);
  };

  if (authLoading || loading) return (
    <div className="min-h-[80vh] flex items-center justify-center">
      <div className="animate-spin w-8 h-8 border-2 border-brand-primary border-t-transparent rounded-full" />
    </div>
  );
  if (!user || !test || !q) return null;

  const sectionIdx = test.questions.findIndex(q2 => q2.id === q.id);
  const SectionIcon = sectionIcons[sectionIdx % sectionIcons.length];

  return (
    <div className="animate-fade-in min-h-[80vh] flex flex-col">
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <button onClick={() => router.back()} className="p-1 -ml-1">
          <X size={20} className="text-brand-text-tertiary" />
        </button>
        <span className="text-sm font-semibold text-brand-text-tertiary">
          {t('Question')} {current + 1}/{test.questions.length}
        </span>
        <div className="w-5" />
      </div>

      {/* Progress */}
      <div className="flex gap-1 mb-6">
        {test.questions.map((_, i) => (
          <div key={i} className={`flex-1 h-1.5 rounded-full transition-colors ${
            i <= current ? 'bg-brand-primary' : 'bg-brand-border'
          }`} />
        ))}
      </div>

      {/* Question */}
      <div className="flex-1 flex flex-col items-center justify-center max-w-md mx-auto w-full">
        <div className="w-14 h-14 rounded-2xl bg-brand-primary-surface flex items-center justify-center mb-5">
          <SectionIcon size={24} className="text-brand-primary" />
        </div>

        <h2 className="text-xl font-bold text-brand-text-primary text-center mb-6 leading-snug">
          {q.text}
        </h2>

        {/* Options by type */}
        {q.type === 'slider' && (
          <div className="w-full">
            <SliderQuestion q={q} value={answers[q.id] as number} onAnswer={handleAnswer} />
          </div>
        )}

        {(q.type === 'likert' || q.type === 'boolean' || q.type === 'multiple_choice') && (
          <div className="w-full space-y-2.5">
            {q.options.map((opt, i) => (
              <button key={opt.id} onClick={() => handleAnswer(opt.value)}
                className={`w-full p-3.5 rounded-xl text-left text-sm font-medium transition-all ${
                  answers[q.id] === opt.value
                    ? 'bg-brand-primary text-white shadow-md scale-[1.02]'
                    : 'bg-brand-surface text-brand-text-secondary hover:bg-brand-primary/5 border border-brand-border'
                }`}>
                {opt.text}
              </button>
            ))}
          </div>
        )}

        {q.type === 'this_or_that' && q.options.length >= 2 && (
          <div className="w-full space-y-3">
            {q.options.slice(0, 2).map((opt, i) => (
              <button key={opt.id} onClick={() => handleAnswer(opt.id)}
                className={`w-full p-5 rounded-2xl text-center font-semibold transition-all ${
                  answers[q.id] === opt.id
                    ? 'bg-gradient-primary text-white shadow-glow scale-[1.02]'
                    : 'bg-brand-surface text-brand-text-secondary border-2 border-brand-border hover:border-brand-primary/30'
                }`}>
                <p className="text-lg mb-1">{opt.emoji}</p>
                <p>{opt.text}</p>
              </button>
            ))}
          </div>
        )}
      </div>

      {/* Navigation */}
      <div className="flex items-center justify-between mt-6">
        {current > 0 ? (
          <button onClick={() => setCurrent(current - 1)}
            className="flex items-center gap-1.5 text-sm font-semibold text-brand-primary">
            <ArrowLeft size={16} />
            {t('Retour')}
          </button>
        ) : <div />}
        {isLast ? (
          <button onClick={handleSubmit} disabled={!answered || submitting}
            className={`flex items-center gap-1.5 px-6 py-2.5 rounded-xl text-sm font-semibold transition-all ${
              answered && !submitting
                ? 'bg-gradient-primary text-white shadow-glow hover:opacity-90'
                : 'bg-brand-surface text-brand-text-tertiary cursor-not-allowed'
            }`}>
            {submitting ? (
              <div className="animate-spin w-4 h-4 border-2 border-white border-t-transparent rounded-full" />
            ) : t('Terminer')}
          </button>
        ) : (
          <button onClick={() => answered && setCurrent(current + 1)} disabled={!answered}
            className={`flex items-center gap-1.5 px-6 py-2.5 rounded-xl text-sm font-semibold transition-all ${
              answered
                ? 'bg-gradient-primary text-white shadow-glow hover:opacity-90'
                : 'bg-brand-surface text-brand-text-tertiary cursor-not-allowed'
            }`}>
            {t('Suivant')}
            <ArrowRight size={16} />
          </button>
        )}
      </div>
    </div>
  );
}

function SliderQuestion({ q, value, onAnswer }: {
  q: Question; value?: number; onAnswer: (v: number) => void;
}) {
  const { t } = useTheme();
  const [val, setVal] = useState(value ?? 50);

  const intensity = Math.min(4, Math.floor(val / 20));
  const IntensityIcon = intensityIcons[intensity];

  return (
    <div className="w-full text-center">
      <div className="w-16 h-16 mx-auto mb-4 rounded-2xl bg-brand-primary-surface text-brand-primary flex items-center justify-center transition-all duration-300">
        <IntensityIcon size={32} strokeWidth={1.8} />
      </div>
      <div className="flex justify-between text-sm text-brand-text-tertiary mb-2">
        <span>{q.slider_left_label || t('Min')}</span>
        <span>{q.slider_right_label || t('Max')}</span>
      </div>
      <input type="range" min={0} max={100} value={val}
        onChange={e => { setVal(Number(e.target.value)); }}
        onMouseUp={() => onAnswer(val)}
        onTouchEnd={() => onAnswer(val)}
        className="w-full h-2 rounded-full appearance-none bg-brand-surface cursor-pointer accent-brand-primary
          [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:w-6 [&::-webkit-slider-thumb]:h-6
          [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:bg-brand-primary
          [&::-webkit-slider-thumb]:shadow-md [&::-webkit-slider-thumb]:cursor-pointer" />
    </div>
  );
}
