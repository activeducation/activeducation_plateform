# Dispatch Instructions for Worker M3_1

## Role & Identity
You are `worker_m3_1` (teamwork_preview_worker).
Working directory: `d:\ActivEducation\.agents\teamwork\worker_m3_1`

## MANDATORY INTEGRITY WARNING
> DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

## Inputs
- User Request: `d:\ActivEducation\.agents\ORIGINAL_REQUEST.md` (specifically ## 2026-09-30T23:21:56Z)
- Project Index: `d:\ActivEducation\.agents\PROJECT.md`
- Explorer Reports:
  - `d:\ActivEducation\.agents\teamwork\explorer_m3_1\handoff.md` (API & contracts)
  - `d:\ActivEducation\.agents\teamwork\explorer_m3_2\handoff.md` (UI/UX & Design System)
  - `d:\ActivEducation\.agents\teamwork\explorer_m3_3\handoff.md` (Build & State architecture)

## Exclusive File Ownership
You exclusively own and can create/modify:
- `d:\ActivEducation\web\src\app\student\orientation\page.tsx`
- `d:\ActivEducation\web\src\app\student\orientation\resultats\page.tsx`
- `d:\ActivEducation\web\src\app\api\orientation\generate\route.ts`
- `d:\ActivEducation\web\src\lib\orientation.ts` (adding `generateDeterministicOrientationM3`)
- `d:\ActivEducation\web\test-orientation-generate.js`

Do NOT touch or overwrite `d:\ActivEducation\web\src\app\orientation\page.tsx` (M2 route) or `web/src/app/api/match/route.ts`.

## Core Implementation Requirements
1. **R1: `/student/orientation/page.tsx`**:
   - `"use client";`
   - Gamified questionnaire with Framer Motion (smooth horizontal transitions, Typeform / QCM interactif feel).
   - 4 key questions:
     1. Intérêts (Sciences, Littérature, Économie, Santé, Arts, Ingénierie)
     2. Matières fortes (Maths/Physique, Français, SVT, Anglais, Histoire-Géo, Informatique) + `<Input label="Autre matière spécifique (facultatif)" />`
     3. Budget (Faible: < 200k FCFA, Moyen: 200k-600k FCFA, Élevé: > 600k FCFA)
     4. Région / Mobilité (Grand Lomé, Kara, Plateaux/Centrale, Savanes, Mobilité Totale) + `<Input label="Votre ville de résidence actuelle" />`
   - Step indicator: 1/4 to 4/4 with progress bar.
   - Screen: "AÏDA analyse votre profil..." with pulsing `Sparkles` icon in Royal Blue (`#3133DD`) and 4 animated analysis steps during `POST /api/orientation/generate`.
   - Store response in `sessionStorage.setItem('activ_orientation_results', JSON.stringify(data))` and redirect with `router.push('/student/orientation/resultats')`.
   - Resilient frontend fallback: if API call returns an error or is unreachable, fallback to deterministic model profile and proceed so the user is never stuck.

2. **R2: `/student/orientation/resultats/page.tsx`**:
   - `"use client";`
   - Read from `sessionStorage` in `useEffect` (safe for React 19 SSR hydration).
   - If accessed directly without test data, load realistic default model data with informative banner and CTA "Faire mon test personnalisé".
   - Render 3 major sections:
     - `psychologicalProfile` (dominantTraits, strengths, weaknesses, summary)
     - `recommendedCareers` (Array of 3: title, matchPercentage, description, salaryRangeCFA, demandInTogo)
     - `recommendedSchools` (Array of 1 to 3: name, program, estimatedAnnualCostCFA, whyThisSchool)
   - Component reuse: `<Card variant="standard">`, `<Button variant="primary">`, `<Button variant="secondary">`, `<Input label="..." />`.
   - Color Rules: Royal Blue (`#3133DD`) for main actions/titles, Gold/Amber (`#FAA100`) STRICTLY reserved for `matchPercentage` and progress bars!
   - STRICT ZERO EMOJI POLICY: Absolutely zero emojis anywhere in the code or UI. Use Lucide icons only (`Sparkles`, `Brain`, `Briefcase`, `Building2`, `TrendingUp`, `Banknote`, `CheckCircle2`, `ShieldAlert`, `GraduationCap`, `Coins`, etc.).
   - Actions: "Repasser le test" (`Button variant="secondary"`), "Explorer les cours" (`Button variant="primary"`), and email input `<Input label="Recevoir mon bilan complet par email" />`.

3. **Backend & Fallback Resilience**:
   - In `web/src/lib/orientation.ts`: Export `generateDeterministicOrientationM3(answers)` using the authentic Togo careers and institutions catalogs, returning the exact M3 schema and sanitized of emojis.
   - In `web/src/app/api/orientation/generate/route.ts`:
     - Allow execution in demo mode (catch auth error and continue with anonymous user).
     - Try Groq AI (`llama-3.1-70b-versatile` or `llama-3.3-70b-versatile`); on missing key, timeout, or error, fallback to `generateDeterministicOrientationM3(answers)`.
     - Non-blocking DB insert (do not fail the request if DB fails).
     - Apply `sanitizeObject()` to guarantee zero emojis.

4. **Verification & Build**:
   - Create and run `web/test-orientation-generate.js`.
   - Run `npm run build` in `d:\ActivEducation\web` to ensure zero compilation or TypeScript errors.
   - Run regex emoji check on the created pages to verify zero emojis.

## Output
Write complete implementation details, build outputs, and test results in `d:\ActivEducation\.agents\teamwork\worker_m3_1\handoff.md`.
Report back when finished.

## 2026-09-30T23:31:32Z
You are worker_m3_1. Your working directory is d:\ActivEducation\.agents\teamwork\worker_m3_1.
Read your instructions in d:\ActivEducation\.agents\teamwork\worker_m3_1\DISPATCH.md.
Also read ORIGINAL_REQUEST.md at d:\ActivEducation\.agents\ORIGINAL_REQUEST.md.
Follow the MANDATORY INTEGRITY WARNING: DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A auditor will independently verify your work.
Implement R1 (/student/orientation/page.tsx) and R2 (/student/orientation/resultats/page.tsx) with strict adherence to Design System V2 and zero-emoji policy, make /api/orientation/generate resilient with Togo fallback in src/lib/orientation.ts, create test-orientation-generate.js, and run npm run build.
Write your complete report to d:\ActivEducation\.agents\teamwork\worker_m3_1\handoff.md.
Report back via send_message to orchestrator when finished.
