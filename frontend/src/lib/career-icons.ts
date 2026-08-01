import {
  Briefcase, Stethoscope, GraduationCap, Landmark, ShoppingBag, Wrench,
  Sprout, Palette, Scale, Code2, Compass, Brain, Target, Heart, Zap,
} from 'lucide-react';
import type { LucideIcon } from 'lucide-react';

export const SECTOR_ICONS: Record<string, LucideIcon> = {
  'technologie & it': Code2,
  'sante': Stethoscope,
  'santé': Stethoscope,
  'education': GraduationCap,
  'éducation': GraduationCap,
  'finance & banque': Landmark,
  'commerce & entrepreneuriat': ShoppingBag,
  'ingenierie & btp': Wrench,
  'ingénierie & btp': Wrench,
  'agriculture & environnement': Sprout,
  'creation & medias': Palette,
  'arts & media': Palette,
  'droit & administration': Scale,
};

export const TEST_ICONS: Record<string, LucideIcon> = {
  riasec: Compass,
  personality: Brain,
  skills: Zap,
  interests: Heart,
  aptitude: Target,
};

export const TEST_GRADIENTS: Record<string, string> = {
  riasec: 'from-brand-category-science to-brand-category-science/60',
  personality: 'from-brand-level-purple to-brand-level-purple/60',
  skills: 'from-brand-success to-brand-success/60',
  interests: 'from-brand-category-economics to-brand-category-economics/60',
  aptitude: 'from-brand-error to-brand-error/60',
};

export function getTestGradient(testType: string | undefined | null): string {
  return TEST_GRADIENTS[testType ?? ''] ?? 'from-brand-primary to-brand-primary/60';
}

export function getSectorIcon(sectorName: string | undefined | null): LucideIcon {
  if (!sectorName) return Briefcase;
  const key = sectorName.toLowerCase().normalize('NFD').replace(/\p{Diacritic}/gu, '');
  return SECTOR_ICONS[key] ?? Briefcase;
}

export function getTestIcon(testType: string | undefined | null): LucideIcon {
  if (!testType) return Compass;
  return TEST_ICONS[testType] ?? Compass;
}
