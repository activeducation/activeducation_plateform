'use client';

import {
  BadgeCheck,
  Building2,
  ChevronRight,
  MapPin,
  Star,
  Users,
  Wallet,
} from 'lucide-react';

type TFunction = (key: string) => string;

/* ── Shared types ─────────────────────────────────────────────────────── */

interface BaseProps {
  id: string;
  /** Optional banner image URL. Falls back to a coloured gradient when absent. */
  bannerUrl?: string;
  /** Optional avatar / logo URL (rendered as a pastille on top of the banner). */
  avatarUrl?: string;
  /** Initials shown in the avatar pastille when avatarUrl is missing. */
  initials: string;
  /** Card-wide click handler. CTA buttons reuse it with their own label. */
  onViewMore: (id: string) => void;
  /** Translation function — passed in instead of imported so the component
   *  stays decoupled from ThemeProvider (pure, testable). */
  t: TFunction;
}

/* ── Discriminated union: school vs mentor ────────────────────────────── */

export type EntityCardProps =
  | (BaseProps & {
      type: 'school';
      title: string;
      subtitle?: string;
      description?: string;
      tuition?: string;
      students?: number;
      accreditations?: string[];
      isPublic?: boolean;
      schoolType?: string;
      ctaPrimaryLabel: string;
      ctaSecondaryLabel: string;
    })
  | (BaseProps & {
      type: 'mentor';
      title: string; // fullName
      subtitle: string; // profession · company
      location?: string;
      rating?: { avg: number; count: number };
      yearsExperience?: number;
      availability?: {
        kind: 'available' | 'limited' | 'unavailable';
        label: string;
      };
      slotsLeft?: number;
      hourlyRate?: number;
      isVerified?: boolean;
      ctaPrimaryLabel: string;
    });

/* ── Helpers ──────────────────────────────────────────────────────────── */

const availabilityStyles: Record<
  'available' | 'limited' | 'unavailable',
  string
> = {
  available: 'bg-brand-success/10 text-brand-success-dark',
  limited: 'bg-brand-warning/10 text-brand-warning-dark',
  unavailable: 'bg-brand-error/10 text-brand-error-dark',
};

/* ── Component ────────────────────────────────────────────────────────── */

export default function EntityCard(props: EntityCardProps) {
  const { type, id, bannerUrl, avatarUrl, initials, onViewMore, t } = props;

  const handleViewMore = () => onViewMore(id);

  return (
    <div
      role="button"
      tabIndex={0}
      onClick={handleViewMore}
      onKeyDown={(e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          handleViewMore();
        }
      }}
      className="bg-white rounded-xl border border-brand-border overflow-hidden shadow-card hover:shadow-card-hover hover:border-brand-primary/30 transition-all cursor-pointer"
    >
      {/* ── Banner ───────────────────────────────────────────────────── */}
      <div
        className="h-24 relative overflow-hidden bg-gradient-to-br from-brand-category-science/20 via-brand-primary-surface to-brand-category-economics/20"
        style={
          bannerUrl
            ? {
                backgroundImage: `url(${bannerUrl})`,
                backgroundSize: 'cover',
                backgroundPosition: 'center',
              }
            : undefined
        }
      >
        {bannerUrl && (
          <div className="absolute inset-0 bg-gradient-to-t from-black/30 to-transparent" />
        )}
        {!bannerUrl && (
          <div className="absolute inset-0 flex items-center justify-center">
            <div className="w-10 h-10 rounded-xl bg-white/60 flex items-center justify-center">
              <Building2 size={20} className="text-brand-text-secondary" />
            </div>
          </div>
        )}

        {/* Type-specific top-row badges */}
        {type === 'school' && <SchoolBadges {...props} />}
        {type === 'mentor' && <MentorTopBadge {...props} />}
      </div>

      {/* ── Avatar pastille (overlap on banner) ─────────────────────── */}
      <div className="px-3.5 -mt-7 mb-2">
        <div className="relative w-14 h-14 rounded-2xl ring-4 ring-white bg-gradient-to-br from-brand-category-arts/20 to-brand-category-technology/20 flex items-center justify-center overflow-hidden">
          {avatarUrl ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              src={avatarUrl}
              alt=""
              loading="lazy"
              className="absolute inset-0 w-full h-full object-cover"
              onError={(e) => {
                e.currentTarget.style.display = 'none';
              }}
            />
          ) : type === 'school' ? (
            // Fallback school: icône lucide plutôt qu'initiale (les écoles ont
            // rarement un logo_url en base, le fallback lettre était laid).
            <Building2 size={22} className="text-brand-text-secondary" aria-hidden="true" />
          ) : (
            // Fallback mentor: initiale du nom (acceptable pour une personne).
            <span className="font-bold text-brand-category-arts text-sm">
              {initials}
            </span>
          )}
        </div>
      </div>

      {/* ── Content ─────────────────────────────────────────────────── */}
      <div className="px-3.5 pb-2.5">
        <h3 className="font-bold text-brand-text-primary text-sm leading-tight truncate">
          {props.title}
        </h3>

        {type === 'school' && props.subtitle && (
          <div className="flex items-center gap-1 text-xs text-brand-text-tertiary mt-0.5">
            <MapPin size={11} />
            <span className="truncate">{props.subtitle}</span>
          </div>
        )}

        {type === 'mentor' && (
          <>
            <p className="text-xs text-brand-text-tertiary mt-0.5 truncate">
              {props.subtitle}
            </p>
            {props.location && (
              <div className="flex items-center gap-1 text-[11px] text-brand-text-tertiary mt-1">
                <MapPin size={10} />
                <span className="truncate">{props.location}</span>
              </div>
            )}
          </>
        )}

        {type === 'school' && props.description && (
          <p className="text-xs text-brand-text-secondary leading-relaxed line-clamp-2 mt-2">
            {props.description}
          </p>
        )}

        {/* Meta row */}
        <div className="flex items-center gap-3 mt-2">
          {type === 'school' && (
            <>
              {props.tuition && (
                <span className="text-[10px] font-semibold text-brand-text-tertiary flex items-center gap-1">
                  <Wallet size={11} />
                  {props.tuition}
                </span>
              )}
              {props.students != null && (
                <span className="text-[10px] font-semibold text-brand-text-tertiary flex items-center gap-1">
                  <Users size={11} />
                  {props.students.toLocaleString('fr-FR')}
                </span>
              )}
            </>
          )}
          {type === 'mentor' && (
            <>
              {props.rating && props.rating.count > 0 ? (
                <span className="inline-flex items-center gap-0.5 text-[11px] font-bold text-brand-text-primary">
                  <Star size={11} className="text-brand-xp-gold fill-brand-xp-gold" />
                  {props.rating.avg.toFixed(1)}
                  <span className="font-normal text-brand-text-tertiary">
                    ({props.rating.count})
                  </span>
                </span>
              ) : (
                <span className="text-[11px] text-brand-text-tertiary">
                  {t('Nouveau')}
                </span>
              )}
              {props.yearsExperience != null && (
                <>
                  <span className="text-brand-text-disabled">·</span>
                  <span className="text-[10px] text-brand-text-tertiary">
                    {props.yearsExperience} {t('ans')}
                  </span>
                </>
              )}
            </>
          )}
        </div>

        {/* Tags row */}
        {type === 'school' &&
          props.accreditations &&
          props.accreditations.length > 0 && (
            <div className="flex flex-wrap gap-1.5 mt-2.5">
              {props.accreditations.slice(0, 3).map((a, i) => (
                <span
                  key={i}
                  className="text-[10px] font-semibold text-brand-success-dark bg-brand-success-surface px-2 py-0.5 rounded-full flex items-center gap-1"
                >
                  <BadgeCheck size={10} />
                  {a}
                </span>
              ))}
            </div>
          )}

        {type === 'mentor' && (
          <div className="flex items-center gap-1.5 mt-2 flex-wrap">
            {props.availability && (
              <span
                className={`text-[10px] font-semibold px-2 py-0.5 rounded-full ${availabilityStyles[props.availability.kind]}`}
              >
                {props.availability.label}
              </span>
            )}
            {props.slotsLeft != null &&
              props.slotsLeft > 0 &&
              props.slotsLeft <= 3 && (
                <span className="text-[10px] font-semibold text-brand-secondary-dark bg-brand-secondary-surface px-2 py-0.5 rounded-full">
                  {props.slotsLeft} {t('place')}
                  {props.slotsLeft > 1 ? 's' : ''}
                </span>
              )}
            {props.hourlyRate != null && props.hourlyRate > 0 && (
              <span className="text-[10px] font-semibold text-brand-xp-gold-dark bg-brand-xp-gold-surface px-2 py-0.5 rounded-full">
                {props.hourlyRate.toLocaleString('fr-FR')} FCFA/h
              </span>
            )}
          </div>
        )}
      </div>

      {/* ── CTA(s) ──────────────────────────────────────────────────── */}
      <div className="px-3.5 pb-3.5 flex gap-2">
        {type === 'school' && (
          <>
            <button
              type="button"
              onClick={(e) => {
                e.stopPropagation();
                handleViewMore();
              }}
              className="flex-1 h-8 rounded-lg border border-brand-border text-xs font-semibold text-brand-text-secondary hover:bg-brand-surface transition-colors"
            >
              {props.ctaSecondaryLabel}
            </button>
            <button
              type="button"
              onClick={(e) => {
                e.stopPropagation();
                handleViewMore();
              }}
              className="flex-1 h-8 rounded-lg bg-brand-primary text-white text-xs font-semibold flex items-center justify-center gap-1 hover:opacity-90 transition-all"
            >
              {props.ctaPrimaryLabel}
              <ChevronRight size={13} />
            </button>
          </>
        )}
        {type === 'mentor' && (
          <button
            type="button"
            onClick={(e) => {
              e.stopPropagation();
              handleViewMore();
            }}
            className="w-full h-8 rounded-lg bg-brand-primary text-white text-xs font-semibold flex items-center justify-center gap-1 hover:opacity-90 transition-all"
          >
            {props.ctaPrimaryLabel}
            <ChevronRight size={13} />
          </button>
        )}
      </div>
    </div>
  );
}

/* ── Internal sub-components ─────────────────────────────────────────── */

function SchoolBadges(props: Extract<EntityCardProps, { type: 'school' }>) {
  return (
    <div className="absolute top-2 left-2 flex gap-1.5">
      <span
        className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
          props.isPublic
            ? 'bg-blue-500 text-white'
            : 'bg-brand-secondary text-white'
        }`}
      >
        {props.isPublic ? props.t('Publique') : props.t('Privee')}
      </span>
      {props.schoolType && (
        <span className="text-[10px] font-semibold text-brand-text-secondary bg-white/90 px-2 py-0.5 rounded-full">
          {props.schoolType}
        </span>
      )}
    </div>
  );
}

function MentorTopBadge(props: Extract<EntityCardProps, { type: 'mentor' }>) {
  if (!props.isVerified) return null;
  return (
    <div className="absolute top-2 right-2">
      <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-brand-info text-white flex items-center gap-1">
        <BadgeCheck size={10} />
        {props.t('Vérifié')}
      </span>
    </div>
  );
}