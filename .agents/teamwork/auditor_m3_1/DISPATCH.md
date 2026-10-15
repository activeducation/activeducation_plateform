# Dispatch Instructions for Forensic Auditor M3_1

## Role & Identity
You are `auditor_m3_1` (teamwork_preview_auditor).
Working directory: `d:\ActivEducation\.agents\teamwork\auditor_m3_1`

## Inputs
- User Request: `d:\ActivEducation\.agents\ORIGINAL_REQUEST.md` (specifically ## 2026-09-30T23:21:56Z)
- Project Index: `d:\ActivEducation\.agents\PROJECT.md`
- Target Implementation Files:
  - `d:\ActivEducation\web\src\app\student\orientation\page.tsx`
  - `d:\ActivEducation\web\src\app\student\orientation\resultats\page.tsx`
  - `d:\ActivEducation\web\src\app\api\orientation\generate\route.ts`
  - `d:\ActivEducation\web\src\lib\orientation.ts`
  - `d:\ActivEducation\web\test-orientation-generate.js`

## Forensic Integrity Verification Focus
You are the Forensic Integrity Auditor with BINARY VETO POWER.
Check for any integrity violations:
1. **No Cheating / No Dummy Facades**:
   - Verify that `/student/orientation/page.tsx` genuinely implements the 4-question interactive questionnaire with Framer Motion, does not bypass question steps, and genuinely calls `/api/orientation/generate`.
   - Verify that `/student/orientation/resultats/page.tsx` genuinely parses and renders the full JSON structure (psychologicalProfile, 3 recommendedCareers, recommendedSchools).
   - Verify that `generateDeterministicOrientationM3` in `src/lib/orientation.ts` genuinely calculates affinities from Togo catalogs, not returning hardcoded dummy single-strings.
2. **Design System & DA V2 Strict Rules**:
   - Verify that Royal Blue (`#3133DD`) is used for primary actions and titles.
   - Verify that Or/Ambre (`#FAA100`) is STRICTLY ISOLATED to `matchPercentage` and progress bars. Check that no generic buttons use `variant="gamification"`.
   - Verify that UI components (`Button`, `Card`, `Input`) are imported and used correctly from `web/src/components/ui/`.
3. **STRICT ZERO EMOJI POLICY**:
   - Perform an exhaustive regex search for any emoji character across all target files.
4. **Authenticity of Togo Institutions & Salaries**:
   - Check that schools are real accredited institutions in Togo (UL, UK, IAI, ESGIS, etc.).
   - Check that salaries are realistically expressed in FCFA.
5. **Verdict**:
   - Verdict must be either `CLEAN` or `INTEGRITY VIOLATION` (with detailed evidence).

## Output
Write your full forensic audit report to `d:\ActivEducation\.agents\teamwork\auditor_m3_1\handoff.md`.
Report back via send_message to orchestrator when finished.

## 2026-09-30T23:38:18Z
You are auditor_m3_1. Your working directory is d:\ActivEducation\.agents\teamwork\auditor_m3_1.
Read your instructions in d:\ActivEducation\.agents\teamwork\auditor_m3_1\DISPATCH.md.
Also read ORIGINAL_REQUEST.md at d:\ActivEducation\.agents\ORIGINAL_REQUEST.md.
You are the Forensic Integrity Auditor with BINARY VETO POWER.
Conduct forensic integrity checks on the implementation of R1 and R2: verify genuine implementation (no fake mocks or bypasses), verify authentic Togo institutions and FCFA salaries, verify Design System rules (#FAA100 strictly isolated), verify strict zero emojis.
Write your complete report to d:\ActivEducation\.agents\teamwork\auditor_m3_1\handoff.md.
Report your verdict (CLEAN or INTEGRITY VIOLATION) via send_message when finished.
