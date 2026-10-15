import React, { useEffect, useState } from 'react';
import { Button } from '@/components/ui/Button';
import { GraduationCap, Flame, Sparkles } from 'lucide-react';
import { createClient } from '@/utils/supabase/client';

export function Navbar() {
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const supabase = createClient();

  useEffect(() => {
    // Vérifier si l'utilisateur est connecté via Supabase
    const checkSession = async () => {
      const { data: { session } } = await supabase.auth.getSession();
      setIsLoggedIn(!!session);
    };
    checkSession();

    // Écouter les changements de connexion
    const { data: authListener } = supabase.auth.onAuthStateChange((event, session) => {
      setIsLoggedIn(!!session);
    });

    return () => {
      authListener.subscription.unsubscribe();
    };
  }, []);

  return (
    <header className="sticky top-0 z-50 bg-surface/90 backdrop-blur-md border-b border-primary/10 transition-colors">
      <div className="max-w-[1400px] mx-auto px-[clamp(1.5rem,5vw,3.5rem)] h-20 flex items-center justify-between">
        {/* LOGO */}
        <a href="/" className="flex items-center gap-3 group">
          <img src="/logo.jpg" alt="ActivEducation Logo" className="w-20 h-20 object-contain transition-transform group-hover:scale-105 mix-blend-multiply" />
          <span className="font-display font-bold text-2xl text-primary tracking-tight hidden lg:block">ActivEducation</span>
        </a>

        {/* NAVIGATION LINKS */}
        <nav className="hidden md:flex items-center gap-2 text-sm font-medium text-text-secondary">
          <a
            href="/"
            className="px-4 py-2 rounded-full hover:bg-primary/5 hover:text-primary transition-all"
          >
            Accueil
          </a>
          <a
            href="/#methodologie"
            className="px-4 py-2 rounded-full hover:bg-primary/5 hover:text-primary transition-all"
          >
            Notre Démarche
          </a>
          <a
            href="/#interventions"
            className="px-4 py-2 rounded-full hover:bg-primary/5 hover:text-primary transition-all"
          >
            Formations
          </a>
          <div className="w-[1px] h-4 bg-border-soft mx-2"></div>
          <a
            href={isLoggedIn ? "/student/cours" : "/auth/login"}
            className="px-4 py-2 rounded-full hover:bg-gold/10 hover:text-gold-dark transition-all flex items-center gap-2"
          >
            <GraduationCap className="w-4 h-4" />
            Mon Espace
          </a>
          <a
            href="/orientation"
            className="ml-2 px-6 py-2.5 rounded-full bg-gradient-to-r from-primary to-blue-500 text-white font-display font-bold text-[15px] shadow-[0_4px_20px_rgba(49,51,221,0.25)] hover:shadow-[0_8px_25px_rgba(49,51,221,0.4)] hover:-translate-y-0.5 transition-all duration-300 flex items-center gap-2 relative overflow-hidden group"
          >
            <div className="absolute inset-0 w-full h-full bg-white/20 -translate-x-full group-hover:translate-x-full transition-transform duration-700 ease-in-out"></div>
            <Sparkles className="w-5 h-5 text-gold animate-pulse" />
            <span className="relative">Passer le Test IA</span>
          </a>
        </nav>

        {/* AUTH ACTIONS OR LOGOUT */}
        <div className="flex items-center gap-3">
          {!isLoggedIn ? (
            <>
              <a href="/auth/login">
                <Button variant="secondary" className="text-xs py-2 px-4 hidden sm:inline-flex">
                  Se connecter
                </Button>
              </a>
              <a href="/auth/register">
                <Button variant="primary" className="text-xs py-2 px-4">
                  S'inscrire
                </Button>
              </a>
            </>
          ) : (
            <button 
              onClick={async () => {
                await supabase.auth.signOut();
                window.location.reload();
              }}
              className="text-xs font-bold text-error hover:underline px-4 py-2"
            >
              Déconnexion
            </button>
          )}
        </div>
      </div>
    </header>
  );
}
