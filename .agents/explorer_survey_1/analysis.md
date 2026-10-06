# Investigation Report: Next.js Web Project Architecture & Layout Survey

- **Investigator**: `explorer_survey_1` (`teamwork_preview_explorer`)
- **Working Directory**: `d:\ActivEducation\.agents\explorer_survey_1`
- **Target Project**: `d:\ActivEducation\web`
- **Authoritative Specification**: `d:\ActivEducation\.agents\ORIGINAL_REQUEST.md`
- **Design System Reference**: `d:\ActivEducation\DESIGN.md`
- **Timestamp**: 2026-09-22T10:33:00Z

---

## 1. Executive Summary

This investigation analyzed the Next.js application in `d:\ActivEducation\web`. The repository contains a newly initialized Next.js 16 (v16.3.5) project powered by React 19 (v19.2.8) and Tailwind CSS 4 (`@tailwindcss/postcss`). The project has three core UI primitives (`Button`, `Card`, `Input` in `src/components/ui/`), a root layout (`layout.tsx`) importing Google fonts (Sora, Outfit, JetBrains Mono), and a single demonstration page (`src/app/page.tsx`).

Key survey findings:
1. **Tooling & Versions**: Next.js `16.3.5`, React `19.2.8`, Tailwind CSS `^4` (configured via `@theme` in `globals.css`), `lucide-react` `^1.47.0` (already installed and available).
2. **Missing Components & Routes**: There is no navigation bar/sidebar, no course catalog route/component, no progression dashboard route/component, and no existing mock data files in `web/`.
3. **Critical Design System Flaw in Current Root Page**: `src/app/page.tsx` currently contains a centered hero (`<div className="max-w-[1400px] w-full text-center">`), which is strictly forbidden by `DESIGN.md` Section 5 & 7 and explicitly tested in `ORIGINAL_REQUEST.md` Acceptance Criteria.
4. **Rich Authentic Domain Data Available**: Exhaustive E-learning and gamification models and seeds exist in `backend/app/schemas/elearning.py`, `backend/app/schemas/gamification.py`, and `backend/db/seed_elearning_50_courses.sql` that can be directly mapped into TypeScript mock data.

---

## 2. Package & Dependency Survey (`package.json`)

### 2.1 File Location
`d:\ActivEducation\web\package.json`

### 2.2 Dependencies Inventory

| Dependency | Version | Purpose & Notes |
|---|---|---|
| `next` | `16.3.5` | Next.js App Router framework. Uses Turbopack by default. Breaking changes documented in `AGENTS.md`. |
| `react` | `19.2.8` | React 19 runtime. Server & Client components supported. |
| `react-dom` | `19.2.8` | React DOM renderer for React 19. |
| `lucide-react` | `^1.47.0` | Icon set is already installed. Can be imported directly (e.g. `BookOpen`, `Trophy`, `Flame`, `CheckCircle`, `Clock`, `Search`, etc.). No emojis allowed per `DESIGN.md`. |
| `@supabase/ssr` | `^0.12.7` | Supabase SSR helper (present for auth/session integration). |
| `@supabase/supabase-js` | `^2.116.0` | Supabase client SDK. |

### 2.3 DevDependencies Inventory

| DevDependency | Version | Purpose & Notes |
|---|---|---|
| `@tailwindcss/postcss` | `^4` | PostCSS plugin for Tailwind CSS v4. |
| `tailwindcss` | `^4` | Tailwind CSS v4 compiler. Configured via `@import "tailwindcss";` and `@theme` in CSS. |
| `typescript` | `^5` | TypeScript compiler. Strict mode enabled in `tsconfig.json`. |
| `@types/node` | `^20` | Node.js type definitions. |
| `@types/react` | `^19` | React 19 type definitions. |
| `@types/react-dom` | `^19` | React 19 DOM type definitions. |
| `eslint` | `^9` | ESLint v9 with flat config (`eslint.config.mjs`). |
| `eslint-config-next` | `16.3.5` | Core Web Vitals & TypeScript ESLint rules for Next.js 16. |

### 2.4 Scripts
- `"dev": "next dev"` — Starts Next.js development server (Turbopack).
- `"build": "next build"` — Compiles application for production, runs TypeScript typecheck and ESLint checks.
- `"start": "next start"` — Serves production build.
- `"lint": "eslint"` — Runs ESLint across project files.

---

## 3. Directory Layout & Architecture

### 3.1 Existing Layout in `d:\ActivEducation\web`

```
d:\ActivEducation\web/
├── .gitignore
├── .next/                         # Next.js build cache / dev output
├── AGENTS.md                      # Agent rules regarding Next.js 16 conventions
├── CLAUDE.md
├── README.md
├── eslint.config.mjs              # ESLint 9 flat configuration
├── next-env.d.ts                  # Next.js TypeScript environment declarations
├── next.config.ts                 # Next.js configuration (typed NextConfig)
├── package.json                   # Project manifest & dependencies
├── package-lock.json              # Dependency lockfile
├── postcss.config.mjs             # PostCSS with @tailwindcss/postcss
├── tsconfig.json                  # TypeScript configuration (@/* -> ./src/*)
├── public/                        # Static assets (file.svg, globe.svg, next.svg, etc.)
└── src/
    ├── app/
    │   ├── favicon.ico
    │   ├── globals.css            # Tailwind v4 theme definitions and base styles
    │   ├── layout.tsx             # Root layout with Google font variables & French lang
    │   └── page.tsx               # Root page with hero demo & UI showcase
    └── components/
        └── ui/
            ├── Button.tsx         # Button component with 4 variants
            ├── Card.tsx           # Card component with 3 variants
            └── Input.tsx          # Input component with floating tracking label
```

### 3.2 Gaps & Missing Folders
- **No `src/pages`**: Project exclusively uses Next.js App Router (`src/app`).
- **No `src/lib` or `src/utils`**: No helper functions (e.g. `cn` class merger or currency/time formatters).
- **No `src/data` or `src/mocks`**: No mock data stores exist for courses or student progression.
- **No `src/types`**: No shared TypeScript interfaces for Course, Student, Progress, Gamification, Badge, etc.
- **No navigation components**: No header, navbar, or sidebar exists.

---

## 4. Analysis of Existing Routes, Pages, Layout, and Components

### 4.1 Root Layout (`src/app/layout.tsx`)
- **Font Setup**: Imports Google Fonts `Sora`, `Outfit`, and `JetBrains_Mono` from `next/font/google`.
  - Injects CSS variables: `--font-sora`, `--font-outfit`, `--font-jetbrains-mono`.
  - Matches `DESIGN.md` Section 3 typography specifications.
- **Root Element**: `<html lang="fr" className={`${sora.variable} ${outfit.variable} ${jetbrainsMono.variable}`}>`.
- **Body**: `<body className="antialiased flex flex-col">`.
- **Current Limitation**: Does not provide a global shell (header, sidebar, navigation, or footer). Any global navigation must either be added to `layout.tsx` or encapsulated in a page shell.

### 4.2 Styling & Brand Tokens (`src/app/globals.css`)
Tailwind CSS v4 `@theme` defines the required tokens:
- Primary Blue:
  - `--color-primary: #1060CF` (Action principale)
  - `--color-primary-dark: #0A45A0`
  - `--color-primary-light: #4A8AE5`
  - `--color-primary-surface: #E8F0FE`
- Gold (Gamification ONLY):
  - `--color-gold: #F2A423`
  - `--color-gold-dark: #CC8800`
  - `--color-gold-light: #FFD166`
  - `--color-gold-surface: #FFF5E0`
- Neutral Canvas & Dark:
  - `--color-canvas: #F5F7FC`
  - `--color-surface: #FFFFFF`
  - `--color-surface-alt: #EEF2FA`
  - `--color-dark-base: #060E1E`
  - `--color-dark-surface: #0B1C3C`
- Radii: `rounded-sm` (8px), `rounded-md` (12px), `rounded-lg` (20px), `rounded-xl` (28px), `rounded-pill` (100px).
- Shadows: `shadow-card`, `shadow-card-hover`, `shadow-blue`, `shadow-gold`.

### 4.3 UI Primitives (`src/components/ui/`)
Requirement R3 mandates: *"L'équipe doit utiliser exclusivement les composants UI déjà créés (`Button`, `Card`, `Input` dans `src/components/ui`)"*.

1. **`Button.tsx`**:
   - `variant?: 'primary' | 'secondary' | 'tertiary' | 'gamification'`
   - `primary`: Blue pill button (`bg-primary text-white rounded-pill shadow-blue hover:-translate-y-[2px]`).
   - `secondary`: Outlined blue pill (`border-primary/30 text-primary hover:bg-primary/5`).
   - `tertiary`: Ghost link button (`text-primary hover:underline`).
   - `gamification`: Gold gradient button (`bg-gradient-to-r from-gold-dark to-gold text-dark-base rounded-pill shadow-gold`).
   - **Crucial Rule**: Gamification variant must NEVER be used on standard course catalog actions (e.g. "Voir le cours", "S'inscrire"). It is reserved strictly for student progression/XP/level validation.

2. **`Card.tsx`**:
   - `variant?: 'standard' | 'gamification' | 'dark'`
   - `interactive?: boolean` (adds hover translation and enhanced shadow)
   - `standard`: `bg-surface border border-primary/10 rounded-lg shadow-card`. Required for course cards in the catalog.
   - `gamification`: `bg-gold-surface border border-gold/25 rounded-lg shadow-gold`. Used for progression, streak, XP, and badge cards.
   - `dark`: `bg-white/5 border border-white/5 rounded-[18px]`.

3. **`Input.tsx`**:
   - Props: `label: string`, `error?: string`, standard HTML input props.
   - Upper-case tracking label (`tracking-[1.2px]`), background `bg-surface-alt`, rounded `rounded-md`.
   - Perfect for course search and filter controls.

### 4.4 Conflict Analysis in `src/app/page.tsx`
`src/app/page.tsx` currently contains:
```tsx
{/* HERO SECTION */}
<div className="max-w-[1400px] w-full text-center">
  <h1 className="font-bold text-[clamp(2.5rem,6vw,5rem)] tracking-[-0.025em] leading-[1.06] text-primary">
...
```
**Direct Violation of Specifications**:
- `ORIGINAL_REQUEST.md` Acceptance Criteria: *"Le layout n'utilise pas un format hero centré classique (qui est interdit par le DESIGN.md)."*
- `DESIGN.md` Section 5: *"Jamais de héros centré. Layout split-screen systématique : Colonne gauche (55%) : Headline Sora display, sous-titre Outfit, CTA unique / Colonne droite (45%) : Visuel de produit..."*
- `DESIGN.md` Section 7 Anti-Patterns: *"Aucun héros centré avec texte + bouton en colonne verticale centrée."*

**Recommendation for Implementation**:
The root page (`src/app/page.tsx`) must be refactored. It should feature an asymmetric split layout (or a structured dashboard shell with a sidebar/topbar) presenting:
1. An asymmetric split header or top dashboard bar.
2. An interactive view switcher or tabbed/split view containing:
   - **Catalogue de cours E-learning (R1)**
   - **Tableau de bord de progression étudiant (R2)**

---

## 5. Build Requirements & Compilation Execution (`npm run build`)

### 5.1 Compilation Pipeline
- In `package.json`: `"build": "next build"`.
- Under the hood, Next.js 16 executes:
  1. TypeScript verification (`tsc --noEmit`) against `tsconfig.json`.
  2. ESLint validation according to `eslint.config.mjs`.
  3. Turbopack production compilation and route manifest generation.
  4. Static generation and type definition exports to `.next/types/`.

### 5.2 Build Constraints to Guarantee Success
1. **TypeScript Strict Mode**:
   - `tsconfig.json` has `"strict": true` and `"noEmit": true`.
   - All components, props, state variables, and mock data must have explicit, valid TypeScript typings.
   - No `any` without proper handling; no missing optional properties.
2. **React 19 & Client Components**:
   - Any component utilizing React hooks (`useState`, `useEffect`, `useMemo`, `useCallback`) or event listeners must have `"use client";` at the very top of the file.
3. **Tailwind CSS v4 Utility Classes**:
   - Tailwind 4 automatically generates classes from the `@theme` block in `globals.css`.
   - Use `text-primary`, `bg-primary`, `text-gold`, `bg-gold-surface`, `font-display`, `font-body`, `font-mono`.
   - Custom Arbitrary classes must strictly conform to CSS syntax.
4. **Icons**:
   - Use `lucide-react` imports. Verify correct icon names (e.g. `BookOpen`, `Clock`, `Award`, `Zap`, `Flame`, `Trophy`, `Search`, `Check`, `CheckCircle2`, `ChevronRight`).
   - Do NOT use emojis (forbidden by `DESIGN.md` Section 7).

---

## 6. Mock Data Specifications & Domain Mapping

No mock data currently exists in `d:\ActivEducation\web`. However, authentic West African EdTech domain data is defined in `backend/app/schemas/elearning.py`, `backend/app/schemas/gamification.py`, and `backend/db/seed_elearning_50_courses.sql`.

### 6.1 Proposed Data Models (`src/data/mockData.ts` or `src/types/index.ts`)

#### A. Course Model (R1 — Catalogue)
```typescript
export type CourseCategory = 'Informatique' | 'Business' | 'Sciences' | 'Orientation' | 'Hackathons';
export type CourseDifficulty = 'debutant' | 'intermediaire' | 'avance';

export interface Course {
  id: string;
  title: string;
  description: string;
  category: CourseCategory;
  difficulty: CourseDifficulty;
  duration_minutes: number;
  points_reward: number;
  thumbnail_url?: string;
  modules_count: number;
  lessons_count: number;
  is_enrolled?: boolean;
  progress_pct?: number; // 0 to 100
}
```

#### B. Student Progress & Gamification Model (R2 — Progression)
```typescript
export interface Badge {
  id: string;
  title: string;
  description: string;
  icon: string; // Lucide icon identifier
  category: 'course' | 'streak' | 'achievement';
  earned_at: string;
  is_unlocked: boolean;
}

export interface EnrolledCourseProgress {
  course_id: string;
  title: string;
  category: CourseCategory;
  progress_pct: number;
  completed_lessons: number;
  total_lessons: number;
  last_accessed: string;
}

export interface StudentProfile {
  id: string;
  full_name: string;
  school_level: string; // e.g., 'Terminale S — Lycée de Tokoin, Lomé'
  avatar_url?: string;
  current_level: number; // e.g., 4
  level_title: string; // e.g., 'Initié Numérique'
  total_xp: number; // e.g., 1850
  next_level_xp: number; // e.g., 2500
  current_streak: number; // e.g., 5 jours
  completed_lessons: number; // e.g., 14
  total_lessons: number; // e.g., 20
  enrolled_courses: EnrolledCourseProgress[];
  badges: Badge[];
}
```

### 6.2 Curated Realistic Seed Data for West Africa

#### Courses for Catalog (R1):
1. **HTML & CSS : Les bases du web** (Informatique / Débutant / 60 min / 120 XP / 4 modules, 12 leçons)
2. **Python : Ton premier langage** (Informatique / Débutant / 120 min / 200 XP / 6 modules, 18 leçons)
3. **Dart & Flutter : Crée ton app mobile** (Informatique / Intermédiaire / 150 min / 300 XP / 8 modules, 24 leçons)
4. **Marketing digital pour débutants** (Business / Débutant / 60 min / 120 XP / 4 modules, 10 leçons)
5. **Créer son entreprise au Togo** (Business / Débutant / 90 min / 180 XP / 5 modules, 15 leçons)
6. **Mathématiques Terminale S** (Sciences / Avancé / 120 min / 250 XP / 8 modules, 20 leçons)
7. **Préparer son Orientation Post-Bac** (Orientation / Débutant / 30 min / 80 XP / 3 modules, 8 leçons)
8. **Hackathon : Résoudre un Problème Local** (Hackathons / Intermédiaire / 120 min / 200 XP / 4 modules, 12 leçons)

#### Mock Student for Progression Dashboard (R2):
- **Student**: Amavi Mensah
- **Level**: Niveau 4 ("Explorateur Passionné")
- **XP**: 1 850 XP (Progression: 1 850 / 2 500 XP → 74%)
- **Streak**: 5 jours consécutifs (flamme active)
- **Leçons terminées**: 14 / 20 leçons
- **Badges débloqués**:
  - "Premier Pas" (Orientation Post-Bac terminée)
  - "Codeur en Herbe" (HTML & CSS complété à 100%)
  - "Flamme Éveillée" (Streak de 5 jours consécutifs)
- **Cours en cours**:
  - HTML & CSS : Les bases du web (100% — examen réussi)
  - Python : Ton premier langage (65% — 12/18 leçons)
  - Préparer son Orientation Post-Bac (100% — terminé)
  - Dart & Flutter : Crée ton app mobile (25% — 6/24 leçons)

---

## 7. Strict Acceptance Criteria Checklist for Implementation

| Requirement | Rule & Specific Location | Status in Current Code | Action for Implementation |
|---|---|---|---|
| **R1: Course Catalog** | Show list of courses with mock data, search/category filter | Missing | Build `CourseCatalog` component using `<Card variant="standard">` |
| **R2: Progression Dashboard** | Show student level, XP progress bar, streak, completed lessons, badges | Partial demo in `page.tsx` | Build `ProgressionDashboard` with mock student data |
| **R3: Exclusive UI Components** | Use ONLY `Button`, `Card`, `Input` from `src/components/ui` | Available | Do not create rogue card/button components; reuse primitives |
| **Color Separation** | Gold (`#F2A423`) ONLY for progression (R2), NEVER on catalog (R1) | Violations prevented by spec | Enforce primary blue for catalog CTA, gold for XP/gamification |
| **Course Cards Variant** | Course cards MUST use `<Card variant="standard">` | N/A | Implement `<Card variant="standard" interactive={true}>` |
| **Layout: No Centered Hero** | Asymmetric split layout or sidebar layout. Centered hero is FORBIDDEN. | Currently VIOLATED in `page.tsx` | Refactor `page.tsx` to asymmetric split hero / dashboard layout |
| **Build Integrity** | Must compile with `npm run build` without error | Required | Use strict TypeScript types and client directives |
