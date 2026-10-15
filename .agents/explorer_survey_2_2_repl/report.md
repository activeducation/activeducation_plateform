# Rapport d'Investigation : Module d'Orientation Scolaire — Route Handler `/api/match` & `test-match.js`

**Auteur** : `explorer_survey_2_2_repl`  
**Date** : 22 Septembre 2026  
**Statut** : Complété (Investigation en lecture seule)  
**Cible** : `web/src/app/api/match/route.ts` et `web/test-match.js`

---

## Synthèse Exécutive

Dans le cadre du sous-jalon 2.2 (`ORIGINAL_REQUEST.md`, section `## 2026-09-22T11:31:59Z`), le module d'orientation scolaire requiert :
1. La création d'un **Route Handler Next.js** (`/api/match`) capable de convertir les réponses ou scores d'un étudiant en un profil psychologique, 3 métiers porteurs et 3 établissements agréés au Togo.
2. L'interrogation fluide de l'**API Groq** avec un **mode de repli déterministe hors-ligne/démo** lorsque `GROQ_API_KEY` est absent ou indisponible.
3. Un script de validation autonome **`test-match.js`** dans `web/` vérifiant le statut HTTP 200, la conformité stricte du schéma JSON, la présence de vrais établissements togolais accrédités MESR, et l'**absence totale d'emojis**.

---

## 1. Route Handler Next.js (`/api/match`) dans `web/src/app/api/match/route.ts`

### 1.1 Format des Données d'Entrée (`Request Body`)

L'interface de test gamifiée (R1 — cartes à swiper ou QCM) peut émettre soit des réponses unitaires par question, soit des scores agrégés par dimension. Pour garantir une interopérabilité maximale entre le composant frontend et le script `test-match.js`, le Route Handler doit accepter une charge utile flexible :

```typescript
export interface MatchRequestBody {
  // Format 1 : Réponses directes (ex: QCM Likert 1-5 ou choix par question)
  answers?: Record<string, number | string>;
  responses?: Record<string, number | string>;

  // Format 2 : Scores RIASEC pré-agrégés (0 à 100)
  scores?: {
    R?: number; // Réaliste
    I?: number; // Investigateur
    A?: number; // Artistique
    S?: number; // Social
    E?: number; // Entrepreneur
    C?: number; // Conventionnel
    [key: string]: number | undefined;
  };

  // Métadonnées optionnelles de l'étudiant
  studentLevel?: string; // ex: "Terminale", "BAC+1"
  serieBac?: string;     // ex: "C", "D", "E", "A4", "F4"
}
```

#### Logique de normalisation dans le handler :
1. Si `body.scores` est fourni, l'extraire et normaliser les clés (`R` -> `Réaliste`, `I` -> `Investigateur`, etc.).
2. Si `body.answers` ou `body.responses` est fourni (ex: `{ "q1": 5, "q2": 4, ... }`), accumuler les points par dimension selon la cartographie des questions du test.
3. Si le corps est vide ou incomplet, appliquer des valeurs par défaut équilibrées pour éviter toute exception non gérée.

---

### 1.2 Modalités d'Interrogation de l'API Groq

#### Dépendances : Direct `fetch` (Recommandé)
- L'inspection de `web/package.json` montre que `groq-sdk` n'est pas installé dans le projet web.
- L'API Groq est **100 % compatible OpenAI** (`https://api.groq.com/openai/v1/chat/completions`).
- Next.js (App Router / Node 18+) intègre nativement l'API standard `fetch`.
- Il est donc optimal d'utiliser un appel direct `fetch` avec `Content-Type: application/json` et `Authorization: Bearer ${GROQ_API_KEY}`, évitant ainsi d'ajouter des dépendances npm superflues.

#### Modèle Groq :
- Dans `backend/tests/test_tutor_foundations.py` (lignes 236-240), les anciens modèles `llama-3.1-8b-instant` et `mixtral-8x7b-32768` sont documentés comme retirés/dépréciés chez Groq.
- Le modèle recommandé pour Groq en production est `llama-3.3-70b-versatile` (ou `llama3-70b-8192`), avec possibilité de surcharge via la variable d'environnement `GROQ_MODEL` :
  ```typescript
  const GROQ_MODEL = process.env.GROQ_MODEL || "llama-3.3-70b-versatile";
  ```

#### Configuration du Prompt et Mode JSON :
- Activer `response_format: { type: "json_object" }` sur l'appel Groq pour forcer une sortie JSON pure.
- **Consigne système stricte** :
  - Identité : « AÏDA, conseillère experte d'orientation pour ActivEducation au Togo ».
  - Interdiction stricte : **Zéro emoji** (aucun caractère unicode d'émoticône, pictogramme ou symbole décoratif).
  - Contrainte territoriale : Sélectionner exclusivement parmi les métiers porteurs au Togo et les universités/écoles supérieures **agréées par le Ministère de l'Enseignement Supérieur et de la Recherche (MESR) du Togo**.

---

### 1.3 Gestion de `GROQ_API_KEY` et Moteur de Repli Déterministe

Le mode démo/test sans connexion ou sans clé d'API valide est une exigence essentielle :
1. **Détection préalable** : Si `!process.env.GROQ_API_KEY` ou si la clé est vide/blanche (`"dummy"`, `"test"`), basculer immédiatement sur le repli sans émettre d'appel réseau inutile.
2. **Tolérance aux pannes réseau** : Si l'appel Groq échoue (erreur réseau, code HTTP 401, 404, 429, timeout), intercepter l'erreur dans un bloc `try / catch` et enclencher le repli déterministe.
3. **Moteur de repli déterministe** :
   - Calcule les traits dominants (ex: Investigateur > Entrepreneur > Réaliste).
   - Sélectionne le profil psychologique correspondant parmi les profils canoniques RIASEC.
   - Extrait exactement **3 métiers porteurs** pertinents parmi les données réelles du catalogue (`seed_careers.sql`), par exemple pour un profil technologique :
     - Développeur Web/Mobile (`Technologie & IT`, demande: Élevée)
     - Data Analyst / Scientifique des Données (`Technologie & IT`, demande: Élevée)
     - Ingénieur Civil / BTP (`Ingénierie & BTP`, demande: Élevée)
   - Extrait exactement **3 établissements agréés** au Togo dispensant ces filières d'après la liste officielle MESR :
     - Université de Lomé (UL) - École Nationale Supérieure d'Ingénieurs (ENSI)
     - Institut Africain d'Informatique (IAI-Togo)
     - École Supérieure de Gestion, d'Informatique et des Sciences (ESGIS)
   - Retourne une réponse HTTP 200 avec le JSON complet.

---

### 1.4 Schéma JSON Exact Attendu en Sortie

Conformément à `ORIGINAL_REQUEST.md` (R2 & R3) et au Design System (`DESIGN.md`), la réponse doit comporter les 3 blocs principaux : `profile`, `careers`, `institutions`.

```json
{
  "profile": {
    "code": "IER",
    "title": "Profil Innovateur et Technologique (Investigateur / Entrepreneur / Réaliste)",
    "description": "Forte appétence pour l'analyse méthodique, la résolution de problèmes concrets et la conception de projets innovants adaptés au contexte sous-régional.",
    "dominantTraits": [
      { "trait": "Investigateur", "score": 90 },
      { "trait": "Entrepreneur", "score": 82 },
      { "trait": "Réaliste", "score": 75 }
    ],
    "strengths": [
      "Rigueur analytique et pensée logique",
      "Autonomie dans la résolution de problèmes techniques",
      "Capacité à transformer une idée en prototype fonctionnel"
    ],
    "advice": "Privilégier les cursus d'ingénierie logicielle ou de sciences appliquées avec une forte composante pratique et des opportunités d'alternance."
  },
  "careers": [
    {
      "id": "dev-web-mobile",
      "title": "Développeur Web/Mobile",
      "sector": "Technologie & IT",
      "matchScore": 95,
      "growthTrend": "En très forte croissance",
      "jobDemand": "Élevée",
      "salaryRange": "150 000 - 800 000 FCFA / mois",
      "description": "Conçoit et développe des applications web et mobiles répondant aux besoins de digitalisation des entreprises et des startups locales.",
      "requiredSkills": [
        "JavaScript / TypeScript",
        "Python",
        "Bases de données SQL / NoSQL",
        "Architecture logicielle",
        "Git & CI/CD"
      ]
    },
    {
      "id": "data-analyst",
      "title": "Data Analyst / Scientifique des Données",
      "sector": "Technologie & IT",
      "matchScore": 88,
      "growthTrend": "En très forte croissance",
      "jobDemand": "Élevée",
      "salaryRange": "200 000 - 900 000 FCFA / mois",
      "description": "Collecte, modélise et valorise les flux de données pour optimiser la prise de décision dans les secteurs bancaires, télécoms et logistiques.",
      "requiredSkills": [
        "SQL avancé",
        "Python / R",
        "Statistiques inférentielles",
        "Power BI / Tableau",
        "Bases du Machine Learning"
      ]
    },
    {
      "id": "ingenieur-btp",
      "title": "Ingénieur Civil / BTP",
      "sector": "Ingénierie & BTP",
      "matchScore": 82,
      "growthTrend": "En croissance soutenue",
      "jobDemand": "Élevée",
      "salaryRange": "250 000 - 1 200 000 FCFA / mois",
      "description": "Supervise la conception et la réalisation technique des infrastructures civiles, routes et constructions durables au Togo.",
      "requiredSkills": [
        "Calcul de structures",
        "Logiciels CAO/DAO (AutoCAD, Revit)",
        "Gestion de chantier",
        "Résistance des matériaux"
      ]
    }
  ],
  "institutions": [
    {
      "id": "ul-ensi",
      "name": "Université de Lomé (UL) - École Nationale Supérieure d'Ingénieurs (ENSI)",
      "type": "Université Publique",
      "city": "Lomé",
      "status": "Agréée MESR",
      "programs": [
        "Génie Informatique & Télécoms",
        "Génie Civil",
        "Génie Mécanique"
      ],
      "admissionLevel": "BAC Scientifique (C, D, E) sur concours",
      "website": "https://univ-lome.tg"
    },
    {
      "id": "iai-togo",
      "name": "Institut Africain d'Informatique (IAI-Togo)",
      "type": "Institution Publique Inter-États",
      "city": "Lomé",
      "status": "Agréée MESR / CAMES",
      "programs": [
        "Ingénierie des Systèmes d'Information",
        "Génie Logiciel",
        "Administration Réseaux"
      ],
      "admissionLevel": "BAC Scientifique sur concours",
      "website": "https://iai-togo.tg"
    },
    {
      "id": "esgis-togo",
      "name": "École Supérieure de Gestion, d'Informatique et des Sciences (ESGIS)",
      "type": "Grande École Privée Agréée",
      "city": "Lomé",
      "status": "Agréée MESR / CAMES",
      "programs": [
        "Licence & Master Informatique et Réseaux",
        "Management des Systèmes d'Information",
        "Sécurité Informatique"
      ],
      "admissionLevel": "BAC sur étude de dossier",
      "website": "https://esgis.org"
    }
  ]
}
```

---

## 2. Exigences pour `test-match.js`

### 2.1 Emplacement
- **Fichier** : `d:\ActivEducation\web\test-match.js`
- Exécutable directement avec Node.js : `node test-match.js`

### 2.2 Modalité de Test de `/api/match`
Le script doit pouvoir être exécuté dans les deux contextes suivants :
1. **Serveur en cours d'exécution** : Le script interroge par défaut `http://localhost:3000/api/match` (avec prise en charge de `PORT` ou `TEST_URL`).
2. **Serveur non démarré (autonome)** : Si `fetch` échoue avec `ECONNREFUSED` sur le port 3000, le script peut :
   - Soit démarrer temporairement le serveur Next.js en arrière-plan via `child_process.spawn('npm', ['run', 'dev'])` ou tester directement le module de logique de matching ;
   - Soit lever une explication claire et précise invitant à lancer `npm run dev` ou `npm run start` avant le test.
3. Pour une robustesse maximale en CI/CD sans dépendance de serveur web complexe, `test-match.js` peut importer la fonction logique pure ou tester l'endpoint HTTP actif.

### 2.3 Assertions Obligatoires

Le script `test-match.js` doit valider les 7 critères suivants à l'aide de `node:assert` :

| N° | Assertion | Condition / Règle de validation |
|---|---|---|
| 1 | **Code HTTP 200** | `res.status === 200` |
| 2 | **Format JSON Valide** | `res.headers.get("content-type")` contient `application/json`, parsing `res.json()` réussi |
| 3 | **Structure du Profil** | `data.profile` est un objet non nul.<br>`data.profile.code` est une chaîne de 2-4 lettres majuscules.<br>`data.profile.title` et `description` sont des chaînes non vides.<br>`data.profile.dominantTraits` est un tableau de longueur >= 3.<br>`data.profile.strengths` est un tableau de chaînes.<br>`data.profile.advice` est une chaîne non vide. |
| 4 | **Carrières (Longueur = 3)** | `Array.isArray(data.careers)` et `data.careers.length === 3`.<br>Chaque carrière contient `title`, `sector`, `matchScore` (0-100), `jobDemand` / `growthTrend`, `requiredSkills` (tableau non vide), `description`. |
| 5 | **Établissements Togolais (Longueur = 3)** | `Array.isArray(data.institutions)` et `data.institutions.length === 3`.<br>Chaque établissement comporte `name`, `city` (au Togo), `status` (agréé MESR), `programs` (tableau). |
| 6 | **Noms d'Établissements Réels et Agréés** | Vérification que chaque établissement correspond à un nom officiel togolais (ex: Université de Lomé, IAI-Togo, ESGIS, ESAG-NDE, FORMATEC, Université de Kara, EAMAU, INFA-Tové, UCAO-UUT). |
| 7 | **Absence Totale d'Emojis (Zéro Emoji)** | Analyse de la chaîne sérialisée `JSON.stringify(data)` contre l'expression régulière Unicode :<br>`const EMOJI_REGEX = /[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{1FA70}-\u{1FAFF}]/u;`<br>Assertion : `assert.strictEqual(EMOJI_REGEX.test(jsonString), false)`. |

---

## 3. Référentiel des Établissements et Métiers au Togo dans le Dépôt

Le dépôt ActivEducation dispose déjà d'un socle de données très précis et vérifié :

### 3.1 Métiers Porteurs (`backend/database/seed_careers.sql`)
Le fichier contient 16 carrières réelles avec leurs métriques d'employabilité et salaires moyens en FCFA :
1. **Développeur Web/Mobile** (`Technologie & IT`, demande: `high`, tendance: `growing`, salaire: 350 000 FCFA, écoles: Université de Lomé - ENSI, ESAG-NDE, IPNET Institute, ESGIS).
2. **Data Analyst / Scientifique des Données** (`Technologie & IT`, demande: `high`, tendance: `growing`, salaire: 400 000 FCFA, écoles: Université de Lomé - Maths/Info, ENSI, CERSA).
3. **Médecin** (`Santé`, demande: `high`, tendance: `growing`, salaire: 600 000 FCFA, écoles: Faculté des Sciences de la Santé - UL).
4. **Pharmacien** (`Santé`, demande: `medium`, tendance: `stable`, salaire: 500 000 FCFA, écoles: FSS - Université de Lomé).
5. **Enseignant** (`Éducation`, demande: `high`, tendance: `stable`, salaire: 180 000 FCFA, écoles: ENS Atakpamé, Université de Lomé).
6. **Comptable** (`Finance & Banque`, demande: `high`, tendance: `stable`, salaire: 250 000 FCFA, écoles: ESAG-NDE, UCAO, Université de Lomé - FASEG, ESGIS).
7. **Agent Bancaire** (`Finance & Banque`, demande: `medium`, tendance: `stable`, salaire: 350 000 FCFA, banques: Ecobank, Orabank, Coris Bank).
8. **Commercial / Chef des Ventes** (`Commerce & Entrepreneuriat`, demande: `high`, tendance: `growing`, salaire: 250 000 FCFA).
9. **Entrepreneur / Chef d'Entreprise** (`Commerce & Entrepreneuriat`, demande: `high`, incubateurs: Woelab, CUBE, FAIEJ).
10. **Ingénieur Civil / BTP** (`Ingénierie & BTP`, demande: `high`, tendance: `growing`, salaire: 500 000 FCFA, écoles: ENSI - Université de Lomé, FORMATEC).
11. **Architecte** (`Ingénierie & BTP`, demande: `medium`, tendance: `growing`, salaire: 450 000 FCFA, écoles: EAMAU Lomé).
12. **Ingénieur Agronome** (`Agriculture & Environnement`, demande: `high`, tendance: `growing`, salaire: 350 000 FCFA, écoles: ESA - Université de Lomé, INFA de Tové).
13. **Designer Graphique** (`Création & Médias`, demande: `high`, tendance: `growing`, salaire: 200 000 FCFA, écoles: IBTC).
14. **Journaliste** (`Création & Médias`, demande: `medium`, tendance: `stable`, salaire: 180 000 FCFA, écoles: ISICA, Université de Lomé).
15. **Avocat** (`Droit & Administration`, demande: `medium`, tendance: `stable`, salaire: 500 000 FCFA, écoles: Faculté de Droit - Université de Lomé).
16. **Responsable Ressources Humaines** (`Droit & Administration`, demande: `medium`, tendance: `growing`, salaire: 300 000 FCFA, écoles: FASEG, ESAG-NDE, UCAO).

### 3.2 Établissements Agréés Officiels MESR (`docs/reference_mesr_2026_2027.csv`)
Le fichier `docs/reference_mesr_2026_2027.csv` répertorie les **111 établissements officiels agréés** (13 publics, 98 privés) par le Ministère de l'Enseignement Supérieur et de la Recherche (MESR) du Togo :
- **Établissements Publics de Référence** :
  - `Université de Lomé (UL)` (Lomé)
  - `Université de Kara (UK)` (Kara)
  - `Institut Africain d'Informatique (IAI-Togo)` (Lomé)
  - `Ecole Normale Supérieure d'Atakpamé (ENS-Atakpamé)` (Atakpamé)
  - `École Nationale des Auxiliaires Médicaux (ENAM)` (Lomé)
  - `Centre Régional de Formation pour l'Entretien Routier (CERFER)` (Lomé)
  - `Institut National de Formation Agricole de Tové (INFA-Tové)` (Tové)
  - `Ecole Africaine des Métiers de l'Architecture et de l'Urbanisme (EAMAU)` (Lomé)
  - `Centre de Formation aux Métiers de l'Industrie (CFMI)` (Lomé)
  - `Ecole Nationale Polytechnique (ENP)` (Lomé)
- **Établissements Privés Agréés Majeurs** :
  - `Ecole Supérieure d'Administration et de Gestion Notre Dame de l'Eglise (ESAG-NDE)` (Lomé)
  - `Ecole Supérieure de Gestion, d'Informatique et des Sciences (ESGIS)` (Lomé)
  - `Université Catholique de l'Afrique de l'Ouest-Unité universitaire du Togo (UCAO-UUT)` (Lomé)
  - `FORMATEC` (Lomé)
  - `Lomé Business School (LBS)` (Lomé)
  - `Institut de technologie IPNET IT` (Lomé)
  - `Carrefour Informatique et Bureautique - Institut des Nouvelles Technologies Appliquées (CIB-INTA)` (Lomé et Kara)
  - `Ecole Supérieure des Affaires (ESA-Lomé et Kara)` (Lomé et Kara)
  - `Institut de Formation aux Normes et Technologies de l'Informatique (IFNTI-Sokodé)` (Sokodé)
  - `Institut Supérieur de Droit et d'Interprétariat (ISDI)` (Lomé)

### 3.3 Règles de Validation et Déterminisme (`docs/ORIENTATION.md` & `docs/AUDIT_IMPORT_ETABLISSEMENTS.md`)
- `docs/AUDIT_IMPORT_ETABLISSEMENTS.md` proscrit formellement les établissements fictifs non agréés (ex: ISDME, ESIM, IFMI, ISSIC, ESSAM, etc.).
- `docs/ORIENTATION.md` prescrit l'explicabilité et le déterminisme strict :
  - Jamais de `random.shuffle()` ou d'aléatoire non reproductible.
  - Départage par : `job_demand` (high > medium > low), puis salaire moyen, puis nom.

---

## 4. Recommandations pour l'Implémentation (Prochaines Étapes)

1. **Création d'un module d'orientation partagé** (`web/src/lib/orientation.ts`) :
   - Contenant le catalogue typé des carrières porteurs et des établissements MESR.
   - Contenant l'algorithme déterministe de calcul du profil RIASEC et du matching.
2. **Implémentation de `web/src/app/api/match/route.ts`** :
   - Importation du module `orientation.ts`.
   - Gestion gracieuse de l'appel Groq avec fallback déterministe immédiat.
   - Validation stricte de l'absence d'emojis avant sérialisation JSON.
3. **Implémentation de `web/test-match.js`** :
   - Test d'appel réseau vers l'API ou fallback logique direct si le serveur n'est pas actif.
   - Validation des 7 assertions spécifiées.
