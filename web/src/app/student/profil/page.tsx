"use client";

import React from "react";
import { 
  User, 
  Settings, 
  FileText, 
  Bell, 
  Shield, 
  UploadCloud, 
  CheckCircle2, 
  Camera, 
  File, 
  Trash2,
  AlertCircle
} from "lucide-react";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Input } from "@/components/ui/Input";

export default function ProfilPage() {
  const [activeTab, setActiveTab] = React.useState<"infos" | "docs" | "notifs" | "securite">("infos");
  
  // Real DB Data
  const [userName, setUserName] = React.useState("Étudiant");
  const [userEmail, setUserEmail] = React.useState("");
  
  // States for interactive simulations
  const [isSaving, setIsSaving] = React.useState(false);
  const [saved, setSaved] = React.useState(false);
  const [uploading, setUploading] = React.useState(false);
  const [uploadedFile, setUploadedFile] = React.useState<string | null>("CV_Profil_Design_2026.pdf");

  // Refs for hidden inputs
  const cvInputRef = React.useRef<HTMLInputElement>(null);
  const avatarInputRef = React.useRef<HTMLInputElement>(null);
  const [avatarImage, setAvatarImage] = React.useState("https://api.dicebear.com/7.x/avataaars/svg?seed=Profil");

  React.useEffect(() => {
    // Fetch real profile from Drizzle / DB
    const fetchUserProfile = async () => {
      try {
        const res = await fetch('/api/user');
        if (res.ok) {
          const userData = await res.json();
          setUserName(userData.fullName || userData.email.split('@')[0]);
          setUserEmail(userData.email);
          setAvatarImage(`https://api.dicebear.com/7.x/avataaars/svg?seed=${userData.email}`);
        }
      } catch (error) {
        console.error("Failed to fetch user");
      }
    };
    fetchUserProfile();

    const savedAvatar = localStorage.getItem('activ_avatar');
    if (savedAvatar) setAvatarImage(savedAvatar);
  }, []);

  // Simulate Save
  const handleSave = () => {
    setIsSaving(true);
    setSaved(false);
    setTimeout(() => {
      setIsSaving(false);
      setSaved(true);
      setTimeout(() => setSaved(false), 3000);
    }, 1000);
  };

  // Real Upload Handlers
  const handleCvChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      const file = e.target.files[0];
      setUploading(true);
      setTimeout(() => {
        setUploading(false);
        setUploadedFile(file.name);
      }, 1500);
    }
  };

  const handleAvatarChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      const url = URL.createObjectURL(e.target.files[0]);
      setAvatarImage(url);
      localStorage.setItem('activ_avatar', url);
      window.dispatchEvent(new Event('avatarUpdated'));
    }
  };

  return (
    <div className="w-full max-w-5xl mx-auto pb-24 animate-fade-in flex flex-col gap-8">
      
      <input type="file" className="hidden" accept=".pdf,.doc,.docx" ref={cvInputRef} onChange={handleCvChange} />
      <input type="file" className="hidden" accept="image/*" ref={avatarInputRef} onChange={handleAvatarChange} />

      <div className="relative mb-8 rounded-3xl overflow-hidden shadow-md bg-gradient-to-r from-primary to-blue-400">
        <div className="absolute inset-0 opacity-10 bg-[radial-gradient(circle_at_1px_1px,#fff_1px,transparent_0)] [background-size:20px_20px]" />
        
        <div className="relative z-10 p-8 flex flex-col md:flex-row items-center md:items-start gap-6">
          <div className="relative group cursor-pointer shrink-0" onClick={() => avatarInputRef.current?.click()}>
            <div className="w-28 h-28 md:w-32 md:h-32 rounded-full bg-white/20 p-1.5 shadow-xl backdrop-blur-sm">
              <div className="w-full h-full rounded-full bg-border-soft overflow-hidden">
                <img src={avatarImage} alt="Avatar" className="w-full h-full object-cover bg-surface-alt" />
              </div>
            </div>
            <div className="absolute bottom-0 right-0 w-8 h-8 bg-white text-primary rounded-full flex items-center justify-center shadow-lg border-2 border-primary group-hover:scale-110 transition-transform">
              <span className="text-xl font-bold mb-0.5">+</span>
            </div>
            <div className="absolute inset-0 bg-black/40 rounded-full opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center text-white m-1.5 pointer-events-none">
              <Camera className="w-8 h-8" />
            </div>
          </div>
          
          <div className="text-center md:text-left mt-2 md:mt-6">
            <h1 className="text-2xl md:text-4xl font-display font-bold text-white drop-shadow-sm mb-1">{userName}</h1>
            <p className="text-sm md:text-lg text-white/90 font-medium">Étudiant / Utilisateur</p>
          </div>
        </div>
      </div>

      <div className="flex flex-col md:flex-row gap-8 px-4 md:px-8 mt-4">
        
        {/* SIDEBAR NAVIGATION */}
        <div className="w-full md:w-64 flex-shrink-0">
          <div className="bg-surface border border-border-soft rounded-2xl p-2 flex flex-col gap-1 sticky top-24 shadow-sm">
            
            <button 
              onClick={() => setActiveTab("infos")}
              className={`flex items-center gap-3 w-full p-3 rounded-xl text-sm font-bold transition-all text-left ${activeTab === "infos" ? "bg-primary/10 text-primary" : "text-text-secondary hover:bg-surface-alt hover:text-text-primary"}`}
            >
              <User className="w-5 h-5" /> Informations
            </button>
            
            <button 
              onClick={() => setActiveTab("docs")}
              className={`flex items-center gap-3 w-full p-3 rounded-xl text-sm font-bold transition-all text-left ${activeTab === "docs" ? "bg-primary/10 text-primary" : "text-text-secondary hover:bg-surface-alt hover:text-text-primary"}`}
            >
              <FileText className="w-5 h-5" /> Documents & CV
            </button>

            <button 
              onClick={() => setActiveTab("notifs")}
              className={`flex items-center gap-3 w-full p-3 rounded-xl text-sm font-bold transition-all text-left ${activeTab === "notifs" ? "bg-primary/10 text-primary" : "text-text-secondary hover:bg-surface-alt hover:text-text-primary"}`}
            >
              <Bell className="w-5 h-5" /> Notifications
            </button>

            <button 
              onClick={() => setActiveTab("securite")}
              className={`flex items-center gap-3 w-full p-3 rounded-xl text-sm font-bold transition-all text-left ${activeTab === "securite" ? "bg-primary/10 text-primary" : "text-text-secondary hover:bg-surface-alt hover:text-text-primary"}`}
            >
              <Shield className="w-5 h-5" /> Sécurité
            </button>

          </div>
        </div>

        {/* MAIN CONTENT AREA */}
        <div className="flex-1">
          
          {/* TAB: INFOS */}
          {activeTab === "infos" && (
            <div className="animate-fade-in flex flex-col gap-6">
              <Card variant="standard" className="p-8">
                <h2 className="text-xl font-bold text-text-primary mb-6">Informations Personnelles</h2>
                
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
                  <div className="md:col-span-2">
                    <label className="block text-sm font-bold text-text-secondary mb-2">Nom complet</label>
                    <Input key={userName} defaultValue={userName} />
                  </div>
                  <div className="md:col-span-2">
                    <label className="block text-sm font-bold text-text-secondary mb-2">Adresse Email</label>
                    <Input key={userEmail} defaultValue={userEmail} type="email" disabled />
                  </div>
                  <div className="md:col-span-2">
                    <label className="block text-sm font-bold text-text-secondary mb-2">Bio rapide</label>
                    <textarea 
                      className="w-full rounded-xl border border-border-strong bg-surface px-4 py-3 text-sm focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary min-h-[100px] resize-none"
                      defaultValue="Passionné par le développement web et l'intelligence artificielle. À la recherche d'une alternance pour mettre en pratique mes compétences."
                    />
                  </div>
                </div>

                <div className="flex items-center justify-end gap-4 border-t border-border-soft pt-6">
                  {saved && (
                    <span className="text-success font-bold text-sm flex items-center gap-1 animate-fade-in">
                      <CheckCircle2 className="w-4 h-4" /> Sauvegardé avec succès
                    </span>
                  )}
                  <Button onClick={handleSave} disabled={isSaving}>
                    {isSaving ? "Sauvegarde..." : "Enregistrer les modifications"}
                  </Button>
                </div>
              </Card>

              <Card variant="standard" className="p-8">
                <h2 className="text-xl font-bold text-text-primary mb-6">Parcours Scolaire</h2>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <label className="block text-sm font-bold text-text-secondary mb-2">Établissement actuel</label>
                    <Input defaultValue="ESIG Global Success" />
                  </div>
                  <div>
                    <label className="block text-sm font-bold text-text-secondary mb-2">Niveau d'études</label>
                    <select defaultValue="Master 1" className="w-full rounded-xl border border-border-strong bg-surface px-4 py-3 text-sm focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary appearance-none">
                      <option value="Licence 1">Licence 1</option>
                      <option value="Licence 2">Licence 2</option>
                      <option value="Licence 3">Licence 3</option>
                      <option value="Master 1">Master 1</option>
                      <option value="Master 2">Master 2</option>
                    </select>
                  </div>
                </div>
              </Card>
            </div>
          )}

          {/* TAB: DOCUMENTS */}
          {activeTab === "docs" && (
            <div className="animate-fade-in flex flex-col gap-6">
              <Card variant="standard" className="p-8">
                <h2 className="text-xl font-bold text-text-primary mb-2">Mon Curriculum Vitae (CV)</h2>
                <p className="text-text-secondary mb-8 text-sm">Ce document est utilisé par l'IA AÏDA pour vous recommander des offres, et est envoyé aux recruteurs lors de vos candidatures.</p>
                
                {uploadedFile ? (
                  <div className="border border-border-strong rounded-2xl p-4 flex items-center justify-between bg-surface-alt mb-6">
                    <div className="flex items-center gap-4">
                      <div className="w-12 h-12 bg-primary/10 rounded-xl flex items-center justify-center text-primary">
                        <File className="w-6 h-6" />
                      </div>
                      <div>
                        <p className="font-bold text-text-primary text-sm">{uploadedFile}</p>
                        <p className="text-xs text-text-secondary">Mis à jour à l'instant</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      <Button variant="outline" className="text-xs border-border-strong">Voir</Button>
                      <button 
                        onClick={() => setUploadedFile(null)}
                        className="p-2 text-error/70 hover:text-error hover:bg-error/10 rounded-lg transition-colors"
                      >
                        <Trash2 className="w-5 h-5" />
                      </button>
                    </div>
                  </div>
                ) : (
                  <div 
                    className="border-2 border-dashed border-primary/40 bg-primary/5 rounded-2xl p-12 flex flex-col items-center justify-center text-center transition-all hover:border-primary/60 hover:bg-primary/10 mb-6 cursor-pointer" 
                    onClick={() => cvInputRef.current?.click()}
                  >
                    {uploading ? (
                      <div className="flex flex-col items-center animate-pulse-soft">
                        <UploadCloud className="w-12 h-12 text-primary mb-4" />
                        <h3 className="font-bold text-primary mb-1">Analyse et Importation...</h3>
                        <p className="text-sm text-text-secondary">AÏDA lit votre CV...</p>
                      </div>
                    ) : (
                      <>
                        <UploadCloud className="w-12 h-12 text-primary mb-4" />
                        <h3 className="font-bold text-text-primary mb-1">Cliquez ou glissez un fichier ici</h3>
                        <p className="text-sm text-text-secondary">PDF, DOCX (Max 5MB)</p>
                      </>
                    )}
                  </div>
                )}
                
                <div className="bg-blue-50 border border-blue-100 rounded-xl p-4 flex gap-3 items-start">
                  <AlertCircle className="w-5 h-5 text-blue-500 flex-shrink-0 mt-0.5" />
                  <p className="text-sm text-blue-800">
                    <strong>Astuce :</strong> Vous pouvez créer un CV parfait directement depuis l'onglet <em>Mon Parcours</em> si vous n'en avez pas encore un au format professionnel.
                  </p>
                </div>
              </Card>
            </div>
          )}

          {/* TAB: NOTIFS & SECU (Placeholders) */}
          {activeTab === "notifs" && (
            <div className="animate-fade-in">
              <Card variant="standard" className="p-8">
                <h2 className="text-xl font-bold text-text-primary mb-6">Préférences de notifications</h2>
                
                <div className="flex flex-col gap-6">
                  <div className="flex items-center justify-between pb-6 border-b border-border-soft">
                    <div>
                      <h3 className="font-bold text-text-primary">Nouvelles bourses</h3>
                      <p className="text-sm text-text-secondary">Soyez alerté quand une bourse correspond à votre profil.</p>
                    </div>
                    <div className="w-12 h-6 bg-primary rounded-full relative cursor-pointer">
                      <div className="w-4 h-4 bg-white rounded-full absolute right-1 top-1 shadow-sm" />
                    </div>
                  </div>
                  
                  <div className="flex items-center justify-between pb-6 border-b border-border-soft">
                    <div>
                      <h3 className="font-bold text-text-primary">Rappels d'apprentissage</h3>
                      <p className="text-sm text-text-secondary">Recevez un rappel pour ne pas perdre votre série de jours.</p>
                    </div>
                    <div className="w-12 h-6 bg-primary rounded-full relative cursor-pointer">
                      <div className="w-4 h-4 bg-white rounded-full absolute right-1 top-1 shadow-sm" />
                    </div>
                  </div>

                  <div className="flex items-center justify-between pb-6">
                    <div>
                      <h3 className="font-bold text-text-primary">Offres d'emploi</h3>
                      <p className="text-sm text-text-secondary">Recevez la newsletter hebdomadaire des stages et emplois.</p>
                    </div>
                    <div className="w-12 h-6 bg-border-strong rounded-full relative cursor-pointer">
                      <div className="w-4 h-4 bg-white rounded-full absolute left-1 top-1 shadow-sm" />
                    </div>
                  </div>
                </div>
              </Card>
            </div>
          )}

          {activeTab === "securite" && (
            <div className="animate-fade-in flex flex-col gap-6">
              <Card variant="standard" className="p-8">
                <h2 className="text-xl font-bold text-text-primary mb-6">Changer de mot de passe</h2>
                <div className="flex flex-col gap-4 max-w-md">
                  <div>
                    <label className="block text-sm font-bold text-text-secondary mb-2">Mot de passe actuel</label>
                    <Input type="password" placeholder="••••••••" />
                  </div>
                  <div>
                    <label className="block text-sm font-bold text-text-secondary mb-2">Nouveau mot de passe</label>
                    <Input type="password" placeholder="••••••••" />
                  </div>
                  <Button className="w-max mt-2">Mettre à jour</Button>
                </div>
              </Card>
              
              <Card variant="standard" className="p-8 border-error/20 bg-error/5">
                <h2 className="text-xl font-bold text-error mb-2">Zone Dangereuse</h2>
                <p className="text-sm text-error/80 mb-4">La suppression de votre compte est définitive. Toutes vos progressions et cristaux seront perdus.</p>
                <Button variant="outline" className="text-error border-error hover:bg-error hover:text-white">
                  Supprimer mon compte
                </Button>
              </Card>
            </div>
          )}

        </div>
      </div>
    </div>
  );
}
