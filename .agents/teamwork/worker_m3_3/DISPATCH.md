# Dispatch Instructions for Worker M3_3 (Iteration 3)

## Role & Identity
You are `worker_m3_3` (teamwork_preview_worker).
Working directory: `d:\ActivEducation\.agents\teamwork\worker_m3_3`

## MANDATORY INTEGRITY WARNING
> DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

## Inputs
- Gate Status: `d:\ActivEducation\.agents\orchestrator_3\GATE_STATUS.md`
- Challenger 2 Report: `d:\ActivEducation\.agents\teamwork\challenger_m3_it2_2\handoff.md`
- Target Files:
  - `d:\ActivEducation\web\src\lib\orientation.ts`
  - `d:\ActivEducation\web\test-orientation-generate.js`

## Exact Tasks to Implement

### 1. Fix Eco Profile Career Scoring in `web/src/lib/orientation.ts`
In `generateDeterministicOrientationM3`:
- Lines ~1244–1247:
  ```ts
  if (career.id === 'entrepreneur-innovation') {
    score += interestEco ? 42 : (hasEco ? 28 : 0);
    if (interestTech || hasTech) score += 8;
  }
  ```
- Lines ~1258–1260:
  ```ts
  if (career.id === 'juriste-affaires') {
    score += interestComm ? 45 : ((hasComm || hasEco || interestEco) ? 28 : 0);
  }
  ```
- This ensures for the Economics profile (`interestEco: true`), the Top 3 is:
  1. `comptable-auditeur` (100)
  2. `entrepreneur-innovation` (97)
  3. `banquier-analyste` (95)

### 2. Fix Health School Recommendation in `web/src/lib/orientation.ts`
In the budget "Faible" / low budget branch (around line 1364):
- If `interestHealth` is true, recommend:
  ```ts
  {
    name: 'Université de Lomé (UL)',
    program: 'Faculté des Sciences de la Santé (FSS) - Médecine & Pharmacie',
    estimatedAnnualCostCFA: 'Public / 25 000 - 50 000 FCFA',
    whyThisSchool: 'Faculté publique d’excellence formant les médecins, pharmaciens et spécialistes de santé au Togo avec droits universitaires publics.',
  }
  ```
  instead of `IAI-Togo` (which is an IT institute).

### 3. Strengthen Assertion 7 in `web/test-orientation-generate.js`
In `test-orientation-generate.js`:
- For Profile 1 (Tech): Assert Top 2 titles include `Développeur` and `Data Analyst`.
- For Profile 2 (Santé): Assert Top 2 titles include `Médecin` and `Pharmacien`.
- For Profile 3 (BTP): Assert Top 2 titles include `Génie Civil` (or `BTP`) and `Architecte`.
- For Profile 4 (Eco): Assert Top 3 titles contain `Comptable`, `Banquier` (or `Analyste`), and `Entrepreneur`.

### 4. Verification
- Run `node test-orientation-generate.js` and verify all 4 profiles pass with 7/7 assertions.
- Run `npm run build` in `d:\ActivEducation\web` and verify exit code 0.
- Verify 0 emojis across all files.

## Output
Write your handoff report to `d:\ActivEducation\.agents\teamwork\worker_m3_3\handoff.md`.
Report back when finished.

## 2026-10-01T00:04:01Z
You are worker_m3_3. Your working directory is d:\ActivEducation\.agents\teamwork\worker_m3_3.
Read your instructions in d:\ActivEducation\.agents\teamwork\worker_m3_3\DISPATCH.md.
Also read ORIGINAL_REQUEST.md at d:\ActivEducation\.agents\ORIGINAL_REQUEST.md.
Follow the MANDATORY INTEGRITY WARNING: DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. An auditor will independently verify your work.
Implement the 3 targeted refinements in web/src/lib/orientation.ts (Eco scoring, health school recommendation) and web/test-orientation-generate.js (strict Top 2/Top 3 assertion).
Run node test-orientation-generate.js and run npm run build.
Write your complete report to d:\ActivEducation\.agents\teamwork\worker_m3_3\handoff.md.
Report back via send_message when finished.
