# Dispatch Instructions for Explorer 2

## Role & Identity
You are `explorer_m3_2` (teamwork_preview_explorer).
Working directory: `d:\ActivEducation\.agents\teamwork\explorer_m3_2`

## Inputs
- User Request: `d:\ActivEducation\.agents\ORIGINAL_REQUEST.md` (specifically ## 2026-09-30T23:21:56Z)
- Project Index: `d:\ActivEducation\.agents\PROJECT.md`
- Codebase: `d:\ActivEducation\web`

## Mission & Objectives
Investigate UI components, Design System rules, and page structure:
1. Check existing UI primitives in `web/src/components/ui/` (`Button.tsx`, `Card.tsx`, `Input.tsx`). Verify available props, variants, and design tokens.
2. Check existing orientation components in `web/src/components/orientation` and pages in `web/src/app`.
3. Check whether `d:\ActivEducation\web\src\app\student\orientation\page.tsx` and `d:\ActivEducation\web\src\app\student\orientation\resultats\page.tsx` exist.
4. Design the UX/UI for R1 (/student/orientation/page.tsx):
   - Gamified questionnaire (Typeform style / interactive QCM) with Framer Motion transitions.
   - 4 questions:
     1. Intérêts (Sciences, Littérature, etc.)
     2. Matières fortes
     3. Budget (Faible, Moyen, Élevé)
     4. Région / Mobilité
   - Loading screen: "AÏDA analyse votre profil..." during API call.
5. Design the UI for R2 (/student/orientation/resultats/page.tsx):
   - Visualizing the AI JSON (psychologicalProfile, recommendedCareers, recommendedSchools).
   - Strict color rules: Royal Blue (`#3133DD`) primary, Gold/Amber (`#FAA100`) strictly for matching scores/progression, zero emojis!
   - Font: Hanken Grotesque, flat borders (`#E3E5EC`).

## Output
Write your findings and evidence chain to `d:\ActivEducation\.agents\teamwork\explorer_m3_2\handoff.md`.
Report back when finished.

## 2026-09-30T23:24:40Z
You are explorer_m3_2. Your working directory is d:\ActivEducation\.agents\teamwork\explorer_m3_2.
Read your instructions in d:\ActivEducation\.agents\teamwork\explorer_m3_2\DISPATCH.md.
Investigate existing UI primitives (Button, Card, Input) in web/src/components/ui, existing orientation components in web/src/components/orientation, and the requirements for R1 (/student/orientation/page.tsx) and R2 (/student/orientation/resultats/page.tsx). Ensure strict adherence to Design System V2 (Hanken Grotesque, #3133DD, #FAA100 for scores only, flat borders, zero emojis).
Write your complete report to d:\ActivEducation\.agents\teamwork\explorer_m3_2\handoff.md.
Report back via send_message to orchestrator when finished.

