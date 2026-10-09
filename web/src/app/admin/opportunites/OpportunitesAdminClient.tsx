"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Plus, Edit, Trash2, MapPin, Calendar, CheckCircle } from "lucide-react";

export default function OpportunitesAdminClient({ initialOpportunities }: { initialOpportunities: any[] }) {
  const [opportunities, setOpportunities] = useState(initialOpportunities);
  const loading = false;

  const handleDelete = async (id: string) => {
    if (!confirm("Voulez-vous vraiment supprimer cette opportunité ?")) return;

    try {
      const res = await fetch(`/api/admin/opportunities/${id}`, {
        method: "DELETE"
      });
      if (res.ok) {
        setOpportunities(prev => prev.filter(o => o.id !== id));
      } else {
        alert("Erreur lors de la suppression");
      }
    } catch (err) {
      console.error(err);
      alert("Erreur réseau");
    }
  };

  return (
    <div className="flex flex-col gap-6 animate-fade-in">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-display font-bold text-text-primary mb-2">Opportunités</h1>
          <p className="text-text-secondary">Gérez les bourses d'études, stages et événements.</p>
        </div>
        <Link href="/admin/opportunites/nouvelle">
          <Button className="flex items-center gap-2">
            <Plus className="w-4 h-4" /> Nouvelle opportunité
          </Button>
        </Link>
      </div>

      <Card variant="standard" className="p-0 overflow-hidden">
        {loading ? (
          <div className="p-8 text-center text-text-secondary">Chargement...</div>
        ) : opportunities.length === 0 ? (
          <div className="p-8 text-center text-text-secondary">
            Aucune opportunité pour le moment. Créez-en une !
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-surface-alt border-b border-border-soft">
                  <th className="p-4 font-bold text-sm text-text-secondary">Titre</th>
                  <th className="p-4 font-bold text-sm text-text-secondary">Type</th>
                  <th className="p-4 font-bold text-sm text-text-secondary">Prestataire</th>
                  <th className="p-4 font-bold text-sm text-text-secondary">Statut</th>
                  <th className="p-4 font-bold text-sm text-text-secondary text-right">Actions</th>
                </tr>
              </thead>
              <tbody>
                {opportunities.map((opp) => (
                  <tr key={opp.id} className="border-b border-border-soft hover:bg-primary/5 transition-colors">
                    <td className="p-4">
                      <div className="font-bold text-text-primary">{opp.title}</div>
                      <div className="text-xs text-text-tertiary flex items-center gap-1 mt-1">
                        <MapPin className="w-3 h-3" /> {opp.location}
                      </div>
                    </td>
                    <td className="p-4">
                      <span className="bg-primary/10 text-primary px-2 py-1 rounded text-xs font-bold uppercase">
                        {opp.type}
                      </span>
                    </td>
                    <td className="p-4 text-sm text-text-secondary">{opp.provider || "-"}</td>
                    <td className="p-4">
                      {opp.isPublished ? (
                        <span className="flex items-center gap-1 text-success text-xs font-bold">
                          <CheckCircle className="w-3 h-3" /> Publié
                        </span>
                      ) : (
                        <span className="text-text-tertiary text-xs font-bold">Brouillon</span>
                      )}
                    </td>
                    <td className="p-4 text-right">
                      <div className="flex items-center justify-end gap-2">
                        <Link href={`/admin/opportunites/edit/${opp.id}`}>
                          <Button variant="secondary" size="sm" className="px-2" title="Modifier">
                            <Edit className="w-4 h-4" />
                          </Button>
                        </Link>
                        <Button variant="secondary" size="sm" className="px-2 text-error border-error/20 hover:bg-error/10 hover:border-error" title="Supprimer" onClick={() => handleDelete(opp.id)}>
                          <Trash2 className="w-4 h-4" />
                        </Button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>
    </div>
  );
}
