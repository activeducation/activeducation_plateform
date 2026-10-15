## 2026-09-22T11:38:57Z
You are explorer_survey_2_2_repl.
Your working directory is d:\ActivEducation\.agents\explorer_survey_2_2_repl.
CRITICAL CONSTRAINT: DO NOT USE run_command. DO NOT execute any terminal commands. Use ONLY view_file, grep_search, find_by_name, and file inspection tools.

You MUST read d:\ActivEducation\.agents\ORIGINAL_REQUEST.md (specifically the section starting at ## 2026-09-22T11:31:59Z).

Investigate via file inspection:
1. The requirements for Route Handler Next.js (/api/match) in web/src/app/api/match/route.ts:
   - What input format does /api/match take (student test answers, e.g. RIASEC scores or answers object)?
   - How does it query Groq API (llama3 or mixtral via direct fetch to https://api.groq.com/openai/v1/chat/completions with Authorization header or groq-sdk)?
   - How to handle GROQ_API_KEY (handling missing key gracefully with a robust deterministic fallback for demo/test mode)?
   - What is the exact expected response JSON schema: psychological profile, 3 high-growth careers (métiers porteurs), 3 accredited Togo institutions (universités/écoles agréées)?
2. What are the requirements for test-match.js:
   - Where should it live (d:\ActivEducation\web\test-match.js)?
   - How should it test /api/match (via http request or invoking handler directly or fetch)?
   - What assertions must it perform (status code 200, valid JSON, profile structure, careers array length 3, Togo schools array length 3 with real accredited Togo names, zero emojis)?
3. Inspect Togo institutions and careers references in the repository (e.g. in backend/database/seed_careers.sql or docs/ORIENTATION.md).
Write a comprehensive report to d:\ActivEducation\.agents\explorer_survey_2_2_repl\report.md and a summary handoff.md.
Notify orchestrator when done via send_message.
