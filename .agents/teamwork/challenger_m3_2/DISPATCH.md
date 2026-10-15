# Dispatch Instructions for Challenger M3_2

## Role & Identity
You are `challenger_m3_2` (teamwork_preview_challenger).
Working directory: `d:\ActivEducation\.agents\teamwork\challenger_m3_2`

## Inputs
- User Request: `d:\ActivEducation\.agents\ORIGINAL_REQUEST.md` (specifically ## 2026-09-30T23:21:56Z)
- Project Index: `d:\ActivEducation\.agents\PROJECT.md`
- Target Verification Files:
  - `d:\ActivEducation\web\test-orientation-generate.js`
  - `d:\ActivEducation\web\src\app\api\orientation\generate\route.ts`
  - `d:\ActivEducation\web\src\lib\orientation.ts`

## Adversarial Verification Focus
1. Adversarially verify `test-orientation-generate.js`:
   - Inspect test assertions and schema validation.
   - Run the script or evaluate its execution against the deterministic fallback and API contract.
   - Verify that all 3 careers contain salaries in FCFA and realistic demand ratings.
   - Verify that schools are official accredited Togo institutions (e.g. UL, UK, IAI-Togo, ESGIS).
2. Execute automated regex check for any Unicode emojis across all new and modified files:
   - `web/src/app/student/orientation/page.tsx`
   - `web/src/app/student/orientation/resultats/page.tsx`
   - `web/src/app/api/orientation/generate/route.ts`
   - `web/src/lib/orientation.ts`
3. Verify Next.js compilation / TypeScript type checking.
4. Issue verdict: `APPROVE` or `REQUEST_CHANGES` with concrete evidence.

## Output
Write your findings to `d:\ActivEducation\.agents\teamwork\challenger_m3_2\handoff.md`.
Report back via send_message to orchestrator when finished.

## 2026-09-30T23:38:18Z
You are challenger_m3_2. Your working directory is d:\ActivEducation\.agents\teamwork\challenger_m3_2.
Read your instructions in d:\ActivEducation\.agents\teamwork\challenger_m3_2\DISPATCH.md.
Also read ORIGINAL_REQUEST.md at d:\ActivEducation\.agents\ORIGINAL_REQUEST.md.
Adversarially verify the test-orientation-generate.js test script, API contract, salaries in FCFA, authentic Togo institutions, and perform regex check for zero emojis across all code files.
Write your complete report to d:\ActivEducation\.agents\teamwork\challenger_m3_2\handoff.md.
Report your verdict (APPROVE or REQUEST_CHANGES) via send_message when finished.

