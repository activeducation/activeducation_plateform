"use client";

import React, { useState } from "react";
import { ArrowLeft, ArrowRight, Mail, KeyRound, Loader2, AlertCircle, CheckCircle2 } from "lucide-react";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { motion } from "framer-motion";
import { createClient } from "@/utils/supabase/client";

export default function ForgotPasswordPage() {
  const [email, setEmail] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  const supabase = createClient();

  const handleResetRequest = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError(null);

    try {
      const redirectUrl = `${window.location.origin}/auth/reset-password`;
      const { error: resetError } = await supabase.auth.resetPasswordForEmail(email.trim(), {
        redirectTo: redirectUrl,
      });

      if (resetError) {
        throw resetError;
      }

      setSuccess(true);
    } catch (err: unknown) {
      console.error("Erreur reset password:", err);
      setError(
        err instanceof Error
          ? err.message
          : "Impossible d'envoyer l'e-mail de réinitialisation. Veuillez réessayer."
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
        <a href="/auth/login" className="flex items-center gap-2 group text-text-secondary hover:text-primary transition-colors text-sm font-medium">
          <ArrowLeft className="w-4 h-4 transition-transform group-hover:-translate-x-1" />
          Retour à la connexion
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
          transition={{ duration: 0.5, ease: "easeOut" }}
          className="w-full max-w-md bg-surface border border-border-soft rounded-2xl shadow-sm p-8 md:p-10"
        >
          <div className="flex flex-col items-center text-center mb-8">
            <div className="w-12 h-12 rounded-sm bg-primary/10 text-primary flex items-center justify-center mb-4">
              <KeyRound className="w-6 h-6" />
            </div>
            <h1 className="font-display font-bold text-2xl text-text-primary mb-2">
              Mot de passe oublié
            </h1>
            <p className="text-text-secondary text-sm">
              Saisissez l'adresse e-mail associée à votre compte ActivEducation pour recevoir un lien de réinitialisation.
            </p>
          </div>

          {success ? (
            <div className="flex flex-col gap-6 text-center">
              <div className="p-4 rounded-xl bg-green-50 border border-green-200 text-green-900 flex flex-col items-center gap-3 text-sm">
                <CheckCircle2 className="w-8 h-8 text-green-600" />
                <p className="font-semibold">E-mail de réinitialisation envoyé !</p>
                <p className="text-xs text-green-800 leading-relaxed">
                  Si un compte correspond à <strong>{email}</strong>, vous recevrez un lien dans quelques instants pour choisir un nouveau mot de passe.
                </p>
              </div>

              <div className="flex flex-col gap-3">
                <Button
                  variant="secondary"
                  onClick={() => setSuccess(false)}
                  className="w-full text-xs"
                >
                  Envoyer à une autre adresse
                </Button>
                <a href="/auth/login">
                  <Button variant="primary" className="w-full gap-2">
                    <ArrowLeft className="w-4 h-4" /> Retour à la connexion
                  </Button>
                </a>
              </div>
            </div>
          ) : (
            <form onSubmit={handleResetRequest} className="flex flex-col gap-5">
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
                  disabled={isLoading}
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
                    <Loader2 className="w-4 h-4 animate-spin" /> Envoi en cours...
                  </>
                ) : (
                  <>
                    <span>Envoyer le lien de réinitialisation</span>
                    <ArrowRight className="w-4 h-4" />
                  </>
                )}
              </Button>

              <div className="mt-4 pt-4 border-t border-border-soft text-center text-xs text-text-secondary">
                Vous vous souvenez de votre mot de passe ?{" "}
                <a href="/auth/login" className="text-primary font-bold hover:underline">
                  Se connecter
                </a>
              </div>
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
