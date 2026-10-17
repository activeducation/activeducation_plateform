"use client";

import React, { useState } from "react";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { 
  Plus, 
  Edit, 
  Trash2, 
  Map, 
  Building2, 
  GraduationCap, 
  Briefcase, 
  X, 
  Search, 
  CheckCircle2, 
  AlertCircle,
  Eye,
  EyeOff,
  Check
} from "lucide-react";
import { Input } from "@/components/ui/Input";
import { ImageUpload } from "@/components/ui/ImageUpload";

export default function AdminExplorerClient({
  initialDomains,
  initialSchools,
  initialPrograms,
  initialCareers,
}: {
  initialDomains: any[];
  initialSchools: any[];
  initialPrograms: any[];
  initialCareers: any[];
}) {
  const [activeTab, setActiveTab] = useState<"domains" | "schools" | "programs" | "careers">("domains");
  const [showForm, setShowForm] = useState(false);
  const [isEditing, setIsEditing] = useState(false);
  const [editingItem, setEditingItem] = useState<any | null>(null);
  const [loading, setLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState("");
  const [feedback, setFeedback] = useState<{ type: "success" | "error"; message: string } | null>(null);

  // Lists in state
  const [domains, setDomains] = useState<any[]>(initialDomains || []);
  const [schools, setSchools] = useState<any[]>(initialSchools || []);
  const [programs, setPrograms] = useState<any[]>(initialPrograms || []);
  const [careers, setCareers] = useState<any[]>(initialCareers || []);

  // Form state
  const [formData, setFormData] = useState<any>({
    isPublished: true,
  });

  const tabs = [
    { id: "domains" as const, label: "Domaines", icon: Map },
    { id: "schools" as const, label: "Écoles", icon: Building2 },
    { id: "programs" as const, label: "Formations", icon: GraduationCap },
    { id: "careers" as const, label: "Métiers", icon: Briefcase },
  ];

  const showNotification = (type: "success" | "error", message: string) => {
    setFeedback({ type, message });
    setTimeout(() => setFeedback(null), 4000);
  };

  const handleOpenCreate = () => {
    setIsEditing(false);
    setEditingItem(null);
    setFormData({
      isPublished: true,
      type: "Public",
      facilitiesString: "",
      programCoursesString: "",
      skillsString: "",
      opportunitiesString: "",
    });
    setShowForm(true);
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  const handleStartEdit = (item: any) => {
    setIsEditing(true);
    setEditingItem(item);
    
    // Format array fields as comma-separated strings for smooth text editing
    setFormData({
      ...item,
      facilitiesString: Array.isArray(item.facilities) ? item.facilities.join(", ") : "",
      programCoursesString: Array.isArray(item.programCourses) ? item.programCourses.join(", ") : "",
      skillsString: Array.isArray(item.skills) ? item.skills.join(", ") : "",
      opportunitiesString: Array.isArray(item.opportunities) ? item.opportunities.join(", ") : "",
    });
    setShowForm(true);
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      const payload: any = { ...formData };

      // Convert comma-separated strings back to JSON arrays
      if (activeTab === "schools" && typeof payload.facilitiesString === "string") {
        payload.facilities = payload.facilitiesString.split(",").map((s: string) => s.trim()).filter(Boolean);
        delete payload.facilitiesString;
      }
      if (activeTab === "programs" && typeof payload.programCoursesString === "string") {
        payload.programCourses = payload.programCoursesString.split(",").map((s: string) => s.trim()).filter(Boolean);
        delete payload.programCoursesString;
      }
      if (activeTab === "careers") {
        if (typeof payload.skillsString === "string") {
          payload.skills = payload.skillsString.split(",").map((s: string) => s.trim()).filter(Boolean);
          delete payload.skillsString;
        }
        if (typeof payload.opportunitiesString === "string") {
          payload.opportunities = payload.opportunitiesString.split(",").map((s: string) => s.trim()).filter(Boolean);
          delete payload.opportunitiesString;
        }
      }

      if (isEditing && editingItem) {
        payload.id = editingItem.id;
        const res = await fetch(`/api/admin/explorer/${activeTab}`, {
          method: "PUT",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        });

        if (!res.ok) {
          const err = await res.json().catch(() => ({}));
          throw new Error(err.error || "Erreur lors de la modification");
        }

        const updated = await res.json();
        if (activeTab === "domains") setDomains(prev => prev.map(d => d.id === updated.id ? updated : d));
        if (activeTab === "schools") setSchools(prev => prev.map(s => s.id === updated.id ? updated : s));
        if (activeTab === "programs") setPrograms(prev => prev.map(p => p.id === updated.id ? updated : p));
        if (activeTab === "careers") setCareers(prev => prev.map(c => c.id === updated.id ? updated : c));

        showNotification("success", "Élément modifié avec succès !");
      } else {
        const res = await fetch(`/api/admin/explorer/${activeTab}`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        });

        if (!res.ok) {
          const err = await res.json().catch(() => ({}));
          throw new Error(err.error || "Erreur lors de la création");
        }

        const newItem = await res.json();
        if (activeTab === "domains") setDomains(prev => [newItem, ...prev]);
        if (activeTab === "schools") setSchools(prev => [newItem, ...prev]);
        if (activeTab === "programs") setPrograms(prev => [newItem, ...prev]);
        if (activeTab === "careers") setCareers(prev => [newItem, ...prev]);

        showNotification("success", "Élément créé avec succès !");
      }

      setShowForm(false);
      setEditingItem(null);
      setFormData({});
    } catch (err: any) {
      showNotification("error", err.message || "Une erreur est survenue.");
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (item: any) => {
    const title = item.name || item.title || "cet élément";
    if (!window.confirm(`Êtes-vous sûr de vouloir supprimer définitivement "${title}" ?`)) {
      return;
    }

    try {
      const res = await fetch(`/api/admin/explorer/${activeTab}?id=${item.id}`, {
        method: "DELETE",
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.error || "Impossible de supprimer l'élément.");
      }

      if (activeTab === "domains") setDomains(prev => prev.filter(d => d.id !== item.id));
      if (activeTab === "schools") setSchools(prev => prev.filter(s => s.id !== item.id));
      if (activeTab === "programs") setPrograms(prev => prev.filter(p => p.id !== item.id));
      if (activeTab === "careers") setCareers(prev => prev.filter(c => c.id !== item.id));

      showNotification("success", `"${title}" a été supprimé.`);
      if (editingItem?.id === item.id) {
        setShowForm(false);
        setEditingItem(null);
      }
    } catch (err: any) {
      showNotification("error", err.message || "Erreur lors de la suppression.");
    }
  };

  const handleTogglePublish = async (item: any) => {
    try {
      const updatedStatus = !item.isPublished;
      const res = await fetch(`/api/admin/explorer/${activeTab}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          ...item,
          isPublished: updatedStatus,
        }),
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.error || "Erreur lors du changement de statut");
      }

      const updated = await res.json();
      if (activeTab === "domains") setDomains(prev => prev.map(d => d.id === updated.id ? updated : d));
      if (activeTab === "schools") setSchools(prev => prev.map(s => s.id === updated.id ? updated : s));
      if (activeTab === "programs") setPrograms(prev => prev.map(p => p.id === updated.id ? updated : p));
      if (activeTab === "careers") setCareers(prev => prev.map(c => c.id === updated.id ? updated : c));

      showNotification("success", updatedStatus ? "Élément maintenant en ligne (publié)" : "Élément passé en brouillon");
    } catch (err: any) {
      showNotification("error", err.message || "Erreur lors de la mise à jour");
    }
  };

  // Filter current list based on search term
  const currentList = (() => {
    let list: any[] = [];
    if (activeTab === "domains") list = domains;
    if (activeTab === "schools") list = schools;
    if (activeTab === "programs") list = programs;
    if (activeTab === "careers") list = careers;

    if (!searchTerm.trim()) return list;

    const term = searchTerm.toLowerCase();
    return list.filter(item => {
      const titleMatch = (item.title || item.name || "").toLowerCase().includes(term);
      const slugMatch = (item.slug || "").toLowerCase().includes(term);
      const cityMatch = (item.city || "").toLowerCase().includes(term);
      return titleMatch || slugMatch || cityMatch;
    });
  })();

  const renderFormFields = () => {
    if (activeTab === "domains") {
      return (
        <div className="flex flex-col gap-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Input 
              label="Titre du domaine *" 
              value={formData.title || ""} 
              onChange={(e) => setFormData({...formData, title: e.target.value})} 
              placeholder="ex: Numérique & Technologies"
              required 
            />
            <Input 
              label="Identifiant URL (slug)" 
              value={formData.slug || ""} 
              onChange={(e) => setFormData({...formData, slug: e.target.value})} 
              placeholder="ex: numerique-technologies (laisser vide pour auto-générer)"
            />
            <Input 
              label="Croissance (ex: +18% / an)" 
              value={formData.growth || ""} 
              onChange={(e) => setFormData({...formData, growth: e.target.value})} 
              placeholder="+15% / an"
            />
            <Input 
              label="Employabilité" 
              value={formData.employability || ""} 
              onChange={(e) => setFormData({...formData, employability: e.target.value})} 
              placeholder="Très forte / Forte"
            />
            <Input 
              label="Rémunération moyenne" 
              value={formData.salary || ""} 
              onChange={(e) => setFormData({...formData, salary: e.target.value})} 
              placeholder="350 000 - 800 000 FCFA"
            />
            <div className="md:col-span-2">
              <ImageUpload 
                label="Image Bannière du domaine" 
                value={formData.bannerImage || ""} 
                onChange={(url) => setFormData({...formData, bannerImage: url})} 
                bucket="domains"
              />
            </div>
          </div>

          <div className="flex flex-col gap-1">
            <label className="text-sm font-bold text-text-primary">Description complète</label>
            <textarea 
              className="w-full rounded-xl border border-border-soft bg-canvas p-3 focus:outline-none focus:ring-2 focus:ring-primary/50 text-sm" 
              rows={3} 
              value={formData.description || ""} 
              onChange={(e) => setFormData({...formData, description: e.target.value})}
              placeholder="Présentation générale du domaine et de ses perspectives au Togo..."
            ></textarea>
          </div>

          <div className="flex flex-col gap-1">
            <label className="text-sm font-bold text-text-primary">Pourquoi choisir ce domaine ?</label>
            <textarea 
              className="w-full rounded-xl border border-border-soft bg-canvas p-3 focus:outline-none focus:ring-2 focus:ring-primary/50 text-sm" 
              rows={2} 
              value={formData.why || ""} 
              onChange={(e) => setFormData({...formData, why: e.target.value})}
              placeholder="Avantages clés, besoins réels du marché ou opportunités..."
            ></textarea>
          </div>

          <label className="flex items-center gap-3 cursor-pointer pt-2">
            <input 
              type="checkbox" 
              checked={formData.isPublished ?? true} 
              onChange={(e) => setFormData({...formData, isPublished: e.target.checked})}
              className="w-5 h-5 text-primary rounded border-border-soft focus:ring-primary"
            />
            <span className="text-sm font-medium text-text-primary">
              Publier cet élément (visible par les étudiants sur l'Explorateur)
            </span>
          </label>
        </div>
      );
    }

    if (activeTab === "schools") {
      return (
        <div className="flex flex-col gap-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Input 
              label="Nom de l'établissement *" 
              value={formData.name || ""} 
              onChange={(e) => setFormData({...formData, name: e.target.value})} 
              placeholder="ex: Université de Lomé (UL)"
              required 
            />
            <Input 
              label="Identifiant URL (slug)" 
              value={formData.slug || ""} 
              onChange={(e) => setFormData({...formData, slug: e.target.value})} 
              placeholder="ex: ul (laisser vide pour auto-générer)"
            />
            <div className="flex flex-col gap-1">
              <label className="text-sm font-bold text-text-primary">Statut / Type</label>
              <select 
                className="w-full h-12 rounded-xl border border-border-soft bg-canvas px-4 focus:outline-none text-sm" 
                value={formData.type || "Public"} 
                onChange={(e) => setFormData({...formData, type: e.target.value})}
              >
                <option value="Public">Public</option>
                <option value="Privé">Privé</option>
                <option value="Confessionnel">Confessionnel</option>
                <option value="International">International</option>
              </select>
            </div>
            <Input 
              label="Ville" 
              value={formData.city || ""} 
              onChange={(e) => setFormData({...formData, city: e.target.value})} 
              placeholder="ex: Lomé, Kara"
            />
            <Input 
              label="Taux d'insertion professionnelle" 
              value={formData.insertionRate || ""} 
              onChange={(e) => setFormData({...formData, insertionRate: e.target.value})} 
              placeholder="ex: 85%"
            />
            <Input 
              label="Note d'évaluation" 
              value={formData.rating || ""} 
              onChange={(e) => setFormData({...formData, rating: e.target.value})} 
              placeholder="ex: 4.6"
            />
            <div className="md:col-span-2">
              <Input 
                label="Équipements (séparés par des virgules)" 
                value={formData.facilitiesString || ""} 
                onChange={(e) => setFormData({...formData, facilitiesString: e.target.value})} 
                placeholder="ex: Campus, Bibliothèque, Laboratoires, Wi-Fi"
              />
            </div>
            <div className="md:col-span-2">
              <ImageUpload 
                label="Image / Logo de l'établissement" 
                value={formData.bannerImage || ""} 
                onChange={(url) => setFormData({...formData, bannerImage: url})} 
                bucket="schools"
              />
            </div>
          </div>

          <div className="flex flex-col gap-1">
            <label className="text-sm font-bold text-text-primary">Description</label>
            <textarea 
              className="w-full rounded-xl border border-border-soft bg-canvas p-3 focus:outline-none focus:ring-2 focus:ring-primary/50 text-sm" 
              rows={3} 
              value={formData.description || ""} 
              onChange={(e) => setFormData({...formData, description: e.target.value})}
              placeholder="Présentation de l'établissement, histoire, accréditations..."
            ></textarea>
          </div>

          <label className="flex items-center gap-3 cursor-pointer pt-2">
            <input 
              type="checkbox" 
              checked={formData.isPublished ?? true} 
              onChange={(e) => setFormData({...formData, isPublished: e.target.checked})}
              className="w-5 h-5 text-primary rounded border-border-soft focus:ring-primary"
            />
            <span className="text-sm font-medium text-text-primary">
              Publier cette école (visible par les étudiants)
            </span>
          </label>
        </div>
      );
    }

    if (activeTab === "programs") {
      return (
        <div className="flex flex-col gap-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Input 
              label="Titre de la formation *" 
              value={formData.title || ""} 
              onChange={(e) => setFormData({...formData, title: e.target.value})} 
              placeholder="ex: Licence en Génie Logiciel"
              required 
            />
            <Input 
              label="Identifiant URL (slug)" 
              value={formData.slug || ""} 
              onChange={(e) => setFormData({...formData, slug: e.target.value})} 
              placeholder="ex: licence-genie-logiciel"
            />

            <div className="flex flex-col gap-1">
              <label className="text-sm font-bold text-text-primary">Établissement rattaché *</label>
              <select 
                className="w-full h-12 rounded-xl border border-border-soft bg-canvas px-4 focus:outline-none text-sm" 
                required 
                value={formData.schoolId || ""} 
                onChange={(e) => setFormData({...formData, schoolId: e.target.value})}
              >
                <option value="">Sélectionner une école...</option>
                {schools.map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
              </select>
            </div>

            <div className="flex flex-col gap-1">
              <label className="text-sm font-bold text-text-primary">Domaine d'études *</label>
              <select 
                className="w-full h-12 rounded-xl border border-border-soft bg-canvas px-4 focus:outline-none text-sm" 
                required 
                value={formData.domainId || ""} 
                onChange={(e) => setFormData({...formData, domainId: e.target.value})}
              >
                <option value="">Sélectionner un domaine...</option>
                {domains.map(d => <option key={d.id} value={d.id}>{d.title}</option>)}
              </select>
            </div>

            <Input 
              label="Niveau de diplôme" 
              value={formData.level || ""} 
              onChange={(e) => setFormData({...formData, level: e.target.value})} 
              placeholder="ex: Licence (Bac+3) ou Master"
            />
            <Input 
              label="Durée du cursus" 
              value={formData.duration || ""} 
              onChange={(e) => setFormData({...formData, duration: e.target.value})} 
              placeholder="ex: 3 ans"
            />
            <Input 
              label="Accréditation / Reconnaissance" 
              value={formData.status || ""} 
              onChange={(e) => setFormData({...formData, status: e.target.value})} 
              placeholder="ex: Reconnu CAMES / État togolais"
            />
            <div className="md:col-span-2">
              <ImageUpload 
                label="Image de la formation" 
                value={formData.bannerImage || ""} 
                onChange={(url) => setFormData({...formData, bannerImage: url})} 
                bucket="programs"
              />
            </div>
            <div className="md:col-span-2">
              <Input 
                label="Matières clés (séparées par des virgules)" 
                value={formData.programCoursesString || ""} 
                onChange={(e) => setFormData({...formData, programCoursesString: e.target.value})} 
                placeholder="ex: Algorithmique, Bases de données, Sécurité, Réseaux"
              />
            </div>
          </div>

          <div className="flex flex-col gap-1">
            <label className="text-sm font-bold text-text-primary">Conditions d'admission</label>
            <textarea 
              className="w-full rounded-xl border border-border-soft bg-canvas p-3 focus:outline-none focus:ring-2 focus:ring-primary/50 text-sm" 
              rows={2} 
              value={formData.admission || ""} 
              onChange={(e) => setFormData({...formData, admission: e.target.value})}
              placeholder="ex: Bac séries C, D ou E avec mention, sélection sur dossier..."
            ></textarea>
          </div>

          <div className="flex flex-col gap-1">
            <label className="text-sm font-bold text-text-primary">Description</label>
            <textarea 
              className="w-full rounded-xl border border-border-soft bg-canvas p-3 focus:outline-none focus:ring-2 focus:ring-primary/50 text-sm" 
              rows={3} 
              value={formData.description || ""} 
              onChange={(e) => setFormData({...formData, description: e.target.value})}
              placeholder="Objectifs pédagogiques, profils formés..."
            ></textarea>
          </div>

          <label className="flex items-center gap-3 cursor-pointer pt-2">
            <input 
              type="checkbox" 
              checked={formData.isPublished ?? true} 
              onChange={(e) => setFormData({...formData, isPublished: e.target.checked})}
              className="w-5 h-5 text-primary rounded border-border-soft focus:ring-primary"
            />
            <span className="text-sm font-medium text-text-primary">
              Publier cette formation (visible par les étudiants)
            </span>
          </label>
        </div>
      );
    }

    if (activeTab === "careers") {
      return (
        <div className="flex flex-col gap-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Input 
              label="Titre du métier *" 
              value={formData.title || ""} 
              onChange={(e) => setFormData({...formData, title: e.target.value})} 
              placeholder="ex: Ingénieur DevOps"
              required 
            />
            <Input 
              label="Identifiant URL (slug)" 
              value={formData.slug || ""} 
              onChange={(e) => setFormData({...formData, slug: e.target.value})} 
              placeholder="ex: ingenieur-devops"
            />

            <div className="flex flex-col gap-1">
              <label className="text-sm font-bold text-text-primary">Domaine rattaché *</label>
              <select 
                className="w-full h-12 rounded-xl border border-border-soft bg-canvas px-4 focus:outline-none text-sm" 
                required 
                value={formData.domainId || ""} 
                onChange={(e) => setFormData({...formData, domainId: e.target.value})}
              >
                <option value="">Sélectionner un domaine...</option>
                {domains.map(d => <option key={d.id} value={d.id}>{d.title}</option>)}
              </select>
            </div>

            <div className="md:col-span-2">
              <ImageUpload 
                label="Image du métier" 
                value={formData.bannerImage || ""} 
                onChange={(url) => setFormData({...formData, bannerImage: url})} 
                bucket="careers"
              />
            </div>

            <div className="md:col-span-2">
              <Input 
                label="Compétences requises (séparées par des virgules)" 
                value={formData.skillsString || ""} 
                onChange={(e) => setFormData({...formData, skillsString: e.target.value})} 
                placeholder="ex: Linux, Docker, CI/CD, Python, Sécurité"
              />
            </div>

            <div className="md:col-span-2">
              <Input 
                label="Débouchés & Postes associés (séparés par des virgules)" 
                value={formData.opportunitiesString || ""} 
                onChange={(e) => setFormData({...formData, opportunitiesString: e.target.value})} 
                placeholder="ex: Architecte Cloud, Administrateur Système, Ingénieur SRE"
              />
            </div>
          </div>

          <div className="flex flex-col gap-1">
            <label className="text-sm font-bold text-text-primary">Description du métier</label>
            <textarea 
              className="w-full rounded-xl border border-border-soft bg-canvas p-3 focus:outline-none focus:ring-2 focus:ring-primary/50 text-sm" 
              rows={3} 
              value={formData.description || ""} 
              onChange={(e) => setFormData({...formData, description: e.target.value})}
              placeholder="Rôle au quotidien, missions, environnement de travail..."
            ></textarea>
          </div>

          <label className="flex items-center gap-3 cursor-pointer pt-2">
            <input 
              type="checkbox" 
              checked={formData.isPublished ?? true} 
              onChange={(e) => setFormData({...formData, isPublished: e.target.checked})}
              className="w-5 h-5 text-primary rounded border-border-soft focus:ring-primary"
            />
            <span className="text-sm font-medium text-text-primary">
              Publier cette fiche métier (visible par les étudiants)
            </span>
          </label>
        </div>
      );
    }

    return null;
  };

  return (
    <div className="flex flex-col gap-6 animate-fade-in relative">
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-display font-bold text-text-primary mb-1">Explorateur (Admin)</h1>
          <p className="text-text-secondary text-sm">
            Gérez et éditez les domaines, écoles togolaises, formations et métiers.
          </p>
        </div>
        <Button 
          className="flex items-center gap-2 self-start sm:self-auto" 
          onClick={handleOpenCreate}
        >
          <Plus className="w-4 h-4" /> Créer un élément
        </Button>
      </div>

      {/* Floating Notification */}
      {feedback && (
        <div className={`p-4 rounded-xl flex items-center gap-3 border ${
          feedback.type === "success" 
            ? "bg-success/10 text-success border-success/20" 
            : "bg-error/10 text-error border-error/20"
        }`}>
          {feedback.type === "success" ? (
            <CheckCircle2 className="w-5 h-5 shrink-0" />
          ) : (
            <AlertCircle className="w-5 h-5 shrink-0" />
          )}
          <p className="text-sm font-semibold">{feedback.message}</p>
        </div>
      )}

      {/* Form Drawer / Card */}
      {showForm && (
        <Card variant="standard" className="p-6 border-primary/30 shadow-md">
          <div className="flex justify-between items-center mb-6 pb-4 border-b border-border-soft">
            <div>
              <h2 className="text-xl font-bold text-text-primary">
                {isEditing ? "Modifier :" : "Créer dans :"} {tabs.find(t => t.id === activeTab)?.label}
              </h2>
              {isEditing && (
                <p className="text-xs text-text-secondary mt-1">
                  ID : {editingItem?.id}
                </p>
              )}
            </div>
            <button 
              onClick={() => { setShowForm(false); setEditingItem(null); }} 
              className="p-2 hover:bg-surface rounded-md text-text-secondary transition-colors"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          <form onSubmit={handleSubmit}>
            {renderFormFields()}
            <div className="flex justify-end gap-3 mt-6 pt-4 border-t border-border-soft">
              <Button 
                type="button" 
                variant="outline" 
                onClick={() => { setShowForm(false); setEditingItem(null); }}
              >
                Annuler
              </Button>
              <Button type="submit" disabled={loading}>
                {loading ? "Enregistrement..." : (isEditing ? "Mettre à jour" : "Créer")}
              </Button>
            </div>
          </form>
        </Card>
      )}

      {/* Category Tabs & Search Bar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="flex gap-1.5 bg-surface p-1.5 rounded-xl border border-border-soft overflow-x-auto">
          {tabs.map((tab) => {
            const Icon = tab.icon;
            const isActive = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => { 
                  setActiveTab(tab.id); 
                  setShowForm(false); 
                  setEditingItem(null);
                  setFormData({}); 
                }}
                className={`flex items-center gap-2 px-4 py-2.5 rounded-lg text-sm font-bold transition-all whitespace-nowrap ${
                  isActive ? "bg-primary text-white shadow-sm" : "text-text-secondary hover:text-text-primary"
                }`}
              >
                <Icon className="w-4 h-4" />
                {tab.label}
              </button>
            );
          })}
        </div>

        {/* Search */}
        <div className="flex items-center gap-2 bg-surface px-3 py-2 rounded-xl border border-border-soft w-full sm:w-72">
          <Search className="w-4 h-4 text-text-secondary shrink-0" />
          <input 
            type="text" 
            placeholder={`Rechercher un élément...`}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="bg-transparent border-none outline-none text-sm w-full text-text-primary placeholder:text-text-secondary"
          />
        </div>
      </div>

      {/* Table Data */}
      <Card variant="standard" className="p-0 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-surface-alt border-b border-border-soft">
                <th className="p-4 font-bold text-xs uppercase tracking-wider text-text-secondary">Titre / Nom</th>
                <th className="p-4 font-bold text-xs uppercase tracking-wider text-text-secondary">Identifiant (URL)</th>
                <th className="p-4 font-bold text-xs uppercase tracking-wider text-text-secondary">Statut</th>
                <th className="p-4 font-bold text-xs uppercase tracking-wider text-text-secondary text-right pr-6">Actions</th>
              </tr>
            </thead>
            <tbody>
              {currentList.length > 0 ? (
                currentList.map((item) => {
                  const title = item.name || item.title;
                  const isPub = !!item.isPublished;

                  return (
                    <tr 
                      key={item.id} 
                      className="border-b border-border-soft hover:bg-surface-alt/50 transition-colors"
                    >
                      <td className="p-4">
                        <div className="flex flex-col">
                          <span className="font-bold text-sm text-text-primary">{title}</span>
                          {activeTab === "schools" && item.city && (
                            <span className="text-xs text-text-secondary">{item.type || "Établissement"} • {item.city}</span>
                          )}
                          {activeTab === "programs" && (
                            <span className="text-xs text-text-secondary">
                              {schools.find(s => s.id === item.schoolId)?.name || "École"} • {domains.find(d => d.id === item.domainId)?.title || "Domaine"}
                            </span>
                          )}
                          {activeTab === "careers" && (
                            <span className="text-xs text-text-secondary">
                              {domains.find(d => d.id === item.domainId)?.title || "Domaine"}
                            </span>
                          )}
                        </div>
                      </td>

                      <td className="p-4 text-sm text-text-secondary font-mono">
                        {item.slug || "-"}
                      </td>

                      <td className="p-4">
                        <button
                          onClick={() => handleTogglePublish(item)}
                          title="Cliquez pour changer le statut"
                          className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs font-bold transition-all ${
                            isPub 
                              ? "bg-success/10 text-success border border-success/30 hover:bg-success/20" 
                              : "bg-surface text-text-secondary border border-border-soft hover:bg-surface-alt"
                          }`}
                        >
                          {isPub ? <Eye className="w-3.5 h-3.5" /> : <EyeOff className="w-3.5 h-3.5" />}
                          {isPub ? "Publié" : "Brouillon"}
                        </button>
                      </td>

                      <td className="p-4 pr-6">
                        <div className="flex items-center justify-end gap-2">
                          <button 
                            onClick={() => handleStartEdit(item)}
                            title="Modifier"
                            className="p-2 text-primary hover:bg-primary/10 rounded-lg border border-border-soft transition-colors"
                          >
                            <Edit className="w-4 h-4" />
                          </button>
                          <button 
                            onClick={() => handleDelete(item)}
                            title="Supprimer"
                            className="p-2 text-error hover:bg-error/10 rounded-lg border border-border-soft transition-colors"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })
              ) : (
                <tr>
                  <td colSpan={4} className="p-10 text-center text-text-secondary text-sm">
                    {searchTerm 
                      ? "Aucun résultat trouvé pour votre recherche." 
                      : "Aucun élément enregistré dans cette catégorie. Cliquez sur « Créer un élément » pour en ajouter un."}
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </Card>
    </div>
  );
}
