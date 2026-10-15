## 2026-09-22T11:34:04Z

You are spec_miner_2_1.
Your working directory is d:\ActivEducation\.agents\spec_miner_2_1.
You MUST read d:\ActivEducation\.agents\ORIGINAL_REQUEST.md (specifically the section starting at ## 2026-09-22T11:31:59Z) and any related design documents (e.g. d:\ActivEducation\DESIGN.md).

Extract and document:
1. Feature specifications for R1 (Interface de Test Ludique):
   - Swiping mechanics (Tinder-like cards / interactive QCM) with Framer Motion.
   - Question set design: how many questions, what categories (RIASEC/Holland codes or psychological interests: Réaliste, Investigateur, Artistique, Social, Entreprenant, Conventionnel, or tech/business/science), options per question.
   - Design constraints: Hanken Grotesque font, flat design, strict components, #3133DD primary color, NO emojis.
2. Feature specifications for R2 (Logique de Matching IA):
   - Route /api/match endpoint specification (POST request payload, response schema).
   - Prompt engineering for Groq (llama-3.3-70b-versatile, llama-3.1-8b-instant, mixtral-8x7b-32768, etc.).
   - Togo context: 3 high-growth careers relevant to Togo/West Africa, 3 accredited Togo institutions.
3. Feature specifications for R3 (Tableau de Bord des Résultats):
   - Visual display of AI results (psychological profile, 3 careers with description/salary/skills, 3 Togo institutions with programs/accreditations).
   - Strict color rule: Amber (#FAA100) for matching/progression scores.
   - Strict design rule: ABSOLUTELY ZERO EMOJIS anywhere in the UI.
4. Acceptance criteria and test plan:
   - npm run build compilation check.
   - test-match.js Node.js script execution specifications.
Write a detailed requirements specification report to d:\ActivEducation\.agents\spec_miner_2_1\report.md and handoff.md.
Notify orchestrator when done via send_message.
