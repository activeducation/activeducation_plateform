"use client";

import React, { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Input } from "@/components/ui/Input";
import { ArrowLeft, Save } from "lucide-react";

export default function AdminEditOpportunityPage({ params }: { params: Promise<{ id: string }> }) {
  const unwrappedParams = React.use(params);
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [initialLoad, setInitialLoad] = useState(true);
  
  const [formData, setFormData] = useState({
    title: "",
    type: "bourse",
    provider: "",
    description: "",
    location: "",
    amountOrSalary: "",
    link: "",
    image: "",
    deadline: "",
    isPublished: true,
  });

  React.useEffect(() => {
    fetch(`/api/admin/opportunities/${unwrappedParams.id}`)
      .then(res => res.json())
      .then(data => {
        if (data && !data.error) {
          setFormData({
            title: data.title || "",
            type: data.type || "bourse",
            provider: data.provider || "",
            description: data.description || "",
            location: data.location || "",
            amountOrSalary: data.amountOrSalary || "",
            link: data.link || "",
            image: data.image || "",
            deadline: data.deadline ? data.deadline.substring(0, 10) : "",
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
      const res = await fetch(`/api/admin/opportunities/${unwrappedParams.id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(formData)
      });
      
      if (res.ok) {
        router.push("/admin/opportunites");
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
        <Link href="/admin/opportunites" className="p-2 bg-surface border border-border-soft rounded-full hover:bg-surface-alt transition-colors">
          <ArrowLeft className="w-5 h-5 text-text-secondary" />
        </Link>
        <div>
          <h1 className="text-2xl font-display font-bold text-text-primary">Modifier l'opportunité</h1>
          <p className="text-sm text-text-secondary">Mettez à jour les informations de cette opportunité.</p>
        </div>
      </div>

      <form onSubmit={handleSubmit} className="flex flex-col gap-6">
        <Card variant="standard" className="p-6 flex flex-col gap-5">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
            <div className="flex flex-col gap-2">
              <label className="text-sm font-bold text-text-primary">Type</label>
              <select 
                name="type" 
                value={formData.type} 
                onChange={handleChange}
                className="w-full px-4 py-3 bg-surface border border-border-soft rounded-xl text-text-primary focus:outline-none focus:border-primary transition-colors appearance-none"
              >
                <option value="bourse">Bourse d'études</option>
                <option value="stage">Stage / Emploi</option>
                <option value="evenement">Événement</option>
              </select>
            </div>
            
            <div className="flex flex-col gap-2">
              <label className="text-sm font-bold text-text-primary">Titre</label>
              <Input name="title" value={formData.title} onChange={handleChange} required placeholder="Ex: Bourse d'Excellence..." />
            </div>
            
            <div className="flex flex-col gap-2">
              <label className="text-sm font-bold text-text-primary">Prestataire / Organisateur</label>
              <Input name="provider" value={formData.provider} onChange={handleChange} placeholder="Ex: État Togolais" />
            </div>
            
            <div className="flex flex-col gap-2">
              <label className="text-sm font-bold text-text-primary">Lieu de validité</label>
              <Input name="location" value={formData.location} onChange={handleChange} placeholder="Ex: Universités Publiques du Togo" />
            </div>
            
            <div className="flex flex-col gap-2">
              <label className="text-sm font-bold text-text-primary">Montant / Couverture</label>
              <Input name="amountOrSalary" value={formData.amountOrSalary} onChange={handleChange} placeholder="Ex: 450 000 FCFA / an" />
            </div>
            
            <div className="flex flex-col gap-2">
              <label className="text-sm font-bold text-text-primary">Date Limite / Date d'événement</label>
              <Input name="deadline" type="date" value={formData.deadline} onChange={handleChange} />
            </div>
          </div>

          <div className="flex flex-col gap-2">
            <label className="text-sm font-bold text-text-primary">Description complète</label>
            <textarea 
              name="description" 
              value={formData.description} 
              onChange={handleChange} 
              rows={4}
              placeholder="Détails de l'opportunité..."
              className="w-full px-4 py-3 bg-surface border border-border-soft rounded-xl text-text-primary focus:outline-none focus:border-primary transition-colors resize-none"
            />
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
            <div className="flex flex-col gap-2">
              <label className="text-sm font-bold text-text-primary">URL de l'image (Optionnelle)</label>
              <Input name="image" value={formData.image} onChange={handleChange} placeholder="https://..." />
            </div>
            <div className="flex flex-col gap-2">
              <label className="text-sm font-bold text-text-primary">Lien officiel pour postuler</label>
              <Input name="link" value={formData.link} onChange={handleChange} placeholder="https://..." />
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
          <Link href="/admin/opportunites">
            <Button variant="secondary" type="button">Annuler</Button>
          </Link>
          <Button type="submit" disabled={loading} className="flex items-center gap-2">
            <Save className="w-4 h-4" /> {loading ? "Enregistrement..." : "Enregistrer"}
          </Button>
        </div>
      </form>
    </div>
  );
}
