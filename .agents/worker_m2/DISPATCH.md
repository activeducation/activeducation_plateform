# Dispatch: Worker M2 (Orientation Module Implementation)

Working directory: d:\ActivEducation\.agents\worker_m2
Target codebase: d:\ActivEducation\web
Mission: Implement the complete Orientation Module (R1 Swiping Test UI, R2 Groq AI Matching & /api/match Route, R3 Results Dashboard, test-match.js) according to PROJECT.md and ORIGINAL_REQUEST.md.

## 2026-09-22T11:44:16Z
You are worker_m2.
Your working directory is d:\ActivEducation\.agents\worker_m2.
You MUST read d:\ActivEducation\.agents\ORIGINAL_REQUEST.md (specifically the section starting at ## 2026-09-22T11:31:59Z) and d:\ActivEducation\.agents\PROJECT.md.

Also consult the survey reports:
- d:\ActivEducation\.agents\explorer_survey_2_1\report.md (UI, DA V2, Card component, animations)
- d:\ActivEducation\.agents\spec_miner_2_1\report.md (Detailed specs, 12 RIASEC questions, scoring, schema)
- d:\ActivEducation\.agents\explorer_survey_2_2_repl\report.md (Groq API, Route Handler, Togo data, test-match.js)

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

YOUR MISSION:
Implement Milestone 2: Orientation Module End-to-End.

Files you own exclusively:
- d:\ActivEducation\web\src\lib\orientation.ts (RIASEC questions, scoring logic, Togo careers & MESR accredited schools catalog, Groq caller & deterministic fallback generator)
- d:\ActivEducation\web\src\app\api\match\route.ts (Next.js App Router POST Route Handler for /api/match)
- d:\ActivEducation\web\test-match.js (Automated Node.js test script for /api/match)
- d:\ActivEducation\web\src\components\orientation\SwipeCard.tsx (Swiping card UI with fluid drag/spring gestures, "Passer" / "M'intéresse" badges)
- d:\ActivEducation\web\src\components\orientation\OrientationTest.tsx (Interactive 12-question RIASEC test deck with progress meter, buttons, and transition to results)
- d:\ActivEducation\web\src\components\orientation\OrientationResults.tsx (Results dashboard with psychological profile, 3 careers, 3 accredited Togo institutions, amber #FAA100 for match scores)
- d:\ActivEducation\web\src\app\orientation\page.tsx (Dedicated orientation page with step flow: intro, test, loading analysis, results)
- d:\ActivEducation\web\src\components\ui\Card.tsx (Update CardProps to include variant?: 'standard' | 'gamification' | 'dark' and handle styling accordingly)
- d:\ActivEducation\web\src\components\Navbar.tsx (Add "Orientation" nav link pointing to /orientation)
- d:\ActivEducation\web\src\app\page.tsx (Add CTA button or banner linking to /orientation)

CRITICAL DESIGN RULES:
1. Strictly follow DA V2: font Hanken Grotesque, primary #3133DD, flat design with #E3E5EC borders.
2. Amber #FAA100 is STRICTLY RESERVED for match/progression scores (e.g. 85%, 92%).
3. ABSOLUTELY ZERO EMOJIS in UI, code, questions, careers, or API responses. Use lucide-react SVG icons only.
4. Route Handler /api/match must call Groq API (llama-3.3-70b-versatile) via fetch in JSON mode, and gracefully fall back to deterministic matching with genuine accredited Togo institutions (MESR/CAMES) and high-growth careers when GROQ_API_KEY is missing or fails.
5. test-match.js must be a robust Node.js script:
   - It should test calling /api/match with fake answers.
   - To be 100% resilient when run standalone (node test-match.js) without needing a dev server started, it can either make a fetch call to http://localhost:3000/api/match (or process.env.TEST_URL) IF a server is up, OR dynamically import/invoke the POST handler from src/app/api/match/route.ts (or src/lib/orientation.ts match logic) if the server is not reachable, asserting status 200, valid JSON, profile structure, careers length === 3, accredited Togo schools length === 3, and zero emojis!
6. VERIFICATION:
   You MUST execute:
   - node test-match.js in d:\ActivEducation\web
   - npm run build in d:\ActivEducation\web
   Verify both exit with code 0!
   Document exact commands and results in your handoff.md.

When finished, write d:\ActivEducation\.agents\worker_m2\handoff.md and report back via send_message.
