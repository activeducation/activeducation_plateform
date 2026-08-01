'use client';
import { usePathname } from 'next/navigation';
import Link from 'next/link';
import { MessageCircleMore } from 'lucide-react';
import { useAuth } from '@/lib/auth';
import {
  Home, School, BookOpen, GraduationCap, User, Sparkles, Briefcase,
} from 'lucide-react';
import SideNav from './side-nav';

const navItems = [
  { href: '/', label: 'Accueil', icon: Home },
  { href: '/orientation', label: 'Orientation', icon: School },
  { href: '/ecoles', label: 'Écoles', icon: GraduationCap },
  { href: '/aida', label: 'AÏDA', icon: Sparkles, fab: true },
  { href: '/cours', label: 'Cours', icon: BookOpen },
  { href: '/opportunities', label: 'Opp.', icon: Briefcase },
  { href: '/profil', label: 'Profil', icon: User },
];

export default function AppShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const { user } = useAuth();
  const isAuthPage = ['/login', '/register'].includes(pathname);
  const isAidaPage = pathname === '/aida';

  // Pages d'auth : pas de shell
  if (isAuthPage) {
    return <main className="min-h-screen">{children}</main>;
  }

  return (
    <div className="min-h-screen flex bg-brand-background">
      {/* Sidebar (tablette + desktop) */}
      <SideNav />

      {/* Zone principale */}
      <div className="flex-1 min-w-0 flex flex-col">
        <main className="flex-1 w-full max-w-2xl md:max-w-4xl xl:max-w-7xl 2xl:max-w-[1400px] mx-auto px-4 md:px-6 lg:px-8 pb-24 md:pb-12 pt-4 md:pt-8">
          {children}
        </main>
      </div>

      {/* Bottom-nav (mobile uniquement) */}
      {user && (
        <nav className="md:hidden fixed bottom-0 left-0 right-0 z-50 bg-white border-t border-brand-border shadow-nav">
          <div className="grid grid-cols-7 items-end max-w-lg mx-auto px-1 pt-1.5 pb-2">
            {navItems.map(item => {
              const active = isActiveFn(pathname, item.href);
              const isFab = 'fab' in item && item.fab;

              if (isFab) {
                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    aria-label={item.label}
                    className="flex flex-col items-center gap-0.5 -mt-4"
                  >
                    <span
                      className="w-14 h-14 rounded-full grid place-items-center text-white transition-transform active:scale-95"
                      style={{
                        background: 'linear-gradient(135deg, var(--color-brand-primary) 0%, var(--color-brand-primary-light) 100%)',
                        boxShadow: '0 8px 20px rgba(49, 51, 221, 0.35)',
                      }}
                    >
                      <item.icon size={26} strokeWidth={2.2} />
                    </span>
                    <span
                      className="text-[10px] font-semibold leading-tight"
                      style={{ color: active ? 'var(--color-brand-primary-dark)' : 'var(--color-brand-text-tertiary)' }}
                    >
                      {item.label}
                    </span>
                  </Link>
                );
              }

              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className="flex flex-col items-center gap-0.5 py-1.5 px-1 rounded-2xl transition-all duration-200"
                  style={{ backgroundColor: active ? 'var(--color-brand-primary-surface)' : 'transparent' }}
                >
                  <item.icon
                    size={22}
                    color={active ? 'var(--color-brand-primary-dark)' : 'var(--color-brand-text-tertiary)'}
                  />
                  <span
                    className="text-[10.5px] leading-tight"
                    style={{
                      color: active ? 'var(--color-brand-primary-dark)' : 'var(--color-brand-text-tertiary)',
                      fontWeight: active ? 600 : 400,
                    }}
                  >
                    {item.label}
                  </span>
                </Link>
              );
            })}
          </div>
        </nav>
      )}

      {/* AÏDA FAB (mobile : bottom-right au-dessus de la nav, desktop : bottom-right de la zone contenu) */}
      {user && !isAidaPage && (
        <Link
          href="/aida"
          aria-label="Discuter avec AÏDA"
          className="fixed z-50 w-14 h-14 rounded-2xl bg-brand-primary flex items-center justify-center text-white shadow-fab hover:bg-brand-primary-light transition-all duration-200 active:scale-95 bottom-24 right-4 md:bottom-8 md:right-8"
          style={{ boxShadow: '0 6px 20px rgba(49,51,221,0.35)' }}
        >
          <MessageCircleMore size={26} />
        </Link>
      )}
    </div>
  );
}

function isActiveFn(pathname: string, href: string): boolean {
  if (href === '/') return pathname === '/';
  return pathname.startsWith(href);
}
