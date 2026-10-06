"use client";

import React, { useState, useMemo } from 'react';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Course, CourseCategory } from '@/types';
import { BookOpen, Clock, Layers, Sparkles, SearchX } from 'lucide-react';

interface CourseCatalogProps {
  courses: Course[];
}

const CATEGORIES: Array<'Tous' | CourseCategory> = [
  'Tous',
  'Informatique',
  'Orientation',
  'Business',
  'Sciences',
];

export function CourseCatalog({ courses }: CourseCatalogProps) {
  const [selectedCategory, setSelectedCategory] = useState<'Tous' | CourseCategory>('Tous');
  const [searchQuery, setSearchQuery] = useState('');

  const filteredCourses = useMemo(() => {
    return courses.filter((course) => {
      const matchesCategory =
        selectedCategory === 'Tous' || course.category === selectedCategory;
      const normalizedSearch = searchQuery.toLowerCase().trim();
      const matchesSearch =
        normalizedSearch === '' ||
        course.title.toLowerCase().includes(normalizedSearch) ||
        course.description.toLowerCase().includes(normalizedSearch) ||
        course.category.toLowerCase().includes(normalizedSearch) ||
        (course.partner && course.partner.toLowerCase().includes(normalizedSearch));

      return matchesCategory && matchesSearch;
    });
  }, [courses, selectedCategory, searchQuery]);

  return (
    <div className="flex flex-col gap-8 w-full" id="catalogue">
      {/* SECTION HEADER */}
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-6 pb-6 border-b border-primary/10">
        <div>
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-sm bg-primary-surface text-primary text-xs font-semibold uppercase tracking-wider mb-2">
            <BookOpen className="w-3.5 h-3.5" />
            <span>Catalogue Académique</span>
          </div>
          <h2 className="text-2xl md:text-3xl font-bold tracking-tight text-text-primary">
            Formations d’Excellence
          </h2>
          <p className="mt-1 text-text-secondary text-sm md:text-base max-w-[65ch]">
            Programmes certifiants conçus pour les filières d’avenir et l’écosystème professionnel ouest-africain.
          </p>
        </div>
        <div className="text-sm text-text-secondary font-mono">
          <span className="font-bold text-primary">{filteredCourses.length}</span> / {courses.length} formations disponibles
        </div>
      </div>

      {/* FILTER & SEARCH BAR */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-end">
        {/* Search Input */}
        <div className="lg:col-span-5">
          <Input
            label="Rechercher un cours"
            placeholder="Mots-clés, technologie, orientation..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>

        {/* Category Pills */}
        <div className="lg:col-span-7 flex flex-col gap-1.5">
          <span className="text-[13px] font-medium text-text-secondary uppercase tracking-[1.2px]">
            Filtrer par filière
          </span>
          <div className="flex flex-wrap gap-2">
            {CATEGORIES.map((cat) => {
              const isActive = selectedCategory === cat;
              return (
                <button
                  key={cat}
                  type="button"
                  onClick={() => setSelectedCategory(cat)}
                  className={`
                    px-4 py-2 text-xs md:text-sm font-semibold rounded-sm transition-all duration-fast
                    ${
                      isActive
                        ? 'bg-primary text-white shadow-blue'
                        : 'bg-surface border border-primary/20 text-primary hover:bg-primary/5 hover:border-primary/40'
                    }
                  `}
                >
                  {cat}
                </button>
              );
            })}
          </div>
        </div>
      </div>

      {/* COURSES GRID */}
      {filteredCourses.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredCourses.map((course) => (
            <Card
              key={course.id}
              variant="standard"
              interactive={true}
              className="p-6 flex flex-col justify-between h-full group"
            >
              {/* Top Card Info */}
              <div className="flex flex-col gap-4">
                {/* Badges Row - Strictly Neutral & Primary */}
                <div className="flex items-center justify-between gap-2">
                  <span className="px-2.5 py-1 rounded-sm text-xs font-semibold bg-primary-surface text-primary border border-primary/15">
                    {course.category}
                  </span>
                  <span className="px-2.5 py-1 rounded-sm text-xs font-medium bg-surface-alt text-text-secondary border border-text-secondary/15">
                    {course.difficulty}
                  </span>
                </div>

                {/* Course Title */}
                <div>
                  <h3 className="font-bold text-lg text-text-primary group-hover:text-primary transition-colors leading-snug">
                    {course.title}
                  </h3>
                  {course.partner && (
                    <p className="text-xs text-text-tertiary mt-1 font-medium">
                      En partenariat avec {course.partner}
                    </p>
                  )}
                </div>

                {/* Course Description */}
                <p className="text-text-secondary text-sm leading-relaxed line-clamp-3">
                  {course.description}
                </p>

                {/* Meta Details: Duration, Lessons, XP Reward */}
                <div className="pt-3 border-t border-primary/10 grid grid-cols-3 gap-2 text-xs font-mono text-text-secondary">
                  <div className="flex items-center gap-1.5">
                    <Clock className="w-3.5 h-3.5 text-primary" />
                    <span>{course.duration}</span>
                  </div>
                  <div className="flex items-center gap-1.5">
                    <Layers className="w-3.5 h-3.5 text-primary" />
                    <span>{course.lessonsCount} leçons</span>
                  </div>
                  <div className="flex items-center gap-1.5">
                    <Sparkles className="w-3.5 h-3.5 text-primary" />
                    <span>+{course.xpReward} XP</span>
                  </div>
                </div>
              </div>

              {/* Action Buttons */}
              <div className="mt-6 pt-4 border-t border-primary/10 flex items-center gap-3">
                <Button variant="primary" className="flex-1 text-xs py-2.5">
                  Commencer
                </Button>
                <Button variant="secondary" className="text-xs py-2.5 px-4">
                  Détails
                </Button>
              </div>
            </Card>
          ))}
        </div>
      ) : (
        /* Empty State */
        <div className="bg-surface rounded-lg border border-primary/10 p-12 text-center flex flex-col items-center justify-center gap-4">
          <div className="w-12 h-12 rounded-sm bg-primary-surface text-primary flex items-center justify-center">
            <SearchX className="w-6 h-6" />
          </div>
          <div>
            <h4 className="font-bold text-lg text-text-primary">Aucun cours ne correspond à vos critères</h4>
            <p className="text-sm text-text-secondary mt-1 max-w-[45ch]">
              Modifiez vos mots-clés ou réinitialisez les filtres pour explorer l’ensemble du catalogue.
            </p>
          </div>
          <Button
            variant="secondary"
            onClick={() => {
              setSearchQuery('');
              setSelectedCategory('Tous');
            }}
          >
            Réinitialiser les filtres
          </Button>
        </div>
      )}
    </div>
  );
}
