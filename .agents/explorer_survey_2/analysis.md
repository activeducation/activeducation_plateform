# UI Components & Styling Setup Analysis

**Target Workspace**: `d:\ActivEducation\web`  
**Date**: 2026-09-22  
**Author**: `explorer_survey_2`  

---

## 1. Executive Summary

This investigation surveys the frontend design system, reusable UI components, styling architecture, and iconography in `d:\ActivEducation\web`.

Key observations:
1. **Existing UI Components**: Located strictly in `src/components/ui`: `Button.tsx`, `Card.tsx`, and `Input.tsx`.
2. **Card Variant Verification**: `<Card variant="standard">` is fully defined and active in `Card.tsx` (it is also the default variant). An optional boolean prop `interactive` provides hover lift and shadow transitions.
3. **Tailwind CSS v4 Configuration**: No `tailwind.config.ts` or `tailwind.config.js` exists. The project uses Tailwind CSS v4 (`@tailwindcss/postcss` v4) where tokens are declared via the `@theme` directive directly inside `src/app/globals.css`.
4. **Color & Typography Constraints**:
   - `primary` (#1060CF royal blue) is the primary interactive brand color.
   - `gold` (#F2A423 amber gold) is strictly reserved for gamification / student progress (R2) and **must never** be used for course catalog elements (R1).
   - `font-display` (Sora), `font-body` (Outfit), and `font-mono` (JetBrains Mono) are loaded in `layout.tsx` via `next/font/google` and mapped in `globals.css`.
5. **Icons & Utilities**:
   - Icon library: `lucide-react` (v1.47.0) is installed and available in `node_modules`. No emojis are allowed per `DESIGN.md`.
   - Utility functions: Neither `clsx`, `tailwind-merge`, nor a `cn()` helper are present. Components rely on ES6 template string concatenation (`${baseStyles} ${variants[variant]} ${className}`).
6. **Anti-Pattern Warning**: The current placeholder in `src/app/page.tsx` has a classic centered hero section. This violates the core design principle in `DESIGN.md` (Split-screen 55%/45% required, centered heroes forbidden). The implementer must replace this with a compliant layout.

---

## 2. UI Components Deep Dive (`src/components/ui`)

### 2.1 `Button.tsx` (`src/components/ui/Button.tsx`)

#### Interface & Types
```typescript
export type ButtonVariant = 'primary' | 'secondary' | 'tertiary' | 'gamification';

export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: ButtonVariant;
  children: React.ReactNode;
}
```

#### Base Styles
```css
inline-flex items-center justify-center font-semibold text-[14px] transition-all duration-normal outline-none focus-visible:ring-2 focus-visible:ring-primary/50 focus-visible:ring-offset-2 active:scale-97 disabled:opacity-50 disabled:pointer-events-none
```

#### Variants
| Variant | Styles | Usage Context |
|---|---|---|
| `primary` (default) | `bg-primary text-white rounded-pill px-6 py-3 shadow-blue hover:-translate-y-[2px] hover:shadow-[0_8px_24px_rgba(10,69,160,0.45)]` | Main calls to action (e.g. Enroll, Search, Submit, Login). |
| `secondary` | `bg-transparent border-[1.5px] border-primary/30 text-primary rounded-pill px-6 py-3 hover:bg-primary/5 hover:border-primary/50` | Alternative actions (e.g. View syllabus, Learn more, Back). |
| `tertiary` | `text-primary px-2 py-1 hover:underline hover:underline-offset-4 hover:decoration-dashed` | Inline text link buttons (e.g. Forgot password, See details). |
| `gamification` | `bg-gradient-to-r from-gold-dark to-gold text-dark-base rounded-pill px-6 py-3 shadow-gold hover:-translate-y-[2px] hover:shadow-[0_8px_24px_rgba(204,136,0,0.45)]` | **STRICTLY for progress/gamification validation** (e.g. "Valider mon niveau", "Réclamer mon badge"). Never use on standard catalog actions. |

---

### 2.2 `Card.tsx` (`src/components/ui/Card.tsx`)

#### Interface & Types
```typescript
export type CardVariant = 'standard' | 'gamification' | 'dark';

export interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  variant?: CardVariant;
  interactive?: boolean;
}
```

#### Base Styles
```css
overflow-hidden transition-all duration-normal
```

#### Variant Breakdown & Acceptance Verification
- **`standard` (default variant)**:
  - Base class: `bg-surface border border-primary/10 rounded-lg shadow-card`
  - When `interactive={true}`: `hover:-translate-y-[4px] hover:shadow-card-hover hover:border-primary/20`
  - **Verification**: Conforms exactly to Acceptance Criteria: `<Card variant="standard">` or `<Card variant="standard" interactive>`.
  - Intended for: **All course catalog cards (R1)**.
- **`gamification`**:
  - Base class: `bg-gold-surface border border-gold/25 rounded-lg shadow-gold`
  - When `interactive={true}`: `hover:-translate-y-[2px] hover:shadow-[0_8px_24px_rgba(204,136,0,0.2)]`
  - Intended for: **Student progress cards, XP indicators, level showcases (R2)**.
- **`dark`**:
  - Base class: `bg-white/5 border border-white/5 rounded-[18px]`
  - When `interactive={true}`: `hover:bg-primary/5 hover:border-primary/30 hover:-translate-y-[2px]`
  - Intended for: Cards placed on dark backgrounds (such as dark headers or sidebars).

*Note on Padding*: `Card` does not inject internal padding by default. Implementers must provide spacing classes (e.g., `className="p-6 flex flex-col"`) on the `<Card>` element.

---

### 2.3 `Input.tsx` (`src/components/ui/Input.tsx`)

#### Interface & Types
```typescript
export interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label: string; // MANDATORY prop
  error?: string; // Optional error message
}
```

#### Rendered Hierarchy & Styling
- Outer container: `<div className="flex flex-col gap-1.5 w-full">`
- Top Label:
  ```html
  <label className="text-[13px] font-medium text-text-secondary uppercase tracking-[1.2px]">
    {label}
  </label>
  ```
  *(Floating labels are explicitly forbidden by `DESIGN.md`; label is always static above the input).*
- Input element:
  - Base classes: `bg-surface-alt rounded-md px-4 py-[14px] text-text-primary text-[15px] outline-none transition-all duration-fast placeholder:text-text-tertiary`
  - Normal state: `border border-transparent focus:border-primary focus:ring-[3px] focus:ring-primary/10`
  - Error state (`isError = Boolean(error)`): `border border-[#DC2626] focus:ring-2 focus:ring-[#DC2626]/20`
- Error text:
  - If `error` is truthy: `<span className="text-[#DC2626] font-mono text-[12px] mt-0.5">{error}</span>`

---

## 3. Styling & Theming Architecture

### 3.1 Tailwind CSS v4 Setup
- Package: `tailwindcss` v4, `@tailwindcss/postcss` v4 (no legacy v3 setup).
- Config file: **No `tailwind.config.ts` or `tailwind.config.js` exists**.
- All custom tokens are defined in `src/app/globals.css` using the `@theme` block.

### 3.2 Design Tokens Defined in `src/app/globals.css`

#### Color Tokens
| Token Variable | Tailwind Utility Class | Hex Code | Semantic Role |
|---|---|---|---|
| `--color-primary` | `text-primary`, `bg-primary`, `border-primary` | `#1060CF` | Main brand royal blue; default actions and focus rings |
| `--color-primary-dark` | `text-primary-dark`, `bg-primary-dark` | `#0A45A0` | Hover states and deep gradients |
| `--color-primary-light` | `text-primary-light`, `bg-primary-light` | `#4A8AE5` | Secondary blue accents, tags, active indicator start |
| `--color-primary-surface` | `bg-primary-surface` | `#E8F0FE` | Light blue surface tint |
| `--color-gold` | `text-gold`, `bg-gold`, `border-gold` | `#F2A423` | **Gamification only**: XP, level, badges, streak |
| `--color-gold-dark` | `text-gold-dark`, `bg-gold-dark` | `#CC8800` | Hover on gold elements, text on light surface |
| `--color-gold-light` | `text-gold-light`, `bg-gold-light` | `#FFD166` | Gold highlights and subtle gradients |
| `--color-gold-surface` | `bg-gold-surface`, `border-gold-surface` | `#FFF5E0` | Gamification card background |
| `--color-canvas` | `bg-canvas` | `#F5F7FC` | Cold background, slightly tinted blue |
| `--color-surface` | `bg-surface` | `#FFFFFF` | Standard card background |
| `--color-surface-alt` | `bg-surface-alt` | `#EEF2FA` | Input background, alternated rows |
| `--color-dark-base` | `bg-dark-base`, `text-dark-base` | `#060E1E` | Deep navy for dark headers/sidebars |
| `--color-dark-surface` | `bg-dark-surface` | `#0B1C3C` | Secondary dark surface |
| `--color-text-primary` | `text-text-primary` | `#0D1832` | Headings, main text |
| `--color-text-secondary` | `text-text-secondary` | `#4A6280` | Subtitles, descriptions, metadata |
| `--color-text-tertiary` | `text-text-tertiary` | `#8AAAC0` | Placeholders, inactive captions |
| `--color-text-light` | `text-text-light` | `#E4EEF8` | Text on dark backgrounds |

#### Typography Tokens
In `src/app/layout.tsx`:
```typescript
const sora = Sora({ variable: "--font-sora", subsets: ["latin"] });
const outfit = Outfit({ variable: "--font-outfit", subsets: ["latin"] });
const jetbrainsMono = JetBrains_Mono({ variable: "--font-jetbrains-mono", subsets: ["latin"] });
```
In `src/app/globals.css`:
```css
--font-display: var(--font-sora), system-ui, sans-serif;
--font-body: var(--font-outfit), system-ui, sans-serif;
--font-mono: var(--font-jetbrains-mono), monospace;
```
- Headings (`h1`–`h6`) automatically inherit `font-family: var(--font-display)` (`font-display`) and `text-wrap: balance`.
- Body text automatically inherits `font-family: var(--font-body)` (`font-body`).
- Numerical data, XP scores, and levels should use `font-mono` (JetBrains Mono).

#### Radius Tokens
- `--radius-sm: 8px` -> `rounded-sm`
- `--radius-md: 12px` -> `rounded-md`
- `--radius-lg: 20px` -> `rounded-lg` (standard for cards)
- `--radius-xl: 28px` -> `rounded-xl`
- `--radius-pill: 100px` -> `rounded-pill` (standard for buttons)

#### Shadow Tokens
- `--shadow-card: 0 4px 20px rgba(13,24,50,0.07)` -> `shadow-card`
- `--shadow-card-hover: 0 12px 36px rgba(10,69,160,0.14)` -> `shadow-card-hover`
- `--shadow-blue: 0 4px 16px rgba(10,69,160,0.35)` -> `shadow-blue`
- `--shadow-gold: 0 4px 16px rgba(204,136,0,0.32)` -> `shadow-gold`

---

## 4. Utilities & Iconography

### 4.1 Icon Library
- **Package**: `lucide-react` (v1.47.0) is present in `package.json` and installed in `node_modules`.
- Icons can be directly imported, e.g.:
  ```typescript
  import { BookOpen, Award, Trophy, Clock, Flame, CheckCircle, Search, Filter, Sparkles } from "lucide-react";
  ```
- **Strict Rule from `DESIGN.md`**: No emojis anywhere in the interface. Only SVG icons (such as Lucide React).

### 4.2 Utility Functions (`cn`, `clsx`, `tailwind-merge`)
- **Status**: Not installed in `dependencies` or `devDependencies`. No helper file exists in `src/`.
- **Established Pattern**: Standard ES6 template strings with whitespace separation:
  ```tsx
  className={`base-class ${isActive ? 'active-class' : ''} ${className}`}
  ```
- **Recommendation for Implementers**: Do not attempt to import `@/lib/utils` or `cn` unless specifically added; follow the existing pattern used in `Button.tsx`, `Card.tsx`, and `Input.tsx`.

---

## 5. Design System Compliance & Acceptance Criteria

### Criteria Checklist

| Requirement / Criterion | Source | Rule & Implementation Guidance |
|---|---|---|
| **Course Catalog (R1)** | `ORIGINAL_REQUEST.md` | Display mock e-learning courses (title, category, duration, lessons, level). |
| **Card Variant "standard"** | Acceptance Criteria | Course cards **must** use `<Card variant="standard">` (or `<Card variant="standard" interactive>`). Do NOT use `variant="gamification"` or `variant="dark"` for courses. |
| **Gold Color Exclusivity** | Acceptance Criteria & `DESIGN.md` | Gold (`text-gold`, `bg-gold`, `shadow-gold`, `variant="gamification"`) **must only be used for student progress (R2)** (level, XP, completed lessons, badges). Gold is strictly forbidden in the course catalog (R1). |
| **No Centered Hero** | Acceptance Criteria & `DESIGN.md` (Sec 5.2, 7.2) | "Le layout n'utilise pas un format hero centré classique". Must use an asymmetric layout or split-screen (e.g. 55% left headline/search, 45% right quick student progress preview or visual teaser), or a top banner with sidebar/grid layout. |
| **Component Exclusivity** | R3 & Acceptance Criteria | Exclusively use `Button`, `Card`, and `Input` from `src/components/ui`. Use Tailwind utility classes for layout, typography, and colors. |
| **Zero Build Errors** | Acceptance Criteria | Must compile cleanly (`npm run build`). |

---

## 6. Blueprint & Code Snippets for Implementers

### A. Course Card (Catalog R1)
```tsx
import { Card } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import { Clock, BookOpen, CheckCircle } from "lucide-react";

<Card variant="standard" interactive className="p-6 flex flex-col justify-between">
  <div>
    <div className="flex items-center justify-between text-xs font-medium text-text-secondary mb-3">
      <span className="bg-primary-surface text-primary px-2.5 py-1 rounded-pill font-medium">
        {course.category}
      </span>
      <span className="flex items-center gap-1">
        <Clock className="w-3.5 h-3.5 text-text-tertiary" />
        {course.duration}
      </span>
    </div>
    <h4 className="text-lg font-bold text-text-primary font-display mb-2">{course.title}</h4>
    <p className="text-sm text-text-secondary line-clamp-2 mb-4">{course.description}</p>
  </div>
  <div className="pt-4 border-t border-primary/10 flex items-center justify-between mt-auto">
    <span className="text-xs text-text-secondary flex items-center gap-1">
      <BookOpen className="w-3.5 h-3.5 text-primary" /> {course.lessonsCount} leçons
    </span>
    <Button variant="primary" className="py-2 px-4 text-xs">
      Accéder au cours
    </Button>
  </div>
</Card>
```

### B. Student Progress Dashboard (Gamification R2)
```tsx
import { Card } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import { Trophy, Flame, Award, CheckCircle2 } from "lucide-react";

<Card variant="gamification" interactive className="p-6 flex flex-col gap-5">
  <div className="flex items-center justify-between">
    <div className="flex items-center gap-2">
      <Trophy className="w-5 h-5 text-gold-dark" />
      <h3 className="text-lg font-bold text-gold-dark font-display">Progression Étudiant</h3>
    </div>
    <span className="font-mono text-xs font-bold bg-gold/15 text-gold-dark px-2.5 py-1 rounded-pill">
      Niveau {student.level}
    </span>
  </div>

  {/* XP Bar */}
  <div className="bg-surface/70 rounded-md p-4 border border-gold/15">
    <div className="flex justify-between items-center mb-2">
      <span className="font-mono text-sm font-bold text-text-primary">Progression Niveau</span>
      <span className="font-mono text-xs text-text-secondary">{student.currentXp} / {student.targetXp} XP</span>
    </div>
    <div className="h-2 bg-surface-alt rounded-pill overflow-hidden border border-gold/10">
      <div 
        className="h-full bg-gradient-to-r from-[#34D399] to-[#10B981] transition-all duration-normal" 
        style={{ width: `${student.progressPercentage}%` }} 
      />
    </div>
  </div>

  {/* Stats Grid */}
  <div className="grid grid-cols-2 gap-3">
    <div className="bg-surface/70 rounded-md p-3 border border-gold/10 text-center">
      <span className="block font-mono text-xl font-bold text-text-primary">{student.completedLessons}</span>
      <span className="text-[11px] uppercase tracking-wider text-text-secondary font-medium">Leçons terminées</span>
    </div>
    <div className="bg-surface/70 rounded-md p-3 border border-gold/10 text-center">
      <span className="block font-mono text-xl font-bold text-gold-dark">{student.streakDays}j</span>
      <span className="text-[11px] uppercase tracking-wider text-text-secondary font-medium">Série active</span>
    </div>
  </div>

  <Button variant="gamification" className="w-full">
    Valider ma progression
  </Button>
</Card>
```

### C. Search & Filter Input (Catalog R1)
```tsx
import { Input } from "@/components/ui/Input";

<Input 
  label="Rechercher un cours" 
  placeholder="Ex: Algorithmique, Entrepreneuriat, Orientation..." 
  value={searchTerm}
  onChange={(e) => setSearchTerm(e.target.value)}
/>
```
