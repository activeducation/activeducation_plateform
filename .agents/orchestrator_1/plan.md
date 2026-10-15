# Execution Plan — orchestrator_1

## Objective
Build the Next.js E-learning course catalog and student progression dashboard in `d:\ActivEducation\web`, strictly adhering to the Design System and acceptance criteria.

## Steps
- [ ] **Step 1: Survey & Technical Investigation**
  - Spawn 3 parallel Explorers:
    - `explorer_1`: Investigate Next.js project structure, routing, dependencies, scripts, build config.
    - `explorer_2`: Investigate existing UI components in `src/components/ui` (`Button`, `Card`, `Input`), variants, Tailwind config, colors, typography.
    - `explorer_3`: Investigate `DESIGN.md` rules, layout constraints (prohibition of centered hero, use of gold strictly for progression, etc.), mock data requirements.
  - Deliverable: 3 exploration reports.

- [ ] **Step 2: Synthesis & PROJECT.md Definition**
  - Aggregate survey reports.
  - Formulate `PROJECT.md` with architecture, feature inventory, code layout, interface contracts, and design rules.

- [ ] **Step 3: Implementation**
  - Dispatch Worker to implement course catalog and progression dashboard with mock data in `d:\ActivEducation\web`.
  - Worker must verify by running `npm run build` in `d:\ActivEducation\web`.
  - Deliverable: Worker handoff with build verification.

- [ ] **Step 4: Review & Adversarial Verification**
  - Dispatch 2 independent Reviewers (`teamwork_preview_reviewer`).
  - Dispatch 2 independent Challengers (`teamwork_preview_challenger`).
  - Dispatch 1 Forensic Auditor (`teamwork_preview_auditor`).

- [ ] **Step 5: Gate Evaluation & Milestone Completion**
  - Evaluate Gate Criteria (build passes, all reviewers approve, all challengers approve, auditor reports CLEAN).
  - Produce final handoff and report to Sentinel.
