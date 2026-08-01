'use client';
import { useEffect, useState } from 'react';
import { useAuth } from '@/lib/auth';
import { useTheme } from '@/lib/theme';
import { api } from '@/lib/api';
import { ArrowLeft, Bell, Info, AlertTriangle, Sparkles, Wrench } from 'lucide-react';
import { useRouter } from 'next/navigation';
import { getReadAnnouncementIds, markAnnouncementRead } from '@/lib/use-announcements';

interface Announcement {
  id: string;
  title: string;
  content: string;
  type: 'info' | 'warning' | 'promotion' | 'update';
  image_url?: string | null;
  created_at: string;
}

const typeMeta: Record<string, { icon: any; bg: string; border: string; color: string; label: string }> = {
  info: { icon: Info, bg: 'bg-brand-primary/6', border: 'border-brand-primary/15', color: 'text-brand-primary', label: 'Info' },
  warning: { icon: AlertTriangle, bg: 'bg-brand-warning/6', border: 'border-brand-warning/15', color: 'text-brand-warning', label: 'Important' },
  promotion: { icon: Sparkles, bg: 'bg-brand-secondary/6', border: 'border-brand-secondary/15', color: 'text-brand-secondary', label: 'Promo' },
  update: { icon: Wrench, bg: 'bg-brand-info/6', border: 'border-brand-info/15', color: 'text-brand-info', label: 'Mise à jour' },
};

export default function NotificationsPage() {
  const { user, loading: authLoading } = useAuth();
  const { t } = useTheme();
  const router = useRouter();
  const [items, setItems] = useState<Announcement[]>([]);
  const [loading, setLoading] = useState(true);
  const [readIds, setReadIds] = useState<Set<string>>(new Set());

  useEffect(() => {
    if (!user) return;
    setReadIds(getReadAnnouncementIds());
    api.get<Announcement[]>('/announcements?audience=students&limit=50')
      .then(d => { setItems(d); setLoading(false); })
      .catch(() => setLoading(false));
  }, [user]);

  if (authLoading) return null;
  if (!user) return null;

  const formatDate = (iso: string) => {
    const d = new Date(iso);
    const now = new Date();
    const diffMs = now.getTime() - d.getTime();
    const diffH = Math.floor(diffMs / 3_600_000);
    if (diffH < 1) return t("À l'instant");
    if (diffH < 24) return `Il y a ${diffH}h`;
    const diffD = Math.floor(diffH / 24);
    if (diffD < 7) return `Il y a ${diffD}j`;
    return d.toLocaleDateString('fr-FR', { day: 'numeric', month: 'short' });
  };

  const onSelect = (a: Announcement) => {
    if (!readIds.has(a.id)) {
      markAnnouncementRead(a.id);
      setReadIds(prev => new Set(prev).add(a.id));
    }
  };

  const unreadCount = items.filter(a => !readIds.has(a.id)).length;

  return (
    <div className="animate-fade-in">
      <div className="flex items-center gap-2 mb-5">
        <button onClick={() => router.back()} className="w-9 h-9 rounded-full bg-white border border-brand-border flex items-center justify-center text-brand-text-secondary shadow-card active:scale-95 transition-transform" aria-label="Retour">
          <ArrowLeft size={18} />
        </button>
        <div className="flex-1">
          <h1 className="text-lg font-extrabold text-brand-text-primary leading-tight">{t('Notifications')}</h1>
          {unreadCount > 0 && (
            <p className="text-xs text-brand-text-tertiary">{unreadCount} {t('non lue')}{unreadCount > 1 ? 's' : ''}</p>
          )}
        </div>
      </div>

      {loading ? (
        <div className="space-y-3">
          {[1, 2, 3].map(i => (
            <div key={i} className="bg-white rounded-2xl border border-brand-border p-4 animate-pulse space-y-2">
              <div className="h-4 bg-brand-surface rounded w-3/4" />
              <div className="h-3 bg-brand-surface rounded w-full" />
              <div className="h-3 bg-brand-surface rounded w-2/3" />
            </div>
          ))}
        </div>
      ) : items.length === 0 ? (
        <div className="text-center py-16">
          <div className="w-16 h-16 rounded-full bg-brand-surface mx-auto mb-4 flex items-center justify-center">
            <Bell size={26} className="text-brand-text-tertiary" />
          </div>
          <p className="font-semibold text-brand-text-secondary">{t('Aucune notification')}</p>
          <p className="text-sm text-brand-text-tertiary mt-1">{t("Tu verras ici les annonces de l'équipe")}</p>
        </div>
      ) : (
        <div className="space-y-2.5">
          {items.map(a => {
            const meta = typeMeta[a.type] || typeMeta.info;
            const Icon = meta.icon;
            const unread = !readIds.has(a.id);
            return (
              <button
                key={a.id}
                onClick={() => onSelect(a)}
                className={`w-full text-left bg-white rounded-2xl border p-4 shadow-card hover:shadow-card-hover active:scale-[.99] transition-all ${meta.border} ${unread ? 'ring-1 ring-brand-primary/15' : ''}`}
              >
                <div className="flex gap-3.5">
                  {a.image_url ? (
                    <img src={a.image_url} alt="" loading="lazy" className="w-11 h-11 rounded-xl object-cover flex-shrink-0" />
                  ) : (
                    <div className={`w-11 h-11 rounded-xl flex items-center justify-center flex-shrink-0 ${meta.bg}`}>
                      <Icon size={18} className={meta.color} />
                    </div>
                  )}
                  <div className="flex-1 min-w-0">
                    <div className="flex items-start gap-2 mb-1">
                      {unread && <span className="mt-1.5 w-2 h-2 rounded-full bg-brand-primary flex-shrink-0" />}
                      <p className={`text-sm leading-tight ${unread ? 'font-bold text-brand-text-primary' : 'font-semibold text-brand-text-secondary'}`}>
                        {a.title}
                      </p>
                    </div>
                    <p className={`text-xs leading-relaxed line-clamp-3 ${unread ? 'text-brand-text-secondary' : 'text-brand-text-tertiary'}`}>
                      {a.content}
                    </p>
                    <div className="flex items-center gap-2 mt-2">
                      <span className={`text-[10px] font-bold uppercase tracking-wider ${meta.color}`}>
                        {t(meta.label)}
                      </span>
                      <span className="text-[10px] text-brand-text-tertiary">·</span>
                      <span className="text-[10px] text-brand-text-tertiary">{formatDate(a.created_at)}</span>
                    </div>
                  </div>
                </div>
              </button>
            );
          })}
        </div>
      )}
    </div>
  );
}
