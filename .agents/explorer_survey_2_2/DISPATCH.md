## 2026-09-22T11:34:04Z

Investigate:
1. The requirements for Route Handler Next.js (/api/match):
   - What input format does /api/match take (student test answers)?
   - How does it query Groq API (llama3 or mixtral)?
   - Is groq-sdk installed or needed? Or direct fetch to https://api.groq.com/openai/v1/chat/completions?
   - How to handle GROQ_API_KEY (whether provided in environment or if demo/mock fallback is needed when no key is provided, or demo mode per ORIGINAL_REQUEST line 37: Integrity mode: demo)?
   - What is the exact expected response JSON schema: psychological profile, 3 high-growth careers (métiers porteurs), 3 accredited Togo institutions (universités/écoles agréées)?
2. What are the requirements for test-match.js:
   - How should test-match.js be structured? Where should it live (d:\ActivEducation\web\test-match.js or project root)?
   - How does it invoke /api/match (via local node fetch, starting server or mock request handler)?
   - What validations must it assert (status code 200, valid JSON, profile structure, careers array length 3, Togo schools array length 3 with real/accredited Togo names)?
3. What are the accredited universities and high schools/institutes in Togo (e.g. Université de Lomé, Université de Kara, EAMAU, ESGIS, IAEC, IFAD, etc.) to ensure the prompt / fallback contains authentic, accurate Togo data?
Write a comprehensive report to d:\ActivEducation\.agents\explorer_survey_2_2\report.md and a summary handoff.md.
Notify orchestrator when done via send_message.
