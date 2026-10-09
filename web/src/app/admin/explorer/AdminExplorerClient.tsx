"use client";

import React, { useState } from "react";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Plus, Edit, Trash2, Map, Building2, GraduationCap, Briefcase, X } from "lucide-react";
import { Input } from "@/components/ui/Input";

export default function AdminExplorerClient({
  initialDomains,
  initialSchools,
  initialPrograms,
  initialCareers
}: {
  initialDomains: any[];
  initialSchools: any[];
  initialPrograms: any[];
  initialCareers: any[];
}) {
  const [activeTab, setActiveTab] = useState("domains");
  const [showForm, setShowForm] = useState(false);
  const [loading, setLoading] = useState(false);

  // States for lists
  const [domains, setDomains] = useState(initialDomains);
  const [schools, setSchools] = useState(initialSchools);
  const [programs, setPrograms] = useState(initialPrograms);
  const [careers, setCareers] = useState(initialCareers);

  // Form states
  const [formData, setFormData] = useState<any>({});

  const tabs = [
    { id: "domains", label: "Domaines", icon: Map },
    { id: "schools", label: "Écoles", icon: Building2 },
    { id: "programs", label: "Formations", icon: GraduationCap },
    { id: "careers", label: "Métiers", icon: Briefcase },
  ];

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      const res = await fetch(`/api/admin/explorer/${activeTab}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(formData)
      });

      if (!res.ok) {
        const err = await res.json();
        alert(err.error || "Erreur lors de la création");
        setLoading(false);
        return;
      }

      const newItem = await res.json();

      if (activeTab === "domains") setDomains([newItem, ...domains]);
      if (activeTab === "schools") setSchools([newItem, ...schools]);
      if (activeTab === "programs") setPrograms([newItem, ...programs]);
      if (activeTab === "careers") setCareers([newItem, ...careers]);

      setShowForm(false);
      setFormData({});
    } catch (err) {
      alert("Erreur réseau");
    } finally {
      setLoading(false);
    }
  };

  const renderForm = () => {
    if (activeTab === "domains") {
      return (
        <>
          <div className="grid grid-cols-2 gap-4 mb-4">
            <Input label="Titre" value={formData.title || ""} onChange={(e) => setFormData({...formData, title: e.target.value})} required />
            <Input label="Identifiant URL (Laisser vide pour auto-générer)" value={formData.slug || ""} onChange={(e) => setFormData({...formData, slug: e.target.value})} />
            <Input label="Image Bannière (URL)" value={formData.bannerImage || ""} onChange={(e) => setFormData({...formData, bannerImage: e.target.value})} />
            <Input label="Croissance (ex: +15%)" value={formData.growth || ""} onChange={(e) => setFormData({...formData, growth: e.target.value})} />
            <Input label="Employabilité" value={formData.employability || ""} onChange={(e) => setFormData({...formData, employability: e.target.value})} />
            <Input label="Rémunération" value={formData.salary || ""} onChange={(e) => setFormData({...formData, salary: e.target.value})} />
          </div>
          <div className="flex flex-col gap-1 mb-4">
            <label className="text-sm font-bold text-text-primary">Description</label>
            <textarea className="w-full rounded-xl border border-border-soft bg-canvas p-3 focus:outline-none focus:ring-2 focus:ring-primary/50 text-sm" rows={3} value={formData.description || ""} onChange={(e) => setFormData({...formData, description: e.target.value})}></textarea>
          </div>
        </>
      );
    }

    if (activeTab === "schools") {
      return (
        <div className="grid grid-cols-2 gap-4 mb-4">
          <Input label="Nom de l'établissement" value={formData.name || ""} onChange={(e) => setFormData({...formData, name: e.target.value})} required />
          <Input label="Type (ex: Public)" value={formData.type || ""} onChange={(e) => setFormData({...formData, type: e.target.value})} />
          <Input label="Ville" value={formData.city || ""} onChange={(e) => setFormData({...formData, city: e.target.value})} />
          <Input label="Taux d'insertion" value={formData.insertionRate || ""} onChange={(e) => setFormData({...formData, insertionRate: e.target.value})} />
          <Input label="Note (ex: 4.5)" value={formData.rating || ""} onChange={(e) => setFormData({...formData, rating: e.target.value})} />
          <Input label="Image (URL)" value={formData.bannerImage || ""} onChange={(e) => setFormData({...formData, bannerImage: e.target.value})} />
        </div>
      );
    }

    if (activeTab === "programs") {
      return (
        <div className="grid grid-cols-2 gap-4 mb-4">
          <Input label="Titre de la formation" value={formData.title || ""} onChange={(e) => setFormData({...formData, title: e.target.value})} required />
          
          <div className="flex flex-col gap-1">
            <label className="text-sm font-bold text-text-primary">École rattachée</label>
            <select className="w-full h-12 rounded-xl border border-border-soft bg-canvas px-4 focus:outline-none text-sm" required value={formData.schoolId || ""} onChange={(e) => setFormData({...formData, schoolId: e.target.value})}>
              <option value="">Sélectionner une école...</option>
              {schools.map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
            </select>
          </div>

          <div className="flex flex-col gap-1">
            <label className="text-sm font-bold text-text-primary">Domaine</label>
            <select className="w-full h-12 rounded-xl border border-border-soft bg-canvas px-4 focus:outline-none text-sm" required value={formData.domainId || ""} onChange={(e) => setFormData({...formData, domainId: e.target.value})}>
              <option value="">Sélectionner un domaine...</option>
              {domains.map(d => <option key={d.id} value={d.id}>{d.title}</option>)}
            </select>
          </div>

          <Input label="Niveau (ex: Bac+3)" value={formData.level || ""} onChange={(e) => setFormData({...formData, level: e.target.value})} />
          <Input label="Durée (ex: 3 ans)" value={formData.duration || ""} onChange={(e) => setFormData({...formData, duration: e.target.value})} />
        </div>
      );
    }

    if (activeTab === "careers") {
      return (
        <div className="grid grid-cols-2 gap-4 mb-4">
          <Input label="Titre du métier" value={formData.title || ""} onChange={(e) => setFormData({...formData, title: e.target.value})} required />
          
          <div className="flex flex-col gap-1">
            <label className="text-sm font-bold text-text-primary">Domaine</label>
            <select className="w-full h-12 rounded-xl border border-border-soft bg-canvas px-4 focus:outline-none text-sm" required value={formData.domainId || ""} onChange={(e) => setFormData({...formData, domainId: e.target.value})}>
              <option value="">Sélectionner un domaine...</option>
              {domains.map(d => <option key={d.id} value={d.id}>{d.title}</option>)}
            </select>
          </div>
          
          <Input label="Image (URL)" value={formData.bannerImage || ""} onChange={(e) => setFormData({...formData, bannerImage: e.target.value})} />
        </div>
      );
    }
  };

  return (
    <div className="flex flex-col gap-6 animate-fade-in relative">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-display font-bold text-text-primary mb-2">Explorateur (Admin)</h1>
          <p className="text-text-secondary">Gérez les domaines, métiers, formations et écoles.</p>
        </div>
        <Button className="flex items-center gap-2" onClick={() => setShowForm(true)}>
          <Plus className="w-4 h-4" /> Créer
        </Button>
      </div>

      <div className="flex gap-2 bg-surface p-1 rounded-xl w-fit border border-border-soft">
        {tabs.map((tab) => {
          const Icon = tab.icon;
          const isActive = activeTab === tab.id;
          return (
            <button
              key={tab.id}
              onClick={() => { setActiveTab(tab.id); setShowForm(false); setFormData({}); }}
              className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-bold transition-all ${
                isActive ? "bg-primary text-white shadow-sm" : "text-text-secondary hover:text-text-primary"
              }`}
            >
              <Icon className="w-4 h-4" />
              {tab.label}
            </button>
          );
        })}
      </div>

      {showForm && (
        <Card variant="standard" className="p-6 border-primary/30">
          <div className="flex justify-between items-center mb-6">
            <h2 className="text-xl font-bold text-text-primary">Créer : {tabs.find(t => t.id === activeTab)?.label}</h2>
            <button onClick={() => setShowForm(false)} className="p-2 hover:bg-surface rounded-md">
              <X className="w-5 h-5 text-text-secondary" />
            </button>
          </div>
          <form onSubmit={handleCreate}>
            {renderForm()}
            <div className="flex justify-end gap-3 mt-6">
              <Button type="button" variant="outline" onClick={() => setShowForm(false)}>Annuler</Button>
              <Button type="submit" disabled={loading}>{loading ? "Création..." : "Enregistrer"}</Button>
            </div>
          </form>
        </Card>
      )}

      <Card variant="standard" className="p-0 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-surface-alt border-b border-border-soft">
                <th className="p-4 font-bold text-sm text-text-secondary">Titre / Nom</th>
                <th className="p-4 font-bold text-sm text-text-secondary">Identifiant URL</th>
                <th className="p-4 font-bold text-sm text-text-secondary">Statut</th>
                <th className="p-4 font-bold text-sm text-text-secondary w-24 text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {activeTab === "domains" && domains.map(item => (
                <tr key={item.id} className="border-b border-border-soft hover:bg-surface-alt/50 transition-colors">
                  <td className="p-4 text-sm font-bold text-text-primary">{item.title}</td>
                  <td className="p-4 text-sm text-text-secondary">{item.slug}</td>
                  <td className="p-4 text-sm">{item.isPublished ? "Publié" : "Brouillon"}</td>
                  <td className="p-4 flex gap-2 justify-end">
                    <button className="p-2 text-text-secondary hover:text-primary bg-surface rounded-md border border-border-soft transition-colors"><Edit className="w-4 h-4" /></button>
                    <button className="p-2 text-text-secondary hover:text-error bg-surface rounded-md border border-border-soft transition-colors"><Trash2 className="w-4 h-4" /></button>
                  </td>
                </tr>
              ))}
              {activeTab === "schools" && schools.map(item => (
                <tr key={item.id} className="border-b border-border-soft hover:bg-surface-alt/50 transition-colors">
                  <td className="p-4 text-sm font-bold text-text-primary">{item.name}</td>
                  <td className="p-4 text-sm text-text-secondary">{item.slug}</td>
                  <td className="p-4 text-sm">{item.isPublished ? "Publié" : "Brouillon"}</td>
                  <td className="p-4 flex gap-2 justify-end">
                    <button className="p-2 text-text-secondary hover:text-primary bg-surface rounded-md border border-border-soft transition-colors"><Edit className="w-4 h-4" /></button>
                    <button className="p-2 text-text-secondary hover:text-error bg-surface rounded-md border border-border-soft transition-colors"><Trash2 className="w-4 h-4" /></button>
                  </td>
                </tr>
              ))}
              {activeTab === "programs" && programs.map(item => (
                <tr key={item.id} className="border-b border-border-soft hover:bg-surface-alt/50 transition-colors">
                  <td className="p-4 text-sm font-bold text-text-primary">{item.title}</td>
                  <td className="p-4 text-sm text-text-secondary">{item.slug}</td>
                  <td className="p-4 text-sm">{item.isPublished ? "Publié" : "Brouillon"}</td>
                  <td className="p-4 flex gap-2 justify-end">
                    <button className="p-2 text-text-secondary hover:text-primary bg-surface rounded-md border border-border-soft transition-colors"><Edit className="w-4 h-4" /></button>
                    <button className="p-2 text-text-secondary hover:text-error bg-surface rounded-md border border-border-soft transition-colors"><Trash2 className="w-4 h-4" /></button>
                  </td>
                </tr>
              ))}
              {activeTab === "careers" && careers.map(item => (
                <tr key={item.id} className="border-b border-border-soft hover:bg-surface-alt/50 transition-colors">
                  <td className="p-4 text-sm font-bold text-text-primary">{item.title}</td>
                  <td className="p-4 text-sm text-text-secondary">{item.slug}</td>
                  <td className="p-4 text-sm">{item.isPublished ? "Publié" : "Brouillon"}</td>
                  <td className="p-4 flex gap-2 justify-end">
                    <button className="p-2 text-text-secondary hover:text-primary bg-surface rounded-md border border-border-soft transition-colors"><Edit className="w-4 h-4" /></button>
                    <button className="p-2 text-text-secondary hover:text-error bg-surface rounded-md border border-border-soft transition-colors"><Trash2 className="w-4 h-4" /></button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>
    </div>
  );
}
