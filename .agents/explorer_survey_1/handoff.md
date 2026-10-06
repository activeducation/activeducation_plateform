# Handoff Report: Next.js Web Project Architecture & Survey

- **Agent**: `explorer_survey_1` (`teamwork_preview_explorer`)
- **Recipient**: `orchestrator_1` (`96133c27-6f6e-4ab0-8933-113e8ad1c330`)
- **Date**: 2026-09-22T10:33:30Z
- **Working Directory**: `d:\ActivEducation\.agents\explorer_survey_1`

---

## 1. Observation

1. **`d:\ActivEducation\web\package.json`**:
   - `dependencies`:
     - `"next": "16.3.5"` (lines 15)
     - `"react": "19.2.8"` (line 16)
     - `"react-dom": "19.2.8"` (line 17)
     - `"lucide-react": "^1.47.0"` (line 14)
     - `"@supabase/ssr": "^0.12.7"`, `"@supabase/supabase-js": "^2.116.0"` (lines 12–13)
   - `devDependencies`:
     - `"@tailwindcss/postcss": "^4"` (line 20)
     - `"tailwindcss": "^4"` (line 26)
     - `"typescript": "^5"` (line 27)
     - `"eslint": "^9"`, `"eslint-config-next": "16.3.5"` (lines 24–25)
   - `scripts`: `"dev": "next dev"`, `"build": "next build"`, `"start": "next start"`, `"lint": "eslint"` (lines 5–10).

2. **`d:\ActivEducation\web\src` Layout**:
   - `src/app/globals.css`: Contains `@import "tailwindcss";` and `@theme` block defining `--color-primary: #1060CF`, `--color-gold: #F2A423`, `--color-canvas: #F5F7FC`, font variables `--font-display: var(--font-sora)`, etc.
   - `src/app/layout.tsx`: Loads `Sora`, `Outfit`, and `JetBrains_Mono` from `next/font/google`. Injects variables into `<html>` with `lang="fr"`.
   - `src/app/page.tsx`: Single route (`/`). Currently contains a centered hero (`<div className="max-w-[1400px] w-full text-center">` at line 11) and a two-column card showcase (lines 28–56).
   - `src/components/ui/`: Contains three primitives:
     - `Button.tsx`: `variant?: 'primary' | 'secondary' | 'tertiary' | 'gamification'`.
     - `Card.tsx`: `variant?: 'standard' | 'gamification' | 'dark'`, `interactive?: boolean`.
     - `Input.tsx`: `label: string`, `error?: string`.
   - Non-existent directories in `web`: No `src/pages`, `src/lib`, `src/data`, `src/mocks`, or `src/types`. No navigation components (Navbar, Header, or Sidebar).

3. **`d:\ActivEducation\.agents\ORIGINAL_REQUEST.md`**:
   - R1: Course catalog with mock data.
   - R2: Student progress dashboard with static mock data (level, XP, completed lessons).
   - R3: Use exclusively UI components from `src/components/ui` (`Button`, `Card`, `Input`), respect Tailwind utility classes (`primary`, `gold`, `font-display`).
   - Acceptance Criteria:
     - Project compiles without error (`npm run build`).
     - Gold (`#F2A423`) is strictly reserved for progression (R2) and NEVER used on the standard course catalog.
     - Course cards must use `<Card variant="standard">`.
     - The layout must NOT use a classic centered hero format (which is forbidden by `DESIGN.md`).

4. **`d:\ActivEducation\DESIGN.md`**:
   - Section 5 (Hero section): *"Jamais de héros centré. Layout split-screen systématique : Colonne gauche (55%) : Headline Sora display, sous-titre Outfit, CTA unique / Colonne droite (45%) : Visuel de produit..."*
   - Section 7 (Anti-Patterns): *"Aucun héros centré avec texte + bouton en colonne verticale centrée."*
   - Section 2 & 7: Gold is strictly for gamification. Blue is for standard primary actions.

5. **Existing Domain Data in Repository**:
   - `backend/app/schemas/elearning.py` and `backend/db/seed_elearning_50_courses.sql`: Definitive Course models and data with categories (`Informatique`, `Business`, `Sciences`, `Orientation`, `Hackathons`), durations, points reward, and difficulty levels.
   - `backend/app/schemas/gamification.py`: Definitive student gamification structure (`total_xp`, `current_level`, `current_streak`, `achievements`, `next_level_xp`).

---

## 2. Logic Chain

1. From Observation 1 (`package.json`), Next.js `16.3.5`, React `19.2.8`, Tailwind CSS `^4`, and `lucide-react` are installed. This means any icons needed can be directly imported from `lucide-react` without installing external packages or using forbidden emojis.
2. From Observation 2 (`src/` layout), the project has no course catalog, no progress dashboard, and no navigation shell. Only `page.tsx` exists.
3. From Observation 2 and Observation 3 (`page.tsx` vs `ORIGINAL_REQUEST.md`), `src/app/page.tsx` currently has a centered hero section (`text-center`). This directly violates both `DESIGN.md` Section 5/7 and the explicit acceptance criterion in `ORIGINAL_REQUEST.md` lines 26–30.
4. Therefore, implementing R1 and R2 requires refactoring `src/app/page.tsx` away from the centered hero into an asymmetric split-screen layout or a structured tabbed/split dashboard containing the Course Catalog and Progression Dashboard.
5. From Observation 3 and Observation 4, the course catalog (R1) must use `<Card variant="standard" interactive={true}>`, and buttons must use `<Button variant="primary">` or `<Button variant="secondary">`. Gold styling (`text-gold`, `bg-gold-surface`, `<Card variant="gamification">`, `<Button variant="gamification">`) is strictly prohibited in the course catalog and strictly confined to the progression dashboard (R2).
6. From Observation 5, authentic seed data from `backend/db/seed_elearning_50_courses.sql` and schemas from `backend/app/schemas/` should be extracted into a dedicated `src/data/mockData.ts` (and `src/types/index.ts`) to satisfy R1 and R2 with high-fidelity West African educational context.

---

## 3. Caveats

- **Build Execution via Tool**: During the survey, executing `npm run build` directly via `run_command` timed out waiting for user confirmation on the shell prompt. However, all build prerequisites (`tsconfig.json`, `package.json`, Next.js 16 setup, and Tailwind 4 configuration) were verified statically.
- **Single Page vs Multiple Routes**: `ORIGINAL_REQUEST.md` specifies building the course catalog and student progression dashboard interface in Next.js. Whether this is implemented on the root page `/` via an asymmetric split view / tabbed view or on separate subroutes (`/catalogue`, `/progression`) with a shared layout and navigation, the acceptance criteria (no centered hero, `<Card variant="standard">`, gold only for progression, `npm run build` clean) apply equally. Implementing a seamless interactive view switcher or split layout on `/` provides an immediate, cohesive experience while eliminating the centered hero.

---

## 4. Conclusion

The Next.js project in `d:\ActivEducation\web` is technically sound (Next.js 16 + React 19 + Tailwind CSS 4 + Lucide React), but is currently only a placeholder showcase with an invalid centered hero. 

The implementation phase should execute the following actionable plan:
1. **Define Data & Types**: Create `src/types/index.ts` and `src/data/mockData.ts` using the schemas and authentic West African courses identified from the backend seeds.
2. **Build Navigation Shell**: Create a clean navigation component conforming to `DESIGN.md` (no emojis, Outfit typography, active indicator) allowing the user to view the Course Catalog and Progression Dashboard.
3. **Build Course Catalog (R1)**:
   - Category filtering (`Tous`, `Informatique`, `Business`, `Sciences`, `Orientation`, `Hackathons`) and search input using `Input`.
   - Course cards strictly using `<Card variant="standard" interactive={true}>`.
   - Action buttons using `<Button variant="primary">` and `<Button variant="secondary">`.
   - **Zero gold classes** in the catalog.
4. **Build Student Progression Dashboard (R2)**:
   - Header with student profile (Amavi Mensah), Level, Streak indicator with flame icon, and XP total in `JetBrains Mono`.
   - Animated XP progress bar towards next level.
   - Lesson completion metrics (e.g. 14/20 leçons terminées).
   - Badges & achievements using `<Card variant="gamification">` and gold accents (`#F2A423`).
   - Active courses in progress.
   - Validation button using `<Button variant="gamification">`.
5. **Refactor Root Page (`src/app/page.tsx`)**:
   - Completely replace the centered hero with an asymmetric split layout (left 55% headline & stats, right 45% live preview card) and integrate the interactive catalog and progression dashboard.

---

## 5. Verification Method

To independently verify these findings:
1. **Inspect package dependencies**:
   `view_file` on `d:\ActivEducation\web\package.json` (lines 11–28).
2. **Inspect current hero layout violation**:
   `view_file` on `d:\ActivEducation\web\src\app\page.tsx` (lines 10–25).
3. **Inspect UI Primitives**:
   `view_file` on `d:\ActivEducation\web\src\components\ui\Button.tsx`, `Card.tsx`, `Input.tsx`.
4. **Inspect backend seed data**:
   `view_file` on `d:\ActivEducation\backend\db\seed_elearning_50_courses.sql` (lines 10–60).
5. **Compilation Verification** (once worker implements changes):
   Run `npm run build` in `d:\ActivEducation\web` to verify that Next.js 16 and TypeScript compile with zero errors.
