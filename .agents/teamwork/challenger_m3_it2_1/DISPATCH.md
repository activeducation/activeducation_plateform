# Dispatch Instructions for Challenger M3_It2_1

## Role & Identity
You are `challenger_m3_it2_1` (teamwork_preview_challenger).
Working directory: `d:\ActivEducation\.agents\teamwork\challenger_m3_it2_1`

## Inputs
- User Request: `d:\ActivEducation\.agents\ORIGINAL_REQUEST.md` (specifically ## 2026-09-30T23:21:56Z)
- Worker Handoff: `d:\ActivEducation\.agents\teamwork\worker_m3_2\handoff.md`
- Target Implementation Files:
  - `d:\ActivEducation\web\src\app\student\orientation\page.tsx`
  - `d:\ActivEducation\web\src\app\student\orientation\resultats\page.tsx`

## Adversarial Verification Focus
1. Adversarially test UI resilience:
   - Verify that simulated missing/null `recommendedSchools` in sessionStorage no longer causes any runtime error or white screen.
   - Verify that simulated network hang or abort on `fetch('/api/orientation/generate')` gracefully falls back to deterministic model within 5 seconds.
   - Verify that custom strong subject without pre-checked boxes preserves user choice.
2. Check zero emojis across both page files.
3. Issue verdict: `APPROVE` or `REQUEST_CHANGES` with concrete evidence.

## Output
Write your findings to `d:\ActivEducation\.agents\teamwork\challenger_m3_it2_1\handoff.md`.


## 2026-09-30T23:57:36Z
You are challenger_m3_it2_1. Your working directory is d:\ActivEducation\.agents\teamwork\challenger_m3_it2_1.
Read your instructions in d:\ActivEducation\.agents\teamwork\challenger_m3_it2_1\DISPATCH.md.
Also read ORIGINAL_REQUEST.md at d:\ActivEducation\.agents\ORIGINAL_REQUEST.md.
Adversarially test UI resilience: missing recommendedSchools handling in resultats page, 5s fetch timeout / abort in orientation page, custom subject preservation, and zero emojis.
Write your complete report to d:\ActivEducation\.agents\teamwork\challenger_m3_it2_1\handoff.md.
Report your verdict (APPROVE or REQUEST_CHANGES) via send_message when finished.
