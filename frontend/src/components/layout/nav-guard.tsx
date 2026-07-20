'use client';
import { usePathname } from 'next/navigation';
import AppShell from './app-shell';

const publicPaths = ['/login', '/register', '/onboarding', '/onboarding/profile', '/onboarding/interests', '/onboarding/goals', '/onboarding/complete'];

export default function NavGuard({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const isPublic = publicPaths.some(p => pathname === p || pathname.startsWith(p));
  if (isPublic) return <>{children}</>;
  return <AppShell>{children}</AppShell>;
}
