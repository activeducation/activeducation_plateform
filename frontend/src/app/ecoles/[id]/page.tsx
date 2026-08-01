'use client';
import { useEffect, useState } from 'react';
import { useAuth } from '@/lib/auth';
import { useTheme } from '@/lib/theme';
import { api } from '@/lib/api';
import { useParams, useRouter } from 'next/navigation';
import {
  ArrowLeft, MapPin, Phone, Mail, Globe, Users, Calendar, GraduationCap,
  BookOpen, Award, ChevronRight, Star, Share2, MessageCircle, Image
} from 'lucide-react';

interface SchoolDetail {
  id: string;
  name: string;
  type: string;
  city: string;
  address?: string;
  phone?: string;
  email?: string;
  website?: string;
  description?: string;
  programs_offered: string[];
  is_public: boolean;
  logo_url?: string;
  cover_image_url?: string;
  tuition_range?: string;
  admission_requirements?: string;
  accreditations: string[];
  founding_year?: number;
  student_count?: number;
  programs: { id: string; name: string; description?: string; level?: string; duration_years?: number }[];
  images: { id: string; image_url: string; caption?: string }[];
}

export default function SchoolDetailPage() {
  const { user, loading: authLoading } = useAuth();
  const { t } = useTheme();
  const params = useParams();
  const router = useRouter();
  const [school, setSchool] = useState<SchoolDetail | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!user) return;
    api.get<SchoolDetail>(`/schools/${params.id}`)
      .then(setSchool)
      .catch(() => router.push('/ecoles'))
      .finally(() => setLoading(false));
  }, [user, params.id, router]);

  if (authLoading || loading) return (
    <div className="min-h-[80vh] flex items-center justify-center">
      <div className="animate-spin w-8 h-8 border-2 border-brand-primary border-t-transparent rounded-full" />
    </div>
  );
  if (!user || !school) return null;

  return (
    <div className="animate-fade-in pb-6">
      {/* Hero */}
      <div className="relative -mx-4 -mt-4 mb-5">
        <div className={`h-40 relative overflow-hidden ${school.cover_image_url ? '' : 'bg-gradient-to-br from-brand-category-science via-brand-category-science to-brand-category-science/60'}`}
          style={school.cover_image_url ? { backgroundImage: `url(${school.cover_image_url})`, backgroundSize: 'cover', backgroundPosition: 'center' } : {}}>
          {school.cover_image_url && <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent" />}
          <div className="absolute top-4 left-4 w-9 h-9 rounded-xl bg-black/30 flex items-center justify-center backdrop-blur-sm cursor-pointer z-10"
            onClick={() => router.back()}>
            <ArrowLeft size={18} className="text-white" />
          </div>
          <button onClick={() => {}}
            className="absolute top-4 right-4 w-9 h-9 rounded-xl bg-black/30 flex items-center justify-center backdrop-blur-sm z-10">
            <Share2 size={16} className="text-white" />
          </button>
        </div>
      </div>

      {/* FAB Contact */}
      {school.phone && (
        <a href={`tel:${school.phone}`}
          className="fixed bottom-24 right-4 z-40 w-12 h-12 rounded-2xl bg-gradient-primary flex items-center justify-center shadow-lg hover:opacity-90 transition-all">
          <MessageCircle size={20} className="text-white" />
        </a>
      )}

      {/* Info card */}
      <div className="bg-white rounded-2xl border border-brand-border p-5 shadow-card mb-4 -mt-16 relative z-10">
        <div className="flex items-start gap-4 mb-4">
          <div className="w-14 h-14 rounded-xl bg-gradient-to-br from-brand-category-science/20 to-brand-category-economics/20 flex items-center justify-center flex-shrink-0 border border-brand-border-light overflow-hidden relative">
            {school.logo_url && (
              <img src={school.logo_url} alt="" loading="lazy" className="absolute inset-0 w-full h-full object-cover rounded-xl"
                onError={(e) => { e.currentTarget.style.display = 'none'; }} />
            )}
            <GraduationCap size={24} className="text-brand-category-science" />
          </div>
          <div className="flex-1 min-w-0">
            <h1 className="text-lg font-bold text-brand-text-primary">{school.name}</h1>
            <div className="flex items-center gap-1 text-sm text-brand-text-tertiary mt-0.5">
              <MapPin size={12} />
              <span>{school.city}</span>
            </div>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-3">
          {school.student_count != null && (
            <div className="flex items-center gap-2.5 bg-brand-surface rounded-xl p-3">
              <Users size={15} className="text-brand-primary" />
              <div>
                <p className="text-sm font-bold text-brand-text-primary">{school.student_count.toLocaleString()}</p>
                <p className="text-[10px] text-brand-text-tertiary">{t('Étudiants')}</p>
              </div>
            </div>
          )}
          {school.founding_year != null && (
            <div className="flex items-center gap-2.5 bg-brand-surface rounded-xl p-3">
              <Calendar size={15} className="text-brand-category-economics" />
              <div>
                <p className="text-sm font-bold text-brand-text-primary">{school.founding_year}</p>
                <p className="text-[10px] text-brand-text-tertiary">{t('Fondation')}</p>
              </div>
            </div>
          )}
          <div className="flex items-center gap-2.5 bg-brand-surface rounded-xl p-3">
            <Award size={15} className="text-brand-xp-gold" />
            <div>
              <p className="text-sm font-bold text-brand-text-primary">{school.accreditations.length || '—'}</p>
              <p className="text-[10px] text-brand-text-tertiary">{t('Accréditations')}</p>
            </div>
          </div>
          <div className="flex items-center gap-2.5 bg-brand-surface rounded-xl p-3">
            <BookOpen size={15} className="text-brand-category-technology" />
            <div>
              <p className="text-sm font-bold text-brand-text-primary">{school.programs.length}</p>
              <p className="text-[10px] text-brand-text-tertiary">{t('Programmes')}</p>
            </div>
          </div>
        </div>
      </div>

      {/* Contact info */}
      {(school.address || school.phone || school.email || school.website) && (
        <div className="bg-white rounded-2xl border border-brand-border p-4 shadow-card mb-4 space-y-3">
          {school.address && (
            <div className="flex items-center gap-3">
              <MapPin size={15} className="text-brand-text-tertiary" />
              <span className="text-sm text-brand-text-secondary">{school.address}</span>
            </div>
          )}
          {school.phone && (
            <div className="flex items-center gap-3">
              <Phone size={15} className="text-brand-text-tertiary" />
              <span className="text-sm text-brand-text-secondary">{school.phone}</span>
            </div>
          )}
          {school.email && (
            <div className="flex items-center gap-3">
              <Mail size={15} className="text-brand-text-tertiary" />
              <span className="text-sm text-brand-text-secondary">{school.email}</span>
            </div>
          )}
          {school.website && (
            <div className="flex items-center gap-3">
              <Globe size={15} className="text-brand-text-tertiary" />
              <a href={school.website} target="_blank" rel="noopener noreferrer"
                className="text-sm text-brand-primary hover:underline">{school.website}</a>
            </div>
          )}
        </div>
      )}

      {/* Description */}
      {school.description && (
        <div className="bg-white rounded-2xl border border-brand-border p-4 shadow-card mb-4">
          <h3 className="font-bold text-sm text-brand-text-primary mb-2">{t('À propos')}</h3>
          <p className="text-sm text-brand-text-secondary leading-relaxed">{school.description}</p>
        </div>
      )}

      {/* Programs */}
      {school.programs.length > 0 && (
        <div className="bg-white rounded-2xl border border-brand-border shadow-card overflow-hidden mb-4">
          <div className="p-4 pb-0">
            <h3 className="font-bold text-sm text-brand-text-primary">{t('Programmes')}</h3>
          </div>
          <div className="p-1">
            {school.programs.map((prog, i) => (
              <div key={prog.id} className="flex items-center gap-3 px-3 py-3 border-b border-brand-border last:border-0">
                <div className="w-1 h-8 rounded-full bg-brand-category-science" />
                <div className="flex-1">
                  <p className="text-sm font-semibold text-brand-text-primary">{prog.name}</p>
                  <div className="flex items-center gap-2 mt-0.5">
                    {prog.level && <span className="text-[10px] text-brand-text-tertiary">{prog.level}</span>}
                    {prog.duration_years && <span className="text-[10px] text-brand-text-tertiary">{prog.duration_years} {t('ans')}</span>}
                  </div>
                </div>
                <ChevronRight size={15} className="text-brand-text-tertiary" />
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Accreditations */}
      {school.accreditations.length > 0 && (
        <div className="bg-white rounded-2xl border border-brand-border p-4 shadow-card mb-4">
          <h3 className="font-bold text-sm text-brand-text-primary mb-2">{t('Accréditations')}</h3>
          <div className="flex flex-wrap gap-2">
            {school.accreditations.map((a, i) => (
              <span key={i} className="text-[11px] font-semibold text-brand-category-science bg-brand-category-science/10 px-2.5 py-1 rounded-full">
                {a}
              </span>
            ))}
          </div>
        </div>
      )}

      {/* Admission */}
      {school.admission_requirements && (
        <div className="bg-white rounded-2xl border border-brand-border p-4 shadow-card mb-4">
          <h3 className="font-bold text-sm text-brand-text-primary mb-2">{t('Admission')}</h3>
          <p className="text-sm text-brand-text-secondary leading-relaxed">{school.admission_requirements}</p>
        </div>
      )}

      {/* Image gallery */}
      {school.images && school.images.length > 0 && (
        <div className="bg-white rounded-2xl border border-brand-border p-4 shadow-card mb-4">
          <h3 className="font-bold text-sm text-brand-text-primary mb-3">{t('Galerie')}</h3>
          <div className="flex gap-3 overflow-x-auto pb-1 scrollbar-none">
            {school.images.map(img => (
              <div key={img.id} className="flex-shrink-0 w-48 h-32 rounded-xl overflow-hidden">
                <div className="w-full h-full bg-gradient-to-br from-brand-surface to-brand-border-light flex items-center justify-center"
                  style={img.image_url ? { backgroundImage: `url(${img.image_url})`, backgroundSize: 'cover', backgroundPosition: 'center' } : {}}>
                  {!img.image_url && <Image size={20} className="text-brand-text-tertiary" />}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Tuition */}
      {school.tuition_range && (
        <div className="bg-gradient-to-r from-brand-xp-gold-surface to-white rounded-2xl border border-brand-xp-gold/20 p-4 shadow-card">
          <div className="flex items-center gap-2">
            <GraduationCap size={16} className="text-brand-xp-gold-dark" />
            <h3 className="font-bold text-sm text-brand-text-primary">{t('Frais de scolarité')}</h3>
          </div>
          <p className="text-sm text-brand-text-secondary mt-1">{school.tuition_range}</p>
        </div>
      )}
    </div>
  );
}
