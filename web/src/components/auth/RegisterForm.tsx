"use client";

import React, { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { 
  User, 
  GraduationCap, 
  Users, 
  Building2, 
  Tent, 
  ArrowRight, 
  ArrowLeft,
  CheckCircle2,
  MapPin,
  Loader2
} from "lucide-react";

type RoleType = "eleve" | "etudiant" | "parent" | "ecole" | "cdej" | null;

const ROLES = [
  { id: "eleve", label: "Élève / Lycéen", icon: User, desc: "Je suis au collège ou au lycée." },
  { id: "etudiant", label: "Étudiant", icon: GraduationCap, desc: "Je suis dans l'enseignement supérieur." },
  { id: "parent", label: "Parent / Tuteur", icon: Users, desc: "J'accompagne l'orientation de mes enfants." },
  { id: "ecole", label: "École / Université", icon: Building2, desc: "Établissement ou centre de formation." },
  { id: "cdej", label: "CDEJ", icon: Tent, desc: "Centre de Développement des Enfants et Jeunes." }
] as const;

export function RegisterForm() {
  const [step, setStep] = useState(1);
  const [selectedRole, setSelectedRole] = useState<RoleType>(null);
  const [schoolType, setSchoolType] = useState<"secondaire" | "superieur">("secondaire");
  
  // Geolocation state
  const [gpsCoords, setGpsCoords] = useState("");
  const [isLocating, setIsLocating] = useState(false);
  const [locationError, setLocationError] = useState("");

  const nextStep = () => setStep((s) => s + 1);
  const prevStep = () => setStep((s) => s - 1);

  const handleGetLocation = () => {
    setIsLocating(true);
    setLocationError("");
    if (!navigator.geolocation) {
      setLocationError("La géolocalisation n'est pas supportée par votre navigateur.");
      setIsLocating(false);
      return;
    }
    
    navigator.geolocation.getCurrentPosition(
      (position) => {
        setGpsCoords(`${position.coords.latitude}, ${position.coords.longitude}`);
        setIsLocating(false);
      },
      (error) => {
        console.error(error);
        setLocationError("Impossible de récupérer la position. Veuillez vérifier vos permissions.");
        setIsLocating(false);
      },
      { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 }
    );
  };

  return (
    <div className="w-full max-w-2xl mx-auto bg-surface border border-border-soft rounded-2xl shadow-sm p-6 md:p-10">
      
      {/* Progress Indicator */}
      <div className="flex items-center justify-between mb-8">
        {[1, 2, 3].map((i) => (
          <div key={i} className="flex items-center flex-1 last:flex-none">
            <div className={`w-8 h-8 rounded-full flex items-center justify-center font-bold text-xs transition-colors ${
              step >= i ? "bg-primary text-white" : "bg-surface-alt text-text-secondary border border-border-soft"
            }`}>
              {i}
            </div>
            {i < 3 && (
              <div className={`h-[2px] flex-1 mx-2 transition-colors ${
                step > i ? "bg-primary" : "bg-border-soft"
              }`} />
            )}
          </div>
        ))}
      </div>

      <AnimatePresence mode="wait">
        
        {/* STEP 1: ROLE SELECTION */}
        {step === 1 && (
          <motion.div
            key="step1"
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
            className="flex flex-col gap-6"
          >
            <div>
              <h2 className="font-display font-bold text-2xl text-text-primary mb-2">Qui êtes-vous ?</h2>
              <p className="text-text-secondary text-sm">Sélectionnez votre profil pour personnaliser votre expérience.</p>
            </div>
            
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              {ROLES.map((role) => {
                const Icon = role.icon;
                const isSelected = selectedRole === role.id;
                return (
                  <button
                    key={role.id}
                    onClick={() => setSelectedRole(role.id as RoleType)}
                    className={`flex flex-col items-start p-4 rounded-xl border text-left transition-all ${
                      isSelected 
                        ? "border-primary bg-primary/5 ring-1 ring-primary shadow-sm" 
                        : "border-border-soft bg-surface hover:border-primary/40 hover:bg-surface-alt"
                    } ${role.id === "cdej" ? "sm:col-span-2" : ""}`}
                  >
                    <div className={`p-2 rounded-sm mb-3 ${isSelected ? "bg-primary text-white" : "bg-surface-alt text-text-secondary"}`}>
                      <Icon className="w-5 h-5" />
                    </div>
                    <span className={`font-bold text-sm ${isSelected ? "text-primary" : "text-text-primary"}`}>
                      {role.label}
                    </span>
                    <span className="text-xs text-text-secondary mt-1">{role.desc}</span>
                  </button>
                );
              })}
            </div>

            <div className="mt-4 flex justify-end">
              <Button variant="primary" onClick={nextStep} disabled={!selectedRole} className="gap-2">
                Continuer <ArrowRight className="w-4 h-4" />
              </Button>
            </div>
          </motion.div>
        )}

        {/* STEP 2: BASIC INFO */}
        {step === 2 && (
          <motion.div
            key="step2"
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
            className="flex flex-col gap-6"
          >
            <div>
              <h2 className="font-display font-bold text-2xl text-text-primary mb-2">Informations de connexion</h2>
              <p className="text-text-secondary text-sm">Créez vos identifiants sécurisés.</p>
            </div>

            <div className="space-y-4">
              <Input 
                label={["ecole", "cdej"].includes(selectedRole as string) ? "Nom de l'établissement / Raison sociale" : "Nom complet"} 
                placeholder={["ecole", "cdej"].includes(selectedRole as string) ? "Ex: Université de Lomé" : "Ex: Jean Dupont"} 
              />
              <Input label="Adresse Email" type="email" placeholder={["ecole", "cdej"].includes(selectedRole as string) ? "contact@etablissement.tg" : "jean@exemple.com"} />
              <Input label="Mot de passe" type="password" placeholder="••••••••" />
            </div>

            <div className="mt-4 flex justify-between items-center">
              <Button variant="secondary" onClick={prevStep} className="gap-2">
                <ArrowLeft className="w-4 h-4" /> Retour
              </Button>
              <Button variant="primary" onClick={nextStep} className="gap-2">
                Continuer <ArrowRight className="w-4 h-4" />
              </Button>
            </div>
          </motion.div>
        )}

        {/* STEP 3: SPECIFIC INFO */}
        {step === 3 && (
          <motion.div
            key="step3"
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
            className="flex flex-col gap-6"
          >
            <div>
              <h2 className="font-display font-bold text-2xl text-text-primary mb-2">Détails du profil</h2>
              <p className="text-text-secondary text-sm">Dites-nous en plus pour un accompagnement sur-mesure.</p>
            </div>

            <div className="space-y-4">
              
              {/* ELEVE */}
              {selectedRole === "eleve" && (
                <>
                  <div className="flex flex-col gap-1">
                    <label className="text-xs font-bold text-text-primary">Niveau d'études</label>
                    <select className="h-[44px] rounded-sm border border-border-soft bg-surface px-3 text-sm focus:outline-none focus:ring-1 focus:ring-primary focus:border-primary">
                      <option value="">Sélectionnez une classe...</option>
                      <option value="college">Collège (6ème - 3ème)</option>
                      <option value="2nde">Seconde</option>
                      <option value="1ere">Première</option>
                      <option value="tle">Terminale</option>
                    </select>
                  </div>
                  <div className="flex flex-col gap-1">
                    <label className="text-xs font-bold text-text-primary">Série (Si Lycée)</label>
                    <select className="h-[44px] rounded-sm border border-border-soft bg-surface px-3 text-sm focus:outline-none focus:ring-1 focus:ring-primary focus:border-primary">
                      <option value="">Non applicable / Tronc commun</option>
                      <option value="A">Série A (Littéraire)</option>
                      <option value="C">Série C (Mathématiques)</option>
                      <option value="D">Série D (Sciences Physiques & SVT)</option>
                      <option value="G">Série G (Gestion / Comptabilité)</option>
                      <option value="F">Série F (Technique)</option>
                    </select>
                  </div>
                </>
              )}

              {/* ETUDIANT */}
              {selectedRole === "etudiant" && (
                <>
                  <Input label="Filière actuelle" placeholder="Ex: Informatique, Droit..." />
                  <div className="flex flex-col gap-1">
                    <label className="text-xs font-bold text-text-primary">Année d'étude</label>
                    <select className="h-[44px] rounded-sm border border-border-soft bg-surface px-3 text-sm focus:outline-none focus:ring-1 focus:ring-primary focus:border-primary">
                      <option value="">Sélectionnez...</option>
                      <option value="L1">Licence 1</option>
                      <option value="L2">Licence 2</option>
                      <option value="L3">Licence 3</option>
                      <option value="M1">Master 1</option>
                      <option value="M2">Master 2</option>
                    </select>
                  </div>
                  <Input label="Aspiration professionnelle" placeholder="Quel métier visez-vous ?" />
                </>
              )}

              {/* PARENT */}
              {selectedRole === "parent" && (
                <>
                  <Input label="Nombre d'enfants à accompagner" type="number" placeholder="Ex: 2" />
                  <Input label="Classes actuelles de vos enfants" placeholder="Ex: Un en Terminale D, un en 3ème" />
                </>
              )}

              {/* ECOLE */}
              {selectedRole === "ecole" && (
                <>
                  <Input label="Nom de l'établissement" placeholder="Ex: Université de Lomé" />
                  <Input label="Domaine de spécialisation principal" placeholder="Ex: Informatique, Gestion, Enseignement Général..." />
                  
                  <div className="flex gap-4 mt-2 mb-4">
                    <label className="flex items-center gap-2 text-sm cursor-pointer">
                      <input type="radio" name="schoolType" checked={schoolType === "secondaire"} onChange={() => setSchoolType("secondaire")} className="text-primary focus:ring-primary" />
                      Primaire / Secondaire
                    </label>
                    <label className="flex items-center gap-2 text-sm cursor-pointer">
                      <input type="radio" name="schoolType" checked={schoolType === "superieur"} onChange={() => setSchoolType("superieur")} className="text-primary focus:ring-primary" />
                      Supérieur / Formation
                    </label>
                  </div>
                  
                  {schoolType === "superieur" && (
                    <>
                      <div className="flex flex-col gap-1">
                        <label className="text-xs font-bold text-text-primary">Domaines de formation disponibles</label>
                        <select multiple className="h-[100px] rounded-sm border border-border-soft bg-surface p-2 text-sm focus:outline-none focus:ring-1 focus:ring-primary focus:border-primary">
                          <option value="tech">Informatique & Numérique</option>
                          <option value="eco">Économie & Gestion</option>
                          <option value="droit">Droit & Sciences Politiques</option>
                          <option value="sante">Sciences de la Santé</option>
                          <option value="ing">Ingénierie & BTP</option>
                          <option value="autre">Autre (préciser ci-dessous)</option>
                        </select>
                        <p className="text-[10px] text-text-secondary mt-1">Maintenez Ctrl (ou Cmd) pour en sélectionner plusieurs.</p>
                      </div>
                      <Input label="Autres formations (si non listées)" placeholder="Saisissez les autres formations..." />
                      <Input label="Débouchés principaux" placeholder="Ex: Développeur, Comptable, Juriste..." />
                    </>
                  )}

                  <div className="flex flex-col gap-2 mt-4 p-4 rounded-xl bg-primary/5 border border-primary/20">
                    <label className="text-xs font-bold text-primary">Coordonnées GPS (Requis pour la carte)</label>
                    <p className="text-[11px] text-text-secondary">⚠️ Vous devez obligatoirement vous trouver dans les locaux de l'établissement pour effectuer cette prise de position.</p>
                    <div className="flex items-center gap-2 mt-1">
                      <div className="flex-1">
                        <Input 
                          placeholder="Ex: 6.1366, 1.2222" 
                          value={gpsCoords}
                          onChange={(e) => setGpsCoords(e.target.value)}
                        />
                      </div>
                      <Button 
                        variant="secondary" 
                        onClick={handleGetLocation} 
                        disabled={isLocating}
                        className="whitespace-nowrap h-[44px] mt-[10px] text-xs gap-2 border-primary/30 text-primary hover:bg-primary hover:text-white"
                      >
                        {isLocating ? <Loader2 className="w-4 h-4 animate-spin" /> : <MapPin className="w-4 h-4" />}
                        {isLocating ? "Localisation..." : "Me localiser"}
                      </Button>
                    </div>
                    {locationError && <p className="text-xs text-red-500 mt-1">{locationError}</p>}
                  </div>
                </>
              )}

              {/* CDEJ */}
              {selectedRole === "cdej" && (
                <>
                  <Input label="Nom du Centre" placeholder="Ex: CDEJ EYRAM" />
                  <Input label="Nombre de bénéficiaires" type="number" placeholder="Ex: 150" />
                  <Input label="Localisation (Indication textuelle)" placeholder="Ex: Quartier Agoè, près de la pharmacie..." />
                  
                  <div className="flex flex-col gap-2 mt-4 p-4 rounded-xl bg-primary/5 border border-primary/20">
                    <label className="text-xs font-bold text-primary">Prise de Coordonnées GPS</label>
                    <p className="text-[11px] text-text-secondary">⚠️ Vous devez obligatoirement vous trouver dans les locaux du CDEJ pour capter la bonne position.</p>
                    <div className="flex items-center gap-2 mt-1">
                      <div className="flex-1">
                        <Input 
                          placeholder="Ex: 6.1366, 1.2222" 
                          value={gpsCoords}
                          onChange={(e) => setGpsCoords(e.target.value)}
                        />
                      </div>
                      <Button 
                        variant="secondary" 
                        onClick={handleGetLocation} 
                        disabled={isLocating}
                        className="whitespace-nowrap h-[44px] mt-[10px] text-xs gap-2 border-primary/30 text-primary hover:bg-primary hover:text-white"
                      >
                        {isLocating ? <Loader2 className="w-4 h-4 animate-spin" /> : <MapPin className="w-4 h-4" />}
                        {isLocating ? "Calcul..." : "Prendre le GPS"}
                      </Button>
                    </div>
                    {locationError && <p className="text-xs text-red-500 mt-1">{locationError}</p>}
                  </div>
                </>
              )}

            </div>

            <div className="mt-6 flex justify-between items-center">
              <Button variant="secondary" onClick={prevStep} className="gap-2">
                <ArrowLeft className="w-4 h-4" /> Retour
              </Button>
              <Button 
                variant="primary" 
                onClick={() => {
                  if (selectedRole) {
                    localStorage.setItem("userRole", selectedRole);
                  }
                  window.location.href = "/student";
                }}
                className="gap-2 bg-gold hover:bg-gold-dark text-white border-none"
              >
                <CheckCircle2 className="w-4 h-4" /> Terminer l'inscription
              </Button>
            </div>
          </motion.div>
        )}

      </AnimatePresence>
    </div>
  );
}
