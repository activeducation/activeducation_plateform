"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Plus, Edit, Trash2, Eye, EyeOff, BookOpen } from "lucide-react";

type Course = {
  id: string;
  title: string;
  category: string;
  difficulty: string;
  isPublished: boolean;
  createdAt: string;
};

export default function AdminCoursesPage() {
  const [courses, setCourses] = useState<Course[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchCourses = async () => {
    try {
      const res = await fetch("/api/admin/courses");
      if (res.ok) {
        const data = await res.json();
        setCourses(data);
      }
    } catch (error) {
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCourses();
  }, []);

  const handleDelete = async (id: string) => {
    if (!confirm("Voulez-vous vraiment supprimer ce cours ? Cette action supprimera également toutes ses leçons.")) return;
    try {
      const res = await fetch(`/api/admin/courses/${id}`, { method: "DELETE" });
      if (res.ok) fetchCourses();
    } catch (error) {
      console.error(error);
    }
  };

  return (
    <div className="flex flex-col gap-6 animate-fade-in">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-4">
        <div>
          <h1 className="text-2xl font-display font-bold text-text-primary">Catalogue de Cours</h1>
          <p className="text-sm text-text-secondary">Gérez les formations E-learning de l'académie.</p>
        </div>
        <Link href="/admin/cours/nouveau">
          <Button variant="primary" className="flex items-center gap-2">
            <Plus className="w-4 h-4" /> Nouveau cours
          </Button>
        </Link>
      </div>

      <Card variant="standard" className="overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="bg-surface-alt text-text-secondary font-medium border-b border-border-soft">
              <tr>
                <th className="px-6 py-4">Titre</th>
                <th className="px-6 py-4">Catégorie</th>
                <th className="px-6 py-4">Difficulté</th>
                <th className="px-6 py-4">Statut</th>
                <th className="px-6 py-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border-soft">
              {loading ? (
                <tr>
                  <td colSpan={5} className="px-6 py-8 text-center text-text-secondary">Chargement...</td>
                </tr>
              ) : courses.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-6 py-8 text-center text-text-secondary">Aucun cours trouvé.</td>
                </tr>
              ) : (
                courses.map((course) => (
                  <tr key={course.id} className="hover:bg-surface-alt/50 transition-colors">
                    <td className="px-6 py-4 font-bold text-text-primary flex items-center gap-3">
                      <div className="w-8 h-8 rounded-md bg-primary/10 flex items-center justify-center">
                        <BookOpen className="w-4 h-4 text-primary" />
                      </div>
                      {course.title}
                    </td>
                    <td className="px-6 py-4 text-text-secondary">{course.category}</td>
                    <td className="px-6 py-4">
                      <span className="px-2 py-1 bg-surface-alt border border-border-soft rounded-md text-xs font-bold text-text-secondary">
                        {course.difficulty}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      {course.isPublished ? (
                        <span className="flex items-center gap-1.5 text-success font-bold text-xs"><Eye className="w-3.5 h-3.5" /> Publié</span>
                      ) : (
                        <span className="flex items-center gap-1.5 text-text-tertiary font-bold text-xs"><EyeOff className="w-3.5 h-3.5" /> Brouillon</span>
                      )}
                    </td>
                    <td className="px-6 py-4 text-right">
                      <div className="flex items-center justify-end gap-2">
                        <Link href={`/admin/cours/edit/${course.id}`}>
                          <button className="p-2 text-text-secondary hover:text-primary transition-colors bg-surface border border-border-soft rounded-md hover:border-primary/30">
                            <Edit className="w-4 h-4" />
                          </button>
                        </Link>
                        <button 
                          onClick={() => handleDelete(course.id)}
                          className="p-2 text-text-secondary hover:text-error transition-colors bg-surface border border-border-soft rounded-md hover:border-error/30"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </Card>
    </div>
  );
}
