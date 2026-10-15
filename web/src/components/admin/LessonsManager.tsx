"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Plus, Edit, Trash2, GripVertical } from "lucide-react";

export function LessonsManager({ courseId }: { courseId: string }) {
  const [lessons, setLessons] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchLessons = async () => {
    try {
      const res = await fetch(`/api/admin/courses/${courseId}/lessons`);
      if (res.ok) {
        const data = await res.json();
        setLessons(data);
      }
    } catch (error) {
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchLessons();
  }, [courseId]);

  const handleDelete = async (lessonId: string) => {
    if (!confirm("Voulez-vous vraiment supprimer cette leçon ?")) return;
    try {
      const res = await fetch(`/api/admin/courses/${courseId}/lessons/${lessonId}`, { method: "DELETE" });
      if (res.ok) fetchLessons();
    } catch (error) {
      console.error(error);
    }
  };

  return (
    <Card variant="standard" className="p-6 mt-8">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h2 className="text-xl font-bold text-text-primary">Programme du cours</h2>
          <p className="text-sm text-text-secondary">Gérez les leçons, les vidéos et les quiz de ce cours.</p>
        </div>
        <Link href={`/admin/cours/edit/${courseId}/lessons/nouveau`}>
          <Button variant="outline" className="flex items-center gap-2 text-sm">
            <Plus className="w-4 h-4" /> Ajouter une leçon
          </Button>
        </Link>
      </div>

      <div className="flex flex-col gap-3">
        {loading ? (
          <p className="text-sm text-text-secondary">Chargement des leçons...</p>
        ) : lessons.length === 0 ? (
          <div className="p-8 text-center bg-surface-alt border border-dashed border-border-strong rounded-xl">
            <p className="text-text-secondary text-sm">Ce cours ne contient aucune leçon.</p>
          </div>
        ) : (
          lessons.map((lesson, index) => (
            <div key={lesson.id} className="flex items-center gap-4 p-4 bg-surface border border-border-soft rounded-xl group hover:border-primary/30 transition-colors">
              <div className="text-border-strong cursor-grab">
                <GripVertical className="w-5 h-5" />
              </div>
              <div className="flex items-center justify-center w-8 h-8 rounded-full bg-surface-alt text-text-secondary font-bold text-sm">
                {index + 1}
              </div>
              <div className="flex-1">
                <h3 className="font-bold text-text-primary">{lesson.title}</h3>
                <p className="text-xs text-text-secondary">{lesson.rewardXp} XP à gagner</p>
              </div>
              <div className="flex items-center gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                <Link href={`/admin/cours/edit/${courseId}/lessons/edit/${lesson.id}`}>
                  <button className="p-2 text-text-secondary hover:text-primary transition-colors bg-surface-alt rounded-md">
                    <Edit className="w-4 h-4" />
                  </button>
                </Link>
                <button 
                  onClick={() => handleDelete(lesson.id)}
                  className="p-2 text-text-secondary hover:text-error transition-colors bg-surface-alt rounded-md"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            </div>
          ))
        )}
      </div>
    </Card>
  );
}
