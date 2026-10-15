# Dispatch Instructions for Challenger M3_It3_1

## Role & Identity
You are `challenger_m3_it3_1` (teamwork_preview_challenger).
Working directory: `d:\ActivEducation\.agents\teamwork\challenger_m3_it3_1`

## Inputs
- User Request: `d:\ActivEducation\.agents\ORIGINAL_REQUEST.md` (specifically ## 2026-09-30T23:21:56Z)
- Worker Handoff: `d:\ActivEducation\.agents\teamwork\worker_m3_3\handoff.md`
- Target Implementation Files:
  - `d:\ActivEducation\web\src\lib\orientation.ts`

## Adversarial Verification Focus
1. Adversarially verify `generateDeterministicOrientationM3`:
   - Calculate exact scores for Profile 4 (Eco):
     - `comptable-auditeur`
     - `entrepreneur-innovation`
     - `banquier-analyste`
     - `juriste-affaires`
     Confirm whether the Top 3 is strictly: 1. Comptable, 2. Entrepreneur, 3. Banquier.
   - Calculate school recommendations for Profile 2 (Santé) with budget 'Faible'. Confirm whether `Faculté des Sciences de la Santé (FSS)` is recommended and that `IAI-Togo` is NOT returned.
2. Check for zero emojis.
3. Issue verdict: `APPROVE` or `REQUEST_CHANGES` with concrete evidence.

## Output
Write your findings to `d:\ActivEducation\.agents\teamwork\challenger_m3_it3_1\handoff.md`.
Report back via send_message when finished.

## 2026-10-01T00:09:38Z
You are challenger_m3_it3_1. Your working directory is d:\ActivEducation\.agents\teamwork\challenger_m3_it3_1.
Read your instructions in d:\ActivEducation\.agents\teamwork\challenger_m3_it3_1\DISPATCH.md.
Also read ORIGINAL_REQUEST.md at d:\ActivEducation\.agents\ORIGINAL_REQUEST.md.
Adversarially verify that the Eco profile returns Comptable #1, Entrepreneur #2, Banquier #3, and that Health student with low budget receives FSS.
Write your complete report to d:\ActivEducation\.agents\teamwork\challenger_m3_it3_1\handoff.md.
Report your verdict (APPROVE or REQUEST_CHANGES) via send_message when finished.

