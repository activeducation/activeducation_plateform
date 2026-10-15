# Project: ActivEducation E-Learning & Orientation Platform

## Architecture
ActivEducation Next.js Web application (`d:\ActivEducation\web`):
- Framework: Next.js 16.3.5 (App Router with Turbopack), React 19.2.8, Tailwind CSS v4, TypeScript 5, Lucide React 1.47.0, Framer Motion 13.4.0.
- Design System V2 Tokens:
  - Font: Hanken Grotesque (`--font-sans`).
  - Primary Color: `#3133DD` (actions, links, active state), hover `#2829B8`.
  - Amber/Gold Color: `#FAA100` strictly reserved for matching scores and progression indicators.
  - Neutral/Surfaces: Canvas `#F7F8FB`, Surface `#FFFFFF`, Border `#E3E5EC`.
  - Iconography: Lucide SVG icons exclusively. ABSOLUTELY ZERO EMOJIS in UI or API responses.
- Primitives (`src/components/ui/`):
  - `Button`: `variant?: 'primary' | 'secondary' | 'gamification'`, `size?: 'sm' | 'md' | 'lg'`
  - `Card`: `variant?: 'standard' | 'gamification' | 'dark'`, `interactive?: boolean`
  - `Input`: `label: string`, `error?: string`
- Domain Layer:
  - RIASEC 12-item calibrated questionnaire (`web/src/lib/orientation.ts`).
  - 16 high-growth Togo careers and 10 MESR/CAMES accredited Togo higher education institutions.
  - Groq AI Matching (`llama-3.3-70b-versatile`) with persona AÏDA + resilient deterministic local fallback.

## Design & Acceptance Rules
1. **DA V2 Strict Compliance**: Hanken Grotesque font, `#3133DD` primary, flat design with 1px `#E3E5EC` borders.
2. **Amber (#FAA100) Boundary**: Amber is STRICTLY RESERVED for matching scores, RIASEC profile percentages, and progression indicators. Never used as general button background or decorative fluff.
3. **Zero Emoji Policy**: NO emojis anywhere in the UI, button labels, question cards, career titles, or AI response text.
4. **Resilient Matching**: Next.js Route Handler `/api/match` must query Groq API, but gracefully fall back to deterministic matching with authentic Togo schools and careers if `GROQ_API_KEY` is absent or unreachable.
5. **Fluid Motion**: Card swiping or interactive QCM must provide smooth, engaging animations (drag physics / spring transitions).
6. **Automated Verification**: `npm run build` must compile cleanly; `test-match.js` must validate `/api/match` contract, 3 careers, 3 Togo institutions, and zero emojis.

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Course Catalog (R1 prev) | Display list of E-learning courses with mock data, `<Card variant="standard">`. Zero gold. | M1 | ORIGINAL_REQUEST §2026-09-22T10:27:06Z |
| 2 | Student Progression (R2 prev) | Student progression (level, XP progress bar, badges) with gold accents. | M1 | ORIGINAL_REQUEST §2026-09-22T10:27:06Z |
| 3 | Core Layout & Design (R3 prev) | Split-screen asymmetric layout, Button, Card, Input. | M1 | ORIGINAL_REQUEST §2026-09-22T10:27:06Z |
| 4 | Groq AI Matching API (R2) | Route Handler `/api/match` (POST) querying Groq (llama3) with persona AÏDA + deterministic Togo fallback returning psychological profile, 3 high-growth careers, 3 accredited Togo institutions. Zero emojis. | M2 | ORIGINAL_REQUEST §2026-09-22T11:31:59Z |
| 5 | Automated Test Script (AC) | Node.js script `test-match.js` testing `/api/match` with mock answers, asserting HTTP 200, valid JSON schema, 3 careers, 3 Togo MESR institutions, and zero emojis. | M2 | ORIGINAL_REQUEST §2026-09-22T11:31:59Z |
| 6 | Interactive Orientation Test UI (R1) | Addictive swiping cards / interactive QCM using fluid drag/spring motion, 12 RIASEC questions, DA V2 (Hanken Grotesque, #3133DD, flat borders), zero emojis. | M2 | ORIGINAL_REQUEST §2026-09-22T11:31:59Z |
| 7 | Orientation Results Dashboard (R3) | Visual results dashboard rendering psychological profile, 3 high-growth careers, 3 accredited Togo institutions, with amber (`#FAA100`) matching scores, and zero emojis. | M2 | ORIGINAL_REQUEST §2026-09-22T11:31:59Z |
| 8 | E2E Integration & Build (AC) | Full integration on `/orientation`, Navbar & Home CTAs, `npm run build` clean compile, `test-match.js` passing, forensic audit clean. | M2 | ORIGINAL_REQUEST §2026-09-22T11:31:59Z |
| 9 | Gamified Student Test UI (R1) | Typeform-style interactive 4-question test with Framer Motion, "AÏDA analyse votre profil..." loading screen, API dispatch, redirect to results. | M3 | ORIGINAL_REQUEST §2026-09-30T23:21:56Z |
| 10 | Student Results Dashboard (R2) | UI displaying psychologicalProfile, 3 recommendedCareers, recommendedSchools with royal blue, amber (#FAA100) strictly for match %, and zero emojis. | M3 | ORIGINAL_REQUEST §2026-09-30T23:21:56Z |
| 11 | Resilient Orientation Generation API | Route `/api/orientation/generate` with demo graceful auth, deterministic Togo fallback, zero-emoji sanitization, and automated verification script `test-orientation-generate.js`. | M3 | ORIGINAL_REQUEST §2026-09-30T23:21:56Z |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Course Catalog & Progression (M1) | Catalog, Dashboard, Primitives | Survey complete | DONE |
| 2 | Orientation Module End-to-End (M2) | R1 Swiping Test UI, R2 Groq Matching & Route `/api/match`, R3 Results Dashboard, `test-match.js`, `npm run build` | Survey complete | DONE |
| 3 | AÏDA Student Orientation Experience (M3) | R1 `/student/orientation`, R2 `/student/orientation/resultats`, `/api/orientation/generate` resilience, `test-orientation-generate.js` | M2 complete | IN_PROGRESS |

## Code Layout
- Shared Orientation Domain & Fallback: `d:\ActivEducation\web\src\lib\orientation.ts`
- Route Handlers:
  - `d:\ActivEducation\web\src\app\api\match\route.ts` (M2 public match)
  - `d:\ActivEducation\web\src\app\api\orientation\generate\route.ts` (M3 student generate)
- Automated Verification Scripts:
  - `d:\ActivEducation\web\test-match.js` (M2 verification)
  - `d:\ActivEducation\web\test-orientation-generate.js` (M3 verification)
- Student Orientation Pages (M3):
  - `d:\ActivEducation\web\src\app\student\orientation\page.tsx` (R1 Gamified test)
  - `d:\ActivEducation\web\src\app\student\orientation\resultats\page.tsx` (R2 Results dashboard)
- Interactive Test Component (M2): `d:\ActivEducation\web\src\components\orientation\SwipeCard.tsx` and `OrientationTest.tsx`
- Results Dashboard Component (M2): `d:\ActivEducation\web\src\components\orientation\OrientationResults.tsx`
- Dedicated Orientation Page (M2): `d:\ActivEducation\web\src\app\orientation\page.tsx`
- UI Primitives:
  - `d:\ActivEducation\web\src\components\ui\Card.tsx`
  - `d:\ActivEducation\web\src\components\ui\Button.tsx`
  - `d:\ActivEducation\web\src\components\ui\Input.tsx`
- Navigation & Entrypoints:
  - `d:\ActivEducation\web\src\components\Navbar.tsx` (Orientation nav link)
  - `d:\ActivEducation\web\src\app\page.tsx` (Hero CTA & orientation highlight banner)

## Interface Contracts
### `/api/match` Route Handler
- Method: `POST`
- Request Payload: `{ answers: Record<string, number | boolean | string> }` or `{ scores: Record<string, number> }`
- Response Schema:
  ```ts
  interface MatchResponse {
    profile: {
      code: string; // e.g. "RIA", "SEC"
      title: string; // e.g. "Profil Créateur Technologique"
      description: string;
      dominantTraits: string[];
      strengths: string[];
      advice: string;
    };
    careers: Array<{
      id: string;
      title: string;
      matchScore: number; // 0 to 100
      demand: string; // "Tres Forte" | "Forte" | "Moyenne"
      salary: string; // e.g. "350 000 - 650 000 FCFA / mois"
      description: string;
      requiredSkills: string[];
      relevantSchools: string[];
    }>; // exactly 3 items
    institutions: Array<{
      id: string;
      name: string; // official Togo institution, e.g. "Université de Lomé (UL)"
      type: 'public' | 'private';
      city: string; // e.g. "Lomé", "Kara"
      accreditation: string; // "MESR Togo / CAMES"
      programs: string[];
    }>; // exactly 3 items
  }
  ```
- No emojis in any property.

### `/api/orientation/generate` Route Handler (M3)
- Method: `POST`
- Request Payload: `{ answers: { interests: string[]; strongSubjects: string[]; budget: string; mobility: string; otherSubject?: string; currentCity?: string } }`
- Response Schema:
  ```ts
  interface OrientationGenerateResponse {
    psychologicalProfile: {
      dominantTraits: string[];
      strengths: string[];
      weaknesses: string[];
      summary: string;
    };
    recommendedCareers: Array<{
      title: string;
      matchPercentage: number; // 0 to 100
      description: string;
      salaryRangeCFA: string; // e.g. "250 000 - 850 000 FCFA / mois"
      demandInTogo: 'Faible' | 'Moyenne' | 'Forte';
    }>; // exactly 3 items
    recommendedSchools: Array<{
      name: string; // official accredited Togo institution
      program: string;
      estimatedAnnualCostCFA: string; // e.g. "Public / 25 000 - 50 000 FCFA" or "450 000 FCFA / an"
      whyThisSchool: string;
    }>; // 1 to 3 items
  }
  ```
- No emojis in any property.
- Graceful degradation: demo mode support (anonymously callable), deterministic Togo fallback if Groq API is absent/unavailable, and non-blocking DB persistence.

