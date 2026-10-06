# Dispatch Instructions for Explorer It2_2

## Role & Identity
You are `explorer_m3_it2_2` (teamwork_preview_explorer).
Working directory: `d:\ActivEducation\.agents\teamwork\explorer_m3_it2_2`

## Inputs
- User Request: `d:\ActivEducation\.agents\ORIGINAL_REQUEST.md` (specifically ## 2026-09-30T23:21:56Z)
- Gate Status: `d:\ActivEducation\.agents\orchestrator_3\GATE_STATUS.md`
- Challenger 2 Report: `d:\ActivEducation\.agents\teamwork\challenger_m3_2\handoff.md`
- Target File: `d:\ActivEducation\web\src\lib\orientation.ts`

## Mission & Objectives
Investigate the career ID mismatch in `generateDeterministicOrientationM3`:
1. Examine `TOGO_CAREERS_CATALOG` (lines 206 to 479) in `src/lib/orientation.ts`.
2. Examine `generateDeterministicOrientationM3` (lines 1190 to 1230) in `src/lib/orientation.ts`.
3. Verify why IDs like `ingenieur-btp-genie-civil`, `medecin-sante-publique`, `designer-graphique-ui-ux`, `juriste-droit-affaires` do not match canonical IDs (`ingenieur-btp-civil`, `medecin-sante`, `designer-graphique`, `juriste-affaires`).
4. Detail the full mapping for all 16 careers and define the exact scoring formula so students in Health, Engineering, Arts, Business, Law are recommended their appropriate career top-3.

## Output
Write your findings and recommendation to `d:\ActivEducation\.agents\teamwork\explorer_m3_it2_2\handoff.md`.
Report back when finished.

## 2026-09-30T23:45:21Z
You are explorer_m3_it2_2. Your working directory is d:\ActivEducation\.agents\teamwork\explorer_m3_it2_2.
Read your instructions in d:\ActivEducation\.agents\teamwork\explorer_m3_it2_2\DISPATCH.md.
Also read ORIGINAL_REQUEST.md at d:\ActivEducation\.agents\ORIGINAL_REQUEST.md.
Investigate the career ID mismatch in generateDeterministicOrientationM3 in web/src/lib/orientation.ts (lines 1197-1217) against TOGO_CAREERS_CATALOG (lines 206-479) and provide the exact canonical mapping for all 16 careers.
Write your report to d:\ActivEducation\.agents\teamwork\explorer_m3_it2_2\handoff.md.
Report back via send_message when finished.

