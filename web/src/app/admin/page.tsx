import React from "react";
import { Card } from "@/components/ui/Card";
import { BookOpen, Briefcase, Users, TrendingUp } from "lucide-react";

export default function AdminDashboardPage() {
  return (
    <div className="flex flex-col gap-8 animate-fade-in">
      <div>
        <h1 className="text-3xl font-display font-bold text-text-primary mb-2">Tableau de bord Administrateur</h1>
        <p className="text-text-secondary">Bienvenue dans l'espace de gestion de la plateforme ActivEducation.</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <Card variant="standard" className="p-6 flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-primary/10 flex items-center justify-center text-primary">
            <Users className="w-6 h-6" />
          </div>
          <div>
            <p className="text-sm font-bold text-text-secondary uppercase">Étudiants</p>
            <p className="text-2xl font-bold text-text-primary">1,245</p>
          </div>
        </Card>

        <Card variant="standard" className="p-6 flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-gold/20 flex items-center justify-center text-gold-dark">
            <BookOpen className="w-6 h-6" />
          </div>
          <div>
            <p className="text-sm font-bold text-text-secondary uppercase">Cours Actifs</p>
            <p className="text-2xl font-bold text-text-primary">8</p>
          </div>
        </Card>

        <Card variant="standard" className="p-6 flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-success/10 flex items-center justify-center text-success-dark">
            <Briefcase className="w-6 h-6" />
          </div>
          <div>
            <p className="text-sm font-bold text-text-secondary uppercase">Opportunités</p>
            <p className="text-2xl font-bold text-text-primary">24</p>
          </div>
        </Card>

        <Card variant="standard" className="p-6 flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-purple-100 flex items-center justify-center text-purple-600">
            <TrendingUp className="w-6 h-6" />
          </div>
          <div>
            <p className="text-sm font-bold text-text-secondary uppercase">Taux d'insertion</p>
            <p className="text-2xl font-bold text-text-primary">78%</p>
          </div>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <Card variant="standard" className="p-6">
          <h2 className="text-xl font-bold text-text-primary mb-4">Derniers cours ajoutés</h2>
          <div className="flex items-center justify-center h-48 border-2 border-dashed border-border-soft rounded-xl text-text-tertiary">
            Le catalogue est actuellement géré via l'onglet Cours & Leçons.
          </div>
        </Card>
        <Card variant="standard" className="p-6">
          <h2 className="text-xl font-bold text-text-primary mb-4">Dernières opportunités</h2>
          <div className="flex items-center justify-center h-48 border-2 border-dashed border-border-soft rounded-xl text-text-tertiary">
            La liste des bourses est gérée via l'onglet Opportunités.
          </div>
        </Card>
      </div>
    </div>
  );
}
