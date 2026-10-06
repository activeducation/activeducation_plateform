# BRIEFING — 2026-09-30T23:45:40Z

## Mission
Investigate career ID mismatches between generateDeterministicOrientationM3 and TOGO_CAREERS_CATALOG in web/src/lib/orientation.ts, provide canonical mapping for all 16 careers, and define exact scoring/selection logic.

## 🔒 My Identity
- Archetype: explorer
- Roles: teamwork_preview_explorer
- Working directory: d:\ActivEducation\.agents\teamwork\explorer_m3_it2_2
- Original parent: f3d00c44-f96b-4e02-b1e0-7ca7de550c74
- Milestone: M3 (Orientation)

## 🔒 Key Constraints
- Read-only investigation — do NOT implement
- Produce structured report in handoff.md
- Verify exact line numbers, IDs, and scoring logic

## Current Parent
- Conversation ID: f3d00c44-f96b-4e02-b1e0-7ca7de550c74
- Updated: 2026-09-30T23:51:00Z

## Investigation State
- **Explored paths**:
  - `web/src/lib/orientation.ts` (lines 206-479: `TOGO_CAREERS_CATALOG`; lines 1140-1365: `generateDeterministicOrientationM3`)
  - `web/src/app/student/orientation/page.tsx` (lines 33-160: `INTEREST_OPTIONS`, `SUBJECT_OPTIONS`; lines 230-265: payload submission)
  - `web/src/app/student/orientation/resultats/page.tsx` (lines 1-100: result consumption)
  - `web/src/app/api/orientation/generate/route.ts` (lines 1-135: route handler & Groq/fallback invocation)
  - `web/test-orientation-generate.js` (lines 1-168: validation contract)
  - `web/src/app/student/explorer/page.tsx` & `metier/[id]/page.tsx` (origin of phantom career IDs)
- **Key findings**:
  - Only 5 of 16 career IDs matched in `generateDeterministicOrientationM3`.
  - 8 IDs suffered from divergent slug names based on career titles/descriptions.
  - 3 canonical IDs were completely omitted (`architecte-urbaniste`, `enseignant-formateur`, `responsable-rh`).
  - 3 phantom IDs not in catalog were checked (`ingenieur-telecom-iot`, `ingenieur-energies-renouvelables`, `chef-projet-logistique-portuaire`).
  - Beyond ID mismatches, coarse regexes (`science` catching medical sciences, `numérique` catching digital arts, `chimie` catching physics-chemistry) plus default fallback bonus bias (: 10, : 8, : 6) in Tech careers caused Tech careers to dominate ties even if IDs were renamed.
  - Designed an exact, two-tier scoring formula: primary domain affinity (+40-45) from `answers.interests` and secondary domain affinity (+25-30) from `answers.strongSubjects` with demand bonuses (+3-5).
- **Unexplored areas**: None. All 16 careers mapped and tested across all 6 profile domains.

## Key Decisions Made
- Confirmed canonical IDs from `TOGO_CAREERS_CATALOG` as single source of truth.
- Validated that Challenger 2's diagnosis was correct on ID mismatches, but Challenger 2's proposed replacement had residual token-overlap edge cases which our proposed formula fully resolves.
- Prepared comprehensive handoff report in `handoff.md`.

## Artifact Index
- handoff.md — Final investigation report

