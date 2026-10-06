import React from "react";
import Link from "next/link";
import { BookOpen, Briefcase, LayoutDashboard, Settings } from "lucide-react";

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen bg-canvas">
      {/* Sidebar */}
      <aside className="w-64 bg-surface border-r border-border-soft flex flex-col hidden md:flex">
        <div className="p-6 border-b border-border-soft flex items-center justify-center">
          <img src="/logo.jpg" alt="ActivEducation" className="w-24 h-24 object-contain mix-blend-multiply" />
          <span className="font-display font-bold text-xl ml-2 text-primary">Admin</span>
        </div>
        
        <nav className="flex-1 p-4 space-y-2">
          <Link href="/admin" className="flex items-center gap-3 px-4 py-3 text-text-primary rounded-xl hover:bg-primary/5 hover:text-primary transition-colors font-bold">
            <LayoutDashboard className="w-5 h-5" /> Dashboard
          </Link>
          <Link href="/admin/cours" className="flex items-center gap-3 px-4 py-3 text-text-secondary rounded-xl hover:bg-primary/5 hover:text-primary transition-colors font-medium">
            <BookOpen className="w-5 h-5" /> Cours & Leçons
          </Link>
          <Link href="/admin/opportunites" className="flex items-center gap-3 px-4 py-3 text-text-secondary rounded-xl hover:bg-primary/5 hover:text-primary transition-colors font-medium">
            <Briefcase className="w-5 h-5" /> Opportunités
          </Link>
        </nav>
        
        <div className="p-4 border-t border-border-soft">
          <Link href="/student" className="flex items-center justify-center gap-2 px-4 py-2 text-sm text-text-secondary hover:text-primary transition-colors">
            Retour à l'app étudiant
          </Link>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 overflow-y-auto">
        <div className="p-8">
          {children}
        </div>
      </main>
    </div>
  );
}
