import React from "react";
import { Card } from "@/components/ui/Card";
import { BookOpen, Briefcase, Users, TrendingUp } from "lucide-react";
import { db } from "@/db";
import { users, courses, opportunities, explorerCareers } from "@/db/schema";
import { desc, count, eq } from "drizzle-orm";
import Link from "next/link";
import { Button } from "@/components/ui/Button";

export default async function AdminDashboardPage() {
  // Execute all queries in parallel using Promise.all to drastically reduce page load time
  const [
    studentsResult,
    coursesResult,
    opportunitiesResult,
    careersResult,
    latestCourses,
    latestOpportunities
  ] = await Promise.all([
    db.select({ value: count() }).from(users).where(eq(users.role, 'STUDENT')),
    db.select({ value: count() }).from(courses).where(eq(courses.isPublished, true)),
    db.select({ value: count() }).from(opportunities).where(eq(opportunities.isPublished, true)),
    db.select({ value: count() }).from(explorerCareers).where(eq(explorerCareers.isPublished, true)),
    db.select().from(courses).orderBy(desc(courses.createdAt)).limit(3),
    db.select().from(opportunities).orderBy(desc(opportunities.createdAt)).limit(3)
  ]);

  const studentsCount = studentsResult[0].value;
  const coursesCount = coursesResult[0].value;
  const opportunitiesCount = opportunitiesResult[0].value;
  const careersCount = careersResult[0].value;

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
            <p className="text-2xl font-bold text-text-primary">{studentsCount}</p>
          </div>
        </Card>

        <Card variant="standard" className="p-6 flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-gold/20 flex items-center justify-center text-gold-dark">
            <BookOpen className="w-6 h-6" />
          </div>
          <div>
            <p className="text-sm font-bold text-text-secondary uppercase">Cours Actifs</p>
            <p className="text-2xl font-bold text-text-primary">{coursesCount}</p>
          </div>
        </Card>

        <Card variant="standard" className="p-6 flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-success/10 flex items-center justify-center text-success-dark">
            <Briefcase className="w-6 h-6" />
          </div>
          <div>
            <p className="text-sm font-bold text-text-secondary uppercase">Opportunités</p>
            <p className="text-2xl font-bold text-text-primary">{opportunitiesCount}</p>
          </div>
        </Card>

        <Card variant="standard" className="p-6 flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-purple-100 flex items-center justify-center text-purple-600">
            <TrendingUp className="w-6 h-6" />
          </div>
          <div>
            <p className="text-sm font-bold text-text-secondary uppercase">Métiers (Explorateur)</p>
            <p className="text-2xl font-bold text-text-primary">{careersCount}</p>
          </div>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <Card variant="standard" className="p-6 flex flex-col h-full">
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-xl font-bold text-text-primary">Derniers cours ajoutés</h2>
            <Link href="/admin/cours"><Button variant="outline" size="sm">Gérer</Button></Link>
          </div>
          
          <div className="flex flex-col gap-3 flex-1">
            {latestCourses.length > 0 ? latestCourses.map(course => (
              <div key={course.id} className="flex items-center justify-between p-3 bg-surface-alt rounded-lg border border-border-soft">
                <div className="flex items-center gap-3">
                  <div className={`w-10 h-10 rounded-lg flex items-center justify-center bg-primary/10 text-primary`}>
                    <BookOpen className="w-5 h-5" />
                  </div>
                  <div>
                    <p className="font-bold text-text-primary text-sm">{course.title}</p>
                    <p className="text-xs text-text-secondary">{course.category} • {course.difficulty}</p>
                  </div>
                </div>
                <div className="text-xs font-medium px-2 py-1 bg-surface rounded-md text-text-secondary border border-border-soft">
                  {course.isPublished ? "Publié" : "Brouillon"}
                </div>
              </div>
            )) : (
              <div className="flex items-center justify-center flex-1 min-h-[120px] border-2 border-dashed border-border-soft rounded-xl text-text-tertiary">
                Aucun cours dans la base de données.
              </div>
            )}
          </div>
        </Card>

        <Card variant="standard" className="p-6 flex flex-col h-full">
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-xl font-bold text-text-primary">Dernières opportunités</h2>
            <Link href="/admin/opportunites"><Button variant="outline" size="sm">Gérer</Button></Link>
          </div>
          
          <div className="flex flex-col gap-3 flex-1">
            {latestOpportunities.length > 0 ? latestOpportunities.map(opp => (
              <div key={opp.id} className="flex items-center justify-between p-3 bg-surface-alt rounded-lg border border-border-soft">
                <div className="flex items-center gap-3">
                  <div className={`w-10 h-10 rounded-lg flex items-center justify-center bg-gold/10 text-gold-dark`}>
                    <Briefcase className="w-5 h-5" />
                  </div>
                  <div>
                    <p className="font-bold text-text-primary text-sm">{opp.title}</p>
                    <p className="text-xs text-text-secondary">{opp.provider || opp.type}</p>
                  </div>
                </div>
                <div className="text-xs font-medium px-2 py-1 bg-surface rounded-md text-text-secondary border border-border-soft">
                  {opp.isPublished ? "Publié" : "Brouillon"}
                </div>
              </div>
            )) : (
              <div className="flex items-center justify-center flex-1 min-h-[120px] border-2 border-dashed border-border-soft rounded-xl text-text-tertiary">
                Aucune opportunité dans la base de données.
              </div>
            )}
          </div>
        </Card>
      </div>
    </div>
  );
}
