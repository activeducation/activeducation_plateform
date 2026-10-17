"use client";

import React, { useState, useEffect } from "react";
import { ArrowRight, Lock, Loader2, AlertCircle, CheckCircle2 } from "lucide-react";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { PasswordInput } from "@/components/auth/PasswordInput";
import { motion } from "framer-motion";
import { createClient } from "@/utils/supabase/client";

export default function ResetPasswordPage() {
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const [isSessionReady, setIsSessionReady] = useState(false);

  const supabase = createClient();

  useEffect(() => {
    // Si un code PKCE est présent dans l'URL
    const code = typeof window !== "undefined" ? new URLSearchParams(window.location.search).get("code") : null;
    if (code) {
      supabase.auth.exchangeCodeForSession(code).then(({ data, error }) => {
        if (!error && data.session) {
          setIsSessionReady(true);
        }
      });
    }

    // Écouter l'événement de récupération de session Supabase
    const { data: authListener } = supabase.auth.onAuthStateChange(async (event, session) => {
      if (event === "PASSWORD_RECOVERY" || session) {
        setIsSessionReady(true);
      }
    });

    supabase.auth.getSession().then(({ data: { session } }) => {
      if (session) {
        setIsSessionReady(true);
      }
    });

    return () => {
      authListener.subscription.unsubscribe();
    };
  }, [supabase]);

  const handleUpdatePassword = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (password.length < 6) {
      setError("Le mot de passe doit comporter au moins 6 caractères.");
      return;
    }

    if (password !== confirmPassword) {
      setError("Les mots de passe ne correspondent pas.");
      return;
    }

    setIsLoading(true);

    try {
      const { error: updateError } = await supabase.auth.updateUser({
        password,
      });

      if (updateError) {
        throw updateError;
      }

      setSuccess(true);
      setTimeout(() => {
        window.location.href = "/auth/login";
      }, 2500);
    } catch (err: unknown) {
      console.error("Erreur mise à jour mot de passe:", err);
      setError(
        err instanceof Error
          ? err.message
          : "Impossible de modifier le mot de passe. Le lien a peut-être expiré."
      );
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-[100dvh] flex flex-col bg-canvas text-text-primary relative overflow-hidden">
      {/* Background Pattern */}
      <div className="absolute inset-0 z-0 pointer-events-none bg-[linear-gradient(to_right,#2947E908_1px,transparent_1px),linear-gradient(to_bottom,#2947E908_1px,transparent_1px)] bg-[size:32px_32px] opacity-70" />

      {/* Header */}
      <header className="w-full p-6 relative z-10 flex items-center justify-between">
        <a href="/auth/login" className="text-text-secondary hover:text-primary transition-colors text-sm font-medium">
          ActivEducation
        </a>
        <div className="flex items-center gap-3">
          <img src="/logo.jpg" alt="ActivEducation" className="w-8 h-8 object-contain mix-blend-multiply" />
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 flex items-center justify-center p-6 relative z-10">
        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, ease: "easeOut" }}
          className="w-full max-w-md bg-surface border border-border-soft rounded-2xl shadow-sm p-8 md:p-10"
        >
          <div className="flex flex-col items-center text-center mb-8">
            <div className="w-12 h-12 rounded-sm bg-primary/10 text-primary flex items-center justify-center mb-4">
              <Lock className="w-6 h-6" />
            </div>
            <h1 className="font-display font-bold text-2xl text-text-primary mb-2">
              Nouveau mot de passe
            </h1>
            <p className="text-text-secondary text-sm">
              Définissez un nouveau mot de passe sécurisé pour votre compte.
            </p>
          </div>

          {success ? (
            <div className="flex flex-col gap-5 text-center">
              <div className="p-4 rounded-xl bg-green-50 border border-green-200 text-green-900 flex flex-col items-center gap-3 text-sm">
                <CheckCircle2 className="w-8 h-8 text-green-600" />
                <p className="font-semibold">Mot de passe réinitialisé avec succès !</p>
                <p className="text-xs text-green-800 leading-relaxed">
                  Redirection vers la page de connexion en cours...
                </p>
              </div>

              <a href="/auth/login">
                <Button variant="primary" className="w-full gap-2">
                  Se connecter immédiatement <ArrowRight className="w-4 h-4" />
                </Button>
              </a>
            </div>
          ) : (
            <form onSubmit={handleUpdatePassword} className="flex flex-col gap-5">
              {error && (
                <div className="flex items-center gap-2 p-3 rounded-md bg-error/10 text-error text-sm border border-error/20">
                  <AlertCircle className="w-4 h-4 shrink-0" />
                  <p>{error}</p>
                </div>
              )}

              <div className="flex flex-col gap-1">
                <PasswordInput 
                  label="Nouveau mot de passe" 
                  placeholder="Minimum 6 caractères" 
                  required 
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  disabled={isLoading}
                  showStrength
                />
              </div>

              <div className="flex flex-col gap-1">
                <PasswordInput 
                  label="Confirmer le nouveau mot de passe" 
                  placeholder="••••••••" 
                  required 
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  disabled={isLoading}
                  error={confirmPassword && password !== confirmPassword ? "Les deux mots de passe ne correspondent pas" : undefined}
                />
              </div>

              <Button 
                variant="primary" 
                type="submit" 
                disabled={isLoading}
                className="w-full mt-2 h-12 gap-2 shadow-sm"
              >
                {isLoading ? (
                  <>
                    <Loader2 className="w-4 h-4 animate-spin" /> Enregistrement...
                  </>
                ) : (
                  <>
                    <span>Mettre à jour le mot de passe</span>
                    <ArrowRight className="w-4 h-4" />
                  </>
                )}
              </Button>
            </form>
          )}
        </motion.div>
      </main>
      
      {/* Footer */}
      <footer className="p-6 text-center text-xs text-text-secondary relative z-10">
        © {new Date().getFullYear()} ActivEducation. Protégé et sécurisé.
      </footer>
    </div>
  );
}
