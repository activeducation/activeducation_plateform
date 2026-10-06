# Dispatch Instructions for Challenger M3_It2_2

## Role & Identity
You are `challenger_m3_it2_2` (teamwork_preview_challenger).
Working directory: `d:\ActivEducation\.agents\teamwork\challenger_m3_it2_2`

## Inputs
- User Request: `d:\ActivEducation\.agents\ORIGINAL_REQUEST.md` (specifically ## 2026-09-30T23:21:56Z)
- Worker Handoff: `d:\ActivEducation\.agents\teamwork\worker_m3_2\handoff.md`
- Target Implementation Files:
  - `d:\ActivEducation\web\src\lib\orientation.ts`
  - `d:\ActivEducation\web\test-orientation-generate.js`

## Adversarial Verification Focus
1. Adversarially verify `generateDeterministicOrientationM3` and `test-orientation-generate.js`:
   - Inspect the 4 multi-profile test cases (Tech, Health, Civil Engineering, Economics).
   - Assert that Health profile returns Médecin/Pharmacien as Top 2 careers (no tech bias).
   - Assert that BTP profile returns Ingénieur Civil & BTP / Architecte as Top 2 careers.
   - Assert that Eco profile returns Comptable / Banquier / Entrepreneur as Top 3 careers.
   - Assert that Tech profile returns Web Dev / Data Analyst as Top 2 careers.
2. Verify TypeScript typecheck / compilation.
3. Perform regex check for zero emojis.
4. Issue verdict: `APPROVE` or `REQUEST_CHANGES` with concrete evidence.

## Output
Write your findings to `d:\ActivEducation\.agents\teamwork\challenger_m3_it2_2\handoff.md`.
Report back via send_message when finished.

## 2026-09-30T23:57:36Z
You are challenger_m3_it2_2. Your working directory is d:\ActivEducation\.agents\teamwork\challenger_m3_it2_2.
Read your instructions in d:\ActivEducation\.agents\teamwork\challenger_m3_it2_2\DISPATCH.md.
Also read ORIGINAL_REQUEST.md at d:\ActivEducation\.agents\ORIGINAL_REQUEST.md.
Adversarially test the multi-profile test execution of test-orientation-generate.js (Tech, Health, BTP, Eco profiles), asserting domain-accurate matching without tech bias, FCFA salaries, authentic Togo schools, and zero emojis.
Write your complete report to d:\ActivEducation\.agents\teamwork\challenger_m3_it2_2\handoff.md.
Report your verdict (APPROVE or REQUEST_CHANGES) via send_message when finished.
