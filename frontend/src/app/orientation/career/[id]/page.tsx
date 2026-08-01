'use client';
import { useEffect, useState, use } from 'react';
import { useAuth } from '@/lib/auth';
import { useTheme } from '@/lib/theme';
import { api } from '@/lib/api';
import { getSectorIcon } from '@/lib/career-icons';
import { useRouter } from 'next/navigation';
import {
  ArrowLeft, Info, Brain, School, TrendingUp, TrendingDown, Minus,
  Timer, CheckCircle, MapPin, Award, Lightbulb, Building, Rocket, Briefcase,
} from 'lucide-react';

interface EducationPath {
  minimum_level: string;
  recommended_formations: string[];
  schools_in_togo: string[];
  duration_years: number;
  certifications?: string;
}

interface Career {
  id: string;
  name: string;
  description: string;
  sector_name: string;
  image_url?: string;
  required_skills: string[];
  related_traits: string[];
  education_path: EducationPath;
  salary_min_fcfa?: number;
  salary_max_fcfa?: number;
  salary_avg_fcfa?: number;
  salary_note?: string;
  job_demand?: string;
  growth_trend?: string;
  outlook_description?: string;
  top_employers: string[];
  entrepreneurship_potential: boolean;
}

const demandColors: Record<string, string> = {
  high: 'bg-emerald-100 text-emerald-700 border-emerald-200',
  medium: 'bg-amber-100 text-amber-700 border-amber-200',
  low: 'bg-rose-100 text-rose-700 border-rose-200',
};

export default function CareerDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const { user, loading: authLoading } = useAuth();
  const { t } = useTheme();
  const router = useRouter();
  const [career, setCareer] = useState<Career | null>(null);
  const [loading, setLoading] = useState(true);

  const demandLabels: Record<string, string> = {
    high: t('Forte demande'), medium: t('Demande modérée'), low: t('Faible demande'),
  };

  useEffect(() => {
    if (!user) return;
    api.get<Career>(`/orientation/careers/${id}`)
      .then(d => { setCareer(d); setLoading(false); })
      .catch(() => setLoading(false));
  }, [user, id]);

  if (authLoading) return null;
  if (!user) return null;
  if (loading) return <div className="min-h-[80vh] flex items-center justify-center"><div className="animate-spin w-8 h-8 border-2 border-brand-primary border-t-transparent rounded-full" /></div>;
  if (!career) return <div className="text-center py-12">{t('Fiche métier introuvable.')}</div>;

  const SectorIcon = getSectorIcon(career.sector_name);

  const formatFcfa = (n?: number) => {
    if (!n) return '—';
    if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1).replace(/\.0$/, '')}M`;
    if (n >= 1_000) return `${Math.round(n / 1_000)}k`;
    return String(n);
  };

  const growthLabel = career.growth_trend === 'growing' ? t('En croissance')
    : career.growth_trend === 'stable' ? t('Stable')
    : career.growth_trend === 'declining' ? t('En déclin') : '—';

  return (
    <div className="animate-fade-in pb-6">
      <button onClick={() => router.back()} className="flex items-center gap-1 text-brand-text-secondary text-sm mb-3">
        <ArrowLeft size={18} /> {t('Retour')}
      </button>

      {/* Hero compact */}
      <div className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-brand-primary via-brand-primary to-brand-primary-light p-4 mb-4 flex items-center gap-3">
        <div className="absolute -top-6 -right-6 w-28 h-28 rounded-full bg-white/10" />
        <div className="absolute -bottom-4 -left-4 w-20 h-20 rounded-full bg-brand-secondary/20" />
        <div className="relative z-10 w-16 h-16 rounded-2xl bg-white/15 border border-white/20 grid place-items-center text-white flex-shrink-0" style={{ filter: 'drop-shadow(0 2px 6px rgba(0,0,0,.2))' }}>
          <SectorIcon size={32} strokeWidth={1.8} />
        </div>
        <div className="relative z-10 flex-1 min-w-0">
          <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-white/20 rounded-full text-[10px] font-bold text-white mb-1">
            <Briefcase size={9} /> {career.sector_name}
          </span>
          <h1 className="text-white font-extrabold text-lg leading-tight">{career.name}</h1>
        </div>
      </div>

      {/* 3 stats */}
      <div className="grid grid-cols-3 gap-2 mb-4">
        <div className="bg-white rounded-xl border border-brand-border p-2.5 text-center">
          <p className="text-base font-extrabold text-brand-text-primary leading-tight">
            {formatFcfa(career.salary_avg_fcfa)}
          </p>
          <p className="text-[10px] text-brand-text-tertiary mt-0.5">{t('FCFA médian')}</p>
        </div>
        <div className="bg-white rounded-xl border border-brand-border p-2.5 text-center">
          <p className="text-base font-extrabold text-brand-text-primary leading-tight">
            {career.growth_trend === 'growing' ? '+18%' : career.growth_trend === 'declining' ? '−5%' : '0%'}
          </p>
          <p className="text-[10px] text-brand-text-tertiary mt-0.5">{t('croissance /an')}</p>
        </div>
        <div className="bg-white rounded-xl border border-brand-border p-2.5 text-center">
          <p className="text-base font-extrabold text-brand-text-primary leading-tight">
            {career.education_path.minimum_level}
          </p>
          <p className="text-[10px] text-brand-text-tertiary mt-0.5">{t('niveau requis')}</p>
        </div>
      </div>

      {/* Salary card (verte, dégradé) */}
      {(career.salary_min_fcfa || career.salary_avg_fcfa || career.salary_max_fcfa) && (
        <div className="bg-gradient-to-br from-emerald-50 to-white border-2 border-emerald-200 rounded-2xl p-4 mb-4 text-center">
          <p className="text-[10px] font-bold text-emerald-700 uppercase tracking-wide">
            {t('Salaire au Togo')}
          </p>
          <p className="text-2xl font-extrabold text-brand-text-primary mt-1 leading-tight">
            {formatFcfa(career.salary_min_fcfa)} – {formatFcfa(career.salary_max_fcfa)} <span className="text-base font-bold text-brand-text-secondary">FCFA</span>
          </p>
          <p className="text-[11px] text-brand-text-tertiary mt-1.5">
            {t('Junior')} : {formatFcfa(career.salary_min_fcfa)} · {t('Moyen')} : {formatFcfa(career.salary_avg_fcfa)} · {t('Senior')} : {formatFcfa(career.salary_max_fcfa)}
          </p>
          {career.salary_note && (
            <p className="text-[11px] text-brand-text-secondary mt-2 leading-relaxed border-t border-emerald-100 pt-2">
              {career.salary_note}
            </p>
          )}
        </div>
      )}

      <div className="space-y-4">
        {/* Description */}
        <section className="bg-white rounded-2xl border border-brand-border p-4">
          <div className="flex items-center gap-2 mb-2">
            <Info size={14} className="text-brand-primary" />
            <h2 className="font-bold text-brand-text-primary text-sm">{t('Le métier')}</h2>
          </div>
          <p className="text-sm text-brand-text-secondary leading-relaxed">{career.description}</p>
        </section>

        {/* Required Skills */}
        {career.required_skills.length > 0 && (
          <section>
            <div className="flex items-center gap-2 mb-2">
              <Brain size={14} className="text-brand-primary" />
              <h2 className="font-bold text-brand-text-primary text-sm">{t('Compétences clés')}</h2>
            </div>
            <div className="flex flex-wrap gap-1.5">
              {career.required_skills.map(s => (
                <span key={s} className="px-3 py-1.5 rounded-full bg-brand-primary-surface text-brand-primary-dark text-xs font-semibold border border-brand-primary/20">
                  {s}
                </span>
              ))}
            </div>
          </section>
        )}

        {/* Education / Formations */}
        <section>
          <div className="flex items-center gap-2 mb-2">
            <School size={14} className="text-brand-primary" />
            <h2 className="font-bold text-brand-text-primary text-sm">{t('Parcours & formations')}</h2>
          </div>
          <div className="bg-white rounded-2xl border border-brand-border p-4 space-y-3">
            <div className="flex items-center justify-between text-sm">
              <div className="flex items-center gap-2 text-brand-text-secondary">
                <TrendingUp size={14} className="text-brand-text-tertiary" />
                {t('Niveau')}
              </div>
              <span className="font-bold text-brand-text-primary">{career.education_path.minimum_level}</span>
            </div>
            <div className="flex items-center justify-between text-sm">
              <div className="flex items-center gap-2 text-brand-text-secondary">
                <Timer size={14} className="text-brand-text-tertiary" />
                {t('Durée')}
              </div>
              <span className="font-bold text-brand-text-primary">{career.education_path.duration_years} {t('ans')}</span>
            </div>
            {career.education_path.recommended_formations.length > 0 && (
              <div className="pt-2 border-t border-brand-border-light">
                <p className="text-[11px] font-bold text-brand-text-tertiary uppercase tracking-wide mb-2">
                  {t('Formations recommandées')}
                </p>
                <div className="space-y-1.5">
                  {career.education_path.recommended_formations.map(f => (
                    <div key={f} className="flex items-center gap-2 text-sm">
                      <CheckCircle size={12} className="text-emerald-500 flex-shrink-0" />
                      <span className="text-brand-text-secondary">{f}</span>
                    </div>
                  ))}
                </div>
              </div>
            )}
            {career.education_path.schools_in_togo.length > 0 && (
              <div className="pt-2 border-t border-brand-border-light">
                <p className="text-[11px] font-bold text-brand-text-tertiary uppercase tracking-wide mb-2">
                  {t('Écoles au Togo')}
                </p>
                <div className="space-y-1.5">
                  {career.education_path.schools_in_togo.map(s => (
                    <button
                      key={s}
                      onClick={() => router.push(`/ecoles?search=${encodeURIComponent(s.split(' - ')[0])}`)}
                      className="w-full flex items-center gap-2 text-sm text-left active:scale-[.99] transition-transform"
                    >
                      <MapPin size={12} className="text-brand-primary flex-shrink-0" />
                      <span className="text-brand-text-secondary flex-1">{s}</span>
                      <ArrowLeft size={11} className="text-brand-text-tertiary rotate-180" />
                    </button>
                  ))}
                </div>
              </div>
            )}
            {career.education_path.certifications && (
              <div className="pt-2 border-t border-brand-border-light flex items-start gap-2 text-sm">
                <Award size={14} className="text-amber-500 flex-shrink-0 mt-0.5" />
                <div>
                  <p className="text-[11px] font-bold text-brand-text-tertiary uppercase tracking-wide mb-0.5">
                    {t('Certifications')}
                  </p>
                  <p className="text-brand-text-secondary">{career.education_path.certifications}</p>
                </div>
              </div>
            )}
          </div>
        </section>

        {/* Outlook / Perspectives */}
        <section>
          <div className="flex items-center gap-2 mb-2">
            <TrendingUp size={14} className="text-brand-primary" />
            <h2 className="font-bold text-brand-text-primary text-sm">{t("Perspectives d'emploi")}</h2>
          </div>
          <div className="bg-white rounded-2xl border border-brand-border p-4 space-y-3">
            <div className="flex flex-wrap gap-2">
              {career.job_demand && (
                <span className={`px-3 py-1 rounded-full text-xs font-semibold border ${demandColors[career.job_demand] || 'bg-brand-surface text-brand-text-tertiary'}`}>
                  {demandLabels[career.job_demand] || career.job_demand}
                </span>
              )}
              {career.growth_trend && (
                <span className="inline-flex items-center gap-1 px-3 py-1 rounded-full text-xs font-semibold bg-brand-surface text-brand-text-secondary border border-brand-border-light">
                  {career.growth_trend === 'growing' && <TrendingUp size={11} className="text-emerald-500" />}
                  {career.growth_trend === 'stable' && <Minus size={11} className="text-amber-500" />}
                  {career.growth_trend === 'declining' && <TrendingDown size={11} className="text-rose-500" />}
                  {growthLabel}
                </span>
              )}
            </div>
            {career.outlook_description && (
              <p className="text-sm text-brand-text-secondary leading-relaxed">{career.outlook_description}</p>
            )}
            {career.top_employers.length > 0 && (
              <div className="pt-2 border-t border-brand-border-light">
                <p className="text-[11px] font-bold text-brand-text-tertiary uppercase tracking-wide mb-2">
                  {t('Principaux employeurs au Togo')}
                </p>
                <div className="flex flex-wrap gap-1.5">
                  {career.top_employers.map(e => (
                    <span key={e} className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-brand-surface text-brand-text-secondary text-[11px] border border-brand-border-light">
                      <Building size={10} />
                      {e}
                    </span>
                  ))}
                </div>
              </div>
            )}
            {career.entrepreneurship_potential && (
              <div className="flex items-start gap-2 bg-brand-level-purple/10 rounded-xl p-3">
                <Rocket size={14} className="text-brand-level-purple flex-shrink-0 mt-0.5" />
                <p className="text-xs text-brand-text-secondary">
                  {t('Ce métier offre un fort potentiel pour créer votre propre entreprise.')}
                </p>
              </div>
            )}
          </div>
        </section>

        {career.salary_note && career.salary_avg_fcfa && (
          <div className="flex items-start gap-2 bg-amber-50 border border-amber-200 rounded-xl p-3">
            <Lightbulb size={14} className="text-amber-500 flex-shrink-0 mt-0.5" />
            <p className="text-xs text-brand-text-secondary">{career.salary_note}</p>
          </div>
        )}
      </div>
    </div>
  );
}
