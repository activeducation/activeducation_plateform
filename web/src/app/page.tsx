"use client";

import React, { useState, useEffect } from "react";
import { Navbar } from "@/components/Navbar";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { motion, AnimatePresence } from "framer-motion";
import {
  ArrowRight,
  Compass,
  Brain,
  Target,
  GraduationCap,
  Briefcase,
  Building,
  CheckCircle2,
  Users
} from "lucide-react";

const GALLERY_IMAGES = [
  { src: "/gallery/media_1790250434427.jpg", caption: "Ateliers Pratiques d'Ingénierie" },
  { src: "/gallery/media_1790250434529.jpg", caption: "Initiation à la Robotique" },
  { src: "/gallery/media_1790250434546.jpg", caption: "Apprentissage Collaboratif" },
  { src: "/gallery/media_1790250435503.jpg", caption: "Ed-Tech Day 2026" },
  { src: "/gallery/media_1790250435896.jpg", caption: "Excellence & Innovation" },
];

const fadeUp = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.6, ease: "easeOut" as any } }
};

const staggerContainer = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.1
    }
  }
};

export default function HomePage() {
  const [currentSlide, setCurrentSlide] = useState(0);

  const [isLoggedIn, setIsLoggedIn] = useState(false);

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentSlide((prev) => (prev + 1) % GALLERY_IMAGES.length);
    }, 4000);
    return () => clearInterval(timer);
  }, []);

  useEffect(() => {
    import("@/utils/supabase/client").then(({ createClient }) => {
      const supabase = createClient();
      supabase.auth.getSession().then(({ data: { session } }) => {
        setIsLoggedIn(!!session);
      });
      supabase.auth.onAuthStateChange((_event, session) => {
        setIsLoggedIn(!!session);
      });
    });
  }, []);

  return (
    <div className="flex flex-col min-h-[100dvh] bg-canvas text-text-primary relative overflow-hidden">
      
      {/* Subtle Animated Background Grid */}
      <div className="absolute inset-0 z-0 pointer-events-none bg-[linear-gradient(to_right,#2947E908_1px,transparent_1px),linear-gradient(to_bottom,#2947E908_1px,transparent_1px)] bg-[size:32px_32px] [mask-image:radial-gradient(ellipse_60%_50%_at_50%_0%,#000_70%,transparent_100%)] opacity-70" />

      {/* NAVIGATION BAR */}
      <Navbar />

      {/* MAIN CONTENT CONTAINER */}
      <main className="flex-1 flex flex-col gap-32 py-12 px-[clamp(1.5rem,5vw,3.5rem)] max-w-[1400px] w-full mx-auto relative z-10">
        
        {/* HERO SECTION — INSTITUTIONAL SPLIT SCREEN */}
        <section id="hero" className="w-full pt-8 pb-12">
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 lg:gap-16 items-center">
            
            {/* LEFT COLUMN */}
            <motion.div 
              className="lg:col-span-7 flex flex-col items-start text-left"
              variants={staggerContainer}
              initial="hidden"
              animate="visible"
            >
              {/* Overline Badge */}
              <motion.div variants={fadeUp} className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-sm bg-primary-surface border border-primary/20 text-primary text-xs font-semibold uppercase tracking-wider mb-6">
                <Compass className="w-4 h-4" />
                <span>Orientation Scolaire & Professionnelle</span>
              </motion.div>

              {/* Headline */}
              <motion.h1 variants={fadeUp} className="font-display font-extrabold text-[clamp(2.5rem,4.5vw,4.5rem)] tracking-[-0.03em] leading-[1.05] text-text-primary">
                Découvrez votre voie. <br />
                <span className="text-primary relative">
                  Construisez votre avenir.
                  <motion.span 
                    className="absolute -bottom-2 left-0 w-full h-[6px] bg-primary/20 rounded-full"
                    initial={{ scaleX: 0, transformOrigin: "left" }}
                    animate={{ scaleX: 1 }}
                    transition={{ delay: 0.5, duration: 0.8, ease: "circOut" as any }}
                  />
                </span>
              </motion.h1>

              {/* Subtitle */}
              <motion.p variants={fadeUp} className="mt-6 text-text-secondary text-base md:text-lg leading-relaxed max-w-[62ch]">
                ActivEducation vous accompagne dans la connaissance de vos aspirations et de votre profil psychologique. Nous analysons votre background pour vous orienter vers les métiers porteurs et les meilleures universités accréditées au Togo.
              </motion.p>

              {/* Actions */}
              <motion.div variants={fadeUp} className="mt-10 flex flex-wrap items-center gap-4">
                {!isLoggedIn ? (
                  <>
                    <a href="/auth/register">
                      <Button variant="primary" size="lg" className="flex items-center gap-2 shadow-sm group text-[15px]">
                        <Target className="w-4 h-4 transition-transform group-hover:scale-110" />
                        <span>Créer un compte</span>
                      </Button>
                    </a>
                    <a href="/auth/login">
                      <Button variant="secondary" size="lg" className="flex items-center gap-2 text-[15px]">
                        <span>Se connecter</span>
                        <ArrowRight className="w-4 h-4" />
                      </Button>
                    </a>
                  </>
                ) : (
                  <a href="/student/cours">
                    <Button variant="primary" size="lg" className="flex items-center gap-2 shadow-sm group text-[15px]">
                      <GraduationCap className="w-4 h-4 transition-transform group-hover:scale-110" />
                      <span>Accéder à mon espace</span>
                      <ArrowRight className="w-4 h-4" />
                    </Button>
                  </a>
                )}
              </motion.div>

              {/* Trust Indicators */}
              <motion.div variants={fadeUp} className="mt-12 flex items-center gap-6 text-xs font-medium text-text-secondary">
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-primary" />
                  <span>Tests Scientifiques (RIASEC)</span>
                </div>
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-primary" />
                  <span>Écoles Agréées MESR</span>
                </div>
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-primary" />
                  <span>IA de Matching AÏDA</span>
                </div>
              </motion.div>
            </motion.div>

            {/* RIGHT COLUMN (VISUAL COMPOSITION) */}
            <motion.div 
              className="lg:col-span-5 relative flex flex-col w-full h-[450px] lg:h-[550px] rounded-2xl overflow-hidden shadow-2xl"
              initial={{ opacity: 0, x: 40 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.8, delay: 0.3, ease: "easeOut" as any }}
            >
              <AnimatePresence mode="wait">
                <motion.div
                  key={currentSlide}
                  initial={{ opacity: 0, scale: 1.05 }}
                  animate={{ opacity: 1, scale: 1 }}
                  exit={{ opacity: 0 }}
                  transition={{ duration: 0.8, ease: "easeInOut" as any }}
                  className="absolute inset-0 w-full h-full"
                >
                  <img 
                    src={GALLERY_IMAGES[currentSlide].src} 
                    alt={GALLERY_IMAGES[currentSlide].caption}
                    className="w-full h-full object-cover"
                  />
                  {/* Overlay gradient */}
                  <div className="absolute inset-0 bg-gradient-to-t from-[#060E1E]/90 via-[#060E1E]/20 to-transparent" />
                  
                  {/* Caption */}
                  <div className="absolute bottom-0 left-0 w-full p-8 flex flex-col gap-2">
                    <motion.div 
                      initial={{ y: 20, opacity: 0 }}
                      animate={{ y: 0, opacity: 1 }}
                      transition={{ delay: 0.3, duration: 0.5 }}
                      className="inline-block px-3 py-1 bg-gold text-white text-[10px] font-bold uppercase tracking-wider rounded-sm w-fit"
                    >
                      En Action
                    </motion.div>
                    <motion.h3 
                      initial={{ y: 20, opacity: 0 }}
                      animate={{ y: 0, opacity: 1 }}
                      transition={{ delay: 0.4, duration: 0.5 }}
                      className="text-white font-display font-bold text-2xl"
                    >
                      {GALLERY_IMAGES[currentSlide].caption}
                    </motion.h3>
                  </div>
                </motion.div>
              </AnimatePresence>
              
              {/* Slider Controls (Dots) */}
              <div className="absolute bottom-8 right-8 flex gap-2 z-10">
                {GALLERY_IMAGES.map((_, idx) => (
                  <button 
                    key={idx}
                    onClick={() => setCurrentSlide(idx)}
                    className={`w-2 h-2 rounded-full transition-all duration-300 ${
                      idx === currentSlide ? "bg-gold w-6" : "bg-white/50 hover:bg-white"
                    }`}
                    aria-label={`Slide ${idx + 1}`}
                  />
                ))}
              </div>
            </motion.div>
          </div>
        </section>

        {/* SECTION 2: NOTRE DÉMARCHE (FEATURES) */}
        <section id="methodologie" className="w-full">
          <div className="text-center max-w-2xl mx-auto mb-16">
            <h2 className="font-display font-bold text-3xl md:text-4xl text-text-primary tracking-tight mb-4">
              Notre Méthodologie
            </h2>
            <p className="text-text-secondary text-base md:text-lg">
              Une approche scientifique et technologique pour sécuriser votre orientation post-bac et professionnelle au Togo.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <motion.div 
              initial={{ opacity: 0, y: 20 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} transition={{ delay: 0.1 }}
              className="flex flex-col gap-4 p-6 rounded-xl bg-surface border border-border-soft hover:border-primary/30 transition-colors"
            >
              <div className="w-12 h-12 rounded-sm bg-primary-surface text-primary flex items-center justify-center mb-2">
                <Brain className="w-6 h-6" />
              </div>
              <h3 className="font-bold text-lg text-text-primary">1. Connaissance de soi</h3>
              <p className="text-sm text-text-secondary leading-relaxed">
                Passez nos tests psychométriques interactifs pour découvrir vos traits de personnalité dominants, vos valeurs et vos aspirations profondes.
              </p>
            </motion.div>

            <motion.div 
              initial={{ opacity: 0, y: 20 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} transition={{ delay: 0.2 }}
              className="flex flex-col gap-4 p-6 rounded-xl bg-surface border border-border-soft hover:border-gold/50 transition-colors relative overflow-hidden group"
            >
              <div className="absolute top-0 right-0 w-24 h-24 bg-gold/5 rounded-full blur-xl group-hover:bg-gold/10 transition-colors" />
              <div className="w-12 h-12 rounded-sm bg-gold-surface text-gold-dark border border-gold/30 flex items-center justify-center mb-2 relative z-10">
                <Briefcase className="w-6 h-6" />
              </div>
              <h3 className="font-bold text-lg text-text-primary relative z-10">2. Matching Métiers</h3>
              <p className="text-sm text-text-secondary leading-relaxed relative z-10">
                Notre IA analyse votre profil et votre background pour vous suggérer les carrières d'avenir et les secteurs qui recrutent activement.
              </p>
            </motion.div>

            <motion.div 
              initial={{ opacity: 0, y: 20 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} transition={{ delay: 0.3 }}
              className="flex flex-col gap-4 p-6 rounded-xl bg-surface border border-border-soft hover:border-primary/30 transition-colors"
            >
              <div className="w-12 h-12 rounded-sm bg-primary-surface text-primary flex items-center justify-center mb-2">
                <Building className="w-6 h-6" />
              </div>
              <h3 className="font-bold text-lg text-text-primary">3. Choix de l'École</h3>
              <p className="text-sm text-text-secondary leading-relaxed">
                Redirection intelligente vers les universités, centres de formation et écoles agréées de bonne reputation pour suivre votre formation.
              </p>
            </motion.div>
          </div>
        </section>

        {/* SECTION 3: NOS INTERVENTIONS (GALERIE) */}
        <section id="interventions" className="w-full">
          <div className="flex flex-col md:flex-row md:items-end justify-between gap-6 mb-12">
            <div className="max-w-xl">
              <h2 className="font-display font-bold text-3xl md:text-4xl text-text-primary tracking-tight mb-4">
                Nos Interventions
              </h2>
              <p className="text-text-secondary text-base">
                Découvrez nos ateliers de robotique, nos journées Ed-Tech et nos programmes d'accompagnement sur le terrain au Togo.
              </p>
            </div>
            <Button variant="secondary" className="w-fit">Voir toute la galerie</Button>
          </div>

          <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
            {GALLERY_IMAGES.map((img, idx) => (
              <motion.div 
                key={idx}
                initial={{ opacity: 0, scale: 0.95 }}
                whileInView={{ opacity: 1, scale: 1 }}
                viewport={{ once: true }}
                transition={{ delay: idx * 0.1, duration: 0.5 }}
                className={`relative rounded-xl overflow-hidden group ${idx === 0 ? "col-span-2 row-span-2" : ""}`}
                style={{ aspectRatio: idx === 0 ? "16/10" : "4/3" }}
              >
                <img 
                  src={img.src} 
                  alt={img.caption}
                  className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-110"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-[#060E1E]/80 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
                <div className="absolute bottom-0 left-0 w-full p-4 translate-y-4 group-hover:translate-y-0 opacity-0 group-hover:opacity-100 transition-all duration-300">
                  <span className="text-white font-bold text-sm">{img.caption}</span>
                </div>
              </motion.div>
            ))}
          </div>
        </section>

        {/* SECTION 4: CTA / INSTITUTIONAL FOOTNOTE */}
        <motion.section 
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.6 }}
          className="w-full bg-surface border border-border-soft rounded-2xl p-10 md:p-14 flex flex-col items-center text-center gap-6 shadow-sm relative overflow-hidden"
        >
          <div className="absolute inset-0 bg-primary/5 pointer-events-none" />
          
          <div className="w-16 h-16 rounded-sm bg-primary flex items-center justify-center text-white mb-2 relative z-10 shadow-sm">
            <Users className="w-8 h-8" />
          </div>
          
          <h2 className="font-display font-bold text-2xl md:text-3xl text-text-primary tracking-tight max-w-xl relative z-10">
            Prêt à tracer votre propre chemin ?
          </h2>
          <p className="text-sm text-text-secondary max-w-xl relative z-10">
            Rejoignez ActivEducation. Renseignez votre profil, passez les tests et accédez instantanément à votre espace d'orientation personnalisé.
          </p>
          
          <div className="mt-4 relative z-10">
            {!isLoggedIn ? (
              <a href="/auth/register">
                <Button variant="primary" size="lg" className="flex items-center justify-center gap-2.5 shadow-sm hover:-translate-y-1 transition-transform">
                  <span>Créer mon Espace Étudiant</span>
                  <ArrowRight className="w-4 h-4" />
                </Button>
              </a>
            ) : (
              <a href="/student/cours">
                <Button variant="primary" size="lg" className="flex items-center justify-center gap-2.5 shadow-sm hover:-translate-y-1 transition-transform">
                  <span>Accéder à mon Espace</span>
                  <ArrowRight className="w-4 h-4" />
                </Button>
              </a>
            )}
          </div>
        </motion.section>

      </main>

      {/* FOOTER */}
      <footer className="mt-20 border-t border-border-soft bg-surface pt-16 pb-8 px-[clamp(1.5rem,5vw,3.5rem)] text-sm text-text-secondary relative z-10">
        <div className="max-w-6xl mx-auto">
          {/* Main Footer Content */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-12 gap-8 lg:gap-10 mb-12">
            
            {/* Brand Column */}
            <div className="md:col-span-2 lg:col-span-4 flex flex-col gap-5 text-left">
              <a href="/" className="flex items-center gap-4 group w-fit">
                <img 
                  src="/logo.jpg" 
                  alt="ActivEducation Logo" 
                  className="w-16 h-16 object-contain mix-blend-multiply" 
                />
                <div className="flex flex-col">
                  <span className="font-display font-extrabold text-xl text-primary leading-tight">
                    ActivEducation
                  </span>
                  <span className="text-[10px] uppercase font-mono tracking-widest text-text-secondary">
                    L'Orientation d'Excellence
                  </span>
                </div>
              </a>
              <p className="text-text-secondary leading-relaxed max-w-sm">
                La première plateforme panafricaine d'orientation basée sur l'intelligence artificielle. Découvrez votre potentiel, trouvez votre voie et intégrez les meilleures écoles.
              </p>
              <div className="flex items-center gap-4 mt-1">
                <a href="#" className="w-10 h-10 rounded-full bg-surface-alt border border-border-soft flex items-center justify-center text-text-secondary hover:text-primary hover:border-primary/50 transition-colors">
                  <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true"><path d="M22 12c0-5.523-4.477-10-10-10S2 6.477 2 12c0 4.991 3.657 9.128 8.438 9.878v-6.987h-2.54V12h2.54V9.797c0-2.506 1.492-3.89 3.777-3.89 1.094 0 2.238.195 2.238.195v2.46h-1.26c-1.243 0-1.63.771-1.63 1.562V12h2.773l-.443 2.891h-2.33v6.988C18.343 21.128 22 16.991 22 12z" /></svg>
                </a>
                <a href="#" className="w-10 h-10 rounded-full bg-surface-alt border border-border-soft flex items-center justify-center text-text-secondary hover:text-primary hover:border-primary/50 transition-colors">
                  <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true"><path fillRule="evenodd" d="M12.315 2c2.43 0 2.784.013 3.808.06 1.064.049 1.791.218 2.427.465a4.902 4.902 0 011.772 1.153 4.902 4.902 0 011.153 1.772c.247.636.416 1.363.465 2.427.048 1.067.06 1.407.06 4.123v.08c0 2.643-.012 2.987-.06 4.043-.049 1.064-.218 1.791-.465 2.427a4.902 4.902 0 01-1.153 1.772 4.902 4.902 0 01-1.772 1.153c-.636.247-1.363.416-2.427.465-1.067.048-1.407.06-4.123.06h-.08c-2.643 0-2.987-.012-4.043-.06-1.064-.049-1.791-.218-2.427-.465a4.902 4.902 0 01-1.772-1.153 4.902 4.902 0 01-1.153-1.772c-.247-.636-.416-1.363-.465-2.427-.047-1.024-.06-1.379-.06-3.808v-.63c0-2.43.013-2.784.06-3.808.049-1.064.218-1.791.465-2.427a4.902 4.902 0 011.153-1.772A4.902 4.902 0 015.45 2.525c.636-.247 1.363-.416 2.427-.465C8.901 2.013 9.256 2 11.685 2h.63zm-.081 1.802h-.468c-2.456 0-2.784.011-3.807.058-.975.045-1.504.207-1.857.344-.467.182-.8.398-1.15.748-.35.35-.566.683-.748 1.15-.137.353-.3.882-.344 1.857-.047 1.023-.058 1.351-.058 3.807v.468c0 2.456.011 2.784.058 3.807.045.975.207 1.504.344 1.857.182.466.399.8.748 1.15.35.35.683.566 1.15.748.353.137.882.3 1.857.344 1.054.048 1.37.058 4.041.058h.08c2.597 0 2.917-.01 3.96-.058.976-.045 1.505-.207 1.858-.344.466-.182.8-.398 1.15-.748.35-.35.566-.683.748-1.15.137-.353.3-.882.344-1.857.048-1.055.058-1.37.058-4.041v-.08c0-2.597-.01-2.917-.058-3.96-.045-.976-.207-1.505-.344-1.858a3.097 3.097 0 00-.748-1.15 3.098 3.098 0 00-1.15-.748c-.353-.137-.882-.3-1.857-.344-1.023-.047-1.351-.058-3.807-.058zM12 6.865a5.135 5.135 0 110 10.27 5.135 5.135 0 010-10.27zm0 1.802a3.333 3.333 0 100 6.666 3.333 3.333 0 000-6.666zm5.338-3.205a1.2 1.2 0 110 2.4 1.2 1.2 0 010-2.4z" clipRule="evenodd" /></svg>
                </a>
                <a href="#" className="w-10 h-10 rounded-full bg-surface-alt border border-border-soft flex items-center justify-center text-text-secondary hover:text-primary hover:border-primary/50 transition-colors">
                  <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true"><path fillRule="evenodd" d="M19 0h-14c-2.761 0-5 2.239-5 5v14c0 2.761 2.239 5 5 5h14c2.762 0 5-2.239 5-5v-14c0-2.761-2.238-5-5-5zm-11 19h-3v-11h3v11zm-1.5-12.268c-.966 0-1.75-.79-1.75-1.764s.784-1.764 1.75-1.764 1.75.79 1.75 1.764-.783 1.764-1.75 1.764zm13.5 12.268h-3v-5.604c0-3.368-4-3.113-4 0v5.604h-3v-11h3v1.765c1.396-2.586 7-2.777 7 2.476v6.759z" clipRule="evenodd" /></svg>
                </a>
              </div>
            </div>

            {/* Links Columns */}
            <div className="flex flex-col gap-3 lg:col-span-3">
              <h4 className="font-bold text-text-primary mb-1 text-base">La Plateforme</h4>
              <a href="#" className="hover:text-primary transition-colors py-1">Accueil</a>
              <a href="/orientation" className="hover:text-primary transition-colors py-1">Test d'Orientation IA</a>
              <a href="#" className="hover:text-primary transition-colors py-1">Nos Écoles Partenaires</a>
              <a href="#" className="hover:text-primary transition-colors py-1">Catalogue de Formations</a>
            </div>

            <div className="flex flex-col gap-3 lg:col-span-2">
              <h4 className="font-bold text-text-primary mb-1 text-base">ActivEducation</h4>
              <a href="#" className="hover:text-primary transition-colors py-1">À Propos</a>
              <a href="#" className="hover:text-primary transition-colors py-1">Nos Interventions</a>
              <a href="#" className="hover:text-primary transition-colors py-1">Équipe & Experts</a>
              <a href="#" className="hover:text-primary transition-colors py-1">Contactez-nous</a>
            </div>

            <div className="flex flex-col gap-3 lg:col-span-3">
              <h4 className="font-bold text-text-primary mb-1 text-base">Contact</h4>
              <p className="text-sm">Lomé, Togo</p>
              <a href="mailto:activedutg@gmail.com" className="text-primary hover:underline font-medium">
                activedutg@gmail.com
              </a>
            </div>
            
          </div>

          {/* Bottom Bar */}
          <div className="flex flex-col md:flex-row items-center justify-between gap-4 pt-8 border-t border-border-soft">
            <div className="text-xs">
              © {new Date().getFullYear()} ActivEducation. Tous droits réservés.
            </div>
            <div className="flex flex-wrap items-center justify-center gap-6 text-xs font-medium">
              <a href="#" className="hover:text-primary transition-colors">Mentions Légales</a>
              <a href="#" className="hover:text-primary transition-colors">Politique de Confidentialité</a>
              <a href="#" className="hover:text-primary transition-colors">CGU</a>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}
