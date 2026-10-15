# Dispatch Instructions for Explorer 1

## Role & Identity
You are `explorer_m3_1` (teamwork_preview_explorer).
Working directory: `d:\ActivEducation\.agents\teamwork\explorer_m3_1`

## Inputs
- User Request: `d:\ActivEducation\.agents\ORIGINAL_REQUEST.md` (specifically ## 2026-09-30T23:21:56Z)
- Project Index: `d:\ActivEducation\.agents\PROJECT.md`
- Codebase: `d:\ActivEducation\web`

## Mission & Objectives
Investigate the backend API and data contracts:
1. Examine `d:\ActivEducation\web\src\app\api`. Does `/api/orientation/generate` already exist? How does it relate to `/api/match`?
2. Examine `d:\ActivEducation\web\src\lib\orientation.ts` and any Groq AI integration or fallback logic.
3. Check the exact JSON response contract specified in R2:
   - `psychologicalProfile` (dominantTraits, strengths, weaknesses, summary)
   - `recommendedCareers` (Array of {title, matchPercentage, description, salaryRangeCFA, demandInTogo})
   - `recommendedSchools` (Array of {name, program, estimatedAnnualCostCFA, whyThisSchool})
4. Determine what request payload `POST /api/orientation/generate` should accept from the 4 question categories:
   - Intérêts
   - Matières fortes
   - Budget
   - Région / Mobilité
5. Provide precise recommendation on how the Route Handler `/api/orientation/generate` should be structured and how it handles AI calls and fallbacks.

## Output
Write your findings and evidence chain to `d:\ActivEducation\.agents\teamwork\explorer_m3_1\handoff.md`.
Report back when finished.

## 2026-09-30T23:24:40Z
You are explorer_m3_1. Your working directory is d:\ActivEducation\.agents\teamwork\explorer_m3_1.
Read your instructions in d:\ActivEducation\.agents\teamwork\explorer_m3_1\DISPATCH.md.
Investigate backend API endpoints in web/src/app/api, specifically checking if /api/orientation/generate exists or how /api/match is implemented, how orientation data and Groq AI fallback are handled in web/src/lib/orientation.ts, and what schema is expected for R2.
Write your complete report to d:\ActivEducation\.agents\teamwork\explorer_m3_1\handoff.md.
Report back via send_message to orchestrator when finished.
