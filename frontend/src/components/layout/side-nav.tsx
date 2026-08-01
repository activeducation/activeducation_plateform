'use client';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useAuth } from '@/lib/auth';
import {
  Home, School, BookOpen, Users, GraduationCap, User, Sparkles, Briefcase,
} from 'lucide-react';

const navItems = [
  { href: '/', label: 'Accueil', icon: Home },
  { href: '/orientation', label: 'Orientation', icon: School },
  { href: '/ecoles', label: 'Écoles', icon: GraduationCap },
  { href: '/aida', label: 'AÏDA', icon: Sparkles, accent: true },
  { href: '/cours', label: 'Cours', icon: BookOpen },
  { href: '/opportunities', label: 'Opportunités', icon: Briefcase },
  { href: '/mentors', label: 'Mentors', icon: Users },
  { href: '/profil', label: 'Profil', icon: User },
];

export default function SideNav() {
  const { user } = useAuth();
  const pathname = usePathname();

  if (!user) return null;

  const isActive = (href: string) => {
    if (href === '/') return pathname === '/';
    return pathname.startsWith(href);
  };

  return (
    <aside className="hidden md:flex md:w-[260px] lg:w-[320px] xl:w-[380px] md:flex-shrink-0 md:sticky md:top-0 md:h-screen md:flex-col md:border-r md:border-brand-border md:bg-white">
      {/* Logo / brand */}
      <div className="px-6 pt-8 pb-6">
        <Link href="/" className="flex items-center gap-2.5">
          <div className="w-10 h-10 rounded-xl overflow-hidden shadow-card bg-white">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src="/logo.jpeg"
              alt="ActivEducation"
              width={40}
              height={40}
              className="w-10 h-10 object-contain"
            />
          </div>
          <div>
            <p className="font-extrabold text-base leading-none">
              <span style={{ color: 'var(--color-brand-primary)' }}>ACTIV</span>
              <span style={{ color: '#FAA100' }}>EDUCATION</span>
            </p>
            <p className="text-[10px] text-brand-text-tertiary mt-0.5">Orientation & apprentissage</p>
          </div>
        </Link>
      </div>

      {/* Nav items */}
      <nav className="flex-1 px-4 space-y-1">
        {navItems.map(item => {
          const active = isActive(item.href);
          const accent = 'accent' in item && item.accent;
          if (accent) {
            return (
              <Link
                key={item.href}
                href={item.href}
                className="group flex items-center gap-3 px-3 py-2.5 rounded-xl mt-3 text-white transition-all"
                style={{
                  background: 'linear-gradient(135deg, var(--color-brand-primary) 0%, var(--color-brand-primary-light) 100%)',
                  boxShadow: '0 6px 16px rgba(49,51,221,0.25)',
                }}
              >
                <span className="w-9 h-9 rounded-lg bg-white/20 grid place-items-center">
                  <item.icon size={18} strokeWidth={2.2} />
                </span>
                <span className="font-semibold text-sm">{item.label}</span>
                <span className="ml-auto text-[10px] font-bold bg-white/20 px-1.5 py-0.5 rounded-md">IA</span>
              </Link>
            );
          }
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex items-center gap-3 px-3 py-2.5 rounded-xl transition-all ${
                active
                  ? 'bg-brand-primary-surface text-brand-primary-dark'
                  : 'text-brand-text-secondary hover:bg-brand-surface hover:text-brand-text-primary'
              }`}
            >
              <item.icon
                size={20}
                color={active ? 'var(--color-brand-primary-dark)' : 'currentColor'}
                strokeWidth={active ? 2.2 : 1.8}
              />
              <span className={`text-sm ${active ? 'font-bold' : 'font-medium'}`}>{item.label}</span>
              {active && <span className="ml-auto w-1.5 h-1.5 rounded-full bg-brand-primary" />}
            </Link>
          );
        })}
      </nav>

      {/* Footer */}
      <div className="px-6 py-5 border-t border-brand-border">
        <p className="text-[10px] text-brand-text-tertiary leading-relaxed">
          © 2026 ActivEducation<br />Tous droits réservés
        </p>
      </div>
    </aside>
  );
}
