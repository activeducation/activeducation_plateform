import React from "react";
import { RegisterForm } from "@/components/auth/RegisterForm";
import { GraduationCap, ArrowLeft } from "lucide-react";

export default function RegisterPage() {
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
        <div className="w-full max-w-2xl">
          <RegisterForm />
        </div>
      </main>
      
      {/* Footer */}
      <footer className="p-6 text-center text-xs text-text-secondary relative z-10">
        © {new Date().getFullYear()} ActivEducation. Protégé et sécurisé.
      </footer>
    </div>
  );
}
