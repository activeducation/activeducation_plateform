# Handoff Report — Challenger M3_It2_2

**Agent** : `challenger_m3_it2_2` (teamwork_preview_challenger)  
**Date** : 2026-10-01T00:05:00Z  
**Parent Agent** : `f3d00c44-f96b-4e02-b1e0-7ca7de550c74`  
**Working Directory** : `d:\ActivEducation\.agents\teamwork\challenger_m3_it2_2`  
**Verdict** : `REQUEST_CHANGES`

---

## 1. Observation

Direct empirical code review and static behavioral analysis were performed on:
- `d:\ActivEducation\web\src\lib\orientation.ts`
- `d:\ActivEducation\web\test-orientation-generate.js`
- `d:\ActivEducation\web\src\app\student\orientation\page.tsx`
- `d:\ActivEducation\web\src\app\student\orientation\resultats\page.tsx`
- `d:\ActivEducation\web\src\app\api\orientation\generate\route.ts`

### 1.1 Scoring Calculation in `generateDeterministicOrientationM3`
In `orientation.ts`:
- Lines 1237–1247:
  ```ts
  // 4. Finance, Banque & Entrepreneuriat
  if (career.id === 'comptable-auditeur') {
    score += interestEco ? 45 : (hasEco ? 30 : 0);
  }
  if (career.id === 'banquier-analyste') {
    score += interestEco ? 42 : (hasEco ? 28 : 0);
  }
  if (career.id === 'entrepreneur-innovation') {
    score += interestEco ? 39 : (hasEco ? 25 : 0);
    if (interestTech || hasTech) score += 8;
  }
  ```
- Lines 1258–1260:
  ```ts
  // 6. Droit, Administration, Éducation & RH
  if (career.id === 'juriste-affaires') {
    score += (interestComm || interestEco) ? 45 : ((hasComm || hasEco) ? 28 : 0);
  }
  ```
- Lines 1269–1270:
  ```ts
  if (career.demand === 'Tres Forte') score += 5;
  else if (career.demand === 'Forte') score += 3;
  ```
- Career catalog definitions in `TOGO_CAREERS_CATALOG`:
  - `comptable-auditeur` (line 351): `demand: 'Tres Forte'` (+5 bonus)
  - `banquier-analyste` (line 368): `demand: 'Forte'` (+3 bonus)
  - `entrepreneur-innovation` (line 402): `demand: 'Tres Forte'` (+5 bonus)
  - `juriste-affaires` (line 436): `demand: 'Forte'` (+3 bonus)

For Profile 4 (`interests: ['Économie, Gestion & Entrepreneuriat']`, `strongSubjects: ['Sciences Économiques & Sociales (SES)']`):
- `interestEco = true`
- `comptable-auditeur`: `50 + 45 + 5 = 100` (Rank 1)
- `juriste-affaires`: `50 + 45 + 3 = 98` (Rank 2)
- `banquier-analyste`: `50 + 42 + 3 = 95` (Rank 3)
- `entrepreneur-innovation`: `50 + 39 + 5 = 94` (Rank 4)

Top 3 careers selected:
1. `comptable-auditeur` (Comptable & Auditeur Financier)
2. `juriste-affaires` (Juriste d’Entreprise & Conseiller Fiscal)
3. `banquier-analyste` (Analyste Bancaire & Gestionnaire de Risque)
`entrepreneur-innovation` is in 4th place and is omitted from the recommendations.

### 1.2 Test Oracle Flaw in `test-orientation-generate.js`
In `test-orientation-generate.js`:
- Lines 88–89:
  ```js
  expectedKeywords: ['Comptable', 'Banquier', 'Auditeur', 'Financier', 'Innovation', 'Affaires'],
  ```
- Lines 201–208:
  ```js
  // Assertion 7 : Pertinence sémantique du profil
  const careerTitles = data.recommendedCareers.map((c) => c.title);
  const hasSemanticMatch = careerTitles.some((title) =>
    profile.expectedKeywords.some((kw) => title.toLowerCase().includes(kw.toLowerCase()))
  );
  assert(
    hasSemanticMatch,
    `[${profile.id}] Erreur sémantique : aucun des métiers recommandés (${careerTitles.join(', ')}) ne correspond aux mots-clés attendus (${profile.expectedKeywords.join(', ')})`
  );
  ```
Because `careerTitles.some(...)` checks if *any single* recommended career matches *any single* keyword, finding "Comptable" or "Affaires" causes the test to pass even though `entrepreneur-innovation` is absent from the top 3 and `juriste-affaires` was improperly promoted.

### 1.3 Recommended Schools Domain Misalignment
In `orientation.ts`:
- Lines 1364–1380 (`else` branch for budget "Faible"):
  ```ts
  recommendedSchools = [
    {
      name: 'Université de Lomé (UL)',
      program: 'Licence LMD - Sciences, Technologies & Gestion',
      estimatedAnnualCostCFA: 'Public / 25 000 - 50 000 FCFA',
      whyThisSchool: 'Première université publique du Togo, offrant un enseignement de haut rang accessible à tous les budgets avec bourses possibles.',
    },
    {
      name: 'Institut Africain d’Informatique (IAI-Togo)',
      program: 'Licence Professionnelle (Filière Conventionnée)',
      estimatedAnnualCostCFA: 'Public-Partenariat / Bourses d’État disponibles',
      whyThisSchool: 'Opportunités d’aides financières et d’exonérations partielles pour les étudiants rigoureux et motivés.',
    },
  ];
  ```
For Profile 2 (Santé: Médecin / Pharmacien) with `budget: 'Faible'`, the student is recommended `IAI-Togo` (an IT institute) and `UL - Sciences, Technologies & Gestion` instead of `Université de Lomé - Faculté des Sciences de la Santé (FSS)`.

### 1.4 Verification of Other Requirements
1. **Tech Profile (Profile 1)**:
   - Top 1: Développeur Web & Mobile (100)
   - Top 2: Data Analyst & Spécialiste IA (97)
   - Top 3: Architecte Réseaux & Cybersécurité (95)
   - Top 2 matches Web Dev / Data Analyst. (PASS)
2. **Health Profile (Profile 2)**:
   - Top 1: Médecin Généraliste / Spécialiste (101)
   - Top 2: Pharmacien & Biologiste Médical (96)
   - Top 3: Ingénieur Agronome & Agroalimentaire (95)
   - Tech careers score 55. Top 2 matches Médecin / Pharmacien without tech bias. (PASS)
3. **BTP Profile (Profile 3)**:
   - Top 1: Ingénieur Génie Civil & BTP (105)
   - Top 2: Architecte & Urbaniste (95)
   - Top 3: Ingénieur Agronome & Agroalimentaire (95)
   - Top 2 matches Ingénieur Civil & BTP / Architecte. (PASS)
4. **Zero Emojis**:
   - Ripgrep regex search across target files:
     `rg "[\x{1F300}-\x{1F9FF}\x{2600}-\x{26FF}\x{2700}-\x{27BF}\x{1F600}-\x{1F64F}\x{1F680}-\x{1F6FF}\x{1FA70}-\x{1FAFF}]"` returned 0 matches. (PASS)
5. **FCFA Salaries**:
   - All salaries in `TOGO_CAREERS_CATALOG` contain `FCFA`. (PASS)
6. **TypeScript Typing**:
   - `RiasecScores` includes string index signature `[key: string]: number;`.
   - `MatchProfile.scores` is typed `scores?: RiasecScores | Record<string, number>;`.
   - TS2322 is resolved. (PASS)

---

## 2. Logic Chain

1. **Dispatch Explicit Criterion**:
   The parent dispatch explicitly states:
   > "Assert that Eco profile returns Comptable / Banquier / Entrepreneur as Top 3 careers."
2. **Mathematical Outcome in `generateDeterministicOrientationM3`**:
   Because `juriste-affaires` is awarded `+45` points for `interestEco` (line 1259), its total score reaches `98` (`50 + 45 + 3`), surpassing `banquier-analyste` (`95`) and `entrepreneur-innovation` (`94`).
3. **Exclusion of Entrepreneur**:
   Since only the top 3 careers are selected, the resulting array contains `['comptable-auditeur', 'juriste-affaires', 'banquier-analyste']`. `entrepreneur-innovation` is displaced to 4th place.
4. **False Positive in Worker Test**:
   `test-orientation-generate.js` used a permissive `.some()` condition combined with `'Affaires'` in `expectedKeywords`, causing it to report `7/7 Assertions validées` despite the dispatch criterion failing.
5. **Actionable Remediation**:
   - Demote `juriste-affaires` for `interestEco` to secondary points (`+28`), or require `interestComm` for the primary `+45`.
   - Increase `entrepreneur-innovation` points for `interestEco` from `39` to `42` so that Entrepreneur and Banquier cleanly occupy ranks 2 and 3 alongside Comptable.
   - Align `test-orientation-generate.js` Assertion 7 to test exact Top 2 / Top 3 careers per profile.
   - For school recommendations in `orientation.ts`, route Health students to `Faculté des Sciences de la Santé (FSS)` rather than `IAI-Togo`.

---

## 3. Caveats

- Interactive shell command execution (`run_command`) timed out in the headless subagent environment waiting for user permission. All evaluations were therefore verified via static trace analysis, regex verification, and AST/type analysis.
- The codebase is otherwise clean: TypeScript interfaces are well structured, UI error handling is robust against missing arrays, and zero emoji discipline is strictly observed.

---

## 4. Conclusion

**Verdict: REQUEST_CHANGES**

Two code changes are required before Milestone 3 can be approved:

### 1. Fix Career Scoring for Eco Profile (`src/lib/orientation.ts`)
- In lines 1244–1247:
  Increase base affinity for `entrepreneur-innovation`:
  ```ts
  if (career.id === 'entrepreneur-innovation') {
    score += interestEco ? 42 : (hasEco ? 28 : 0);
    if (interestTech || hasTech) score += 8;
  }
  ```
- In lines 1258–1260:
  Restrict `+45` primary affinity of `juriste-affaires` to `interestComm`:
  ```ts
  if (career.id === 'juriste-affaires') {
    score += interestComm ? 45 : ((hasComm || hasEco || interestEco) ? 28 : 0);
  }
  ```
  *Result*: For Eco profile:
  - `comptable-auditeur`: `50 + 45 + 5 = 100` (Rank 1)
  - `entrepreneur-innovation`: `50 + 42 + 5 = 97` (Rank 2)
  - `banquier-analyste`: `50 + 42 + 3 = 95` (Rank 3)
  - `juriste-affaires`: `50 + 28 + 3 = 81` (Rank 7)
  -> Top 3 are Comptable, Entrepreneur, and Banquier.

### 2. Strengthen Assertion 7 in `test-orientation-generate.js`
Replace the loose `.some()` check with specific assertions matching the dispatch criteria:
- Profile 1 (Tech): Top 2 titles must match `Développeur` and `Data Analyst`.
- Profile 2 (Santé): Top 2 titles must match `Médecin` and `Pharmacien`.
- Profile 3 (BTP): Top 2 titles must match `Génie Civil` (or `BTP`) and `Architecte`.
- Profile 4 (Eco): Top 3 titles must contain `Comptable`, `Banquier` (or `Analyste`), and `Entrepreneur`.

### 3. (Recommended) Domain-aware School Recommendation
In `generateDeterministicOrientationM3`, ensure health profiles (`interestHealth`) with budget 'Faible' recommend `Université de Lomé (UL) - Faculté des Sciences de la Santé (FSS)` instead of `Institut Africain d’Informatique (IAI-Togo)`.

---

## 5. Verification Method

1. **Verify Scoring Fix**:
   Execute the scoring trace for Profile 4 answers:
   ```js
   const res = generateDeterministicOrientationM3({
     interests: ['Économie, Gestion & Entrepreneuriat'],
     strongSubjects: ['Sciences Économiques & Sociales (SES)'],
     otherSubject: 'Comptabilité et Finance',
     budget: 'Moyen',
     mobility: 'Région de la Kara & Nord Togo',
     currentCity: 'Kara',
   });
   console.log(res.recommendedCareers.map(c => c.title));
   ```
   *Expected Output*:
   - Top 1: `Comptable & Auditeur Financier`
   - Top 2: `Entrepreneur & Chef de Projet Innovant`
   - Top 3: `Analyste Bancaire & Gestionnaire de Risque`

2. **Verify Multi-Profile Test Execution**:
   Run from `web/`:
   ```powershell
   node test-orientation-generate.js
   ```
   *Expected Output*: Exit code 0 with all 4 profiles validating specific Top 2 / Top 3 career rankings.
