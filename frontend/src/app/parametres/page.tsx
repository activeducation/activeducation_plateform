'use client';
import { useState } from 'react';
import { useAuth } from '@/lib/auth';
import { useTheme } from '@/lib/theme';
import { useRouter } from 'next/navigation';
import { ArrowLeft, User, Bell, Moon, Globe, ChevronRight, LogOut, Shield, Check } from 'lucide-react';

export default function ParametresPage() {
  const { user, logout } = useAuth();
  const { darkMode, setDarkMode, lang, setLang, t } = useTheme();
  const router = useRouter();
  const [notifications, setNotifications] = useState(true);
  const [showLangPicker, setShowLangPicker] = useState(false);

  const langLabel = lang === 'fr' ? 'Français' : 'English';

  const sections = [
    {
      title: t('settings.account'),
      items: [
        { icon: User, label: 'Nom', value: `${user?.first_name || ''} ${user?.last_name || ''}`.trim() || '—' },
        { icon: Shield, label: 'Email', value: user?.email || '—' },
      ],
    },
    {
      title: t('settings.preferences'),
      items: [
        { icon: Bell, label: t('settings.notifications'), toggle: true, checked: notifications, onChange: setNotifications },
        { icon: Moon, label: t('settings.dark_mode'), toggle: true, checked: darkMode, onChange: setDarkMode },
        { icon: Globe, label: t('settings.language'), value: langLabel, onClick: () => setShowLangPicker(true) },
      ],
    },
  ];

  return (
    <div className="min-h-screen bg-brand-background pb-8">
      <div className="bg-gradient-hero px-6 pt-12 pb-8">
        <button onClick={() => router.back()} className="w-9 h-9 rounded-full bg-white/10 flex items-center justify-center mb-5">
          <ArrowLeft size={18} className="text-white" />
        </button>
        <h1 className="text-[28px] font-extrabold text-white tracking-tight">{t('settings.title')}</h1>
        <p className="text-white/70 text-sm mt-1.5">Gère ton compte et tes préférences</p>
      </div>

      <div className="px-4 -mt-4 space-y-4">
        {sections.map((section) => (
          <div key={section.title} className="bg-white rounded-2xl border border-brand-border shadow-card overflow-hidden">
            <div className="px-4 pt-4 pb-1">
              <p className="text-xs font-bold text-brand-text-tertiary uppercase tracking-wider">{section.title}</p>
            </div>
            {section.items.map((item: any, i) => (
              <div key={i} onClick={item.onClick}
                className={`flex items-center gap-3 px-4 py-3.5 border-b border-brand-border last:border-0 ${item.onClick ? 'cursor-pointer hover:bg-brand-surface transition-colors' : ''}`}>
                <div className="w-8 h-8 rounded-lg bg-brand-surface flex items-center justify-center flex-shrink-0">
                  <item.icon size={15} className="text-brand-text-secondary" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-semibold text-brand-text-primary">{item.label}</p>
                  {'value' in item && item.value && (
                    <p className="text-xs text-brand-text-tertiary truncate">{item.value}</p>
                  )}
                </div>
                {'toggle' in item && item.toggle ? (
                  <button onClick={(e) => { e.stopPropagation(); item.onChange(!item.checked); }}
                    className={`w-11 h-6 rounded-full transition-colors relative ${item.checked ? 'bg-brand-primary' : 'bg-brand-border'}`}>
                    <div className={`w-4 h-4 rounded-full bg-white absolute top-1 transition-transform shadow-sm ${item.checked ? 'translate-x-6' : 'translate-x-1'}`} />
                  </button>
                ) : (
                  <ChevronRight size={15} className="text-brand-text-tertiary flex-shrink-0" />
                )}
              </div>
            ))}
          </div>
        ))}

        <button onClick={() => { logout(); }}
          className="w-full flex items-center justify-center gap-2 h-11 rounded-xl border border-red-200 bg-red-50 text-red-600 font-semibold text-sm hover:bg-red-100 transition-colors">
          <LogOut size={16} />
          {t('settings.logout')}
        </button>
      </div>

      {/* Language picker modal */}
      {showLangPicker && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40" onClick={() => setShowLangPicker(false)}>
          <div className="bg-white rounded-2xl p-5 w-full max-w-sm shadow-xl animate-scale-in" onClick={e => e.stopPropagation()}>
            <h3 className="font-bold text-brand-text-primary text-sm mb-3">{t('settings.language')}</h3>
            <div className="space-y-1">
              {([['fr', 'Français'], ['en', 'English']] as const).map(([code, label]) => (
                <button key={code} onClick={() => { setLang(code); setShowLangPicker(false); }}
                  className={`w-full flex items-center justify-between px-4 py-3 rounded-xl text-sm font-semibold transition-colors ${
                    lang === code ? 'bg-brand-primary/10 text-brand-primary' : 'text-brand-text-primary hover:bg-brand-surface'
                  }`}>
                  {label}
                  {lang === code && <Check size={16} className="text-brand-primary" />}
                </button>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
