# Rapport d'Investigation Handoff — Explorer M3_1

**Auteur** : `explorer_m3_1` (Teamwork Explorer)  
**Date** : 2026-09-30T23:31:00Z  
**Destinataire** : Agent Orchestrateur (`f3d00c44-f96b-4e02-b1e0-7ca7de550c74`)  
**Mission** : Investigation approfondie des endpoints API backend (`web/src/app/api`), de la relation entre `/api/orientation/generate` et `/api/match`, du traitement des données d'orientation et repli Groq IA dans `web/src/lib/orientation.ts`, et de la conformité du contrat JSON attendu pour l'exigence R2.

---

## 1. Observation

### 1.1 Endpoint `/api/orientation/generate` (`web/src/app/api/orientation/generate/route.ts`)
Le fichier `web/src/app/api/orientation/generate/route.ts` existe déjà (105 lignes). Ses éléments clés observés sont :

1. **Schéma Zod défini (lignes 11-35)** :
   ```ts
   const OrientationResultSchema = z.object({
     psychologicalProfile: z.object({
       dominantTraits: z.array(z.string()).describe("Les traits dominants de l'étudiant (ex: Réaliste, Entreprenant)"),
       strengths: z.array(z.string()).describe("Points forts de l'étudiant"),
       weaknesses: z.array(z.string()).describe("Points de vigilance"),
       summary: z.string().describe("Un court paragraphe (max 3 phrases) décrivant le profil global de l'étudiant et son potentiel.")
     }),
     recommendedCareers: z.array(
       z.object({
         title: z.string().describe("Nom du métier recommandé"),
         matchPercentage: z.number().describe("Pourcentage de compatibilité (entre 0 et 100)"),
         description: z.string().describe("Pourquoi ce métier lui correspond"),
         salaryRangeCFA: z.string().describe("Fourchette de salaire mensuel estimée au Togo en FCFA (ex: 150 000 - 300 000 FCFA)"),
         demandInTogo: z.enum(['Faible', 'Moyenne', 'Forte']).describe("La demande actuelle pour ce métier au Togo")
       })
     ).length(3).describe("Exactement 3 métiers recommandés"),
     recommendedSchools: z.array(
       z.object({
         name: z.string().describe("Nom de l'Université ou École supérieure (ex: Université de Lomé, ESGIS, IAEC, IAI...)"),
         program: z.string().describe("La filière recommandée dans cette école"),
         estimatedAnnualCostCFA: z.string().describe("Coût annuel estimé en FCFA (ou 'Public/Gratuit')"),
         whyThisSchool: z.string().describe("Pourquoi cette école est recommandée par rapport au profil et budget de l'étudiant")
       })
     ).min(1).max(3).describe("Entre 1 et 3 écoles ou universités recommandées au Togo, en respectant le budget de l'étudiant"),
   });
   ```
   **Constat** : Ce schéma Zod correspond exactement aux champs spécifiés dans `ORIGINAL_REQUEST.md` (R2) :
   - `psychologicalProfile` (`dominantTraits`, `strengths`, `weaknesses`, `summary`)
   - `recommendedCareers` (Array de `{title, matchPercentage, description, salaryRangeCFA, demandInTogo}`)
   - `recommendedSchools` (Array de `{name, program, estimatedAnnualCostCFA, whyThisSchool}`)

2. **Vérification d'authentification Supabase bloquante (lignes 39-44)** :
   ```ts
   const supabase = await createClient();
   const { data: { user }, error } = await supabase.auth.getUser();

   if (error || !user) {
     return NextResponse.json({ error: 'Non autorisé' }, { status: 401 });
   }
   ```
   **Constat** : La route renvoie immédiatement un statut HTTP `401 Non autorisé` si l'utilisateur n'est pas connecté via une session active Supabase.

3. **Validation du Payload entrant (lignes 46-51)** :
   ```ts
   const body = await req.json();
   const { answers } = body;

   if (!answers) {
     return NextResponse.json({ error: 'Données manquantes' }, { status: 400 });
   }
   ```
   **Constat** : Le corps de la requête attend une propriété `answers`. L'injection dans le prompt utilisateur est brute : `${JSON.stringify(answers, null, 2)}`.

4. **Appel Groq via Vercel AI SDK sans aucun repli (lignes 53-83)** :
   ```ts
   if (!process.env.GROQ_API_KEY) {
     return NextResponse.json({ error: 'Clé API Groq manquante' }, { status: 500 });
   }

   const groq = createGroq({
     apiKey: process.env.GROQ_API_KEY,
   });
   ...
   const { object: orientationResult } = await generateObject({
     model: groq('llama-3.1-70b-versatile'),
     schema: OrientationResultSchema,
     system: systemPrompt,
     prompt: userPrompt,
   });
   ```
   **Constat** : Si `process.env.GROQ_API_KEY` est absente, ou si l'API Groq est inaccessible, lente (timeout), ou rejette la requête, la route échoue brutalement avec une erreur HTTP 500. **Aucun mécanisme de repli (fallback) n'est implémenté dans cette route.**

5. **Insertion en base de données non protégée (lignes 85-97)** :
   ```ts
   await db.insert(orientationResults).values({
     userId: user.id,
     inputs: answers,
     results: orientationResult,
   });
   ```
   **Constat** : Si la base de données PostgreSQL n'est pas joignable (ou si `DATABASE_URL` n'est pas configuré), l'exception est levée et capturée par le bloc `catch` global, renvoyant `{ error: "Erreur lors de la génération IA" }` avec le code HTTP 500.

6. **Absence de filtrage des emojis** :
   Contrairement à `/api/match`, aucune fonction `stripEmojis()` ou `sanitizeObject()` n'est invoquée sur `orientationResult` avant de le renvoyer, ce qui risque d'enfreindre la règle stricte ZÉRO EMOJI.

---

### 1.2 Endpoint `/api/match` (`web/src/app/api/match/route.ts`)
Créé pour le Milestone M2 (48 lignes) :
1. **Accès Public** : Aucune exigence d'authentification Supabase. Fonctionne immédiatement en mode anonyme et pour les tests automatisés (`test-match.js`).
2. **Utilisation de `matchOrientation`** : Déléguée entièrement à `web/src/lib/orientation.ts`.
3. **Nettoyage Zéro Emoji** : Exécute explicitement `sanitizeObject(result)` (ligne 29) avant le retour JSON.
4. **Schéma retourné** : Contrat M2 :
   - `profile` (`code`, `title`, `description`, `dominantTraits`, `strengths`, `advice`, `scores`)
   - `careers` (tableau de `Career` avec `id`, `title`, `matchScore`, `demand`, `salary`, `description`, `requiredSkills`, `relevantSchools`)
   - `institutions` (tableau de `Institution` avec `id`, `name`, `type`, `city`, `accreditation`, `programs`)

---

### 1.3 Module de Référence et Logique de Repli (`web/src/lib/orientation.ts`)
Ce fichier de 1114 lignes constitue le cœur métier :
1. **Protection Zéro Emoji (lignes 7-30)** :
   - `EMOJI_REGEX` : Expression régulière Unicode exhaustive `u{1F300}-u{1FAFF}`.
   - `stripEmojis(text)` et `sanitizeObject(obj)` : Assainissement récursif de toutes les chaînes et objets.
2. **Catalogues Nationaux Togolais** :
   - `TOGO_CAREERS_CATALOG` (lignes 206-479) : 16 métiers porteurs au Togo avec salaires réalistes en FCFA (ex: `250 000 - 850 000 FCFA / mois`), compétences requises, tendances de croissance nationales, et écoles togolaises associées.
   - `TOGO_INSTITUTIONS_CATALOG` (lignes 482-634) : 10 universités et écoles supérieures togolaises accréditées MESR Togo / CAMES (`Université de Lomé (UL)`, `Université de Kara (UK)`, `IAI-Togo`, `EAMAU`, `ESGIS`, `ESAG-NDE`, `IPNET Institute`, `FORMATEC`, `INFA de Tové`, `UCAO-UUT`).
3. **Moteur Déterministe Local `generateDeterministicMatch` (lignes 819-924)** :
   - Calcule les scores dimensionnels RIASEC.
   - Trie les carrières togolaises selon leur affinité et le niveau de demande.
   - Sélectionne les 3 meilleurs métiers et les 3 établissements togolais les plus pertinents.
   - Produit une réponse instantanée, 100% sans emoji, sans dépendance réseau.
4. **Intégration Groq `generateGroqMatch` (lignes 927-1103)** :
   - Modèle : `llama-3.3-70b-versatile`.
   - Timeout automatique à 9 secondes (`AbortController`).
   - Bascule automatique vers `generateDeterministicMatch(scores)` si la clé est absente/invalide (`dummy`/`test`), si HTTP status != 200, ou en cas d'erreur de parsing.
5. **Lacune constatée dans `orientation.ts`** :
   `orientation.ts` ne contient actuellement QUE la logique pour le schéma M2 (`profile`, `careers`, `institutions`). Il **ne contient pas** de fonction de repli générant directement le schéma M3 (`psychologicalProfile`, `recommendedCareers`, `recommendedSchools`).

---

### 1.4 Script de Test Automatisé Existant (`web/test-match.js`)
- Exécute des assertions strictes sur `/api/match` :
  - HTTP 200
  - Schéma JSON complet
  - Exactement 3 métiers avec salaires en FCFA et matchScore >= 60
  - Exactement 3 établissements togolais reconnus MESR / CAMES
  - Zéro emoji vérifié par regex

---

## 2. Logic Chain

### 2.1 Relation et Distinction entre `/api/match` et `/api/orientation/generate`

| Critère | `/api/match` (M2) | `/api/orientation/generate` (M3) |
| :--- | :--- | :--- |
| **Objectif** | Test d'orientation public (12 items RIASEC swipables sur `/orientation`) | Test d'orientation étudiant connecté (4 catégories clés sur `/student/orientation`) |
| **Authentification** | Publique (aucune session requise) | Requiert Supabase Auth (`getUser()`) dans l'état actuel |
| **Persistance BD** | Aucune persistance BD | Sauvegarde dans `orientation_results` + gain de 200 XP dans `users` |
| **Fournisseur IA** | Fetch direct `api.groq.com` (`llama-3.3-70b-versatile`) | Vercel AI SDK `generateObject` (`llama-3.1-70b-versatile`) |
| **Mécanisme de Repli** | Résilient : Bascule automatique vers `generateDeterministicMatch()` | **AUCUN** : Crash HTTP 500 si Groq indisponible ou clé absente |
| **Sanitisation Emoji** | `sanitizeObject()` systématique | Aucune sanitisation |
| **Clés Racine JSON** | `profile`, `careers`, `institutions` | `psychologicalProfile`, `recommendedCareers`, `recommendedSchools` |

### 2.2 Analyse du Schéma de Données R2
L'exigence R2 requiert le format JSON suivant pour `/student/orientation/resultats/page.tsx` :
1. `psychologicalProfile` :
   - `dominantTraits` : Tableau de chaînes (ex: `["Analytique", "Méthodique", "Pragmatique"]`).
   - `strengths` : Tableau de points forts (ex: `["Raisonnement logique", "Autonomie technique"]`).
   - `weaknesses` : Tableau de points de vigilance (ex: `["Tendance au sur-détail", "Besoin d'un cadre explicite"]`).
   - `summary` : Synthèse bienveillante et percutante (1 à 3 phrases).
2. `recommendedCareers` :
   - Exactement 3 objets.
   - `title` : Nom du métier porteur (ex: `Développeur Web & Mobile / Ingénieur Cloud`).
   - `matchPercentage` : Nombre entier entre 0 et 100 (réservé pour affichage en ambre `#FAA100`).
   - `description` : Explication personnalisée de la correspondance.
   - `salaryRangeCFA` : Rémunération mensuelle estimée au Togo (ex: `250 000 - 850 000 FCFA / mois`).
   - `demandInTogo` : `'Faible' | 'Moyenne' | 'Forte'` (ou `'Tres Forte'`).
3. `recommendedSchools` :
   - Entre 1 et 3 objets.
   - `name` : Nom de l'établissement togolais agréé (ex: `Université de Lomé (UL)`, `IAI-Togo`, `ESGIS`).
   - `program` : Filière d'excellence recommandée (ex: `Génie Logiciel & Technologies Web`).
   - `estimatedAnnualCostCFA` : Coût annuel réaliste en FCFA (ex: `Public / 25 000 - 50 000 FCFA` ou `450 000 FCFA / an`).
   - `whyThisSchool` : Justification explicite au regard du profil et du budget de l'étudiant.

### 2.3 Correspondance du Payload Entrant (Les 4 Catégories R1)
Le questionnaire R1 interroge l'étudiant sur :
1. **Intérêts** (ex: Sciences, Technologies, Économie, Arts, Santé, Littérature...)
2. **Matières fortes** (ex: Mathématiques, Physique-Chimie, Français, SVT, Anglais...)
3. **Budget** (`Faible` < 200k FCFA, `Moyen` 200k-600k FCFA, `Élevé` > 600k FCFA)
4. **Région / Mobilité** (`Lomé / Maritime`, `Kara / Nord`, `Plateaux / Centre`, `Savanes`, `Mobilité Totale`)

Pour assurer une interopérabilité maximale entre le frontend (`/student/orientation/page.tsx`) et le handler backend (`/api/orientation/generate`), le payload accepté doit être structuré de manière souple :
```json
{
  "answers": {
    "interests": ["Sciences & Nouvelles Technologies", "Ingénierie"],
    "strongSubjects": ["Mathématiques & Physique-Chimie", "Informatique"],
    "budget": "Moyen",
    "mobility": "Grand Lomé & Région Maritime",
    "otherSubject": "",
    "currentCity": "Lomé"
  }
}
```
Le backend doit accepter indifféremment que les clés soient au niveau racine ou imbriquées dans `answers`, avec support des libellés français (`interets`, `matieresFortes`, `region`).

### 2.4 Diagnostic des Vulnérabilités de la Route Actuelle `/api/orientation/generate`
1. **Bloquage Auth en Mode Démo** : Si l'étudiant passe le test sans être connecté (ou si les tests automatisés interrogent l'API), le code retourne 401. En mode démo (`Integrity mode: demo`), l'API doit autoriser l'exécution anonyme sans faire échouer le flux.
2. **Panne Sèche sans Groq** : Sans clé `GROQ_API_KEY` ou en cas de quota dépassé, la route renvoie 500. Elle doit impérativement basculer vers un générateur déterministe local.
3. **Plantage lors de la sauvegarde BD** : Si PostgreSQL n'est pas opérationnel, l'insertion `db.insert` fait planter la requête. Cette opération doit être enveloppée dans un bloc isolé qui ne bloque pas la réponse HTTP.
4. **Non-respect du Zéro Emoji** : L'absence de filtre de sanitisation expose l'API à des émojis générés par l'IA.

---

## 3. Caveats

1. **Environnement Démo (`Integrity mode: demo`) vs Middleware Supabase** :
   - `web/src/middleware.ts` et `web/src/utils/supabase/middleware.ts` redirigent toute requête non connectée sur `/student/*` vers `/auth/login`.
   - Si les tests d'audit ou les vérifications automatisées naviguent directement sur `/student/orientation`, une session de contournement démo ou un utilisateur test doit être prévu côté frontend ou middleware pour éviter une redirection inattendue.
2. **Contrainte Zod stricte sur le nombre de carrières** :
   - `recommendedCareers: z.array(...).length(3)` : Le modèle Groq doit obligatoirement renvoyer 3 métiers. Si Groq en renvoie 2 ou 4, `generateObject` déclenche une `ZodError`. Le gestionnaire de repli doit intercepter cette erreur et fournir les 3 métiers du catalogue togolais.
3. **Contrainte sur l'énumération `demandInTogo`** :
   - `demandInTogo: z.enum(['Faible', 'Moyenne', 'Forte'])` : Attention, dans `orientation.ts`, le catalogue utilise `'Tres Forte' | 'Forte' | 'En Croissance'`. Il est crucial d'harmoniser cette valeur (transformer `'Tres Forte'` en `'Forte'` ou étendre le schéma Zod à `z.enum(['Faible', 'Moyenne', 'Forte', 'Tres Forte'])`) pour éviter tout rejet Zod.
4. **Respect absolu du Design System V2** :
   - La couleur Or/Ambre (`#FAA100`) doit être restreinte **exclusivement** aux pourcentages de matching (`matchPercentage`) et barres de score.
   - Les boutons d'action doivent impérativement être `variant="primary"` (Bleu Royal) ou `variant="secondary"`.
   - Zéro émoji dans toute réponse API et tout affichage UI.

---

## 4. Conclusion & Recommandations Architecturales

### 4.1 Recommandation pour la Route Backend `web/src/app/api/orientation/generate/route.ts`
La route handler doit être refactorisée pour intégrer le modèle de résilience éprouvé de `/api/match` tout en respectant le schéma R2 :

1. **Authentification Souple (Graceful Degradation)** :
   ```ts
   let user = null;
   try {
     const supabase = await createClient();
     const { data } = await supabase.auth.getUser();
     user = data?.user || null;
   } catch {
     user = null; // Autoriser le mode démo sans bloquer
   }
   ```
2. **Génération IA avec Repli Déterministe Garanti** :
   - Tenter l'appel Groq avec prompt enrichi des contraintes togolaises et consigne stricte ZÉRO EMOJI.
   - En cas d'absence de `GROQ_API_KEY`, d'erreur réseau, de dépassement de délai (timeout 8s), ou d'erreur de schéma Zod, basculer instantanément sur `generateDeterministicOrientationM3(answers)`.
3. **Persistance BD Asynchrone et Non-Bloquante** :
   - Si `user` est défini, tenter la sauvegarde dans `orientationResults` et la mise à jour de l'XP dans un bloc `try/catch` dédié.
   - Si la BD échoue, enregistrer un avertissement console mais renvoyer tout de même la réponse JSON avec HTTP 200.
4. **Sanitisation Zéro Emoji** :
   - Appliquer `sanitizeObject(result)` sur la réponse finale avant `NextResponse.json(sanitized)`.

### 4.2 Spécification du Moteur Déterministe de Repli M3 (`web/src/lib/orientation.ts`)
Créer la fonction exportée `generateDeterministicOrientationM3(answers: any)` :
- **Intérêts & Matières fortes** : Mappés vers les métiers de `TOGO_CAREERS_CATALOG` :
  - *Sciences / Technologies / Maths / Info* -> `dev-web-mobile`, `data-analyst-ia`, `cybersecurite-reseaux`
  - *Santé / SVT* -> `medecin-sante`, `pharmacien-biologiste`, `ingenieur-agronome`
  - *Économie / Gestion / Droit* -> `comptable-auditeur`, `banquier-analyste`, `juriste-affaires`
  - *Arts / Design / Communication* -> `designer-graphique`, `architecte-urbaniste`, `marketing-digital`
- **Budget** : Filtre et assigne les frais d'études réalistes :
  - *Faible* -> Établissements publics (`Université de Lomé (UL)` : `Public / 25 000 - 50 000 FCFA`, `Université de Kara (UK)` : `Public / 25 000 - 50 000 FCFA`)
  - *Moyen* -> Écoles conventionnées (`ESGIS` : `450 000 FCFA / an`, `IAI-Togo` : `500 000 FCFA / an`, `FORMATEC` : `400 000 FCFA / an`)
  - *Élevé* -> Grandes écoles de référence (`EAMAU` : `1 200 000 FCFA / an`, `Lomé Business School` : `1 500 000 FCFA / an`)
- **Profil Psychologique** : Génération des 4 traits dominants, forces, points de vigilance, et résumé synthétique valorisant.

### 4.3 Structure TypeScript Finale du Contrat R2
```ts
export interface PsychologicalProfile {
  dominantTraits: string[];
  strengths: string[];
  weaknesses: string[];
  summary: string;
}

export interface RecommendedCareer {
  title: string;
  matchPercentage: number; // 0 à 100
  description: string;
  salaryRangeCFA: string; // ex: "250 000 - 850 000 FCFA / mois"
  demandInTogo: 'Faible' | 'Moyenne' | 'Forte';
}

export interface RecommendedSchool {
  name: string; // Établissement togolais agréé
  program: string; // Filière d'excellence
  estimatedAnnualCostCFA: string; // Frais annuels en FCFA ou Public
  whyThisSchool: string; // Motivation en lien avec budget et profil
}

export interface OrientationGenerateResponse {
  psychologicalProfile: PsychologicalProfile;
  recommendedCareers: RecommendedCareer[]; // Exactement 3
  recommendedSchools: RecommendedSchool[]; // 1 à 3
  executionMode?: 'groq' | 'fallback_deterministic';
}
```

---

## 5. Verification Method

### 5.1 Protocole de Validation Technique Indépendante

1. **Compilation TypeScript & Next.js** :
   ```bash
   cd d:\ActivEducation\web
   npm run build
   ```
   *Critère de réussite* : Zéro erreur de type TypeScript, validation des routes `/student/orientation` et `/student/orientation/resultats`.

2. **Création du Script de Test Dédié `test-orientation-generate.js`** :
   Un script de test automatisé Node.js doit être fourni (analogue à `test-match.js`) pour valider spécifiquement l'endpoint `/api/orientation/generate` :
   - Tester l'appel avec le payload des 4 catégories :
     ```json
     {
       "answers": {
         "interests": ["Sciences & Nouvelles Technologies", "Ingénierie"],
         "strongSubjects": ["Mathématiques", "Physique-Chimie"],
         "budget": "Moyen",
         "mobility": "Grand Lomé & Région Maritime"
       }
     }
     ```
   - Assertions obligatoires :
     - Statut HTTP 200 (y compris en l'absence de session Supabase).
     - Clés de premier niveau `psychologicalProfile`, `recommendedCareers`, `recommendedSchools` présentes.
     - `recommendedCareers` contient exactement 3 éléments avec `matchPercentage` numérique (>= 60) et mention de `FCFA`.
     - `recommendedSchools` contient entre 1 et 3 écoles avec `name`, `program`, `estimatedAnnualCostCFA`, `whyThisSchool`.
     - Établissements figurant parmi les établissements togolais accrédités MESR / CAMES.
     - **Zéro émoji** sur l'intégralité du JSON (testé via `EMOJI_REGEX.test(rawJson) === false`).
     - Validation de la résilience : test exécuté sans `GROQ_API_KEY` pour prouver le bon fonctionnement du repli déterministe.

3. **Conditions d'Invalidation** :
   - Tout retour de code HTTP 401 ou 500 lors d'un test anonyme ou hors-ligne.
   - Présence d'un seul caractère emoji dans le JSON retourné.
   - Incohérence des salaires (absence de la devise FCFA).
   - Présence d'écoles fictives ou non accréditées au Togo.
