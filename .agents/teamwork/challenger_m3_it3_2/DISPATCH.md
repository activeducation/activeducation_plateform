# Dispatch Instructions for Challenger M3_It3_2

## Role & Identity
You are `challenger_m3_it3_2` (teamwork_preview_challenger).
Working directory: `d:\ActivEducation\.agents\teamwork\challenger_m3_it3_2`

## Inputs
- User Request: `d:\ActivEducation\.agents\ORIGINAL_REQUEST.md` (specifically ## 2026-09-30T23:21:56Z)
- Worker Handoff: `d:\ActivEducation\.agents\teamwork\worker_m3_3\handoff.md`
- Target Implementation Files:
  - `d:\ActivEducation\web\test-orientation-generate.js`
  - `d:\ActivEducation\web\src\lib\orientation.ts`

## Adversarial Verification Focus
1. Adversarially verify `test-orientation-generate.js`:
   - Inspect the 4 multi-profile test cases.
   - Verify that Assertion 7 strictly enforces:
     - Profile 1: Top 2 must be Développeur and Data Analyst.
     - Profile 2: Top 2 must be Médecin and Pharmacien.
     - Profile 3: Top 2 must be Génie Civil/BTP and Architecte.
     - Profile 4: Top 3 must contain Comptable, Banquier/Analyste, and Entrepreneur.
   - Run the test script and verify that all 4 profiles pass with 7/7 assertions.
2. Check for zero emojis across all target files.
3. Issue verdict: `APPROVE` or `REQUEST_CHANGES` with concrete evidence.

## Output
Write your findings to `d:\ActivEducation\.agents\teamwork\challenger_m3_it3_2\handoff.md`.
Report back via send_message when finished.

## 2026-10-01T00:09:38Z
You are challenger_m3_it3_2. Your working directory is d:\ActivEducation\.agents\teamwork\challenger_m3_it3_2.
Read your instructions in d:\ActivEducation\.agents\teamwork\challenger_m3_it3_2\DISPATCH.md.
Also read ORIGINAL_REQUEST.md at d:\ActivEducation\.agents\ORIGINAL_REQUEST.md.
Adversarially verify the multi-profile test execution of test-orientation-generate.js across all 4 profiles, asserting domain matching and zero emojis.
Write your complete report to d:\ActivEducation\.agents\teamwork\challenger_m3_it3_2\handoff.md.
Report your verdict (APPROVE or REQUEST_CHANGES) via send_message when finished.

