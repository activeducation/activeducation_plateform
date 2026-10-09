"use client";

import React from "react";
import Link from "next/link";
import { BookOpen, Briefcase, LayoutDashboard, Settings, Map, Users } from "lucide-react";
import { usePathname } from "next/navigation";

export default function AdminLayoutClient({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();

  const navLinks = [
    { href: "/admin", label: "Dashboard", icon: LayoutDashboard, exact: true },
    { href: "/admin/utilisateurs", label: "Utilisateurs", icon: Users },
    { href: "/admin/cours", label: "Cours & Leçons", icon: BookOpen },
    { href: "/admin/opportunites", label: "Opportunités", icon: Briefcase },
    { href: "/admin/explorer", label: "Explorateur", icon: Map },
  ];

  return (
    <div className="flex min-h-screen bg-canvas">
      {/* Sidebar */}
      <aside className="w-64 bg-surface border-r border-border-soft flex flex-col hidden md:flex">
        <div className="p-6 border-b border-border-soft flex items-center justify-center">
          <img src="/logo.jpg" alt="ActivEducation" className="w-24 h-24 object-contain mix-blend-multiply" />
          <span className="font-display font-bold text-xl ml-2 text-primary">Admin</span>
        </div>
        
        <nav className="flex-1 p-4 space-y-2">
          {navLinks.map((link) => {
            const Icon = link.icon;
            const isActive = link.exact ? pathname === link.href : pathname.startsWith(link.href);
            
            return (
              <Link 
                key={link.href} 
                href={link.href} 
                className={`flex items-center gap-3 px-4 py-3 rounded-xl transition-colors font-medium ${
                  isActive 
                    ? "bg-primary/10 text-primary font-bold shadow-sm" 
                    : "text-text-secondary hover:bg-primary/5 hover:text-primary"
                }`}
              >
                <Icon className="w-5 h-5" /> {link.label}
              </Link>
            );
          })}
        </nav>
        
        <div className="p-4 border-t border-border-soft">
          <Link href="/student" className="flex items-center justify-center gap-2 px-4 py-2 text-sm text-text-secondary hover:text-primary transition-colors font-medium">
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
