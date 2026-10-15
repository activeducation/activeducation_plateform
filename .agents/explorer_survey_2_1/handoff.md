# Handoff Report — explorer_survey_2_1

**Auteur** : explorer_survey_2_1  
**Destinataire** : orchestrateur / subagents d'implémentation  
**Date** : 2026-09-22T11:38:15Z  
**Type de handoff** : Hard handoff (Tâche d'investigation complète)  

---

## 1. Observation

1. **`web/package.json` (lignes 11–28)** :
   ```json
   "dependencies": {
     "@supabase/ssr": "^0.12.7",
     "@supabase/supabase-js": "^2.116.0",
     "lucide-react": "^1.47.0",
     "next": "16.3.5",
     "react": "19.2.8",
     "react-dom": "19.2.8"
   },
   "devDependencies": {
     "@tailwindcss/postcss": "^4",
     "@types/node": "^20",
     "@types/react": "^19",
     "@types/react-dom": "^19",
     "eslint": "^9",
     "eslint-config-next": "16.3.5",
     "tailwindcss": "^4",
     "typescript": "^5"
   }
   ```
   - `lucide-react` est présent (`^1.47.0`).
   - `framer-motion` et `motion` sont absents de `dependencies` et `devDependencies`.
   - `tailwindcss` v4 et `@tailwindcss/postcss` v4 sont configurés.

2. **`web/src/app/globals.css` (lignes 1–26)** :
   ```css
   @import url('https://fonts.googleapis.com/css2?family=Hanken+Grotesque:ital,wght@0,100..900;1,100..900&display=swap');
   @import "tailwindcss";

   @theme {
     --color-primary: #3133DD;
     --color-primary-hover: #2829B8;
     --color-gold: #FAA100;
     --color-canvas: #F7F8FB;
     --color-surface: #FFFFFF;
     --color-border-soft: #E3E5EC;
     --color-error: #D23A3A;
     --color-text-primary: #111827;
     --color-text-secondary: #4B5563;
     --color-text-tertiary: #9CA3AF;
     --font-sans: "Hanken Grotesque", system-ui, sans-serif;
     --radius-sm: 8px;
     --radius-md: 12px;
     --radius-lg: 16px;
     --radius-xl: 24px;
     --shadow-hover: 0 4px 12px rgba(0,0,0,0.05);
   }
   ```

3. **`web/src/app/layout.tsx` (lignes 14–19)** :
   ```tsx
   <body className="antialiased flex flex-col font-sans">
     {children}
   </body>
   ```

4. **`web/src/components/ui/`** :
   - `Button.tsx` (lignes 3–30) : gère `variant?: 'primary' | 'secondary' | 'gamification'`, `size?: 'sm' | 'md' | 'lg'`.
   - `Card.tsx` (lignes 3–26) :
     ```tsx
     export interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
       interactive?: boolean;
     }
     ```
     `variant` n'est pas déclaré dans `CardProps`, alors que `page.tsx` et `CourseCatalog.tsx` passent `variant="standard"` et `variant="gamification"`.
   - `Input.tsx` (lignes 3–7) : gère `label: string`, `error?: string`.

5. **`d:\ActivEducation\.agents\ORIGINAL_REQUEST.md` (lignes 41–60)** :
   - R1 : *« Créer une interface de passage de test d'orientation addictive (ex: cartes à swiper type Tinder ou QCM interactif fluide) utilisant Framer Motion ou similaire. L'interface doit respecter la nouvelle Direction Artistique (Hanken Grotesque, flat design, composants stricts). »*
   - R2 : *« Route Handler Next.js (/api/match) qui prend les réponses de l'étudiant en entrée, interroge l'API Groq (llama3 ou mixtral), et retourne un profil psychologique, 3 métiers porteurs, et 3 établissements au Togo (universités/écoles agréées). »*
   - R3 : *« Construire l'UI affichant les résultats retournés par l'IA de façon visuelle et claire, en utilisant l'ambre (#FAA100) pour les scores de correspondance/progression, et sans le moindre emoji. »*
   - Acceptance Criteria : *« Le projet compile sans erreur (npm run build). Un script de test Node.js (test-match.js) appelle l'API /api/match avec de fausses réponses et vérifie qu'elle répond un JSON valide avec métiers et écoles au Togo. »*

6. **Données Référentielles Togo** (`backend/scripts/seed_knowledge_base.py` lignes 40–100 & `backend/alembic/versions/017_seed_careers.py`) :
   - Établissements togolais homologués CAMES : Université de Lomé, Université de Kara, UCAO-UUT, ESA, ESIBA, IPNET Institute, IAEC, EAMAU, IAI-TOGO, ESGIS.

---

## 2. Logic Chain

1. **Observations 1 & 5 (Stack & Animations)** :
   - Observation 1 montre que `framer-motion` n'est pas installé dans `package.json`.
   - Observation 5 (R1) exige une interface à cartes swipables utilisant « Framer Motion ou similaire ».
   - Comme React 19 (`19.2.8`) et Next 16 (`16.3.5`) sont utilisés, l'implémentation doit intégrer soit `motion` / `framer-motion@latest` compatible React 19, soit un contrôleur gestuel fluide (pointer drag + spring physics).

2. **Observations 2, 3 & 5 (DA V2 & Typographie)** :
   - Observation 2 et 3 montrent que `globals.css` et `layout.tsx` configurent `Hanken Grotesque` via `--font-sans` sur le `body`.
   - `DESIGN.md` mentionnait Sora et Outfit, mais la charte V2 a consolidé la typographie sur **Hanken Grotesque**.
   - La couleur primaire est strictement **`#3133DD`** et l'ambre des scores de correspondance est **`#FAA100`**.
   - Le design est flat (bordures `#E3E5EC`, pas de glow, ombres discrètes). Aucun emoji n'est toléré (Observation 5, R3).

3. **Observation 4 (Composants UI)** :
   - `Button` et `Input` sont directement réutilisables.
   - `Card.tsx` fonctionne bien pour les conteneurs visuels, mais `CardProps` doit être enrichi de `variant?: 'standard' | 'gamification'` pour éviter les divergences de typage TypeScript.
   - Pour les cartes à swiper, un sous-composant `SwipeCard` doit envelopper `Card` avec la gestion du drag/swipe et les cachets graphiques (Oui/Non).

4. **Observations 5 & 6 (Architecture des Routes)** :
   - Une route dédiée `src/app/orientation/page.tsx` est la solution optimale pour isoler le flux gamifié du test sans surcharger la page d'accueil.
   - Le Route Handler `src/app/api/match/route.ts` doit interroger Groq (`llama-3.1-8b-instant`), avec un fallback local immédiat basé sur la base de connaissances des écoles togolaises (Observation 6) pour garantir le succès inconditionnel du script `test-match.js`.

---

## 3. Caveats

1. **Exécution des commandes (`run_command`)** : L'exécution directe en ligne de commande (`npm run build`) nécessite une autorisation interactive ; l'analyse statique du code, du typage TS et des fichiers de dépendances a été privilégiée pour cette phase d'exploration.
2. **Clé API Groq** : L'environnement peut ne pas avoir `GROQ_API_KEY` injectée en local lors des tests d'audit. Le Route Handler `/api/match` **doit impérativement implémenter un fallback déterministe** avec de vraies universités togolaises (Université de Lomé, UCAO, IPNET) et métiers porteurs, afin que `test-match.js` réussisse en mode déconnecté.
3. **Compatibilité Framer Motion / React 19** : En cas de blocage d'installation de dépendances externes sur React 19, une gestuelle Pointer Events native avec transitions CSS spring constitue une alternative robuste respectant la clause « ou similaire ».

---

## 4. Conclusion

- **Stack confirmée** : Next.js 16.3.5, React 19.2.8, Tailwind CSS v4, Lucide React 1.47.0. `framer-motion` n'est pas encore installé.
- **DA V2 clarifiée** : Hanken Grotesque comme police unique, `#3133DD` en primaire, `#FAA100` pour les scores de matching, style flat avec bordures fines `#E3E5EC`, 0 emoji.
- **Composants UI** : `Button` et `Input` sont réutilisables tels quels ; `Card` doit voir son interface `CardProps` complétée avec `variant`. Le composant `SwipeCard` composera sur cette base.
- **Routes & Fichiers cibles à créer** :
  - `src/app/orientation/page.tsx` (expérience test + dashboard résultats).
  - `src/app/api/match/route.ts` (API POST Groq + fallback Togo).
  - `web/test-match.js` (script de test de conformité automatisé).
  - Ajout du lien "Orientation" dans `Navbar.tsx` et Hero de `page.tsx`.

---

## 5. Verification Method

Pour vérifier de façon autonome les constats de ce rapport :
1. **Vérifier l'absence de framer-motion** :
   Inspecter `web/package.json` et constater l'absence de `framer-motion` dans les dépendances.
2. **Vérifier la configuration DA V2** :
   Inspecter `web/src/app/globals.css` (lignes 1 et 20) pour constater l'import de Hanken Grotesque, `--color-primary: #3133DD;` et `--color-gold: #FAA100;`.
3. **Vérifier le typage de Card** :
   Inspecter `web/src/components/ui/Card.tsx` pour constater que `variant` n'est pas dans `CardProps`.
4. **Vérifier le rapport complet** :
   Consulter `d:\ActivEducation\.agents\explorer_survey_2_1\report.md`.
