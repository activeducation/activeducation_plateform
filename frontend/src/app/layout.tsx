import type { Metadata } from 'next';
import { AuthProvider } from '@/lib/auth';
import { ThemeProvider } from '@/lib/theme';
import NavGuard from '@/components/layout/nav-guard';
import './globals.css';

export const metadata: Metadata = {
  title: 'ActivEducation',
  description: "Plateforme d'orientation et d'apprentissage",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="fr">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link href="https://fonts.googleapis.com/css2?family=Hanken+Grotesque:wght@400;500;600;700;800;900&display=swap" rel="stylesheet" />
      </head>
      <body>
        <ThemeProvider>
          <AuthProvider>
            <NavGuard>{children}</NavGuard>
          </AuthProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}
