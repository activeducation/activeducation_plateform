# Dispatch Instructions for Worker M3_2 (Iteration 2)

## Role & Identity
You are `worker_m3_2` (teamwork_preview_worker).
Working directory: `d:\ActivEducation\.agents\teamwork\worker_m3_2`

## MANDATORY INTEGRITY WARNING
> DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

## Inputs
- Gate Status: `d:\ActivEducation\.agents\orchestrator_3\GATE_STATUS.md`
- Original Request: `d:\ActivEducation\.agents\ORIGINAL_REQUEST.md` (specifically ## 2026-09-30T23:21:56Z)
- Explorer Solutions:
  - `d:\ActivEducation\.agents\teamwork\explorer_m3_it2_1\handoff.md` (TS2322 fix in orientation.ts)
  - `d:\ActivEducation\.agents\teamwork\explorer_m3_it2_2\handoff.md` (16 career canonical mapping in orientation.ts)
  - `d:\ActivEducation\.agents\teamwork\explorer_m3_it2_3\handoff.md` (UI resilience & multi-profile test suite)

## Exclusive File Ownership
You exclusively own and can modify:
- `d:\ActivEducation\web\src\lib\orientation.ts`
- `d:\ActivEducation\web\src\app\student\orientation\resultats\page.tsx`
- `d:\ActivEducation\web\src\app\student\orientation\page.tsx`
- `d:\ActivEducation\web\test-orientation-generate.js`

## Specific Tasks to Implement

### 1. Fix TypeScript Error TS2322 in `web/src/lib/orientation.ts`
Apply the patch from `explorer_m3_it2_1`:
- In `RiasecScores` (around line 76): Add `[key: string]: number;`.
- In `MatchProfile` (around line 90): Set `scores?: RiasecScores | Record<string, number>;`.

### 2. Fix Career ID Mismatch & Two-Tier Scoring in `web/src/lib/orientation.ts`
Apply the patch from `explorer_m3_it2_2`:
- In `generateDeterministicOrientationM3` (lines 1177 to 1225): Replace scoring logic with the two-tier decoupled interest & subject mapping covering all 16 canonical IDs (`dev-web-mobile`, `data-analyst-ia`, `cybersecurite-reseaux`, `ingenieur-btp-civil`, `architecte-urbaniste`, `ingenieur-agronome`, `medecin-sante`, `pharmacien-biologiste`, `comptable-auditeur`, `banquier-analyste`, `entrepreneur-innovation`, `responsable-rh`, `designer-graphique`, `marketing-digital`, `juriste-affaires`, `enseignant-formateur`).

### 3. Fix UI Resilience in `web/src/app/student/orientation/resultats/page.tsx`
Apply the patch from `explorer_m3_it2_3`:
- Line ~104: Guard `parsed.recommendedSchools`: `&& Array.isArray(parsed.recommendedSchools)`.
- Line ~382: Guard rendering: `{(recommendedSchools || []).map((school, idx) => (` (and ensure `recommendedCareers` and `psychologicalProfile` arrays are similarly guarded).

### 4. Fix UI Resilience & Timeout in `web/src/app/student/orientation/page.tsx`
Apply the patch from `explorer_m3_it2_3`:
- In `handleSubmit`:
  - If `selectedSubjects.length === 0 && otherSubject.trim().length > 0`, set `strongSubjects: [otherSubject.trim()]` instead of overwriting with math.
  - Add `const controller = new AbortController(); const timeoutId = setTimeout(() => controller.abort(), 5000);` passed to `fetch('/api/orientation/generate', { signal: controller.signal })`. Clear timeout in `finally`.
  - On network error or abort, seamlessly fall back to `generateDeterministicOrientationM3`.

### 5. Expand `web/test-orientation-generate.js`
Apply the multi-profile expansion from `explorer_m3_it2_3`:
- Add test cases for Tech, Health (expecting Médecin/Pharmacien), BTP (expecting Ingénieur BTP), and Eco/Management (expecting Comptable/Banquier).
- Assert all 6 contract rules + zero emojis on every test case.

### 6. Build & Test Verification
- Run `node test-orientation-generate.js`.
- Run `npm run build` in `d:\ActivEducation\web` and verify that the build compiles with 0 errors (exit code 0).
- Run regex emoji check on all target files.

## Output
Write your handoff report with build and test execution results to `d:\ActivEducation\.agents\teamwork\worker_m3_2\handoff.md`.
Report back when finished.

## 2026-09-30T23:51:45Z
You are worker_m3_2. Your working directory is d:\ActivEducation\.agents\teamwork\worker_m3_2.
Read your instructions in d:\ActivEducation\.agents\teamwork\worker_m3_2\DISPATCH.md.
Also read ORIGINAL_REQUEST.md at d:\ActivEducation\.agents\ORIGINAL_REQUEST.md.
Follow the MANDATORY INTEGRITY WARNING: DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. An auditor will independently verify your work.
Implement the 5 targeted fixes from explorer_m3_it2_1, explorer_m3_it2_2, and explorer_m3_it2_3 in web/src/lib/orientation.ts, web/src/app/student/orientation/resultats/page.tsx, web/src/app/student/orientation/page.tsx, and web/test-orientation-generate.js.
Run node test-orientation-generate.js and run npm run build to verify 0 errors.
Write your complete report to d:\ActivEducation\.agents\teamwork\worker_m3_2\handoff.md.
Report back via send_message to orchestrator when finished.
