"use client";

import React, { useState } from "react";
import { ArrowLeft, ArrowRight, Lock, Mail, Loader2, AlertCircle } from "lucide-react";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { motion } from "framer-motion";
import { createClient } from "@/utils/supabase/client";

export default function LoginPage() {
  const [isLoading, setIsLoading] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);

  const supabase = createClient();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError(null);

    const { data, error: authError } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (authError) {
      setError("Identifiants incorrects. Veuillez réessayer.");
      setIsLoading(false);
      return;
    }

    // Connexion réussie, le cookie de session est posé.
    localStorage.setItem("activeducation_session", "true");
    const searchParams = new URLSearchParams(window.location.search);
    const redirectUrl = searchParams.get("redirect") || "/student/cours";
    window.location.href = redirectUrl;
  };

  return (
    <div className="min-h-[100dvh] flex flex-col bg-canvas text-text-primary relative overflow-hidden">
      {/* Background Pattern */}
      <div className="absolute inset-0 z-0 pointer-events-none bg-[linear-gradient(to_right,#2947E908_1px,transparent_1px),linear-gradient(to_bottom,#2947E908_1px,transparent_1px)] bg-[size:32px_32px] opacity-70" />

      {/* Simple Header */}
      <header className="w-full p-6 relative z-10 flex items-center justify-between">
        <a href="/" className="flex items-center gap-2 group text-text-secondary hover:text-primary transition-colors text-sm font-medium">
          <ArrowLeft className="w-4 h-4 transition-transform group-hover:-translate-x-1" />
          Retour à l'accueil
        </a>
        
        <div className="flex items-center gap-3">
          <img src="/logo.jpg" alt="ActivEducation" className="w-8 h-8 object-contain mix-blend-multiply" />
          <span className="font-display font-bold text-primary">ActivEducation</span>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 flex items-center justify-center p-6 relative z-10">
        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, ease: [0.33, 1, 0.68, 1] }}
          className="w-full max-w-md bg-surface border border-border-soft rounded-2xl shadow-sm p-8 md:p-10"
        >
          <div className="flex flex-col items-center text-center mb-8">
            <div className="w-12 h-12 rounded-sm bg-primary/10 text-primary flex items-center justify-center mb-4">
              <Lock className="w-6 h-6" />
            </div>
            <h1 className="font-display font-bold text-2xl text-text-primary mb-2">
              Bon retour parmi nous
            </h1>
            <p className="text-text-secondary text-sm">
              Connectez-vous pour accéder à votre espace d'orientation.
            </p>
          </div>

          <form onSubmit={handleLogin} className="flex flex-col gap-5">
            {error && (
              <div className="flex items-center gap-2 p-3 rounded-md bg-error/10 text-error text-sm border border-error/20">
                <AlertCircle className="w-4 h-4 shrink-0" />
                <p>{error}</p>
              </div>
            )}

            <div className="flex flex-col gap-1">
              <Input 
                label="Adresse Email" 
                type="email" 
                placeholder="votre.email@exemple.com" 
                required 
                value={email}
                onChange={(e) => setEmail(e.target.value)}
              />
            </div>

            <div className="flex flex-col gap-1">
              <div className="flex items-center justify-between">
                <label className="text-xs font-bold text-text-primary">Mot de passe</label>
                <a href="#" className="text-xs text-primary hover:underline font-medium">
                  Mot de passe oublié ?
                </a>
              </div>
              <input 
                type="password" 
                placeholder="••••••••" 
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="h-[44px] rounded-sm border border-border-soft bg-surface px-3 text-sm focus:outline-none focus:ring-1 focus:ring-primary focus:border-primary"
              />
            </div>

            <Button 
              variant="primary" 
              type="submit" 
              disabled={isLoading}
              className="w-full mt-2 h-12 gap-2"
            >
              {isLoading ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" /> Connexion en cours...
                </>
              ) : (
                <>
                  Se connecter <ArrowRight className="w-4 h-4" />
                </>
              )}
            </Button>
          </form>

          <div className="mt-8 pt-6 border-t border-border-soft text-center text-sm text-text-secondary">
            Vous n'avez pas encore de compte ?{" "}
            <a href="/auth/register" className="text-primary font-bold hover:underline">
              S'inscrire
            </a>
          </div>
        </motion.div>
      </main>
      
      {/* Footer */}
      <footer className="p-6 text-center text-xs text-text-secondary relative z-10">
        © {new Date().getFullYear()} ActivEducation. Protégé et sécurisé.
      </footer>
    </div>
  );
}
