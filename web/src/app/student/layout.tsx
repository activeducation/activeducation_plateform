"use client";

import React from "react";
import { 
  Home, 
  Compass, 
  Map, 
  Briefcase, 
  User, 
  Target,
  BookOpen
} from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { AidaChatWidget } from "@/components/AidaChatWidget";

export default function StudentLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const getDesktopLinkClass = (path: string) => {
    // If the path is exact (for /student) or starts with the path (for sub-routes like /student/explorer/...)
    const isActive = path === "/student" ? pathname === "/student" : pathname.startsWith(path);
    return isActive 
      ? "flex items-center gap-3 px-4 py-3 rounded-md bg-primary/10 text-primary font-bold text-sm"
      : "flex items-center gap-3 px-4 py-3 rounded-md text-text-secondary hover:bg-surface-alt hover:text-text-primary font-medium text-sm transition-colors";
  };

  const getMobileLinkClass = (path: string) => {
    const isActive = path === "/student" ? pathname === "/student" : pathname.startsWith(path);
    return isActive
      ? "flex flex-col items-center gap-1 text-primary"
      : "flex flex-col items-center gap-1 text-text-secondary";
  };

  return (
    <div className="min-h-[100dvh] bg-canvas text-text-primary flex flex-col md:flex-row relative">
      
      {/* FLOATING TOP RIGHT AVATAR */}
      <div className="fixed top-4 right-4 md:top-6 md:right-8 z-50">
        <Link href="/student/profil" className="block w-10 h-10 md:w-12 md:h-12 rounded-full border-2 border-white shadow-md overflow-hidden hover:scale-105 transition-transform bg-surface">
          <User aria-label="Mon profil" className="w-full h-full p-2" />
        </Link>
      </div>

      {/* DESKTOP SIDEBAR */}
      <aside className="hidden md:flex flex-col w-64 bg-surface border-r border-border-soft sticky top-0 h-[100dvh]">
        <div className="p-6 flex flex-col items-center gap-2 border-b border-border-soft">
          <img src="/logo.jpg" alt="ActivEducation" className="w-24 h-24 object-contain mix-blend-multiply" />
          <span className="font-display font-bold text-2xl text-primary tracking-tight text-center leading-none">ActivEducation</span>
        </div>
        
        <nav className="flex-1 p-4 flex flex-col gap-2">
          <Link href="/student" className={getDesktopLinkClass("/student")}>
            <Home className="w-5 h-5" />
            Accueil
          </Link>
          <Link href="/student/explorer" className={getDesktopLinkClass("/student/explorer")}>
            <Compass className="w-5 h-5" />
            Explorer
          </Link>
          <Link href="/student/cours" className={getDesktopLinkClass("/student/cours")}>
            <BookOpen className="w-5 h-5" />
            Académie
          </Link>
          <Link href="/student/parcours" className={getDesktopLinkClass("/student/parcours")}>
            <Map className="w-5 h-5" />
            Mon parcours
          </Link>
          <Link href="/student/orientation" className={getDesktopLinkClass("/student/orientation")}>
            <Target className="w-5 h-5" />
            Orientation AÏDA
          </Link>
          <Link href="/student/opportunites" className={getDesktopLinkClass("/student/opportunites")}>
            <Briefcase className="w-5 h-5" />
            Opportunités
          </Link>
          <Link href="/student/profil" className={getDesktopLinkClass("/student/profil")}>
            <User className="w-5 h-5" />
            Mon profil
          </Link>
        </nav>
      </aside>

      {/* MAIN CONTENT AREA */}
      <main className="flex-1 overflow-y-auto pb-24 md:pb-0">
        <div className="max-w-5xl mx-auto p-4 md:p-8 pt-16 md:pt-8">
          {children}
        </div>
      </main>

      {/* MOBILE BOTTOM NAV */}
      <nav className="md:hidden fixed bottom-0 left-0 w-full bg-surface border-t border-border-soft flex items-center justify-around p-3 z-50">
        <Link href="/student" className={getMobileLinkClass("/student")}>
          <Home className="w-5 h-5" />
          <span className={`text-[10px] ${pathname === "/student" ? "font-bold" : "font-medium"}`}>Accueil</span>
        </Link>
        <Link href="/student/explorer" className={getMobileLinkClass("/student/explorer")}>
          <Compass className="w-5 h-5" />
          <span className={`text-[10px] ${pathname.startsWith("/student/explorer") ? "font-bold" : "font-medium"}`}>Explorer</span>
        </Link>
        <Link href="/student/cours" className={getMobileLinkClass("/student/cours")}>
          <BookOpen className="w-5 h-5" />
          <span className={`text-[10px] ${pathname.startsWith("/student/cours") ? "font-bold" : "font-medium"}`}>Académie</span>
        </Link>
        <Link href="/student/parcours" className={getMobileLinkClass("/student/parcours")}>
          <Map className="w-5 h-5" />
          <span className={`text-[10px] ${pathname.startsWith("/student/parcours") ? "font-bold" : "font-medium"}`}>Parcours</span>
        </Link>
        <Link href="/student/orientation" className={getMobileLinkClass("/student/orientation")}>
          <Target className="w-5 h-5" />
          <span className={`text-[10px] ${pathname.startsWith("/student/orientation") ? "font-bold" : "font-medium"}`}>AÏDA</span>
        </Link>
        <Link href="/student/profil" className={getMobileLinkClass("/student/profil")}>
          <User className="w-5 h-5" />
          <span className={`text-[10px] ${pathname.startsWith("/student/profil") ? "font-bold" : "font-medium"}`}>Profil</span>
        </Link>
      </nav>

      {/* AÏDA CHAT WIDGET */}
      <AidaChatWidget />
      
    </div>
  );
}
