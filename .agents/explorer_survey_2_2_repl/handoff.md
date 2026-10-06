# Handoff Report — Investigation Route Handler `/api/match` & `test-match.js`

**Author**: `explorer_survey_2_2_repl`  
**Working Directory**: `d:\ActivEducation\.agents\explorer_survey_2_2_repl`  
**Target Milestone**: Sub-milestone 2.2 Survey Analysis & Matching Route Handler  
**Status**: Completed (Hard Handoff)

---

## 1. Observation

1. **User Request & Acceptance Criteria**:
   - In `d:\ActivEducation\.agents\ORIGINAL_REQUEST.md` (lines 32-60):
     - R2 specifies: "Créer un Route Handler Next.js (`/api/match`) qui prend les réponses de l'étudiant en entrée, interroge l'API Groq (llama3 ou mixtral), et retourne un profil psychologique, 3 métiers porteurs, et 3 établissements au Togo (universités/écoles agréées)."
     - R3 specifies: "Construire l'UI affichant les résultats retournés par l'IA de façon visuelle et claire, en utilisant l'ambre (#FAA100) pour les scores de correspondance/progression, et sans le moindre emoji."
     - Acceptance Criteria specifies: "Un script de test Node.js (`test-match.js`) appelle l'API `/api/match` avec de fausses réponses et vérifie qu'elle répond un JSON valide avec métiers et écoles au Togo."

2. **Web Application Dependencies**:
   - In `d:\ActivEducation\web\package.json` (lines 11-18):
     - Dependencies are `@supabase/ssr`, `@supabase/supabase-js`, `lucide-react`, `next`: "16.3.5", `react`: "19.2.8", `react-dom`: "19.2.8".
     - `groq-sdk` is **not** installed.
     - Node 18+ and Next.js App Router have native global `fetch`.

3. **Backend Groq Provider & Model Status**:
   - In `d:\ActivEducation\backend\app\services\llm\groq_provider.py` (lines 22, 79-96):
     - Groq endpoint is `https://api.groq.com/openai/v1/chat/completions`, authenticated via `Authorization: Bearer <key>`.
   - In `d:\ActivEducation\backend\tests\test_tutor_foundations.py` (lines 236-240):
     - Retired models by Groq explicitly noted: `"llama-3.1-8b-instant"`, `"llama-3.1-70b-versatile"`, `"mixtral-8x7b-32768"`.
     - Active production model configured is `llama-3.3-70b-versatile` or `openai/gpt-oss-120b` or `llama3-70b-8192`.

4. **Environment Variables**:
   - No `.env` or `.env.local` containing `GROQ_API_KEY` exists in `d:\ActivEducation\web`.
   - Therefore, a graceful deterministic fallback when `GROQ_API_KEY` is missing is mandatory for test and demo executions.

5. **Togo Careers and Schools Data**:
   - In `d:\ActivEducation\backend\database\seed_careers.sql`:
     - 16 careers seeded with `job_demand`, `growth_trend`, `salary_avg_fcfa`, `required_skills`, and `education_path.schools_in_togo`.
   - In `d:\ActivEducation\docs\reference_mesr_2026_2027.csv`:
     - 111 official accredited higher education institutions in Togo (13 public, 98 private), e.g. `Université de Lomé (UL)`, `Université de Kara (UK)`, `Institut Africain d'Informatique (IAI-Togo)`, `ESGIS`, `ESAG-NDE`, `EAMAU`, `FORMATEC`, `UCAO-UUT`.
   - In `d:\ActivEducation\docs\AUDIT_IMPORT_ETABLISSEMENTS.md` (lines 61-85):
     - Explicit audit excluding unaccredited/fictitious names (e.g. ISDME, ESIM, IFMI, ISSIC).
   - In `d:\ActivEducation\docs\ORIENTATION.md`:
     - Holland RIASEC model is the pivot language (R, I, A, S, E, C).
     - Matching scores and tie-breaking must be strictly deterministic (`job_demand` -> `salary_avg_fcfa` -> `name`).

---

## 2. Logic Chain

1. **Input Format Design**:
   - Observation 1 shows that students submit test answers, while Observation 5 shows the matching engine relies on RIASEC dimensions.
   - Therefore, `/api/match` must accept both `{ "answers": ... }` (raw questionnaire answers/Likert scores) and `{ "scores": ... }` (pre-computed RIASEC dimensions), normalizing them internally to determine dominant traits.

2. **Groq API Querying**:
   - Observation 2 demonstrates that `groq-sdk` is not in `package.json`. Observation 3 shows that Groq provides an OpenAI-compatible REST endpoint at `https://api.groq.com/openai/v1/chat/completions`.
   - Therefore, using native `fetch` in `/api/match/route.ts` with `response_format: { type: "json_object" }` is the cleanest, dependency-free approach.
   - As observed in Observation 3, older models (`mixtral-8x7b-32768`, `llama-3.1-8b-instant`) were retired, so `llama-3.3-70b-versatile` (or `process.env.GROQ_MODEL`) should be the primary model target.

3. **Deterministic Fallback Engine**:
   - Observation 4 confirms `GROQ_API_KEY` is not present by default in local/CI environments.
   - If `GROQ_API_KEY` is undefined or if the Groq HTTP call fails, `/api/match` must not throw a 500 error.
   - Instead, it must invoke a deterministic fallback matching logic based on the repository's verified career catalog (`seed_careers.sql`) and MESR accredited institutions (`reference_mesr_2026_2027.csv`).

4. **Output Schema & Emoji Ban**:
   - Observation 1 strictly forbids emojis ("sans le moindre emoji") and requires a psychological profile, 3 high-growth careers, and 3 accredited Togo institutions.
   - Therefore, the JSON schema must have keys `profile`, `careers` (length = 3), and `institutions` (length = 3), and an automated unicode regex check must confirm zero emojis exist in the response.

5. **Requirements for `test-match.js`**:
   - Per Observation 1, `test-match.js` must reside in `d:\ActivEducation\web\test-match.js`.
   - It should send mock answers via HTTP POST to `/api/match` (supporting `http://localhost:3000/api/match` or `process.env.TEST_URL`), verify HTTP 200, parse JSON, validate exact object shapes, assert array lengths of 3, verify Togo MESR school names, and assert zero emojis.

---

## 3. Caveats

1. **Next.js Server Execution**: `test-match.js` relies on an active HTTP server (e.g., `npm run dev` or `next start`) listening on the target port unless programmatic invocation is also wrapped.
2. **Groq Model Availability**: Groq periodically retires models. While `llama-3.3-70b-versatile` is currently active, the deterministic fallback guarantees 100% test reliability regardless of external Groq API availability or model deprecation.
3. **No Terminal Commands Run**: In compliance with the critical subagent constraint, no shell commands were executed during this investigation.

---

## 4. Conclusion

The specification for Sub-milestone 2.2 is complete, fully documented, and ready for implementation:
- **Route Handler Path**: `web/src/app/api/match/route.ts`
- **Shared Orientation Logic**: `web/src/lib/orientation.ts` (defining the Togo MESR catalog, RIASEC engine, and deterministic fallback)
- **Test Script Path**: `web/test-match.js`
- **Output Validation**: Strict adherence to the JSON schema, 3 careers, 3 accredited Togo institutions, and zero emojis.
- Full details, schemas, and references are recorded in `d:\ActivEducation\.agents\explorer_survey_2_2_repl\report.md`.

---

## 5. Verification Method

To verify these findings:
1. Inspect `d:\ActivEducation\.agents\explorer_survey_2_2_repl\report.md` for full specifications and data mappings.
2. Inspect `backend/database/seed_careers.sql` (lines 20-276) to verify Togo career titles, demand, and school paths.
3. Inspect `docs/reference_mesr_2026_2027.csv` to verify official MESR higher education institution names and cities.
4. Inspect `backend/tests/test_tutor_foundations.py` (lines 236-240) to verify retired Groq models.
5. Invalidation conditions: If `web/package.json` had required groq-sdk or if the test script were required to run without Node.js.
