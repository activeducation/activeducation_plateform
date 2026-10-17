"use client";

import React, { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Input } from "@/components/ui/Input";
import { ImageUpload } from "@/components/ui/ImageUpload";
import { ArrowLeft, Save } from "lucide-react";
import { LessonsManager } from "@/components/admin/LessonsManager";

export default function AdminEditCoursePage({ params }: { params: Promise<{ id: string }> }) {
  const unwrappedParams = React.use(params);
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [initialLoad, setInitialLoad] = useState(true);
  
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

  useEffect(() => {
    fetch(`/api/admin/courses/${unwrappedParams.id}`)
      .then(res => res.json())
      .then(data => {
        if (data && !data.error) {
          setFormData({
            title: data.title || "",
            category: data.category || "Soft Skills & Leadership",
            difficulty: data.difficulty || "Débutant",
            description: data.description || "",
            icon: data.icon || "Users",
            color: data.color || "from-blue-500 to-primary",
            image: data.image || "",
            isPublished: data.isPublished !== undefined ? data.isPublished : true,
          });
        }
        setInitialLoad(false);
      })
      .catch(err => {
        console.error(err);
        setInitialLoad(false);
      });
  }, [unwrappedParams.id]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    
    try {
      const res = await fetch(`/api/admin/courses/${unwrappedParams.id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(formData)
      });
      
      if (res.ok) {
        router.push("/admin/cours");
      } else {
        alert("Erreur lors de la modification");
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

  if (initialLoad) {
    return <div className="p-8 text-center text-text-secondary">Chargement...</div>;
  }

  return (
    <div className="flex flex-col gap-6 max-w-3xl mx-auto animate-fade-in">
      <div className="flex items-center gap-4 mb-4">
        <Link href="/admin/cours" className="p-2 bg-surface border border-border-soft rounded-full hover:bg-surface-alt transition-colors">
          <ArrowLeft className="w-5 h-5 text-text-secondary" />
        </Link>
        <div>
          <h1 className="text-2xl font-display font-bold text-text-primary">Modifier le cours</h1>
          <p className="text-sm text-text-secondary">Mettez à jour les informations du cours.</p>
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
            <div className="flex flex-col gap-2 md:col-span-2">
              <label className="text-sm font-bold text-text-primary">Nom de l'icône Lucide</label>
              <Input name="icon" value={formData.icon} onChange={handleChange} placeholder="Ex: Users, Monitor, Briefcase..." />
            </div>
            <div className="md:col-span-2">
              <ImageUpload
                label="Image de couverture du cours"
                value={formData.image || ""}
                onChange={(url) => setFormData(prev => ({ ...prev, image: url }))}
                bucket="elearning"
              />
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
            <Save className="w-4 h-4" /> {loading ? "Enregistrement..." : "Enregistrer"}
          </Button>
        </div>
      </form>

      <LessonsManager courseId={unwrappedParams.id} />
    </div>
  );
}
