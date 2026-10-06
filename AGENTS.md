# ActivEducation - Configuration Agentique

Ce projet utilise l'infrastructure Google Antigravity pour garantir des standards élevés de développement. 
Les configurations des agents sont réparties dans le dossier `.agents/`.

## Structure
- `.agents/rules/` : Contient les instructions strictes que l'agent et les développeurs doivent suivre (Design System, Architecture).
- `.agents/skills/` : Outils et workflows réutilisables spécifiques au projet.
- `.agents/hooks/` : Scripts liés au cycle de vie du code (vérifications avant commit, formatage).
- `.agents/docs/` : Documentation technique et architecturale pour donner du contexte au LLM.

## Priorités
Les règles définies dans `.agents/rules/` ont une priorité **absolue** sur les habitudes globales de code.
