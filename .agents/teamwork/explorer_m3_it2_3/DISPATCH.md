# Dispatch Instructions for Explorer It2_3

## Role & Identity
You are `explorer_m3_it2_3` (teamwork_preview_explorer).
Working directory: `d:\ActivEducation\.agents\teamwork\explorer_m3_it2_3`

## Inputs
- User Request: `d:\ActivEducation\.agents\ORIGINAL_REQUEST.md` (specifically ## 2026-09-30T23:21:56Z)
- Gate Status: `d:\ActivEducation\.agents\orchestrator_3\GATE_STATUS.md`
- Challenger 1 Report: `d:\ActivEducation\.agents\teamwork\challenger_m3_1\handoff.md`
- Target Files:
  - `d:\ActivEducation\web\src\app\student\orientation\page.tsx`
  - `d:\ActivEducation\web\src\app\student\orientation\resultats\page.tsx`
  - `d:\ActivEducation\web\test-orientation-generate.js`

## Mission & Objectives
Investigate the UI resilience and test script improvements:
1. In `src/app/student/orientation/resultats/page.tsx`:
   - Inspect lines 100-115 and 380-400.
   - Formulate the fix to guard `parsed.recommendedSchools` and use `(recommendedSchools || []).map(...)`.
2. In `src/app/student/orientation/page.tsx`:
   - Inspect lines 245-275 (`handleSubmit`).
   - Formulate the addition of an `AbortController` with a 5000ms timeout on `fetch('/api/orientation/generate')`.
   - Inspect step 1 subject selection: if only `otherSubject` is entered and `selectedSubjects` is empty, use `[otherSubject.trim()]` instead of overwriting with math.
3. In `web/test-orientation-generate.js`:
   - Formulate the addition of multi-profile test cases (e.g. Health profile expecting Medecin/Pharmacien, Engineering/BTP expecting Ingénieur Civil/Architecte).

## Output
Write your findings and recommendations to `d:\ActivEducation\.agents\teamwork\explorer_m3_it2_3\handoff.md`.
Report back when finished.

## 2026-09-30T23:45:21Z
You are explorer_m3_it2_3. Your working directory is d:\ActivEducation\.agents\teamwork\explorer_m3_it2_3.
Read your instructions in d:\ActivEducation\.agents\teamwork\explorer_m3_it2_3\DISPATCH.md.
Also read ORIGINAL_REQUEST.md at d:\ActivEducation\.agents\ORIGINAL_REQUEST.md.
Investigate UI resilience fixes (recommendedSchools undefined check, AbortController with 5s timeout on fetch in page.tsx, custom subject handling) and multi-profile test suite expansion in test-orientation-generate.js.
Write your report to d:\ActivEducation\.agents\teamwork\explorer_m3_it2_3\handoff.md.
Report back via send_message when finished.

