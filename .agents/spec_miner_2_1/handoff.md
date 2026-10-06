# Handoff Report — spec_miner_2_1

**Archetype**: Specification Miner  
**Mission**: Mine and document detailed specifications for R1 (Ludic Orientation Test / Swiping), R2 (Groq AI Matching Engine & Togo Context), R3 (Orientation Results Dashboard), and Acceptance Criteria.  
**Working Directory**: `d:\ActivEducation\.agents\spec_miner_2_1`

---

## 1. Observation

1. **User Request & Requirements**:
   - In `d:\ActivEducation\.agents\ORIGINAL_REQUEST.md` (lines 32–60), the new section added at `## 2026-09-22T11:31:59Z` specifies:
     > "Construire le module d'Orientation Scolaire de bout en bout : interface de test gamifiée, intégration IA pour le matching, et tableau de bord de résultats métiers/écoles au Togo.
     > Working directory: d:\ActivEducation\web
     > Integrity mode: demo
     > R1. Interface de Test Ludique (Swiping/QCM) : Créer une interface de passage de test d'orientation addictive (ex: cartes à swiper type Tinder ou QCM interactif fluide) utilisant Framer Motion ou similaire. L'interface doit respecter la nouvelle Direction Artistique (Hanken Grotesque, flat design, composants stricts).
     > R2. Logique de Matching IA (Groq / AÏDA) : Créer un Route Handler Next.js (`/api/match`) qui prend les réponses de l'étudiant en entrée, interroge l'API Groq (llama3 ou mixtral), et retourne un profil psychologique, 3 métiers porteurs, et 3 établissements au Togo (universités/écoles agréées).
     > R3. Tableau de Bord des Résultats : Construire l'UI affichant les résultats retournés par l'IA de façon visuelle et claire, en utilisant l'ambre (#FAA100) pour les scores de correspondance/progression, et sans le moindre emoji.
     > Acceptance Criteria :
     > - [ ] Le projet compile sans erreur (`npm run build`).
     > - [ ] Un script de test Node.js (`test-match.js`) appelle l'API `/api/match` avec de fausses réponses et vérifie qu'elle répond un JSON valide avec métiers et écoles au Togo.
     > - [ ] Les animations sont présentes, fluides, et ludiques (swipe ou transitions).
     > - [ ] La charte graphique V2 est strictement respectée (Hanken Grotesque, `#3133DD`, bordures flat)."

2. **Design System & Global Styling**:
   - In `d:\ActivEducation\web\src\app\globals.css` (lines 1–25):
     - Font: `@import url('https://fonts.googleapis.com/css2?family=Hanken+Grotesque:ital,wght@0,100..900;1,100..900&display=swap');` and `--font-sans: "Hanken Grotesque", system-ui, sans-serif;`.
     - Primary Color: `--color-primary: #3133DD;`, hover `--color-primary-hover: #2829B8;`.
     - Gold/Amber Color: `--color-gold: #FAA100;`.
     - Canvas & Surfaces: `--color-canvas: #F7F8FB;`, `--color-surface: #FFFFFF;`, `--color-border-soft: #E3E5EC;`.
   - In `d:\ActivEducation\DESIGN.md` (lines 240–280):
     - Strict rule: "Aucun emoji dans l'interface applicative — icônes SVG custom uniquement".
     - Strict color roles: Primary `#3133DD` for actions, Gold/Amber `#FAA100` strictly for gamification/progression/scores.

3. **Orientation Domain Model & Question Calibration**:
   - In `d:\ActivEducation\docs\ORIENTATION.md` (lines 30–52):
     - Holland's RIASEC model is the pivot language of the platform: `Réaliste` (R), `Investigateur` (I), `Artistique` (A), `Social` (S), `Entrepreneur/Entreprenant` (E), `Conventionnel` (C).
   - In `d:\ActivEducation\backend\alembic\versions\023_riasec_full_questionnaire.py` (lines 80–155):
     - Questions are calibrated and interleaved across the 6 dimensions to avoid halo bias.

4. **Togo Higher Education & Job Market Data**:
   - In `d:\ActivEducation\backend\database\seed_careers.sql` (lines 20–270):
     - Careers: Développeur Web/Mobile, Data Analyst, Ingénieur Civil / BTP, Ingénieur Agronome, Comptable, Architecte.
     - Accredited Togo Institutions: Université de Lomé (ENSI, FSS, FASEG), EAMAU (Architecture & Urbanisme), ESGIS (Informatique & Gestion), ESAG-NDE (Comptabilité & Finance), Université de Kara.
     - Accreditation bodies: MESR Togo (Ministère de l'Enseignement Supérieur et de la Recherche) and CAMES.

5. **Existing Dependencies**:
   - In `d:\ActivEducation\web\package.json`:
     - Dependencies include `next: 16.3.5`, `react: 19.2.8`, `lucide-react: ^1.47.0`, `@tailwindcss/postcss: ^4`, `tailwindcss: ^4`.
     - `framer-motion` is not yet installed in `dependencies` and must be added.

6. **Environment & API Key Fallback**:
   - In root `.env` and `backend/.env.example`, `GROQ_API_KEY` is not populated by default.
   - Requirement mode is `Integrity mode: demo`. Therefore, `/api/match` must handle missing or rate-limited `GROQ_API_KEY` with a robust deterministic fallback.

---

## 2. Logic Chain

1. **From Observation 1 & 5 (R1 Swiping)**:
   The user specifies an addictive orientation test with swipe cards (Tinder-like) using Framer Motion. Because `web/package.json` contains React 19, `framer-motion` must be added to `package.json` or imported cleanly. The interaction requires X-axis dragging, angular tilt proportional to drag distance, visual badges ("M'intéresse" vs "Passer"), spring exit animations, and fallback action buttons for accessibility.

2. **From Observation 3 & 1 (Question Set)**:
   Holland's RIASEC model is the authoritative standard in ActivEducation. A set of 12 questions (2 items per dimension R-I-A-S-E-C, interleaved) provides the optimal balance for an engaging swipe experience completed in 60–90 seconds while yielding statistically differentiated RIASEC profile scores (0–100).

3. **From Observation 1, 4 & 6 (R2 Groq API & Togo Fallback)**:
   The Next.js Route Handler `/api/match` must receive student answers, calculate or forward RIASEC scores, and invoke Groq chat completions (`llama-3.3-70b-versatile` or `llama-3.1-8b-instant`) with persona AÏDA. Because the platform runs in `Integrity mode: demo` and `GROQ_API_KEY` might be absent in CI or test runners, `/api/match` must implement a deterministic local fallback that returns valid Togo careers and MESR/CAMES accredited institutions with exact schema compliance.

4. **From Observation 1 & 2 (R3 Results Dashboard & Design Rules)**:
   The results UI must render the psychological profile, 3 high-growth careers, and 3 accredited institutions. It must enforce two non-negotiable styling rules:
   - Amber `#FAA100` strictly for match scores and progression metrics.
   - ABSOLUTELY ZERO EMOJIS anywhere in the UI or AI output, using Lucide SVG icons instead.
   - Font Hanken Grotesque and flat design with 1px borders (`#E3E5EC`).

5. **From Observation 1 & 6 (Acceptance Criteria & test-match.js)**:
   Acceptance requires `npm run build` to pass cleanly without TypeScript or CSS errors, and `test-match.js` to execute an automated POST call to `/api/match`, validating the JSON schema, Togo schools, 3 careers, and the absence of emojis.

---

## 3. Caveats

1. **React 19 & Framer Motion Compatibility**:
   `web/package.json` uses React `19.2.8`. When installing `framer-motion`, modern versions (`framer-motion@^12` or `motion@^12`) support React 19 cleanly.
2. **Groq API Rate Limits & Network Independence**:
   In CI or sandboxed offline environments where internet access to `api.groq.com` may be blocked or unauthenticated, the automated script `test-match.js` must test `/api/match`, which will rely on the deterministic fallback if `GROQ_API_KEY` is not provided. Both live Groq execution and local fallback return the exact same JSON schema.

---

## 4. Conclusion

All requirements for R1, R2, R3, and Acceptance Criteria have been thoroughly mined, cross-referenced with the authoritative project documentation (`docs/ORIENTATION.md`, `seed_careers.sql`, `globals.css`, `DESIGN.md`), and documented in `d:\ActivEducation\.agents\spec_miner_2_1\report.md`.
The specifications provide clear, unambiguous blueprints for:
- Framer Motion swiping deck with RIASEC 12-item questionnaire.
- Route Handler `/api/match` with Groq AÏDA prompt and resilient Togo fallback.
- Results dashboard respecting Amber `#FAA100`, Hanken Grotesque, flat borders, and zero emojis.
- Automated testing via `test-match.js` and `npm run build`.

---

## 5. Verification Method

To verify these specifications:
1. Review the full report at `d:\ActivEducation\.agents\spec_miner_2_1\report.md`.
2. Verify font and color tokens in `d:\ActivEducation\web\src\app\globals.css` (`--color-primary: #3133DD`, `--color-gold: #FAA100`, `--font-sans: "Hanken Grotesque"`).
3. Verify domain RIASEC alignment in `d:\ActivEducation\docs\ORIENTATION.md` and `d:\ActivEducation\backend\database\seed_careers.sql`.
4. Downstream implementation verification:
   - Run `npm run build` in `d:\ActivEducation\web` (expected exit code 0).
   - Run `node test-match.js` in `d:\ActivEducation\web` (expected exit code 0).
