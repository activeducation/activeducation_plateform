# Execution Plan: AÏDA Orientation Web Experience (R1 & R2)

## Objectives
1. **R1: Gamified Orientation Test (/student/orientation/page.tsx)**:
   - Interactive questionnaire (Typeform style or interactive QCM) with Framer Motion.
   - Core questions:
     1. Intérêts (Sciences, Littérature, etc.)
     2. Matières fortes
     3. Budget (Faible, Moyen, Élevé)
     4. Région / Mobilité
   - Transition to loading state: "AÏDA analyse votre profil..." during `POST /api/orientation/generate`.
   - Forwarding results to results page or state.
2. **R2: Results Dashboard (/student/orientation/resultats/page.tsx)**:
   - Rendering structured AI JSON:
     - `psychologicalProfile` (dominantTraits, strengths, weaknesses, summary)
     - `recommendedCareers` (Array of {title, matchPercentage, description, salaryRangeCFA, demandInTogo})
     - `recommendedSchools` (Array of {name, program, estimatedAnnualCostCFA, whyThisSchool})
   - Color palette: Royal Blue primary (`#3133DD`) & Gold/Amber (`#FAA100`), flat borders, Hanken Grotesque font.
   - STRICTLY ZERO EMOJIS.
3. **Acceptance & Verification**:
   - Reuse existing UI components (`Button`, `Card`, `Input`).
   - Clean compilation: `npm run build`.
   - Comprehensive multi-agent gate checks (Reviewers, Challengers, Auditor).

## Phases & Milestones

### Phase 1: Exploration & Technical Investigation
- Dispatch 3 Explorers in parallel:
  - `explorer_3_1`: Investigate Next.js App Router structure in `web/src/app`, check if `/api/orientation/generate` exists or if `/api/match` exists, inspect request/response schemas, check route handling.
  - `explorer_3_2`: Investigate existing UI components (`web/src/components/ui`), Tailwind config, typography (Hanken Grotesque), color tokens, Framer Motion setup, and existing orientation components in `web/src/components/orientation`.
  - `explorer_3_3`: Investigate state passing between `/student/orientation` and `/student/orientation/resultats` (query params, localStorage, session storage, or server/client state), edge cases, error states, and build constraints (`npm run build`).

### Phase 2: Implementation (Worker)
- Dispatch Worker `worker_3_1` to implement:
  - Verify and create `/api/orientation/generate` (or route adapter to existing AI matching logic) returning the exact specified schema.
  - Implement `/student/orientation/page.tsx` with Framer Motion, 4 key questions, loading screen "AÏDA analyse votre profil...", and API integration.
  - Implement `/student/orientation/resultats/page.tsx` displaying `psychologicalProfile`, `recommendedCareers`, and `recommendedSchools` with royal blue & amber accents, zero emojis, and full design system compliance.
  - Ensure `npm run build` passes with 0 errors.

### Phase 3: Review, Challenge & Forensic Audit
- Dispatch Reviewers:
  - `reviewer_3_1` & `reviewer_3_2`: Review UI/UX, Design System V2 rules, zero emojis, component reuse, Next.js build.
- Dispatch Challengers:
  - `challenger_3_1` & `challenger_3_2`: Empirical stress-testing, API contract validation, routing/state transitions, edge cases.
- Dispatch Forensic Auditor:
  - `auditor_3_1`: Forensic integrity check (no mock bypasses, authentic implementation, zero emojis, layout integrity).

### Phase 4: Gate Synthesis & Completion
- Synthesize all results in `GATE_STATUS.md`.
- Report to Sentinel with comprehensive summary.
