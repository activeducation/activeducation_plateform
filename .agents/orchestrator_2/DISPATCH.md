## 2026-09-22T11:32:46Z

You are the Project Orchestrator (teamwork_preview_orchestrator).
Your identity: orchestrator_2
Your working directory: d:\ActivEducation\.agents\orchestrator_2
Project workspace: d:\ActivEducation (and specifically web app in d:\ActivEducation\web)

Please read the user request in:
d:\ActivEducation\.agents\ORIGINAL_REQUEST.md (specifically the section starting at ## 2026-09-22T11:31:59Z)

Key Requirements:
1. R1. Interface de Test Ludique (Swiping/QCM) : Créer une interface de passage de test d'orientation addictive (ex: cartes à swiper type Tinder ou QCM interactif fluide) utilisant Framer Motion ou similaire. Respecter la nouvelle Direction Artistique (Hanken Grotesque, flat design, composants stricts).
2. R2. Logique de Matching IA (Groq / AÏDA) : Créer un Route Handler Next.js (`/api/match`) qui prend les réponses de l'étudiant en entrée, interroge l'API Groq (llama3 ou mixtral), et retourne un profil psychologique, 3 métiers porteurs, et 3 établissements au Togo (universités/écoles agréées).
3. R3. Tableau de Bord des Résultats : Construire l'UI affichant les résultats retournés par l'IA de façon visuelle et claire, en utilisant l'ambre (#FAA100) pour les scores de correspondance/progression, et SANS LE MOINDRE EMOJI.

Acceptance Criteria:
- Le projet compile sans erreur (`npm run build`).
- Un script de test Node.js (`test-match.js`) appelle l'API `/api/match` avec de fausses réponses et vérifie qu'elle répond un JSON valide avec métiers et écoles au Togo.
- Animations fluides et ludiques (swipe ou transitions).
- Charte graphique V2 strictement respectée (Hanken Grotesque, `#3133DD`, bordures flat).

Maintain your `plan.md`, `progress.md`, and `BRIEFING.md` in your working directory `d:\ActivEducation\.agents\orchestrator_2`.
When complete, notify the sentinel.
