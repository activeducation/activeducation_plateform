'use client';
import { useState, useEffect, useRef } from 'react';
import { useAuth } from '@/lib/auth';
import { api } from '@/lib/api';
import { useRouter } from 'next/navigation';
import {
  Search as SearchIcon, ArrowLeft, School as SchoolIcon, Briefcase, BookOpen, X,
  Clock, Sparkles, Code2, FlaskConical, Palette,
  Stethoscope, GraduationCap, Search,
} from 'lucide-react';
import { useTheme } from '@/lib/theme';
import type { LucideIcon } from 'lucide-react';

interface SearchResult {
  type: 'school' | 'career' | 'course';
  id: string;
  title: string;
  subtitle?: string;
  image?: string;
  route: string;
}

const RECENT_SEARCHES = [
  { term: 'développeur python', count: 9 },
  { term: 'EPITECH', count: 1 },
  { term: 'bourse mastercard', count: 3 },
];

const QUICK_CATEGORIES: { icon: LucideIcon; label: string }[] = [
  { icon: Code2, label: 'Tech' },
  { icon: FlaskConical, label: 'Sciences' },
  { icon: Briefcase, label: 'Business' },
  { icon: Palette, label: 'Arts' },
  { icon: Stethoscope, label: 'Santé' },
  { icon: GraduationCap, label: 'Lettres' },
];

export default function SearchPage() {
  const { user } = useAuth();
  const router = useRouter();
  const { t } = useTheme();
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<SearchResult[]>([]);
  const [total, setTotal] = useState(0);
  const [searching, setSearching] = useState(false);
  const [searched, setSearched] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    inputRef.current?.focus();
  }, []);

  useEffect(() => {
    if (!query.trim() || query.trim().length < 2) {
      setResults([]);
      setSearched(false);
      return;
    }
    const timer = setTimeout(async () => {
      setSearching(true);
      try {
        const data = await api.get<{ query: string; schools: SearchResult[]; careers: SearchResult[]; courses: SearchResult[]; total: number }>(
          `/search?q=${encodeURIComponent(query.trim())}&limit=8`
        );
        const combined = [
          ...data.schools.map(s => ({ ...s, type: 'school' as const })),
          ...data.careers.map(c => ({ ...c, type: 'career' as const })),
          ...data.courses.map(c => ({ ...c, type: 'course' as const })),
        ];
        setResults(combined);
        setTotal(data.total);
        setSearched(true);
      } catch {
        setResults([]);
        setSearched(true);
      }
      setSearching(false);
    }, 300);
    return () => clearTimeout(timer);
  }, [query]);

  if (!user) return null;

  const icons: Record<string, any> = { school: SchoolIcon, career: Briefcase, course: BookOpen };
  const colors: Record<string, string> = {
    school: 'text-brand-category-science bg-brand-category-science/10',
    career: 'text-brand-category-economics bg-brand-category-economics/10',
    course: 'text-brand-primary bg-brand-primary/10',
  };

  const triggerSearch = (term: string) => {
    setQuery(term);
    inputRef.current?.focus();
  };

  return (
    <div className="animate-fade-in">
      {/* Header : back + input pill */}
      <div className="flex items-center gap-2 mb-5">
        <button onClick={() => router.back()} className="w-9 h-9 rounded-full bg-white border border-brand-border flex items-center justify-center text-brand-text-secondary shadow-card active:scale-95 transition-transform" aria-label="Retour">
          <ArrowLeft size={18} />
        </button>
        <div className="flex-1 flex items-center gap-2 px-4 h-11 bg-white rounded-full border border-brand-border shadow-card focus-within:border-brand-primary transition-colors">
          <SearchIcon size={16} className="text-brand-text-tertiary flex-shrink-0" />
          <input
            ref={inputRef}
            type="text"
            value={query}
            onChange={e => setQuery(e.target.value)}
            placeholder={t('Métier, école, mentor...')}
            className="flex-1 bg-transparent border-none outline-none text-sm text-brand-text-primary placeholder:text-brand-text-tertiary"
          />
          {query && (
            <button onClick={() => { setQuery(''); setResults([]); setSearched(false); }} aria-label="Effacer" className="text-brand-text-tertiary active:scale-90 transition-transform">
              <X size={16} />
            </button>
          )}
        </div>
      </div>

      {/* Loading */}
      {searching && (
        <div className="flex items-center justify-center py-12">
          <div className="animate-spin w-6 h-6 border-2 border-brand-primary border-t-transparent rounded-full" />
        </div>
      )}

      {/* No results */}
      {!searching && searched && results.length === 0 && query.length >= 2 && (
        <div className="text-center py-10">
          <div className="w-20 h-20 rounded-full bg-brand-primary-surface mx-auto mb-4 flex items-center justify-center text-brand-primary">
            <Search size={32} strokeWidth={1.8} />
          </div>
          <h2 className="font-bold text-brand-text-primary text-base mb-1">Aucun résultat</h2>
          <p className="text-sm text-brand-text-secondary mb-5">Essaie avec d'autres mots-clés</p>
          <div className="flex flex-wrap gap-2 justify-center">
            {['développeur', 'EPITECH', 'médecin', 'mastercard'].map(s => (
              <button key={s} onClick={() => triggerSearch(s)}
                className="px-3 py-1.5 bg-white border border-brand-border rounded-full text-xs text-brand-text-secondary active:scale-95 transition-transform">
                {s}
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Grouped results */}
      {!searching && results.length > 0 && (
        <div className="space-y-5">
          <p className="text-xs text-brand-text-tertiary font-medium px-1">
            {total} résultat{total > 1 ? 's' : ''} pour <span className="font-bold text-brand-text-primary">"{query}"</span>
          </p>
          {(['school', 'career', 'course'] as const).map(type => {
            const grouped = results.filter(r => r.type === type);
            if (grouped.length === 0) return null;
            const Icon = icons[type];
            const sectionLabels: Record<string, string> = {
              school: 'Écoles', career: 'Métiers & carrières', course: 'Cours',
            };
            const sectionIconColors: Record<string, string> = {
              school: 'text-brand-category-science bg-brand-category-science/10',
              career: 'text-brand-category-economics bg-brand-category-economics/10',
              course: 'text-brand-primary bg-brand-primary/10',
            };
            return (
              <div key={type}>
                <div className="flex items-center gap-2 mb-2.5 px-1">
                  <div className={`w-6 h-6 rounded-md grid place-items-center ${sectionIconColors[type]}`}>
                    <Icon size={12} />
                  </div>
                  <h3 className="text-[11px] font-bold text-brand-text-secondary uppercase tracking-wider">{sectionLabels[type]}</h3>
                  <span className="text-[10px] font-bold text-brand-text-tertiary bg-brand-surface px-1.5 py-0.5 rounded-full">{grouped.length}</span>
                </div>
                <div className="space-y-1.5">
                  {grouped.map((item, i) => {
                    const color = colors[item.type] || 'text-brand-text-tertiary bg-brand-surface';
                    return (
                      <button
                        key={`${item.type}-${item.id}-${i}`}
                        onClick={() => {
                          const routes: Record<string, string> = {
                            school: `/ecoles/${item.id}`,
                            career: `/orientation/career/${item.id}`,
                            course: `/cours/${item.id}`,
                          };
                          router.push(routes[item.type] || item.route);
                        }}
                        className="w-full bg-white rounded-xl border border-brand-border p-3 text-left shadow-card hover:shadow-card-hover active:scale-[.99] transition-all"
                      >
                        <div className="flex items-center gap-3">
                          <div className={`w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0 ${color} overflow-hidden relative`}>
                            {item.image && (
                              <img src={item.image} alt="" loading="lazy" className="absolute inset-0 w-full h-full object-cover rounded-lg"
                                onError={(e) => { e.currentTarget.style.display = 'none'; }} />
                            )}
                            <Icon size={16} />
                          </div>
                          <div className="flex-1 min-w-0">
                            <p className="text-sm font-semibold text-brand-text-primary truncate">
                              {item.title}
                            </p>
                            {item.subtitle && (
                              <p className="text-[11px] text-brand-text-tertiary mt-0.5 truncate">{item.subtitle}</p>
                            )}
                          </div>
                          <ArrowLeft size={14} className="text-brand-text-tertiary rotate-180 flex-shrink-0" />
                        </div>
                      </button>
                    );
                  })}
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Empty state (no query yet) */}
      {!searching && !searched && query.length < 2 && (
        <div className="space-y-6">
          {/* Recent searches */}
          <div>
            <h2 className="text-[11px] font-bold text-brand-text-tertiary uppercase tracking-wider mb-3 px-1">
              Recherches récentes
            </h2>
            <div className="space-y-2">
              {RECENT_SEARCHES.map(({ term, count }) => (
                <button
                  key={term}
                  onClick={() => triggerSearch(term)}
                  className="w-full flex items-center gap-3 px-3.5 py-3 bg-white border border-brand-border rounded-xl shadow-card active:scale-[.99] transition-transform text-left"
                >
                  <div className="w-9 h-9 rounded-full bg-brand-surface grid place-items-center text-brand-text-tertiary flex-shrink-0">
                    <Clock size={14} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-semibold text-brand-text-primary truncate">{term}</p>
                    <p className="text-[11px] text-brand-text-tertiary">{count} résultat{count > 1 ? 's' : ''}</p>
                  </div>
                  <ArrowLeft size={14} className="text-brand-text-disabled rotate-180 flex-shrink-0" />
                </button>
              ))}
            </div>
          </div>

          {/* Quick categories */}
          <div>
            <h2 className="text-[11px] font-bold text-brand-text-tertiary uppercase tracking-wider mb-3 px-1">
              Explorer par catégorie
            </h2>
            <div className="grid grid-cols-3 gap-2">
              {QUICK_CATEGORIES.map(({ icon: Icon, label }) => (
                <button
                  key={label}
                  onClick={() => triggerSearch(label.toLowerCase())}
                  className="bg-white border border-brand-border rounded-2xl py-4 px-2 text-center shadow-card active:scale-95 transition-transform"
                >
                  <div className="w-9 h-9 mx-auto mb-1.5 rounded-xl bg-brand-primary-surface text-brand-primary grid place-items-center">
                    <Icon size={18} strokeWidth={1.8} />
                  </div>
                  <div className="text-[11px] font-semibold text-brand-text-secondary">{label}</div>
                </button>
              ))}
            </div>
          </div>

          {/* Astuce */}
          <div className="bg-gradient-to-br from-brand-primary-surface to-white border border-brand-primary/15 rounded-2xl p-4 flex gap-3">
            <div className="w-9 h-9 rounded-xl bg-white grid place-items-center flex-shrink-0 shadow-sm">
              <Sparkles size={16} className="text-brand-primary" />
            </div>
            <div>
              <p className="text-xs font-bold text-brand-primary-dark mb-0.5">Astuce</p>
              <p className="text-xs text-brand-text-secondary leading-relaxed">
                Tape le nom d'un métier, d'une école ou d'un mentor. Tu peux aussi parcourir par catégorie ci-dessus.
              </p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
