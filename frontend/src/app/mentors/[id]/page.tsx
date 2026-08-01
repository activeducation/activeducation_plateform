'use client';
import { useEffect, useState } from 'react';
import { useAuth } from '@/lib/auth';
import { useTheme } from '@/lib/theme';
import { api } from '@/lib/api';
import { useParams, useRouter } from 'next/navigation';
import {
  ArrowLeft, Star, MapPin, Briefcase, Award, CheckCircle2,
  MessageCircle, Link2, Calendar, Users, Building2,
  Sparkles, X, AlertTriangle, GraduationCap, BookOpen,
  Globe, ExternalLink, Code, Languages,
} from 'lucide-react';

interface PortfolioFormation {
  ecole: string;
  diplome: string;
  domaine?: string;
  annee_debut?: number;
  annee_fin?: number;
}

interface PortfolioExperience {
  poste: string;
  entreprise: string;
  debut: string;
  fin?: string;
  en_cours: boolean;
  description?: string;
}

interface PortfolioCertification {
  nom: string;
  organisme: string;
  annee?: number;
  lien?: string;
}

interface PortfolioProjet {
  nom: string;
  description?: string;
  lien?: string;
  technologies?: string[];
}

interface PortfolioLangue {
  langue: string;
  niveau: string;
}

interface PortfolioLien {
  type: string;
  url: string;
}

interface MentorPortfolio {
  formations: PortfolioFormation[];
  experiences: PortfolioExperience[];
  certifications: PortfolioCertification[];
  projets: PortfolioProjet[];
  langues: PortfolioLangue[];
  liens: PortfolioLien[];
}

interface Mentor {
  id: string;
  full_name: string;
  specialty: string;
  expertise_areas: string[];
  bio?: string;
  avatar_url?: string;
  years_experience?: number;
  is_verified: boolean;
  hourly_rate?: number;
  available_slots?: string[];
  location?: string;
  linkedin_url?: string;
  company?: string;
  profession?: string;
  availability?: 'available' | 'limited' | 'unavailable';
  current_mentees: number;
  max_mentees: number;
  rating_avg: number;
  rating_count: number;
  portfolio?: MentorPortfolio;
}

interface Review {
  id: string;
  rating: number;
  comment?: string;
  created_at: string;
  reviewer_name: string;
  reviewer_avatar?: string;
}

const availabilityMeta: Record<string, { label: string; bg: string; color: string; dot: string }> = {
  available: { label: 'Disponible', bg: 'bg-brand-success/10', color: 'text-brand-success-dark', dot: 'bg-brand-success' },
  limited: { label: 'Bientôt complet', bg: 'bg-brand-warning/10', color: 'text-brand-warning-dark', dot: 'bg-brand-warning' },
  unavailable: { label: 'Complet', bg: 'bg-brand-error/10', color: 'text-brand-error-dark', dot: 'bg-brand-error' },
};

function normalizeUrl(url?: string): string | undefined {
  if (!url) return undefined;
  if (!url.startsWith('http://') && !url.startsWith('https://') && !url.startsWith('//')) return `https://${url}`;
  return url;
}

function PortfolioSection({ portfolio }: { portfolio: MentorPortfolio }) {
  const { t } = useTheme();
  if (!portfolio) return null;
  const hasData = portfolio.formations?.length > 0 || portfolio.experiences?.length > 0
    || portfolio.certifications?.length > 0 || portfolio.projets?.length > 0
    || portfolio.langues?.length > 0 || portfolio.liens?.length > 0;
  if (!hasData) return null;

  return (
    <section className="space-y-4">
      <h2 className="font-bold text-brand-text-primary text-sm flex items-center gap-2">
        <BookOpen size={14} className="text-brand-primary" />
        {t('Portfolio')}
      </h2>

      {portfolio.formations?.length > 0 && (
        <div className="bg-white rounded-2xl border border-brand-border p-4">
          <div className="flex items-center gap-2 mb-3">
            <GraduationCap size={14} className="text-brand-primary" />
            <h3 className="font-bold text-brand-text-primary text-xs uppercase tracking-wider">{t('Formation')}</h3>
          </div>
          <div className="space-y-3">
            {portfolio.formations.map((f, i) => (
              <div key={i} className="flex gap-3">
                <div className="w-2 h-2 mt-1.5 rounded-full bg-brand-primary flex-shrink-0" />
                <div>
                  <p className="text-sm font-bold text-brand-text-primary">{f.diplome}</p>
                  <p className="text-xs text-brand-text-secondary">{f.ecole}{f.domaine ? ` — ${f.domaine}` : ''}</p>
                  {(f.annee_debut || f.annee_fin) && (
                    <p className="text-[10px] text-brand-text-tertiary mt-0.5">
                      {f.annee_debut || '?'} — {f.annee_fin || '?'}
                    </p>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {portfolio.experiences?.length > 0 && (
        <div className="bg-white rounded-2xl border border-brand-border p-4">
          <div className="flex items-center gap-2 mb-3">
            <Briefcase size={14} className="text-brand-primary" />
            <h3 className="font-bold text-brand-text-primary text-xs uppercase tracking-wider">{t('Expérience')}</h3>
          </div>
          <div className="space-y-3">
            {portfolio.experiences.map((e, i) => (
              <div key={i} className="flex gap-3">
                <div className="w-2 h-2 mt-1.5 rounded-full bg-brand-category-arts flex-shrink-0" />
                <div>
                  <p className="text-sm font-bold text-brand-text-primary">{e.poste}</p>
                  <p className="text-xs text-brand-text-secondary">{e.entreprise}</p>
                  <p className="text-[10px] text-brand-text-tertiary mt-0.5">
                    {e.debut} — {e.en_cours ? t("Aujourd'hui") : e.fin || '?'}
                  </p>
                  {e.description && (
                    <p className="text-xs text-brand-text-tertiary mt-1 leading-relaxed">{e.description}</p>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {portfolio.certifications?.length > 0 && (
        <div className="bg-white rounded-2xl border border-brand-border p-4">
          <div className="flex items-center gap-2 mb-3">
            <Award size={14} className="text-brand-primary" />
            <h3 className="font-bold text-brand-text-primary text-xs uppercase tracking-wider">{t('Certifications')}</h3>
          </div>
          <div className="space-y-2">
            {portfolio.certifications.map((c, i) => (
              <div key={i} className="flex items-start gap-2">
                <CheckCircle2 size={14} className="text-brand-success mt-0.5 flex-shrink-0" />
                <div>
                  <p className="text-sm font-bold text-brand-text-primary">{c.nom}</p>
                  <p className="text-xs text-brand-text-secondary">{c.organisme}{c.annee ? ` — ${c.annee}` : ''}</p>
                  {c.lien && (
                    <a href={normalizeUrl(c.lien)} target="_blank" rel="noopener noreferrer"
                      className="text-xs text-brand-primary font-semibold inline-flex items-center gap-1 mt-0.5 hover:underline">
                      <ExternalLink size={10} /> Voir
                    </a>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {portfolio.projets?.length > 0 && (
        <div className="bg-white rounded-2xl border border-brand-border p-4">
          <div className="flex items-center gap-2 mb-3">
            <Code size={14} className="text-brand-primary" />
            <h3 className="font-bold text-brand-text-primary text-xs uppercase tracking-wider">{t('Projets')}</h3>
          </div>
          <div className="space-y-3">
            {portfolio.projets.map((p, i) => (
              <div key={i} className="flex gap-3">
                <div className="w-2 h-2 mt-1.5 rounded-full bg-brand-category-technology flex-shrink-0" />
                <div>
                  <p className="text-sm font-bold text-brand-text-primary">{p.nom}</p>
                  {p.description && <p className="text-xs text-brand-text-tertiary mt-0.5">{p.description}</p>}
                  <div className="flex flex-wrap gap-1 mt-1.5">
                    {p.technologies?.map(t => (
                      <span key={t} className="text-[10px] font-semibold text-brand-secondary-dark bg-brand-secondary-surface px-2 py-0.5 rounded-full">
                        {t}
                      </span>
                    ))}
                  </div>
                  {p.lien && (
                    <a href={normalizeUrl(p.lien)} target="_blank" rel="noopener noreferrer"
                      className="text-xs text-brand-primary font-semibold inline-flex items-center gap-1 mt-1 hover:underline">
                      <ExternalLink size={10} /> Voir le projet
                    </a>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {portfolio.langues?.length > 0 && (
        <div className="bg-white rounded-2xl border border-brand-border p-4">
          <div className="flex items-center gap-2 mb-3">
            <Languages size={14} className="text-brand-primary" />
            <h3 className="font-bold text-brand-text-primary text-xs uppercase tracking-wider">{t('Langues')}</h3>
          </div>
          <div className="flex flex-wrap gap-2">
            {portfolio.langues.map((l, i) => (
              <span key={i} className="px-3 py-1.5 rounded-full bg-brand-surface text-brand-text-secondary text-xs font-semibold border border-brand-border">
                {l.langue} — <span className="text-brand-primary">{l.niveau}</span>
              </span>
            ))}
          </div>
        </div>
      )}

      {portfolio.liens?.length > 0 && (
        <div className="bg-white rounded-2xl border border-brand-border p-4">
          <div className="flex items-center gap-2 mb-3">
            <Globe size={14} className="text-brand-primary" />
            <h3 className="font-bold text-brand-text-primary text-xs uppercase tracking-wider">{t('Liens')}</h3>
          </div>
          <div className="space-y-2">
            {portfolio.liens.map((l, i) => (
              <a key={i} href={normalizeUrl(l.url)} target="_blank" rel="noopener noreferrer"
                className="flex items-center gap-2 text-sm text-brand-primary font-semibold hover:underline">
                <Link2 size={12} />
                {l.type === 'github' ? 'GitHub' : l.type === 'website' ? t('Site web') : l.type}
              </a>
            ))}
          </div>
        </div>
      )}
    </section>
  );
}

function StarRating({ value, size = 14 }: { value: number; size?: number }) {
  return (
    <div className="inline-flex items-center gap-0.5">
      {[1, 2, 3, 4, 5].map(i => (
        <Star
          key={i}
          size={size}
          className={i <= Math.round(value) ? 'text-brand-xp-gold fill-brand-xp-gold' : 'text-brand-text-disabled'}
        />
      ))}
    </div>
  );
}

export default function MentorDetailPage() {
  const { id } = useParams<{ id: string }>();
  const { user, loading: authLoading } = useAuth();
  const { t } = useTheme();
  const router = useRouter();
  const [mentor, setMentor] = useState<Mentor | null>(null);
  const [reviews, setReviews] = useState<Review[]>([]);
  const [loading, setLoading] = useState(true);
  const [contactOpen, setContactOpen] = useState(false);
  const [message, setMessage] = useState('');
  const [sending, setSending] = useState(false);
  const [sent, setSent] = useState(false);
  const [sendError, setSendError] = useState(false);

  useEffect(() => {
    if (!user) return;
    setLoading(true);
    Promise.all([
      api.get<Mentor>(`/mentors/${id}`),
      api.get<Review[]>(`/mentors/${id}/reviews?limit=10`).catch(() => []),
    ]).then(([m, r]) => {
      setMentor(m);
      setReviews(r);
    }).catch(() => {
      setMentor(null);
    }).finally(() => setLoading(false));
  }, [user, id]);

  if (authLoading) return null;
  if (!user) return null;
  if (loading) {
    return (
      <div className="animate-fade-in">
        <div className="flex items-center gap-2 mb-5">
          <button onClick={() => router.back()} className="w-9 h-9 rounded-full bg-white border border-brand-border flex items-center justify-center shadow-card">
            <ArrowLeft size={18} />
          </button>
          <div className="h-5 w-32 bg-brand-surface rounded animate-pulse" />
        </div>
        <div className="bg-white rounded-2xl border border-brand-border p-5 animate-pulse space-y-3">
          <div className="flex items-center gap-3">
            <div className="w-20 h-20 rounded-2xl bg-brand-surface" />
            <div className="flex-1 space-y-2">
              <div className="h-5 bg-brand-surface rounded w-2/3" />
              <div className="h-3 bg-brand-surface rounded w-1/2" />
            </div>
          </div>
        </div>
      </div>
    );
  }
  if (!mentor) {
    return (
      <div className="text-center py-12">
        <p className="font-semibold text-brand-text-secondary">{t('Mentor introuvable')}</p>
        <button onClick={() => router.back()} className="mt-3 text-sm text-brand-primary font-semibold">{t('Retour')}</button>
      </div>
    );
  }

  const initials = mentor.full_name.split(' ').map(s => s[0]).join('').toUpperCase().slice(0, 2);
  const availability = mentor.availability ? availabilityMeta[mentor.availability] : null;
  const slotsLeft = (mentor.max_mentees ?? 0) - (mentor.current_mentees ?? 0);
  const canContact = mentor.availability !== 'unavailable';

  const sendMessage = async () => {
    if (!message.trim() || sending) return;
    setSending(true);
    setSendError(false);
    try {
      await api.post(`/mentors/${mentor.id}/contact`, { message: message.trim() });
      setSent(true);
      setMessage('');
      setTimeout(() => { setContactOpen(false); setSent(false); }, 1500);
    } catch {
      setSendError(true);
    }
    setSending(false);
  };

  return (
    <div className="animate-fade-in pb-4">
      {/* Back */}
      <button onClick={() => router.back()} className="flex items-center gap-1 text-brand-text-secondary text-sm mb-3">
        <ArrowLeft size={18} /> {t('Retour')}
      </button>

      {/* Hero */}
      <div className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-brand-category-arts via-[#A855F7] to-brand-category-technology p-5 mb-4">
        <div className="absolute -top-8 -right-8 w-36 h-36 rounded-full bg-white/5" />
        <div className="absolute -bottom-4 -left-4 w-24 h-24 rounded-full bg-white/10" />
        <div className="relative z-10 flex items-center gap-4">
          <div className="w-20 h-20 rounded-2xl bg-white/15 border-2 border-white/30 grid place-items-center text-white font-extrabold text-xl overflow-hidden flex-shrink-0">
            {mentor.avatar_url ? (
              <img src={mentor.avatar_url} alt="" className="w-full h-full object-cover"
                onError={(e) => { e.currentTarget.style.display = 'none'; }} />
            ) : initials}
          </div>
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-1.5 mb-0.5">
              <h1 className="text-white font-extrabold text-lg leading-tight truncate">{mentor.full_name}</h1>
              {mentor.is_verified && <CheckCircle2 size={16} className="text-white flex-shrink-0" />}
            </div>
            <p className="text-white/90 text-sm font-medium truncate">
              {mentor.profession || mentor.specialty}
            </p>
            {mentor.company && (
              <div className="flex items-center gap-1 mt-1 text-white/70 text-xs">
                <Building2 size={11} />
                <span className="truncate">{mentor.company}</span>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* 3 stats */}
      <div className="grid grid-cols-3 gap-2 mb-4">
        <div className="bg-white rounded-xl border border-brand-border p-2.5 text-center">
          <div className="flex items-center justify-center gap-1 text-base font-extrabold text-brand-text-primary leading-tight">
            {mentor.rating_count > 0 ? mentor.rating_avg.toFixed(1) : '—'}
            <Star size={13} className={mentor.rating_count > 0 ? 'text-brand-xp-gold fill-brand-xp-gold' : 'text-brand-text-disabled'} />
          </div>
          <p className="text-[10px] text-brand-text-tertiary mt-0.5">
            {mentor.rating_count > 0 ? `${mentor.rating_count} ${t('avis')}` : t('Nouveau')}
          </p>
        </div>
        <div className="bg-white rounded-xl border border-brand-border p-2.5 text-center">
          <p className="text-base font-extrabold text-brand-text-primary leading-tight">
            {mentor.years_experience ?? '—'}
          </p>
          <p className="text-[10px] text-brand-text-tertiary mt-0.5">{t("ans d'exp.")}</p>
        </div>
        <div className="bg-white rounded-xl border border-brand-border p-2.5 text-center">
          <p className="text-base font-extrabold text-brand-text-primary leading-tight">
            {mentor.hourly_rate && mentor.hourly_rate > 0
              ? `${(mentor.hourly_rate / 1000).toFixed(0)}k`
              : 'Gratuit'}
          </p>
          <p className="text-[10px] text-brand-text-tertiary mt-0.5">FCFA / h</p>
        </div>
      </div>

      {/* Status row */}
      <div className="flex flex-wrap gap-2 mb-4">
        {availability && (
          <span className={`inline-flex items-center gap-1.5 text-xs font-bold px-3 py-1.5 rounded-full ${availability.bg} ${availability.color}`}>
            <span className={`w-1.5 h-1.5 rounded-full ${availability.dot}`} />
            {t(availability.label)}
          </span>
        )}
        {mentor.location && (
          <span className="inline-flex items-center gap-1 text-xs font-semibold text-brand-text-secondary bg-brand-surface px-3 py-1.5 rounded-full">
            <MapPin size={11} /> {mentor.location}
          </span>
        )}
        {mentor.years_experience != null && (
          <span className="inline-flex items-center gap-1 text-xs font-semibold text-brand-text-secondary bg-brand-surface px-3 py-1.5 rounded-full">
            <Briefcase size={11} /> {mentor.years_experience} {t('ans')}
          </span>
        )}
      </div>

      <div className="space-y-4">
        {/* About */}
        {mentor.bio && (
          <section className="bg-white rounded-2xl border border-brand-border p-4">
            <div className="flex items-center gap-2 mb-2">
              <Sparkles size={14} className="text-brand-primary" />
              <h2 className="font-bold text-brand-text-primary text-sm">{t('À propos')}</h2>
            </div>
            <p className="text-sm text-brand-text-secondary leading-relaxed whitespace-pre-line">{mentor.bio}</p>
          </section>
        )}

        {/* Expertise */}
        {mentor.expertise_areas.length > 0 && (
          <section>
            <div className="flex items-center gap-2 mb-2">
              <Award size={14} className="text-brand-primary" />
              <h2 className="font-bold text-brand-text-primary text-sm">{t('Domaines d\'expertise')}</h2>
            </div>
            <div className="flex flex-wrap gap-1.5">
              {mentor.expertise_areas.map(area => (
                <span key={area} className="px-3 py-1.5 rounded-full bg-brand-primary-surface text-brand-primary-dark text-xs font-semibold border border-brand-primary/20">
                  {area}
                </span>
              ))}
            </div>
          </section>
        )}

        {/* Mentee capacity */}
        <section className="bg-white rounded-2xl border border-brand-border p-4">
          <div className="flex items-center justify-between mb-2">
            <div className="flex items-center gap-2">
              <Users size={14} className="text-brand-primary" />
              <h2 className="font-bold text-brand-text-primary text-sm">{t('Capacité d\'accompagnement')}</h2>
            </div>
            <span className="text-xs font-bold text-brand-text-primary">
              {mentor.current_mentees} / {mentor.max_mentees}
            </span>
          </div>
          <div className="h-2 bg-brand-surface rounded-full overflow-hidden">
            <div className="h-full bg-gradient-to-r from-brand-primary to-brand-primary-light rounded-full transition-all duration-700"
              style={{ width: `${mentor.max_mentees > 0 ? Math.min(100, (mentor.current_mentees / mentor.max_mentees) * 100) : 0}%` }} />
          </div>
          {slotsLeft > 0 ? (
            <p className="text-xs text-brand-text-tertiary mt-2">
              {t('Il reste')} <span className="font-bold text-brand-success-dark">{slotsLeft}</span> {slotsLeft > 1 ? t('places disponibles') : t('place disponible')}
            </p>
          ) : (
            <p className="text-xs text-brand-error-dark mt-2 font-semibold">{t('Plus de place pour le moment')}</p>
          )}
        </section>

        {/* Available slots */}
        {mentor.available_slots && mentor.available_slots.length > 0 && (
          <section>
            <div className="flex items-center gap-2 mb-2">
              <Calendar size={14} className="text-brand-primary" />
              <h2 className="font-bold text-brand-text-primary text-sm">{t('Prochains créneaux')}</h2>
            </div>
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
              {mentor.available_slots.slice(0, 6).map((slot, i) => (
                <div key={i} className="bg-white border border-brand-border rounded-xl p-2.5 text-center">
                  <p className="text-sm font-bold text-brand-text-primary">{slot}</p>
                </div>
              ))}
            </div>
          </section>
        )}

        {/* Reviews */}
        <section>
          <div className="flex items-center gap-2 mb-3">
            <Star size={14} className="text-brand-primary" />
            <h2 className="font-bold text-brand-text-primary text-sm">{t('Avis')}</h2>
            {mentor.rating_count > 0 && (
              <span className="text-[10px] font-bold text-brand-text-tertiary bg-brand-surface px-1.5 py-0.5 rounded-full">
                {mentor.rating_count}
              </span>
            )}
          </div>
          {reviews.length === 0 ? (
            <div className="bg-white rounded-2xl border border-dashed border-brand-border p-5 text-center">
              <p className="text-sm text-brand-text-tertiary">{t('Pas encore d\'avis')}</p>
            </div>
          ) : (
            <div className="space-y-2">
              {reviews.map(rv => {
                const initials = rv.reviewer_name.split(' ').map(s => s[0]).join('').toUpperCase().slice(0, 2);
                return (
                  <div key={rv.id} className="bg-white rounded-2xl border border-brand-border p-4">
                    <div className="flex items-center gap-2.5 mb-2">
                      <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-brand-primary/15 to-brand-secondary/15 grid place-items-center text-xs font-bold text-brand-primary flex-shrink-0 overflow-hidden">
                        {rv.reviewer_avatar ? (
                          <img src={rv.reviewer_avatar} alt="" loading="lazy" className="w-full h-full object-cover"
                            onError={(e) => { e.currentTarget.style.display = 'none'; }} />
                        ) : initials}
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-bold text-brand-text-primary truncate">{rv.reviewer_name}</p>
                        <StarRating value={rv.rating} size={11} />
                      </div>
                      <span className="text-[10px] text-brand-text-tertiary">
                        {new Date(rv.created_at).toLocaleDateString('fr-FR', { day: 'numeric', month: 'short' })}
                      </span>
                    </div>
                    {rv.comment && (
                      <p className="text-xs text-brand-text-secondary leading-relaxed">{rv.comment}</p>
                    )}
                  </div>
                );
              })}
            </div>
          )}
        </section>

        {/* External link */}
        {mentor.linkedin_url && (
          <a href={normalizeUrl(mentor.linkedin_url)} target="_blank" rel="noopener noreferrer"
            className="flex items-center gap-3 bg-white rounded-2xl border border-brand-border p-4 hover:shadow-card-hover transition-all">
            <div className="w-10 h-10 rounded-xl bg-[#0A66C2]/10 grid place-items-center">
              <Link2 size={18} className="text-[#0A66C2]" />
            </div>
            <div className="flex-1">
              <p className="text-sm font-bold text-brand-text-primary">LinkedIn</p>
              <p className="text-xs text-brand-text-tertiary">Voir le profil professionnel</p>
            </div>
          </a>
        )}

        {/* Portfolio */}
        {mentor.portfolio && <PortfolioSection portfolio={mentor.portfolio} />}

        {/* Contact CTA */}
        {canContact && (
          <button onClick={() => setContactOpen(true)}
            className="w-full h-12 rounded-xl bg-gradient-primary text-white font-bold text-sm flex items-center justify-center gap-2 shadow-glow hover:opacity-95 transition-all active:scale-[.99]">
            <MessageCircle size={18} />
            {t('Contacter ce mentor')}
          </button>
        )}
      </div>

      {/* Contact modal */}
      {contactOpen && (
        <div className="fixed inset-0 z-[60] bg-black/50 flex items-end md:items-center justify-center p-0 md:p-4 animate-fade-in"
          onClick={() => !sending && setContactOpen(false)}>
          <div className="bg-white w-full max-w-md rounded-t-3xl md:rounded-2xl p-5 animate-slide-up"
            onClick={e => e.stopPropagation()}>
            <div className="flex items-center justify-between mb-4">
              <h3 className="font-extrabold text-brand-text-primary text-base">{t('Envoyer un message')}</h3>
              <button onClick={() => setContactOpen(false)} className="w-8 h-8 rounded-full bg-brand-surface grid place-items-center text-brand-text-secondary">
                <X size={16} />
              </button>
            </div>
            {sent ? (
              <div className="py-8 text-center">
                <div className="w-14 h-14 rounded-full bg-brand-success/10 grid place-items-center mx-auto mb-3">
                  <CheckCircle2 size={28} className="text-brand-success" />
                </div>
                <p className="font-bold text-brand-text-primary">{t('Message envoyé !')}</p>
                <p className="text-xs text-brand-text-tertiary mt-1">{t('Le mentor te répondra bientôt')}</p>
              </div>
            ) : sendError ? (
              <div className="py-8 text-center">
                <div className="w-14 h-14 rounded-full bg-brand-warning/10 grid place-items-center mx-auto mb-3">
                  <AlertTriangle size={28} className="text-brand-warning" />
                </div>
                <p className="font-bold text-brand-text-primary">{t('Messagerie indisponible')}</p>
                <p className="text-xs text-brand-text-tertiary mt-1 mb-4">{t('Cette fonctionnalité sera bientôt disponible. Contacte le mentor via son email.')}</p>
                <button onClick={() => setSendError(false)}
                  className="h-10 px-6 rounded-xl bg-brand-surface text-brand-text-secondary font-semibold text-sm">
                  {t('Réessayer')}
                </button>
              </div>
            ) : (
              <>
                <div className="flex items-center gap-2.5 mb-3 p-3 bg-brand-surface rounded-xl">
                  <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-brand-category-arts/20 to-brand-category-technology/20 grid place-items-center text-xs font-bold text-brand-category-arts overflow-hidden flex-shrink-0">
                    {mentor.avatar_url ? (
                      <img src={mentor.avatar_url} alt="" className="w-full h-full object-cover"
                        onError={(e) => { e.currentTarget.style.display = 'none'; }} />
                    ) : initials}
                  </div>
                  <div className="min-w-0">
                    <p className="text-sm font-bold text-brand-text-primary truncate">{mentor.full_name}</p>
                    <p className="text-xs text-brand-text-tertiary truncate">{mentor.profession || mentor.specialty}</p>
                  </div>
                </div>
                <textarea
                  value={message}
                  onChange={e => setMessage(e.target.value)}
                  rows={5}
                  placeholder={t('Salut ! J\'aimerais en savoir plus sur ton parcours...')}
                  className="w-full p-3 rounded-xl border border-brand-border text-sm outline-none focus:border-brand-primary transition-colors resize-none"
                />
                <button onClick={sendMessage} disabled={!message.trim() || sending}
                  className="w-full h-11 rounded-xl bg-gradient-primary text-white font-bold text-sm mt-3 disabled:opacity-40 flex items-center justify-center gap-2">
                  {sending ? <span className="animate-pulse">{t('Envoi...')}</span> : <><MessageCircle size={16} /> {t('Envoyer')}</>}
                </button>
              </>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
