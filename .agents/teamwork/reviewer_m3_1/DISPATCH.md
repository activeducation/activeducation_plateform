# Dispatch Instructions for Reviewer M3_1

## Role & Identity
You are `reviewer_m3_1` (teamwork_preview_reviewer).
Working directory: `d:\ActivEducation\.agents\teamwork\reviewer_m3_1`

## Inputs
- User Request: `d:\ActivEducation\.agents\ORIGINAL_REQUEST.md` (specifically ## 2026-09-30T23:21:56Z)
- Project Index: `d:\ActivEducation\.agents\PROJECT.md`
- Worker Handoff: `d:\ActivEducation\.agents\teamwork\worker_m3_1\handoff.md`
- Target Implementation Files:
  - `d:\ActivEducation\web\src\app\student\orientation\page.tsx`
  - `d:\ActivEducation\web\src\app\student\orientation\resultats\page.tsx`
  - `d:\ActivEducation\web\src\components\ui\Button.tsx`
  - `d:\ActivEducation\web\src\components\ui\Card.tsx`
  - `d:\ActivEducation\web\src\components\ui\Input.tsx`

## Review Focus: UI/UX & Design System V2
1. Verify compliance with Design System V2 rules:
   - Primary Royal Blue (`#3133DD`) used for main actions/titles.
   - Gold/Amber (`#FAA100`) STRICTLY reserved for `matchPercentage` and progress bars (NOT on generic action buttons).
   - Component reuse: `<Card variant="standard">`, `<Button variant="primary">` and `<Button variant="secondary">`, `<Input label="..." />`.
   - Flat design styling, 1px border (`#E3E5EC`).
   - Font: Hanken Grotesque.
2. Verify strict Zero Emoji policy:
   - Ensure absolutely no unicode emojis are present in `src/app/student/orientation/page.tsx` and `src/app/student/orientation/resultats/page.tsx`.
   - Check Lucide icon usage.
3. Verify R1 & R2 acceptance criteria:
   - 4 questions present (Intérêts, Matières fortes, Budget, Mobilité).
   - Loading screen "AÏDA analyse votre profil..." during API call.
   - Results page displaying `psychologicalProfile`, 3 `recommendedCareers`, and 1-3 `recommendedSchools`.
4. Verdict must be either `APPROVE` or `REQUEST_CHANGES` with clear rationale.

## Output
Write your full review report to `d:\ActivEducation\.agents\teamwork\reviewer_m3_1\handoff.md`.
Report back via send_message to orchestrator when finished.

## 2026-09-30T23:38:17Z
You are reviewer_m3_1. Your working directory is d:\ActivEducation\.agents\teamwork\reviewer_m3_1.
Read your instructions in d:\ActivEducation\.agents\teamwork\reviewer_m3_1\DISPATCH.md.
Also read ORIGINAL_REQUEST.md at d:\ActivEducation\.agents\ORIGINAL_REQUEST.md.
Review UI/UX, Design System V2 compliance (Hanken Grotesque, #3133DD primary, #FAA100 isolated strictly to match percentage, component reuse: Button, Card, Input), and zero-emoji policy for /student/orientation/page.tsx and /student/orientation/resultats/page.tsx.
Write your complete review report to d:\ActivEducation\.agents\teamwork\reviewer_m3_1\handoff.md.
Report your verdict (APPROVE or REQUEST_CHANGES) via send_message when finished.

