# Dispatch Instructions for Reviewer M3_It3_2

## Role & Identity
You are `reviewer_m3_it3_2` (teamwork_preview_reviewer).
Working directory: `d:\ActivEducation\.agents\teamwork\reviewer_m3_it3_2`

## Inputs
- User Request: `d:\ActivEducation\.agents\ORIGINAL_REQUEST.md` (specifically ## 2026-09-30T23:21:56Z)
- Worker Handoff: `d:\ActivEducation\.agents\teamwork\worker_m3_3\handoff.md`
- Target Implementation Files:
  - `d:\ActivEducation\web\test-orientation-generate.js`
  - `d:\ActivEducation\web\src\lib\orientation.ts`
  - `d:\ActivEducation\web\src\app\api\orientation\generate\route.ts`

## Review Focus
1. Review `test-orientation-generate.js`:
   - Inspect Assertion 7 (lines 200-236): verify strict Top 2 / Top 3 positional assertions for all 4 profiles (Tech, Santé, BTP, Gestion).
   - Verify that test assertions reject invalid or displaced rankings.
2. Review API route `/api/orientation/generate/route.ts` resilience and zero-emoji sanitization.
3. Verify zero emojis across all target files.
4. Issue verdict: `APPROVE` or `REQUEST_CHANGES` with clear rationale.

## Output
Write your report to `d:\ActivEducation\.agents\teamwork\reviewer_m3_it3_2\handoff.md`.
Report back via send_message when finished.

## 2026-10-01T00:09:38Z
You are reviewer_m3_it3_2. Your working directory is d:\ActivEducation\.agents\teamwork\reviewer_m3_it3_2.
Read your instructions in d:\ActivEducation\.agents\teamwork\reviewer_m3_it3_2\DISPATCH.md.
Also read ORIGINAL_REQUEST.md at d:\ActivEducation\.agents\ORIGINAL_REQUEST.md.
Review the hardened multi-profile test suite in test-orientation-generate.js (lines 200-236) and API route resilience.
Write your complete report to d:\ActivEducation\.agents\teamwork\reviewer_m3_it3_2\handoff.md.
Report your verdict (APPROVE or REQUEST_CHANGES) via send_message when finished.
