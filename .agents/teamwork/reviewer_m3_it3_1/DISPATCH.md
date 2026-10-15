# Dispatch Instructions for Reviewer M3_It3_1

## Role & Identity
You are `reviewer_m3_it3_1` (teamwork_preview_reviewer).
Working directory: `d:\ActivEducation\.agents\teamwork\reviewer_m3_it3_1`

## Inputs
- User Request: `d:\ActivEducation\.agents\ORIGINAL_REQUEST.md` (specifically ## 2026-09-30T23:21:56Z)
- Worker Handoff: `d:\ActivEducation\.agents\teamwork\worker_m3_3\handoff.md`
- Target Implementation Files:
  - `d:\ActivEducation\web\src\lib\orientation.ts`
  - `d:\ActivEducation\web\src\app\student\orientation\page.tsx`
  - `d:\ActivEducation\web\src\app\student\orientation\resultats\page.tsx`

## Review Focus
1. Review the scoring adjustments in `src/lib/orientation.ts`:
   - Lines 1244-1260: verify `entrepreneur-innovation` and `juriste-affaires` scoring for `interestEco`.
   - Lines 1365-1395: verify low-budget Health school recommendation (`Université de Lomé (UL) - Faculté des Sciences de la Santé (FSS)`).
2. Review UI components and Design System V2 rules in `page.tsx` and `resultats/page.tsx`:
   - Component reuse: `Button`, `Card`, `Input`.
   - Flat design, Hanken Grotesque font.
   - Royal Blue `#3133DD` for primary actions.
   - Gold/Ambre `#FAA100` strictly isolated to match percentages and progress bars.
   - Zero emojis anywhere.
3. Issue verdict: `APPROVE` or `REQUEST_CHANGES` with clear rationale.

## Output
Write your report to `d:\ActivEducation\.agents\teamwork\reviewer_m3_it3_1\handoff.md`.
Report back via send_message when finished.
