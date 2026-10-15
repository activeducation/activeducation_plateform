# BRIEFING — 2026-09-22T11:38:25Z

## Mission
Discover and document complete specification requirements for R1 (Ludic Orientation Test / Swipe Interface), R2 (Groq AI Matching Engine & Togo Context), and R3 (Orientation Results Dashboard) with Acceptance Criteria.

## 🔒 My Identity
- Archetype: spec_miner
- Roles: Specification Miner, Teamwork specialist
- Working directory: d:\ActivEducation\.agents\spec_miner_2_1
- Original parent: 91e0495e-c2c1-4610-b1fc-9016448ea61b
- Milestone: M2 - Specification Mining

## 🔒 Key Constraints
- Read-only on implementation: do NOT write code outside `.agents/spec_miner_2_1/`.
- Zero emojis anywhere in UI design or specification.
- Primary color #3133DD, Score/Progression Amber #FAA100, Font Hanken Grotesque.
- Context strictly grounded in Togo and West Africa higher education and career market.
- AI provider: Groq API with structured JSON output.

## Current Parent
- Conversation ID: 91e0495e-c2c1-4610-b1fc-9016448ea61b
- Updated: 2026-09-22T11:38:25Z

## Task Summary
- **What to build**: Detailed specification report (`report.md`) and 5-component handoff (`handoff.md`) covering R1, R2, R3, and test criteria.
- **Success criteria**: Exhaustive interface definitions, prompt schemas, QCM/swipe design, Togo institutional data, edge cases, and test plan.
- **Interface contracts**: `d:\ActivEducation\.agents\ORIGINAL_REQUEST.md`, `d:\ActivEducation\DESIGN.md`.
- **Code layout**: Next.js App Router application structure in `d:\ActivEducation`.

## Key Decisions Made
- Anchored R1 on RIASEC 12-question set (2 items per dimension R, I, A, S, E, C interleaved) with Framer Motion drag gestures.
- Defined `/api/match` endpoint schema with dual execution capability: Groq API (`llama-3.3-70b-versatile` / `llama-3.1-8b-instant`) and a resilient local deterministic fallback matching Togo careers and institutions for demo/test reliability.
- Codified strict Amber `#FAA100` color rule for scores and ABSOLUTELY ZERO EMOJIS everywhere in the UI and AI text.
- Defined specifications for `test-match.js` Node.js script.

## Artifact Index
- `d:\ActivEducation\.agents\spec_miner_2_1\report.md` — Detailed feature requirements report
- `d:\ActivEducation\.agents\spec_miner_2_1\handoff.md` — 5-component handoff report
- `d:\ActivEducation\.agents\spec_miner_2_1\progress.md` — Liveness heartbeat and progress log
- `d:\ActivEducation\.agents\spec_miner_2_1\DISPATCH.md` — Dispatch log
