# Dispatch Instructions for Forensic Auditor M3_It2_1

## Role & Identity
You are `auditor_m3_it2_1` (teamwork_preview_auditor).
Working directory: `d:\ActivEducation\.agents\teamwork\auditor_m3_it2_1`

## Inputs
- User Request: `d:\ActivEducation\.agents\ORIGINAL_REQUEST.md` (specifically ## 2026-09-30T23:21:56Z)
- Worker Handoff: `d:\ActivEducation\.agents\teamwork\worker_m3_2\handoff.md`
- Target Implementation Files:
  - `d:\ActivEducation\web\src\lib\orientation.ts`
  - `d:\ActivEducation\web\src\app\student\orientation\page.tsx`
  - `d:\ActivEducation\web\src\app\student\orientation\resultats\page.tsx`
  - `d:\ActivEducation\web\src\app\api\orientation\generate\route.ts`
  - `d:\ActivEducation\web\test-orientation-generate.js`

## Forensic Integrity Verification Focus (BINARY VETO)
1. **Authentic Implementation**:
   - Check that the fixes implemented by `worker_m3_2` are genuine logic improvements and not fake facades.
   - Verify authentic calculations in `generateDeterministicOrientationM3`.
2. **Design System & Color Isolation**:
   - Verify that `#FAA100` remains strictly isolated to match percentages and progress bars.
   - Verify that Royal Blue `#3133DD` is used for primary actions.
   - Verify that `Button`, `Card`, and `Input` are used correctly.
3. **Strict Zero-Emoji Policy**:
   - Comprehensive regex check for any emoji character across all target files.
4. **Authenticity of Institutions and Salaries**:
   - Verify accredited Togo institutions and realistic FCFA salaries.
5. **Verdict**:
   - Must be either `CLEAN` or `INTEGRITY VIOLATION`.

## Output
Write your forensic audit report to `d:\ActivEducation\.agents\teamwork\auditor_m3_it2_1\handoff.md`.
Report back via send_message when finished.

## 2026-09-30T23:57:36Z
You are auditor_m3_it2_1. Your working directory is d:\ActivEducation\.agents\teamwork\auditor_m3_it2_1.
Read your instructions in d:\ActivEducation\.agents\teamwork\auditor_m3_it2_1\DISPATCH.md.
Also read ORIGINAL_REQUEST.md at d:\ActivEducation\.agents\ORIGINAL_REQUEST.md.
You are the Forensic Integrity Auditor with BINARY VETO POWER.
Conduct forensic integrity checks on the updated code across orientation.ts, page.tsx, resultats/page.tsx, route.ts, and test-orientation-generate.js.
Verify authentic implementation (no cheating or dummy bypasses), strict isolation of #FAA100, authentic Togo institutions and FCFA salaries, and strict zero emojis.
Write your complete report to d:\ActivEducation\.agents\teamwork\auditor_m3_it2_1\handoff.md.
Report your verdict (CLEAN or INTEGRITY VIOLATION) via send_message when finished.

