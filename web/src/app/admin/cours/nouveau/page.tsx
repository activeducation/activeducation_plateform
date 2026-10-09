"use client";

import React, { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Input } from "@/components/ui/Input";
import { ArrowLeft, Save } from "lucide-react";

export default function AdminNewCoursePage() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  
  const [formData, setFormData] = useState({
    title: "",
    category: "Soft Skills & Leadership",
    difficulty: "Débutant",
    description: "",
    icon: "Users",
    color: "from-blue-500 to-primary",
    image: "",
    isPublished: true,
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    
    try {
      const res = await fetch("/api/admin/courses", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(formData)
      });
      
      if (res.ok) {
        router.push("/admin/cours");
      } else {
        alert("Erreur lors de la création");
      }
    } catch (err) {
      console.error(err);
      alert("Erreur réseau");
    } finally {
      setLoading(false);
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    const { name, value, type } = e.target;
    const val = type === 'checkbox' ? (e.target as HTMLInputElement).checked : value;
    setFormData(prev => ({ ...prev, [name]: val }));
  };

  return (
    <div className="flex flex-col gap-6 max-w-3xl mx-auto animate-fade-in">
      <div className="flex items-center gap-4 mb-4">
        <Link href="/admin/cours" className="p-2 bg-surface border border-border-soft rounded-full hover:bg-surface-alt transition-colors">
          <ArrowLeft className="w-5 h-5 text-text-secondary" />
        </Link>
        <div>
          <h1 className="text-2xl font-display font-bold text-text-primary">Nouveau cours</h1>
          <p className="text-sm text-text-secondary">Créez un nouveau parcours E-learning.</p>
        </div>
      </div>

      <form onSubmit={handleSubmit} className="flex flex-col gap-6">
        <Card variant="standard" className="p-6 flex flex-col gap-5">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
            <div className="flex flex-col gap-2">
              <label className="text-sm font-bold text-text-primary">Titre du cours</label>
              <Input name="title" value={formData.title} onChange={handleChange} required placeholder="Ex: Art de la Négociation" />
            </div>
            
            <div className="flex flex-col gap-2">
              <label className="text-sm font-bold text-text-primary">Catégorie</label>
              <select 
                name="category" 
                value={formData.category} 
                onChange={handleChange}
                className="w-full px-4 py-3 bg-surface border border-border-soft rounded-xl text-text-primary focus:outline-none focus:border-primary transition-colors appearance-none"
              >
                <option value="Soft Skills & Leadership">Soft Skills & Leadership</option>
                <option value="Initiation à la Tech">Initiation à la Tech</option>
                <option value="Insertion Pro">Insertion Pro</option>
                <option value="Langues & Communication">Langues & Communication</option>
              </select>
            </div>
            
            <div className="flex flex-col gap-2">
              <label className="text-sm font-bold text-text-primary">Niveau de difficulté</label>
              <select 
                name="difficulty" 
                value={formData.difficulty} 
                onChange={handleChange}
                className="w-full px-4 py-3 bg-surface border border-border-soft rounded-xl text-text-primary focus:outline-none focus:border-primary transition-colors appearance-none"
              >
                <option value="Débutant">Débutant</option>
                <option value="Intermédiaire">Intermédiaire</option>
                <option value="Avancé">Avancé</option>
              </select>
            </div>
            
            <div className="flex flex-col gap-2">
              <label className="text-sm font-bold text-text-primary">Couleur de thème (Tailwind classes)</label>
              <Input name="color" value={formData.color} onChange={handleChange} placeholder="Ex: from-blue-500 to-primary" />
            </div>
          </div>

          <div className="flex flex-col gap-2">
            <label className="text-sm font-bold text-text-primary">Description complète</label>
            <textarea 
              name="description" 
              value={formData.description} 
              onChange={handleChange} 
              rows={4}
              placeholder="Objectifs d'apprentissage, public cible..."
              className="w-full px-4 py-3 bg-surface border border-border-soft rounded-xl text-text-primary focus:outline-none focus:border-primary transition-colors resize-none"
            />
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
            <div className="flex flex-col gap-2">
              <label className="text-sm font-bold text-text-primary">Nom de l'icône Lucide</label>
              <Input name="icon" value={formData.icon} onChange={handleChange} placeholder="Ex: Users, Monitor, Briefcase..." />
            </div>
            <div className="flex flex-col gap-2">
              <label className="text-sm font-bold text-text-primary">URL de l'image (Optionnelle)</label>
              <Input name="image" value={formData.image} onChange={handleChange} placeholder="https://..." />
            </div>
          </div>
          
          <div className="flex items-center gap-3 pt-4 border-t border-border-soft">
            <input 
              type="checkbox" 
              id="isPublished" 
              name="isPublished"
              checked={formData.isPublished}
              onChange={handleChange}
              className="w-5 h-5 rounded border-border-soft text-primary focus:ring-primary"
            />
            <label htmlFor="isPublished" className="text-sm font-bold text-text-primary cursor-pointer">
              Publier immédiatement
            </label>
          </div>
        </Card>

        <div className="flex justify-end gap-4">
          <Link href="/admin/cours">
            <Button variant="secondary" type="button">Annuler</Button>
          </Link>
          <Button type="submit" disabled={loading} className="flex items-center gap-2">
            <Save className="w-4 h-4" /> {loading ? "Création..." : "Créer le cours"}
          </Button>
        </div>
      </form>
    </div>
  );
}
