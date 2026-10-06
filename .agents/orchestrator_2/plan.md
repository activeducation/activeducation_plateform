# Plan: Orientation Module (Orchestrator 2)

## Objectives
Deliver the Orientation Module for ActivEducation according to the request in `ORIGINAL_REQUEST.md`:
1. R1: Interactive gamified orientation test interface (swiping cards or fluid interactive QCM) with Framer Motion, DA V2 (Hanken Grotesque, flat design, strict components, #3133DD, zero emojis).
2. R2: Next.js Route Handler `/api/match` calling Groq API (llama3 / mixtral) returning psychological profile, 3 high-growth careers (métiers porteurs), and 3 accredited Togo institutions.
3. R3: Visual results dashboard with amber `#FAA100` for matching/progression scores, zero emojis, clean layout.
4. Acceptance Criteria:
   - `npm run build` succeeds cleanly.
   - `test-match.js` executes and validates `/api/match` response format and Togo data.
   - Fluid animations (swipe or transitions).
   - Strict DA V2 adherence.

## Execution Steps
1. **Survey (Phase 0)**:
   - Spawn 3 parallel survey agents (`teamwork_preview_explorer` x2, `teamwork_preview_spec_miner` x1):
     - `explorer_survey_2_1`: Inspect existing `web` codebase, Next.js setup, Tailwind configuration, existing fonts/tokens, Framer motion availability, UI components.
     - `explorer_survey_2_2`: Inspect Groq API usage/setup, environment variables (`GROQ_API_KEY`), route handler conventions in Next.js App Router, fallback strategy for demo/testing mode, data schema for orientation results.
     - `spec_miner_2_1`: Mine full requirements and constraints for the orientation test (questions, scoring, psychological profiles, Togo institutions list, careers list, test-match.js specs).
2. **Decomposition & Specification (Phase 1)**:
   - Consolidate survey reports into `PROJECT.md` Feature Inventory & Milestones.
   - Define exact interface contracts, file paths, and test definitions.
3. **Milestone Execution (Phase 2)**:
   - Milestone 1: Groq AI matching Route Handler (`/api/match`), fallback/mock data, and automated test script `test-match.js`.
   - Milestone 2: Gamified Orientation Test UI (Swiping cards / fluid QCM) with Framer Motion, strict DA V2, zero emojis.
   - Milestone 3: Results Dashboard with amber `#FAA100` scores, Togo accredited schools/careers, integration with `/api/match` and test UI.
   - Milestone 4 (Final Milestone): E2E integration, `npm run build` validation, `test-match.js` execution, adversarial challenge, forensic audit.
4. **Final Gate & Reporting**:
   - Verify all pass criteria.
   - Send completion message to parent (sentinel).
