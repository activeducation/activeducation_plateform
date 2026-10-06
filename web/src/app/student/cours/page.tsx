"use client";

import React, { useState } from "react";
import { 
  Flame, 
  Hexagon, 
  Lock, 
  Play, 
  Check, 
  Star, 
  X,
  Zap,
  Brain,
  Users,
  Monitor,
  Briefcase,
  Search,
  BookOpen,
  Award,
  Medal,
  Download,
  WifiOff,
  CloudDownload,
  Trophy
} from "lucide-react";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Input } from "@/components/ui/Input";
import { useSound } from "@/hooks/useSound";

// Mock data for multiple parallel courses
const myCourses = [
  {
    id: "soft-skills",
    title: "Soft Skills & Leadership",
    icon: Users,
    color: "from-blue-500 to-primary",
    progress: 40,
    levels: [
      { id: 11, title: "Découverte de Soi", desc: "Comprendre ses valeurs", status: "done", stars: 3 },
      { id: 12, title: "L'écoute active", desc: "Mindset", status: "done", stars: 2 },
      { id: 13, title: "Parler en public", desc: "Gérer le stress", status: "current", stars: 0 },
      { id: 14, title: "Travail en équipe", desc: "Synergie", status: "locked", stars: 0 },
      { id: 15, title: "Leadership 101", desc: "Inspirer les autres", status: "locked", stars: 0 },
    ]
  },
  {
    id: "tech-101",
    title: "Initiation à la Tech",
    icon: Monitor,
    color: "from-purple-500 to-purple-700",
    progress: 15,
    levels: [
      { id: 21, title: "C'est quoi un algorithme ?", desc: "Les bases", status: "done", stars: 3 },
      { id: 22, title: "Le monde du Web", desc: "Internet expliqué", status: "current", stars: 0 },
      { id: 23, title: "No-Code", desc: "Créer sans coder", status: "locked", stars: 0 },
      { id: 24, title: "L'IA au quotidien", desc: "Utiliser ChatGPT", status: "locked", stars: 0 },
    ]
  },
  {
    id: "insertion",
    title: "Insertion Pro",
    icon: Briefcase,
    color: "from-gold to-gold-dark",
    progress: 80,
    levels: [
      { id: 31, title: "Bilan de compétences", desc: "Savoir ce qu'on vaut", status: "done", stars: 3 },
      { id: 32, title: "Le CV Parfait", desc: "Format et contenu", status: "done", stars: 3 },
      { id: 33, title: "Lettre de motivation", desc: "Convaincre", status: "done", stars: 2 },
      { id: 34, title: "L'entretien final", desc: "Questions pièges", status: "current", stars: 0 },
    ]
  }
];

const catalogCourses = [
  { id: "c1", title: "Anglais pour l'entretien", category: "Langues", difficulty: "Débutant", duration: "10 leçons", image: "https://images.unsplash.com/photo-1546410531-bb4caa6b424d?auto=format&fit=crop&w=600&q=80", downloaded: false },
  { id: "c2", title: "Bases du Marketing Digital", category: "Business", difficulty: "Intermédiaire", duration: "15 leçons", image: "https://images.unsplash.com/photo-1432888498266-38ffec3eaf0a?auto=format&fit=crop&w=600&q=80", downloaded: true },
  { id: "c3", title: "Excel de A à Z", category: "Outils", difficulty: "Tous niveaux", duration: "20 leçons", image: "https://images.unsplash.com/photo-1551288049-bebda4e38f71?auto=format&fit=crop&w=600&q=80", downloaded: false },
  { id: "c4", title: "Gestion du temps", category: "Productivité", difficulty: "Débutant", duration: "5 leçons", image: "https://images.unsplash.com/photo-1499951360447-b19be8fe80f5?auto=format&fit=crop&w=600&q=80", downloaded: false },
];

const defaultBadges = [
  { id: "b1", title: "Premier pas", desc: "A terminé sa première leçon", icon: Star, color: "text-blue-500", bg: "bg-blue-100", unlocked: true },
  { id: "b2", title: "Régulier", desc: "3 jours de suite", icon: Flame, color: "text-error", bg: "bg-error/10", unlocked: false },
  { id: "b3", title: "Maître du CV", desc: "Terminer le parcours Insertion", icon: Medal, color: "text-gold-dark", bg: "bg-gold/20", unlocked: false },
  { id: "b4", title: "Super Cerveau", desc: "Gagner 1000 cristaux", icon: Brain, color: "text-purple-500", bg: "bg-purple-100", unlocked: false },
];

export default function CoursPage() {
  const [activeTab, setActiveTab] = React.useState<"bureau" | "catalogue" | "recompenses">("bureau");
  
  const [courses, setCourses] = React.useState(myCourses);
  const [selectedCourseId, setSelectedCourseId] = React.useState("soft-skills");
  
  const [streak, setStreak] = React.useState(0);
  const [crystals, setCrystals] = React.useState(0);
  
  const [leaderboard, setLeaderboard] = React.useState<any[]>([]);
  const [badges, setBadges] = React.useState(defaultBadges);

  const [activeLesson, setActiveLesson] = React.useState<number | null>(null);
  const [showCelebration, setShowCelebration] = React.useState(false);

  const [userName, setUserName] = React.useState("Étudiant");
  const [isLoadingUser, setIsLoadingUser] = React.useState(true);

  // Offline status simulation
  const [isOffline, setIsOffline] = React.useState(false);
  const playSound = useSound();

  React.useEffect(() => {
    // Fetch user profile from Database
    const fetchUserProfile = async () => {
      try {
        const res = await fetch('/api/user');
        if (res.ok) {
          const userData = await res.json();
          setUserName(userData.fullName || userData.email.split('@')[0]);
          
          const xp = userData.xpPoints || 0;
          const userStreak = userData.level || 1;
          
          setCrystals(xp);
          setStreak(userStreak);

          // Update badges dynamically based on real XP & Level
          setBadges(prev => prev.map(b => {
            if (b.id === "b2" && userStreak >= 3) return { ...b, unlocked: true };
            if (b.id === "b4" && xp >= 1000) return { ...b, unlocked: true };
            return b;
          }));
        }
      } catch (error) {
        console.error("Failed to fetch user");
      } finally {
        setIsLoadingUser(false);
      }
    };

    const fetchLeaderboard = async () => {
      try {
        const res = await fetch('/api/user/leaderboard');
        if (res.ok) {
          const data = await res.json();
          setLeaderboard(data);
        }
      } catch (e) {
        console.error("Leaderboard fetch error", e);
      }
    };
    
    fetchUserProfile();
    fetchLeaderboard();

    // Listen to network status
    const handleOffline = () => setIsOffline(true);
    const handleOnline = () => setIsOffline(false);
    
    window.addEventListener('offline', handleOffline);
    window.addEventListener('online', handleOnline);
    
    // Check initial state
    setIsOffline(!navigator.onLine);
    
    return () => {
      window.removeEventListener('offline', handleOffline);
      window.removeEventListener('online', handleOnline);
    };
  }, []);

  const selectedCourse = courses.find(c => c.id === selectedCourseId)!;

  const getOffsetClass = (index: number) => {
    const pattern = [0, 1, 2, 1, 0, -1, -2, -1];
    const offset = pattern[index % pattern.length];
    
    if (offset === 0) return "translate-x-0";
    if (offset === 1) return "translate-x-12";
    if (offset === 2) return "translate-x-24";
    if (offset === -1) return "-translate-x-12";
    if (offset === -2) return "-translate-x-24";
    return "";
  };

  const completeActiveLesson = async () => {
    if (activeLesson !== null) {
      playSound('celebration');
      setCourses(prevCourses => {
        const newCourses = [...prevCourses];
        const courseIndex = newCourses.findIndex(c => c.id === selectedCourseId);
        
        if (courseIndex !== -1) {
          const levels = [...newCourses[courseIndex].levels];
          const lessonIndex = levels.findIndex(l => l.id === activeLesson);
          
          if (lessonIndex !== -1) {
            levels[lessonIndex].status = "done";
            levels[lessonIndex].stars = 3;
            
            if (lessonIndex + 1 < levels.length) {
              levels[lessonIndex + 1].status = "current";
            }
            
            // Mettre à jour la progression %
            const doneCount = levels.filter(l => l.status === "done").length;
            newCourses[courseIndex].progress = Math.round((doneCount / levels.length) * 100);
            newCourses[courseIndex].levels = levels;
          }
        }
        return newCourses;
      });
      
      const xpGained = 50;

      // Update XP in the Database
      try {
        const res = await fetch('/api/user/xp', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ xpToAdd: xpGained })
        });
        if (res.ok) {
          const data = await res.json();
          setCrystals(data.xpPoints);
          setStreak(data.level);
        } else {
          // Fallback UI update if error
          setCrystals(c => c + xpGained);
        }
      } catch (err) {
        setCrystals(c => c + xpGained);
      }

      setActiveLesson(null);
      setShowCelebration(true);
      
      setTimeout(() => {
        setShowCelebration(false);
      }, 4000);
    }
  };

  return (
    <div className="relative min-h-[calc(100vh-100px)] w-full max-w-5xl mx-auto pb-24">
      
      {/* OFFLINE INDICATOR */}
      {isOffline && (
        <div className="w-full bg-surface-alt border-b border-border-strong px-4 py-2 flex items-center justify-center gap-2 text-sm font-bold text-text-secondary animate-fade-in">
          <WifiOff className="w-4 h-4" /> Mode hors-ligne activé. Vos cours téléchargés restent accessibles.
        </div>
      )}

      {/* GAMIFICATION HEADER (Sticky) */}
      <div className={`sticky top-0 z-40 w-full bg-canvas/90 backdrop-blur-md p-4 flex flex-col md:flex-row justify-between items-center border-b border-border-soft mb-6 ${isOffline ? "" : "rounded-b-2xl"} gap-4`}>
        
        {/* TABS */}
        <div className="flex bg-surface-alt p-1 rounded-full w-full md:w-auto">
          <button 
            onClick={() => setActiveTab("bureau")}
            className={`flex-1 md:flex-none flex items-center justify-center gap-2 px-4 py-2 rounded-full text-sm font-bold transition-colors ${activeTab === "bureau" ? "bg-white text-primary shadow-sm" : "text-text-secondary hover:text-text-primary"}`}
          >
            <BookOpen className="w-4 h-4" /> Mon Bureau
          </button>
          <button 
            onClick={() => setActiveTab("catalogue")}
            className={`flex-1 md:flex-none flex items-center justify-center gap-2 px-4 py-2 rounded-full text-sm font-bold transition-colors ${activeTab === "catalogue" ? "bg-white text-primary shadow-sm" : "text-text-secondary hover:text-text-primary"}`}
          >
            <Search className="w-4 h-4" /> Catalogue
          </button>
          <button 
            onClick={() => setActiveTab("recompenses")}
            className={`flex-1 md:flex-none flex items-center justify-center gap-2 px-4 py-2 rounded-full text-sm font-bold transition-colors ${activeTab === "recompenses" ? "bg-white text-primary shadow-sm" : "text-text-secondary hover:text-text-primary"}`}
          >
            <Award className="w-4 h-4" /> Certificats
          </button>
        </div>

        <div className="flex gap-4">
          <div className="flex items-center gap-2 bg-error/10 px-3 py-1.5 rounded-full text-error font-bold text-sm">
            <Flame className="w-4 h-4 fill-error" /> {streak} jours
          </div>
          
          <div className="flex items-center gap-2 bg-gold/10 px-3 py-1.5 rounded-full text-gold-dark font-bold text-sm">
            <Hexagon className="w-4 h-4 fill-gold-dark" /> {crystals}
          </div>
        </div>
      </div>

      {/* --- TAB: MON BUREAU (The Winding Path) --- */}
      {activeTab === "bureau" && (
        <div className="w-full animate-fade-in flex flex-col items-center">
          {/* MES COURS EN PARALLÈLE (Horizontal Scroll) */}
          <div className="w-full max-w-4xl px-4 mb-8">
            <h2 className="font-bold text-text-primary mb-3 text-left">Mes parcours en cours</h2>
            <div className="flex gap-4 overflow-x-auto pb-4 snap-x hide-scrollbar">
              {courses.map(course => {
                const Icon = course.icon;
                const isSelected = course.id === selectedCourseId;
                return (
                  <button 
                    key={course.id}
                    onClick={() => {
                      playSound('pop');
                      setSelectedCourseId(course.id);
                    }}
                    className={`snap-start flex-shrink-0 w-60 p-4 rounded-2xl border text-left transition-all ${
                      isSelected 
                        ? "border-primary bg-primary/5 ring-2 ring-primary/20 shadow-sm" 
                        : "border-border-soft bg-surface hover:border-primary/30"
                    }`}
                  >
                    <div className={`w-10 h-10 rounded-xl bg-gradient-to-br ${course.color} flex items-center justify-center text-white mb-3 shadow-md`}>
                      <Icon className="w-5 h-5" />
                    </div>
                    <h3 className="font-bold text-sm text-text-primary mb-2 line-clamp-1">{course.title}</h3>
                    <div className="w-full bg-border-soft h-1.5 rounded-full overflow-hidden">
                      <div className={`bg-gradient-to-r ${course.color} h-full rounded-full transition-all`} style={{ width: `${course.progress}%` }} />
                    </div>
                    <div className="mt-1 text-right text-[10px] font-bold text-text-secondary">{course.progress}%</div>
                  </button>
                );
              })}
            </div>
          </div>

          {/* DAILY QUEST CARD */}
          <div className="w-full max-w-3xl px-4 mb-12">
            <div className={`bg-gradient-to-r ${selectedCourse.color} rounded-3xl p-6 md:p-8 text-white shadow-xl relative overflow-hidden`}>
              <Brain className="absolute -right-4 -bottom-4 w-32 h-32 opacity-10" />
              <h2 className="text-sm font-bold uppercase tracking-wider mb-1 text-white/80">Quête en cours</h2>
              <h3 className="text-2xl md:text-3xl font-display font-bold mb-4">{selectedCourse.title}</h3>
              <p className="text-sm md:text-base text-white/90 mb-6 max-w-[80%]">Continuez votre progression et complétez la prochaine leçon pour gagner de l'XP !</p>
            </div>
          </div>

          {/* THE WINDING PATH FOR SELECTED COURSE */}
          <div className="w-full max-w-xl flex flex-col items-center gap-12 relative px-4">
            
            <div className="absolute top-10 bottom-10 w-[4px] border-l-4 border-dashed border-border-strong -z-10" />

            {selectedCourse.levels.map((level, i) => {
              const isDone = level.status === "done";
              const isCurrent = level.status === "current";
              const isLocked = level.status === "locked";
              const offsetClass = getOffsetClass(i);

              return (
                <div key={level.id} className={`relative flex flex-col items-center group transition-transform ${offsetClass}`}>
                  
                  {isCurrent && (
                    <div className="absolute -top-12 bg-white px-4 py-2 rounded-xl font-bold text-sm shadow-lg text-primary border border-border-soft whitespace-nowrap animate-bounce z-20">
                      {level.title}
                      <div className="absolute -bottom-2 left-1/2 -translate-x-1/2 w-4 h-4 bg-white border-b border-r border-border-soft transform rotate-45" />
                    </div>
                  )}

                  <button 
                    onClick={() => {
                      if (!isLocked) {
                        playSound('pop');
                        setActiveLesson(level.id);
                      }
                    }}
                    disabled={isLocked}
                    className={`w-20 h-20 rounded-full flex items-center justify-center relative z-10 transition-all duration-300 ${
                      isDone 
                        ? "bg-primary border-b-8 border-primary-dark shadow-md hover:translate-y-1 hover:border-b-4 active:translate-y-2 active:border-b-0" 
                        : isCurrent
                        ? `bg-gold-dark border-b-8 border-yellow-600 shadow-xl ring-4 ring-gold/30 hover:translate-y-1 hover:border-b-4 active:translate-y-2 active:border-b-0 animate-pulse-soft`
                        : "bg-surface-alt border-b-8 border-border-strong opacity-80 cursor-not-allowed"
                    }`}
                  >
                    {isDone && <Check className="w-8 h-8 text-white stroke-[3]" />}
                    {isCurrent && <Play className="w-8 h-8 text-white fill-white ml-1" />}
                    {isLocked && <Lock className="w-8 h-8 text-text-tertiary" />}
                  </button>

                  {isDone && (
                    <div className="absolute -bottom-4 flex gap-1 z-20 bg-white px-2 py-1 rounded-full shadow-sm border border-border-soft">
                      {[1, 2, 3].map(star => (
                        <Star 
                          key={star} 
                          className={`w-3 h-3 ${star <= level.stars ? "text-gold fill-gold" : "text-border-strong"}`} 
                        />
                      ))}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* --- TAB: CATALOGUE --- */}
      {activeTab === "catalogue" && (
        <div className="w-full px-4 animate-fade-in">
          <div className="flex flex-col gap-8">
            <div className="bg-primary/5 rounded-3xl p-8 border border-primary/20">
              <h2 className="text-2xl font-display font-bold text-primary mb-2">Découvrez de nouveaux horizons</h2>
              <p className="text-text-secondary mb-6 max-w-xl">Parcourez notre bibliothèque de micro-cours créés par des experts et ajoutez-les à votre bureau pour enrichir votre parcours.</p>
              <div className="relative max-w-md">
                <Search className="w-5 h-5 absolute left-4 top-1/2 -translate-y-1/2 text-text-tertiary" />
                <Input placeholder="Chercher un cours..." className="pl-12 py-6 text-lg rounded-2xl shadow-sm" />
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
              {catalogCourses.map(course => (
                <Card key={course.id} variant="interactive" className="overflow-hidden flex flex-col h-full hover:shadow-lg transition-all group">
                  <div className="h-40 w-full relative overflow-hidden">
                    <img src={course.image} alt={course.title} className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-110" />
                    <div className="absolute top-3 right-3 bg-black/70 backdrop-blur-md px-3 py-1.5 rounded-lg text-white text-[10px] font-bold uppercase tracking-wider">
                      {course.category}
                    </div>
                    {course.downloaded && (
                      <div className="absolute top-3 left-3 bg-success/90 backdrop-blur-md px-2 py-1 rounded text-white text-[10px] font-bold flex items-center gap-1 shadow-sm">
                        <Check className="w-3 h-3" /> Hors-ligne
                      </div>
                    )}
                  </div>
                  <div className="p-5 flex flex-col flex-1">
                    <h3 className="font-bold text-lg text-text-primary mb-2 leading-tight">{course.title}</h3>
                    <div className="flex items-center gap-4 mt-auto pt-4 border-t border-border-soft">
                      <span className="text-xs font-medium text-text-secondary flex items-center gap-1.5"><Brain className="w-3.5 h-3.5 text-text-tertiary" /> {course.difficulty}</span>
                      <span className="text-xs font-medium text-text-secondary flex items-center gap-1.5"><Play className="w-3.5 h-3.5 text-text-tertiary" /> {course.duration}</span>
                    </div>
                    <div className="flex gap-2 mt-5">
                      <Button variant="outline" className="flex-1 text-primary border-primary hover:bg-primary hover:text-white transition-colors px-2 text-xs" onClick={() => playSound('pop')}>
                        Suivre
                      </Button>
                      <Button variant="outline" className="text-text-tertiary border-border-strong hover:bg-surface-alt px-3" title="Télécharger pour accès hors-ligne" onClick={() => playSound('pop')}>
                        <CloudDownload className="w-4 h-4" />
                      </Button>
                    </div>
                  </div>
                </Card>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* --- TAB: RECOMPENSES --- */}
      {activeTab === "recompenses" && (
        <div className="w-full px-4 animate-fade-in flex flex-col gap-8 pb-12">
          
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            
            {/* LEFT COLUMN: Badges & Certifs */}
            <div className="lg:col-span-2 flex flex-col gap-8">
              <section>
                <h2 className="text-xl font-display font-bold text-text-primary mb-4 flex items-center gap-2">
                  <Award className="w-5 h-5 text-primary" /> Vos Attestations
                </h2>
                <div className="bg-surface border border-border-soft rounded-2xl p-6 text-center shadow-sm">
                  <div className="w-16 h-16 bg-surface-alt rounded-full flex items-center justify-center mx-auto mb-4 border border-border-strong">
                    <FileCertificateIcon className="w-8 h-8 text-text-tertiary" />
                  </div>
                  <p className="text-sm text-text-secondary mb-4">Vous n'avez pas encore obtenu d'attestation officielle. Complétez un parcours à 100% pour débloquer votre premier certificat validé par nos partenaires !</p>
                  <Button variant="outline" disabled className="mx-auto">
                    <Download className="w-4 h-4 mr-2" /> Télécharger (Aucun)
                  </Button>
                </div>
              </section>

              <section>
                <h2 className="text-xl font-display font-bold text-text-primary mb-4 flex items-center gap-2">
                  <Medal className="w-5 h-5 text-gold-dark" /> Galerie de Badges
                </h2>
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                  {badges.map(badge => {
                    const Icon = badge.icon;
                    return (
                      <div key={badge.id} className={`flex flex-col items-center p-4 rounded-2xl border ${badge.unlocked ? "bg-surface border-border-soft shadow-sm" : "bg-surface-alt/50 border-dashed border-border-strong opacity-60"}`}>
                        <div className={`w-16 h-16 rounded-full flex items-center justify-center mb-3 ${badge.unlocked ? badge.bg : "bg-surface-alt"}`}>
                          <Icon className={`w-8 h-8 ${badge.unlocked ? badge.color : "text-text-tertiary"}`} />
                        </div>
                        <h3 className="font-bold text-sm text-center text-text-primary mb-1 leading-tight">{badge.title}</h3>
                        <p className="text-[10px] text-center text-text-secondary">{badge.desc}</p>
                        {!badge.unlocked && <Lock className="w-3 h-3 text-text-tertiary mt-2" />}
                      </div>
                    );
                  })}
                </div>
              </section>
            </div>

            {/* RIGHT COLUMN: Leaderboard */}
            <div className="flex flex-col gap-6">
              <div className="bg-surface border border-border-soft rounded-3xl p-6 shadow-sm">
                <div className="flex items-center gap-3 mb-6 border-b border-border-soft pb-4">
                  <div className="w-10 h-10 bg-primary/10 rounded-xl flex items-center justify-center text-primary">
                    <Trophy className="w-5 h-5" />
                  </div>
                  <div>
                    <h2 className="font-bold text-lg text-text-primary">Classement</h2>
                    <p className="text-xs text-text-secondary">Mon école cette semaine</p>
                  </div>
                </div>

                <div className="flex flex-col gap-1">
                  {leaderboard.map((user) => (
                    <div 
                      key={user.rank}
                      className={`flex items-center justify-between p-3 rounded-xl transition-colors ${
                        user.isMe 
                          ? "bg-primary/5 border border-primary/20 shadow-sm" 
                          : "hover:bg-surface-alt border border-transparent"
                      }`}
                    >
                      <div className="flex items-center gap-3">
                        <span className={`font-bold w-4 text-center ${user.rank <= 3 ? "text-gold-dark" : "text-text-tertiary"}`}>
                          {user.rank}
                        </span>
                        <img src={user.avatar} alt="avatar" className="w-8 h-8 rounded-full bg-border-soft" />
                        <span className={`font-bold text-sm ${user.isMe ? "text-primary" : "text-text-primary"}`}>
                          {user.name}
                        </span>
                      </div>
                      <div className="text-xs font-bold text-text-secondary flex items-center gap-1">
                        {user.xp} XP
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>

          </div>
        </div>
      )}

      {/* COURSE MODAL (Rich Micro-learning Experience) */}
      {activeLesson && (
        <LessonViewer 
          onClose={() => {
            playSound('pop');
            setActiveLesson(null);
          }} 
          onComplete={completeActiveLesson} 
          playSound={playSound}
        />
      )}

      {/* CELEBRATION OVERLAY */}
      {showCelebration && (
        <div className="fixed inset-0 z-50 pointer-events-none flex items-center justify-center bg-primary/20 backdrop-blur-sm transition-opacity duration-500">
          <div className="bg-white p-8 rounded-3xl shadow-2xl text-center transform scale-110 animate-bounce-soft">
            <h2 className="text-4xl font-display font-bold text-primary mb-2">LEÇON ACCOMPLIE !</h2>
            <p className="text-lg font-bold text-text-secondary">Votre progression a été sauvegardée.</p>
          </div>
        </div>
      )}

    </div>
  );
}

// Composant interne pour l'interface de micro-apprentissage
function LessonViewer({ onClose, onComplete, playSound }: { onClose: () => void, onComplete: () => void, playSound: (t: any) => void }) {
  const [currentStep, setCurrentStep] = React.useState(0);
  const [selectedAnswer, setSelectedAnswer] = React.useState<number | null>(null);
  const [showFeedback, setShowFeedback] = React.useState(false);

  // Mock content for a lesson
  const lessonData = [
    {
      type: "theory",
      title: "L'art de l'écoute active",
      content: "L'écoute active n'est pas seulement entendre des mots. C'est comprendre le message complet que votre interlocuteur essaie de transmettre. Cela demande de l'attention, du contact visuel, et de mettre de côté ses propres jugements.",
      icon: <Brain className="w-16 h-16 text-primary" />
    },
    {
      type: "theory",
      title: "La règle des 80/20",
      content: "Dans une bonne conversation, vous devriez écouter 80% du temps et parler seulement 20% du temps. C'est particulièrement vrai en entretien d'embauche ou lors d'une première rencontre réseau.",
      icon: <Users className="w-16 h-16 text-primary" />
    },
    {
      type: "quiz",
      title: "À vous de jouer !",
      content: "En entretien, quel est le ratio idéal pour pratiquer l'écoute active ?",
      options: [
        "Parler 50% et écouter 50%",
        "Écouter 80% et parler 20%",
        "Ne pas parler du tout"
      ],
      correctAnswer: 1, // index 1
      feedbackSuccess: "Exact ! C'est la fameuse règle des 80/20.",
      feedbackError: "Oups... Pensez à la règle des 80/20 que nous venons de voir."
    },
    {
      type: "reward",
      title: "C'est dans la poche !",
      content: "Vous avez brillamment terminé cette notion. L'écoute active est désormais dans votre boîte à outils.",
      icon: <Hexagon className="w-20 h-20 text-gold-dark fill-gold-dark" />
    }
  ];

  const step = lessonData[currentStep];
  const progress = ((currentStep + 1) / lessonData.length) * 100;

  const handleNext = () => {
    playSound('pop');
    if (currentStep < lessonData.length - 1) {
      setCurrentStep(c => c + 1);
      setSelectedAnswer(null);
      setShowFeedback(false);
    } else {
      onComplete();
    }
  };

  const handleAnswerSubmit = (index: number) => {
    if (showFeedback) return;
    setSelectedAnswer(index);
    setShowFeedback(true);
    
    if (index === step.correctAnswer) {
      playSound('success');
    } else {
      playSound('error');
    }
  };

  return (
    <div className="fixed inset-0 z-50 bg-surface-alt flex flex-col">
      {/* HEADER PROGRESS */}
      <div className="p-4 flex items-center justify-between border-b border-border-soft bg-canvas">
        <button onClick={onClose} className="p-2 text-text-tertiary hover:text-text-primary">
          <X className="w-6 h-6" />
        </button>
        <div className="flex-1 px-8">
          <div className="w-full bg-border-soft h-3 rounded-full overflow-hidden">
            <div 
              className="bg-primary h-full rounded-full transition-all duration-500 ease-out" 
              style={{ width: `${progress}%` }}
            />
          </div>
        </div>
        <div className="w-10" /> {/* Spacer for balance */}
      </div>
      
      {/* MAIN CONTENT (Story-like) */}
      <div className="flex-1 flex flex-col items-center justify-center p-4 max-w-lg mx-auto w-full relative">
        
        {step.type === "theory" && (
          <div className="bg-canvas p-8 rounded-3xl shadow-xl w-full flex flex-col items-center text-center animate-fade-in border border-border-soft">
            <div className="w-24 h-24 bg-primary/10 rounded-full flex items-center justify-center mb-6">
              {step.icon}
            </div>
            <h2 className="text-2xl font-display font-bold text-text-primary mb-4">{step.title}</h2>
            <p className="text-lg text-text-secondary leading-relaxed mb-8">{step.content}</p>
            <Button size="lg" className="w-full text-lg shadow-primary/20 shadow-lg" onClick={handleNext}>
              Compris !
            </Button>
          </div>
        )}

        {step.type === "quiz" && (
          <div className="bg-canvas p-8 rounded-3xl shadow-xl w-full flex flex-col items-center text-center animate-fade-in border border-border-soft">
            <h2 className="text-2xl font-display font-bold text-text-primary mb-4">{step.title}</h2>
            <p className="text-lg text-text-secondary leading-relaxed mb-8">{step.content}</p>
            
            <div className="w-full flex flex-col gap-3 mb-8">
              {step.options?.map((opt, i) => {
                const isSelected = selectedAnswer === i;
                const isCorrect = step.correctAnswer === i;
                const showState = showFeedback;

                let btnClass = "border-border-soft hover:border-primary hover:bg-primary/5 bg-surface";
                
                if (showState) {
                  if (isCorrect) {
                    btnClass = "border-success bg-success/10 text-success-dark font-bold";
                  } else if (isSelected && !isCorrect) {
                    btnClass = "border-error bg-error/10 text-error-dark opacity-50";
                  } else {
                    btnClass = "border-border-soft bg-surface opacity-50";
                  }
                } else if (isSelected) {
                  btnClass = "border-primary bg-primary/10";
                }

                return (
                  <button 
                    key={i} 
                    onClick={() => handleAnswerSubmit(i)}
                    disabled={showFeedback}
                    className={`p-4 rounded-2xl border-2 text-left text-text-primary transition-all duration-300 ${btnClass}`}
                  >
                    {opt}
                  </button>
                );
              })}
            </div>

            {showFeedback && (
              <div className={`p-4 rounded-xl w-full mb-6 ${selectedAnswer === step.correctAnswer ? "bg-success/10 text-success-dark" : "bg-error/10 text-error-dark"}`}>
                <p className="font-bold">{selectedAnswer === step.correctAnswer ? step.feedbackSuccess : step.feedbackError}</p>
              </div>
            )}

            <Button 
              size="lg" 
              className={`w-full text-lg shadow-lg ${showFeedback && selectedAnswer !== step.correctAnswer ? "bg-error hover:bg-error-dark text-white border-error" : ""}`} 
              onClick={() => {
                if (showFeedback && selectedAnswer !== step.correctAnswer) {
                  // Retry logic
                  setShowFeedback(false);
                  setSelectedAnswer(null);
                } else {
                  handleNext();
                }
              }}
              disabled={!showFeedback}
            >
              {showFeedback 
                ? (selectedAnswer === step.correctAnswer ? "Continuer" : "Réessayer") 
                : "Sélectionnez une réponse"}
            </Button>
          </div>
        )}

        {step.type === "reward" && (
          <div className="bg-gradient-to-br from-gold/20 to-gold-dark/20 p-8 rounded-3xl shadow-xl border border-gold/30 w-full flex flex-col items-center text-center animate-bounce-soft">
            <div className="mb-6 drop-shadow-xl">
              {step.icon}
            </div>
            <h2 className="text-3xl font-display font-bold text-gold-dark mb-4">{step.title}</h2>
            <p className="text-lg text-text-secondary leading-relaxed mb-8">{step.content}</p>
            <Button size="lg" className="w-full text-lg bg-gold-dark hover:bg-yellow-600 shadow-gold/30 shadow-lg text-white" onClick={handleNext}>
              Récupérer mes points (+50)
            </Button>
          </div>
        )}

      </div>
    </div>
  );
}

// Dummy icon to avoid error since I forgot to import it from lucide-react in the massive import list
function FileCertificateIcon(props: any) {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><path d="M9 15h6"/><path d="M9 11h6"/><path d="M9 19h4"/>
    </svg>
  );
}
