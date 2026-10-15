# Dispatch Instructions for Reviewer M3_2

## Role & Identity
You are `reviewer_m3_2` (teamwork_preview_reviewer).
Working directory: `d:\ActivEducation\.agents\teamwork\reviewer_m3_2`

## Inputs
- User Request: `d:\ActivEducation\.agents\ORIGINAL_REQUEST.md` (specifically ## 2026-09-30T23:21:56Z)
- Project Index: `d:\ActivEducation\.agents\PROJECT.md`
- Worker Handoff: `d:\ActivEducation\.agents\teamwork\worker_m3_1\handoff.md`
- Target Implementation Files:
  - `d:\ActivEducation\web\src\app\api\orientation\generate\route.ts`
  - `d:\ActivEducation\web\src\lib\orientation.ts`
  - `d:\ActivEducation\web\test-orientation-generate.js`
  - `d:\ActivEducation\web\src\app\student\orientation\resultats\page.tsx`

## Review Focus: Backend API, Data Contracts & State Architecture
1. Verify `/api/orientation/generate/route.ts`:
   - Handles demo mode / anonymous access gracefully without failing 401.
   - Calls Groq AI or falls back to `generateDeterministicOrientationM3`.
   - Zod schema matches R2: `psychologicalProfile`, `recommendedCareers` (3 items), `recommendedSchools` (1-3 items).
   - Non-blocking DB persistence.
   - Strict zero-emoji sanitization (`sanitizeObject`).
2. Verify deterministic fallback in `src/lib/orientation.ts`:
   - Uses authentic Togo careers and institutions catalogs.
   - Correctly maps answers to realistic recommendations with salaries in FCFA.
3. Verify state persistence & SSR hydration:
   - Safe reading of `sessionStorage` in `useEffect` in results page.
   - Graceful fallback model when accessing `/student/orientation/resultats` directly without test session.
4. Verdict must be either `APPROVE` or `REQUEST_CHANGES` with clear rationale.

## Output
Write your full review report to `d:\ActivEducation\.agents\teamwork\reviewer_m3_2\handoff.md`.
Report back via send_message to orchestrator when finished.

## 2026-09-30T23:38:17Z
You are reviewer_m3_2. Your working directory is d:\ActivEducation\.agents\teamwork\reviewer_m3_2.
Read your instructions in d:\ActivEducation\.agents\teamwork\reviewer_m3_2\DISPATCH.md.
Also read ORIGINAL_REQUEST.md at d:\ActivEducation\.agents\ORIGINAL_REQUEST.md.
Review backend API resilience (/api/orientation/generate), deterministic fallback in src/lib/orientation.ts, data contracts (psychologicalProfile, recommendedCareers, recommendedSchools), state persistence, and SSR hydration safety.
Write your complete review report to d:\ActivEducation\.agents\teamwork\reviewer_m3_2\handoff.md.
Report your verdict (APPROVE or REQUEST_CHANGES) via send_message when finished.

