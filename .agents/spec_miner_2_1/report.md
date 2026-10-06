# Rapport de Spécification Détaillée : Module d'Orientation Scolaire & Professionnelle (R1, R2, R3)

**Auteur** : `spec_miner_2_1`  
**Date** : 2026-09-22  
**Projet** : ActivEducation Web Platform (`d:\ActivEducation\web`)  
**Conformité** : `ORIGINAL_REQUEST.md` (§ 2026-09-22T11:31:59Z), `DESIGN.md`, `docs/ORIENTATION.md`

---

## 1. Synthèse Exécutive

Ce document définit les spécifications fonctionnelles, techniques, ergonomiques et de test pour le nouveau module d'**Orientation Scolaire et Professionnelle Gamifiée** d'ActivEducation.
Le module repose sur trois exigences fondamentales (R1, R2, R3) et deux critères d'acceptation stricts :
- **R1** : Interface de passage de test ludique et addictive basée sur le modèle RIASEC (Holland), exploitant des cartes gestuelles à swiper (type Tinder / cartes interactives) propulsées par Framer Motion.
- **R2** : Route Handler Next.js (`/api/match`) connectant l'intelligence artificielle Groq (modèles LLaMA 3.3 70B, LLaMA 3.1 8B, Mixtral 8x7B) avec le persona **AÏDA**, assorti d'un moteur de repli déterministe hors-ligne garantissant le matching vers 3 métiers porteurs et 3 établissements agréés au Togo.
- **R3** : Tableau de bord visuel des résultats affichant le profil psychologique, les 3 métiers et les 3 établissements togolais, appliquant de façon intransigeante la couleur Ambre (`#FAA100`) pour les scores et **ZÉRO EMOJI** dans toute l'interface.
- **Acceptance Criteria** : Compilation propre `npm run build` et script automatisé de test d'API `test-match.js`.

---

## 2. Spécifications Détaillées pour R1 : Interface de Test Ludique (Swiping / QCM)

### 2.1. Mécanique de Swiping (Framer Motion)
L'interface de test est conçue comme un deck de cartes empilées avec gestes fluides de glisser-déposer (swipe) :
1. **Comportement gestuel** :
   - Interaction tactile et à la souris via `motion.div` avec `drag="x"`.
   - Contraintes élastiques : `dragConstraints={{ left: 0, right: 0 }}` avec résistance (`dragElastic={0.7}`).
   - Rotation dynamique en fonction du déplacement horizontal : `rotate = useTransform(x, [-200, 200], [-18, 18])`.
   - Opacité dynamique des indicateurs d'intention incrustés sur la carte :
     - Badge « J'aime / M'intéresse » (vert / bleu `#3133DD`) apparaissant quand `x > 20`.
     - Badge « Passer / Pas pour moi » (gris / rouge doux) apparaissant quand `x < -20`.
   - Seuil de déclenchement : Si `|x| > 100px` ou `|velocity.x| > 400px/s`, la carte est expulsée dans la direction du swipe (`animate={{ x: swipeDirection > 0 ? 500 : -500, opacity: 0 }}`).
2. **Pile de cartes (Card Stack)** :
   - Carte active (Index 0) : `scale: 1`, `y: 0`, `z-index: 30`, pleinement interactive.
   - Carte suivante (Index 1) : `scale: 0.95`, `y: 10px`, `z-index: 20`, opacité 0.85, non cliquable.
   - Troisième carte (Index 2) : `scale: 0.90`, `y: 20px`, `z-index: 10`, opacité 0.60, non cliquable.
   - À chaque swipe, la carte active est retirée du DOM via `<AnimatePresence mode="popLayout">` et la carte suivante effectue une transition spring (`stiffness: 300, damping: 25`).
3. **Contrôles alternatifs / Accessibilité** :
   - Sous la carte, deux boutons principaux et un bouton d'annulation :
     - Bouton « Pas pour moi » (gauche) : Déclenche l'animation de sortie vers la gauche (Score = 1 ou rejet).
     - Bouton « M'intéresse » (droite) : Déclenche l'animation de sortie vers la droite (Score = 5 ou validation).
     - Bouton « Recommencer / Annuler » (icône `RotateCcw`) : Permet de revenir à la question précédente.
   - Mode QCM interactif complémentaire : Grille de 4 ou 5 boutons de Likert rapide (Pas du tout, Peu, Neutre, Beaucoup, Passionnément) pour les utilisateurs préférant un choix gradué sans swipe.

### 2.2. Conception du Questionnaire (Modèle RIASEC / Holland)
Le test s'appuie sur le modèle éprouvé de Holland (RIASEC), standard international et langue pivot d'ActivEducation (`docs/ORIENTATION.md`) :
- **6 Dimensions Psychologiques** :
  1. **Réaliste (R)** : Concret, travail manuel, outils, extérieur, mécanique, installations.
  2. **Investigateur (I)** : Analytique, sciences, mathématiques, logique, recherche de causes, data.
  3. **Artistique (A)** : Créativité, design visuel, imagination, expression libre, narration.
  4. **Social (S)** : Entraide, enseignement, écoute, empathie, travail collaboratif, santé.
  5. **Entreprenant / Entrepreneur (E)** : Leadership, persuasion, négociation, esprit d'initiative, création de projets.
  6. **Conventionnel (C)** : Organisation, rigueur méthodique, gestion de données, respect des procédures.

- **Nombre de questions & calibrage** :
  - **Format nominal gamifié : 12 questions** (exactement 2 questions par dimension RIASEC, entrelacées R-I-A-S-E-C, R-I-A-S-E-C pour éliminer le biais de halo).
  - Durée moyenne de passation : **60 à 90 secondes**.
  - Banque de questions calibrée :
    - *Q1 [Réaliste]* : « J'aime démonter des appareils, comprendre leur fonctionnement mécanique ou réparer du matériel concret. »
    - *Q2 [Investigateur]* : « Résoudre une énigme logique, analyser des données ou comprendre un problème complexe me passionne. »
    - *Q3 [Artistique]* : « J'aime imaginer des concepts visuels, créer du contenu ou concevoir des interfaces originales. »
    - *Q4 [Social]* : « Expliquer une notion difficile à un camarade ou aider quelqu'un à surmonter un obstacle me motive naturellement. »
    - *Q5 [Entreprenant]* : « Prendre la parole pour défendre une idée, convaincre une équipe et lancer un projet m'enthousiasme. »
    - *Q6 [Conventionnel]* : « J'apprécie quand les consignes sont précises, les dossiers ordonnés et les tableaux de chiffres bien structurés. »
    - *Q7 [Réaliste]* : « Je préfère concevoir un objet physique ou travailler sur le terrain plutôt que passer toute ma journée devant un traitement de texte. »
    - *Q8 [Investigateur]* : « Les avancées technologiques, le code informatique et les découvertes scientifiques attirent immédiatement mon attention. »
    - *Q9 [Artistique]* : « Improviser et proposer une approche originale me met plus à l'aise que suivre un protocole rigide. »
    - *Q10 [Social]* : « Travailler au sein d'un collectif uni et veiller à la bonne entente du groupe est essentiel pour moi. »
    - *Q11 [Entreprenant]* : « Négocier, trouver des opportunités et diriger des projets ambitieux me donne de l'énergie. »
    - *Q12 [Conventionnel]* : « Planifier mes tâches étape par étape et vérifier minutieusement les détails m'évite les mauvaises surprises. »

### 2.3. Contraintes de Design & Charte Graphique V2
- **Typographie** : Police **Hanken Grotesque** (déclarée dans `globals.css` via `--font-sans`). Titres en font-weight 700 avec `text-wrap: balance`.
- **Direction Artistique Flat** :
  - Fonds épurés : Canvas froid `#F7F8FB`, surface des cartes `#FFFFFF`.
  - Bordures nettes et précises : `1px solid #E3E5EC` (`border-border-soft`).
  - Ombres subtiles : `0 4px 12px rgba(0,0,0,0.05)` au hover, aucun néon ni lueur artificielle.
- **Couleurs de marque** :
  - Primaire : Bleu Cobalt `#3133DD` (hover `#2829B8`) pour toutes les actions structurantes, boutons actifs et barres de progression de test.
  - Or / Ambre : `#FAA100` (réservé exclusivement à la progression/XP et aux scores de correspondance en R3).
- **Règle absolue ZÉRO EMOJI** :
  - Aucun emoji (🚫 👍 🎓 💡 ⭐ 🚀) nulle part dans le code, les labels, ou les questions.
  - Remplacement systématique par des icônes SVG vectorielles `lucide-react` (`Check`, `X`, `RotateCcw`, `Compass`, `Sparkles`, `Layers`, `ArrowRight`, `ChevronRight`).
- **Composants stricts** :
  - Réutilisation des primitives `Button` (`src/components/ui/Button.tsx`) et `Card` (`src/components/ui/Card.tsx`).

---

## 3. Spécifications Détaillées pour R2 : Logique de Matching IA (Groq / AÏDA)

### 3.1. Spécification de l'Endpoint `/api/match`
- **Méthode** : `POST`
- **Route** : `/api/match`
- **Consommation** : `application/json`
- **Production** : `application/json`

#### Payload de Requête (Entrée) :
```typescript
interface MatchRequestPayload {
  answers: Array<{
    questionId: string;
    category: 'Réaliste' | 'Investigateur' | 'Artistique' | 'Social' | 'Entreprenant' | 'Conventionnel';
    score: number; // 1 (Rejet) à 5 (Adhésion forte)
  }>;
  // Optionnel: scores précalculés par dimension (0 - 100)
  dimensionScores?: Record<string, number>;
  // Optionnel: informations contextuelles de l'étudiant
  studentContext?: {
    schoolLevel?: string; // ex: "Terminale D", "BAC+1"
    city?: string;        // ex: "Lomé", "Kara"
    interests?: string[];
  };
}
```

#### Schéma de Réponse JSON (Sortie) :
```typescript
interface MatchResponsePayload {
  success: boolean;
  profile: {
    dominantTraits: string[]; // ex: ["Investigateur", "Réaliste", "Entreprenant"]
    code: string;             // ex: "IRE"
    title: string;            // ex: "Bâtisseur Technologique & Analyste"
    summary: string;          // Synthèse rédigée par AÏDA (sans emoji)
    scores: {
      Réaliste: number;
      Investigateur: number;
      Artistique: number;
      Social: number;
      Entreprenant: number;
      Conventionnel: number;
    };
  };
  careers: Array<{
    id: string;
    name: string;
    sector: string;
    matchScore: number;       // Score 0 - 100
    description: string;
    averageSalary: string;    // En FCFA (ex: "350 000 - 800 000 FCFA / mois")
    requiredSkills: string[];
    outlook: string;          // Perspectives au Togo / UEMOA
  }>; // Exactement 3 métiers
  institutions: Array<{
    id: string;
    name: string;
    city: string;             // Lomé, Kara, etc.
    accreditation: string;    // ex: "Agrément MESR Togo & Homologation CAMES"
    programs: string[];       // Filières recommandées
    type: string;             // "Public" | "Privé agréé" | "Inter-États"
    matchReason: string;      // Justification personnalisée du choix
  }>; // Exactement 3 établissements
  metadata?: {
    modelUsed: string;
    generatedAt: string;
    executionMode: 'groq' | 'fallback_deterministic';
  };
}
```

### 3.2. Prompt Engineering pour Groq (AÏDA)
- **Fournisseur & Modèles supportés** :
  - Provider : Groq API (`https://api.groq.com/openai/v1/chat/completions`)
  - Clé d'API : `process.env.GROQ_API_KEY`
  - Modèles recommandés par ordre de priorité :
    1. `llama-3.3-70b-versatile` (haute précision analytique et fidélité au format JSON)
    2. `llama-3.1-8b-instant` (vitesse d'inférence < 500ms)
    3. `mixtral-8x7b-32768` (architecture Mixture-of-Experts)
- **Paramètres d'inférence** :
  - `temperature: 0.3` (faible température pour un formatage JSON strict et déterministe)
  - `response_format: { type: "json_object" }` (contrainte JSON native Groq)
  - `max_tokens: 1800`
- **System Prompt & Persona** :
  ```text
  Tu es AÏDA, conseillère d'orientation académique et professionnelle d'élite pour ActivEducation, spécialisée dans le contexte togolais et ouest-africain.
  À partir des scores RIASEC (Réaliste, Investigateur, Artistique, Social, Entreprenant, Conventionnel) et des réponses de l'étudiant :
  1. Établis le profil psychologique RIASEC (traits dominants, code 3 lettres, titre professionnel valorisant et synthèse analytique bienveillante).
  2. Sélectionne EXACTEMENT 3 métiers d'avenir à forte employabilité au Togo et dans l'UEMOA correspondant au profil. Pour chaque métier, précise le salaire moyen mensuel en FCFA, les compétences requises et les perspectives locales.
  3. Sélectionne EXACTEMENT 3 établissements d'enseignement supérieur agréés au Togo (Universités publiques, grandes écoles reconnues par le Ministère de l'Enseignement Supérieur et de la Recherche - MESR Togo et le CAMES).
  
  RÈGLES CRITIQUES ET ABSOLUES :
  - Tu dois répondre EXCLUSIVEMENT sous la forme d'un document JSON valide respectant le schéma fourni.
  - AUCUN EMOJI : L'usage du moindre emoji est formellement interdit dans tous les textes générés (titres, descriptions, compétences).
  - Ancrage togolais réel : Ne propose que des institutions réelles et accréditées au Togo (ex: Université de Lomé, Université de Kara, EAMAU, ESGIS, ESAG-NDE, UCAO-UUT, IPNET, INFA de Tové) et des rémunérations réalistes en Francs CFA (FCFA).
  ```

### 3.3. Ancrage Local : Métiers Porteurs et Établissements Agréés au Togo
La spécification intègre le référentiel authentifié du marché togolais (`seed_careers.sql`, `ORIENTATION.md`) :
- **Métiers porteurs au Togo & Afrique de l'Ouest** :
  1. *Développeur Web & Mobile / Ingénieur Cloud* (Tech & IT — Pôle digital de Lomé, Togocom, Moov Africa, banques UEMOA, startups). Salaire : 250 000 - 850 000 FCFA/mois.
  2. *Data Analyst / Spécialiste IA & Décisionnel* (Finance, Télécoms, Port Autonome de Lomé, cabinets de conseil). Salaire : 300 000 - 900 000 FCFA/mois.
  3. *Ingénieur Génie Civil & BTP* (Infrastructures nationales, voiries, urbanisme, aménagements portuaires PIA). Salaire : 350 000 - 1 200 000 FCFA/mois.
  4. *Ingénieur Agronome & Agro-industriel* (Secteur clé représentant 40% du PIB, mécanisation, export et transformation). Salaire : 250 000 - 750 000 FCFA/mois.
  5. *Comptable & Contrôleur de Gestion* (Place bancaire de Lomé, sièges régionaux Ecobank, Orabank, BOAD). Salaire : 200 000 - 800 000 FCFA/mois.
  6. *Architecte & Urbaniste* (Croissance démographique, aménagement urbain durable de Lomé et Kara). Salaire : 300 000 - 1 100 000 FCFA/mois.
- **Établissements d'Enseignement Supérieur Agréés au Togo** :
  1. **Université de Lomé (UL)** : Établissement public national d'excellence. Écoles de pointe : **ENSI** (École Nationale Supérieure d'Ingénieurs - Génie Civil, Génie Électrique, Génie Mécanique), **FSS** (Faculté des Sciences de la Santé), **FASEG** (Sciences Économiques et de Gestion). Accrédité MESR Togo & CAMES.
  2. **EAMAU (École Africaine des Métiers de l'Architecture et de l'Urbanisme)** : Grande école inter-États (14 pays membres) sise à Lomé. Formations d'excellence en Architecture, Urbanisme et Gestion Urbaine. Reconnue CAMES.
  3. **ESGIS Togo (École Supérieure de Gestion, d'Informatique et des Sciences)** : Établissement privé d'enseignement supérieur agréé MESR Togo, filières Informatique de Gestion, Réseaux et Télécoms, IA & Développement homologuées CAMES.
  4. **ESAG-NDE (École Supérieure d'Administration et de Gestion Notre-Dame de l'Église)** : Institution de référence à Lomé pour l'expertise comptable, la finance, l'audit et la gestion, programmes accrédités CAMES.
  5. **Université de Kara (UK)** : Deuxième université publique du Togo, pôle d'excellence en sciences agronomiques, droit, sciences économiques et de gestion.
  6. **UCAO-UUT (Université Catholique de l'Afrique de l'Ouest - Unité Universitaire au Togo)** : Campus de Lomé, formations d'excellence en sciences de gestion et technologies.
  7. **IPNET Institute of Technology** : Lomé, formation supérieure certifiante en infrastructures systèmes, cybersécurité et génie logiciel.

### 3.4. Stratégie de Résilience et Fallback Déterministe (Mode Démo)
Conformément à l'intitulé de mission `Integrity mode: demo` et pour pallier l'absence ou la révocation temporaire de clé Groq en local/CI :
- Si `GROQ_API_KEY` est indéfinie, vide ou si l'appel Groq échoue (timeout, quota dépassé 429, erreur réseau), la route `/api/match` **ne plante jamais avec une erreur 500**.
- Elle active instantanément un **moteur de repli heuristique déterministe** qui :
  1. Calcule les scores normalisés RIASEC à partir des réponses soumises (`score_dim = (somme - n) / (4n) * 100`).
  2. Identifie les 3 traits dominants de l'étudiant.
  3. Mappe ces traits avec les 3 métiers les plus pertinents de la base togolais avec scores de correspondance (85% à 96%).
  4. Associe les 3 établissements d'enseignement supérieur togolais dispensant les filières correspondantes.
  5. Génère une synthèse de profil rigoureuse, sans le moindre emoji.

---

## 4. Spécifications Détaillées pour R3 : Tableau de Bord des Résultats

### 4.1. Architecture Visuelle et Hiérarchie des Résultats
Dès que les résultats sont renvoyés par `/api/match` (ou que le test s'achève), l'interface bascule de manière animée vers le Dashboard des Résultats :
1. **En-tête de Profil Psychologique** :
   - Badge d'archétype en JetBrains Mono (ex: `PROFIL ISC • INVESTIGATEUR - SOCIAL - CONVENTIONNEL`).
   - Titre du profil en Hanken Grotesque 700 (ex: « Analyste Stratégique & Coordinateur »).
   - Synthèse de personnalité AÏDA dans un conteneur soigné (`bg-surface`, bordure `border-border-soft`).
   - Visualisation des 6 dimensions RIASEC sous forme de barres de progression horizontales ou de jauges avec étiquettes claires.
2. **Section « Vos 3 Métiers Porteurs au Togo »** :
   - 3 cartes au format `Card` flat, présentant chacune :
     - En-tête : Nom du métier + badge du secteur d'activité.
     - **Score de correspondance** : Badge bien visible arborant la couleur **Ambre `#FAA100`** (ex: `95% Match`).
     - Description du métier et opportunités locales au Togo.
     - Rémunération indicative en FCFA avec icône vectorielle `Banknote` ou `Coins`.
     - Liste de badges de compétences requises (`bg-canvas`, bordure fine).
3. **Section « Vos 3 Établissements Agréés au Togo »** :
   - 3 cartes détaillant les établissements d'accueil :
     - Nom complet et ville (Lomé, Kara).
     - Badge d'agrément officiel : `Agrément MESR Togo` ou `Homologué CAMES`.
     - Filières recommandées pour accéder aux métiers ciblés.
     - Motivation du matching rédigée par l'IA.
4. **Boutons d'Action Inférieurs** :
   - Bouton primaire (`#3133DD`) : « Explorer les formations & cours » (lien vers le catalogue).
   - Bouton secondaire : « Repasser le test d'orientation » (réinitialise le questionnaire avec confirmation).

### 4.2. Règle Stricte sur l'Ambre (`#FAA100`)
- La couleur Ambre (`#FAA100`, configurée comme `--color-gold` dans `globals.css`) est **exclusivement réservée** aux :
  - Pourcentages de matching des métiers (`95% Match`, `88% Match`).
  - Barres de progression et jauges de score RIASEC.
  - Badges d'expérience / XP gagnés suite au passage du test (ex: `+200 XP`).
- Elle ne doit **jamais** être utilisée pour des boutons d'action primaire classiques (qui restent `#3133DD`).

### 4.3. Règle Stricte ZÉRO EMOJI
- **Interdiction formelle absolue de tout emoji** dans :
  - Les titres, sous-titres, paragraphes et tooltips.
  - Les options de questions et les labels de boutons.
  - Les retours de texte de l'IA (le prompt AÏDA l'interdit et un filtre de sécurité regex côté frontend/API éliminera tout emoji accidentel `replace(/[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]/gu, '')`).
  - Les icônes de métiers et d'écoles (utiliser `GraduationCap`, `Building2`, `Briefcase`, `TrendingUp`, `CheckCircle2`, `Award`, `Sparkles`, `ChevronRight`).

---

## 5. Critères d'Acceptation et Plan de Test

### 5.1. Vérification de Compilation (`npm run build`)
- **Commande** : `npm run build` dans le répertoire `d:\ActivEducation\web`.
- **Conditions de succès** :
  - Code de sortie : `0`.
  - Zéro erreur TypeScript (`tsc`).
  - Zéro erreur ESLint bloquante.
  - Génération réussie des pages statiques et des routes dynamiques Next.js (y compris `/api/match`).

### 5.2. Spécification du Script de Test Node.js (`test-match.js`)
- **Emplacement du fichier** : `d:\ActivEducation\web\test-match.js`.
- **Exécution** : `node test-match.js`.
- **Scénario de test automatisé** :
  1. Exécute un appel POST vers l'endpoint `/api/match` avec un jeu de données de test simulé (réponses Likert orientées Tech & Investigation : Investigateur = 5, Réaliste = 4, etc.).
  2. Valide le code de statut HTTP : `200 OK`.
  3. Valide le Content-Type : `application/json`.
  4. Valide l'intégrité de la structure JSON retournée :
     - `success === true`.
     - `profile` contient `dominantTraits` (array de strings non vide), `code` (string), `summary` (string d'au moins 20 caractères).
     - `careers` est un array de **longueur exactement 3**.
     - Chaque métier de `careers` possède `name`, `sector`, `matchScore` (nombre entre 0 et 100), `averageSalary` (mentionnant "FCFA"), et `requiredSkills` (array non vide).
     - `institutions` est un array de **longueur exactement 3**.
     - Chaque institution de `institutions` possède `name`, `city` (mentionnant "Lomé", "Kara" ou Togo), `accreditation` (mentionnant "MESR" ou "CAMES"), et `programs` (array non vide).
     - **Test anti-emoji** : Vérification par expression régulière qu'aucun champ textuel du JSON ne contient de caractère emoji Unicode.
  5. Fournit une trace lisible en console (stdout) attestant de la validation de chaque assertion.
  6. Code de sortie : `0` en cas de réussite totale, `1` en cas d'échec d'une assertion.

---

## 6. Registre des Fonctionnalités Découvertes (Features Discovered)

| # | Catégorie | Fonctionnalité | Description | Entrées | Sorties | Comportement d'Erreur | Découvert Via |
|---|-----------|----------------|-------------|---------|---------|-----------------------|---------------|
| 1 | Test R1 | Swipe Deck Framer Motion | Deck de cartes empilées avec gestes drag 'x' et rotation proportionnelle | Gestes tactiles / drag souris, clics boutons | Carte expulsée, transition de carte suivante | Si geste annulé sous le seuil, retour élastique au centre | ORIGINAL_REQUEST §R1, DESIGN.md §6 |
| 2 | Test R1 | Questionnaire RIASEC 12 items | 12 questions calibrées équitablement (2 par dimension R, I, A, S, E, C) entrelacées | Clic Like/Dislike ou Likert 1-5 | Tableau d'objets `{ questionId, category, score }` | Si question sautée, bouton désactivé tant qu'aucun choix n'est fait | 023_riasec_full_questionnaire.py, docs/ORIENTATION.md |
| 3 | Test R1 | DA V2 & Hanken Grotesque | Typographie Hanken Grotesque, surfaces `#FFFFFF`, canvas `#F7F8FB`, bordures `#E3E5EC` | Classes CSS / tokens Tailwind v4 | Rendu visuel flat rigoureux | Rejet d'Inter, Roboto ou ombres néon | DESIGN.md, globals.css |
| 4 | API R2 | Route Handler `/api/match` | Endpoint POST Next.js App Router traitant les réponses du test | JSON `{ answers, dimensionScores?, studentContext? }` | JSON `{ success, profile, careers, institutions }` | 400 si payload vide, fallback 200 déterministe si Groq offline | ORIGINAL_REQUEST §R2 |
| 5 | API R2 | Groq LLM Provider | Prompt AÏDA interrogeant Groq (`llama-3.3-70b-versatile` ou `llama-3.1-8b-instant`) | System prompt + scores étudiant | JSON structuré pur | Repli automatique sur moteur heuristique local si erreur Groq | backend/app/services/llm/groq_provider.py |
| 6 | API R2 | Référentiel Togo Écoles & Métiers | Base de données locale de métiers à fort impact et d'écoles agréées MESR/CAMES au Togo | Codes RIASEC dominants | 3 métiers porteurs + 3 établissements agréés | Si profil atypique, sélection des métiers les plus polyvalents | seed_careers.sql, docs/ORIENTATION.md |
| 7 | Dashboard R3 | Affichage Visuel Profil & Métiers | Dashboard avec carte d'archétype, 3 cartes métiers détaillées et 3 cartes écoles | Objet résultat de `/api/match` | Éléments UI organisés en grilles asymétriques | État de chargement skeleton si attente API | ORIGINAL_REQUEST §R3, DESIGN.md §5 |
| 8 | Dashboard R3 | Accent Ambre `#FAA100` | Utilisation stricte de l'Ambre pour les scores de matching et progression | Score de correspondance (0-100%) | Badges et jauges stylisés en `#FAA100` | Interdiction d'appliquer `#FAA100` sur CTA principal | ORIGINAL_REQUEST §R3, DESIGN.md §2 |
| 9 | Dashboard R3 | Zéro Emoji Strict | Absence totale de glyphes emojis sur toute l'interface | Contenu textuel et icônes | Icônes Lucide SVG conformes uniquement | Filtre regex assainissant toute chaîne avant injection UI | ORIGINAL_REQUEST §R3, DESIGN.md §7 |
| 10 | QA / Test | Compilation Next.js | Validation de compilation TypeScript + CSS sans régression | Code source `src/` | Build assets `.next` | Échec build si type invalide ou import cassé | ORIGINAL_REQUEST Acceptance Criteria |
| 11 | QA / Test | Script `test-match.js` | Script Node.js de test automatisé validant la conformité de l'API `/api/match` | Données simulées d'un élève | Validation de schéma, assertions Togo, sortie code 0 | Sortie code 1 avec log d'erreur précis si validation KO | ORIGINAL_REQUEST Acceptance Criteria |

---

## 7. Cas Limites et Edge Cases

| # | Fonctionnalité | Entrée / Contexte | Comportement Attendu / Observé |
|---|----------------|-------------------|--------------------------------|
| 1 | Swiping Framer Motion | Glissement incomplet (< 100px) et faible vélocité | La carte subit un rappel élastique (spring physics) et revient exactement au centre sans enregistrer de réponse. |
| 2 | Swiping Framer Motion | Rafale de swipes très rapides (double-click ou drag frénétique) | Les événements de drag sont verrouillés pendant l'animation de sortie de la carte active (`isAnimating` flag) pour éviter les sauts de questions. |
| 3 | Questionnaire RIASEC | Réponses uniformes minimales (tout à 1 / « Pas pour moi ») | Le score de chaque dimension est normalisé à 0% ; le moteur renvoie un profil exploratoire généraliste avec les métiers de repli les plus porteurs au Togo sans crash. |
| 4 | Questionnaire RIASEC | Réponses uniformes maximales (tout à 5 / « J'adore ») | Toutes les dimensions sont à 100% ; le moteur sélectionne les 3 traits avec priorité déterministe et renvoie une alerte bienveillante suggérant des intérêts très variés. |
| 5 | Route `/api/match` | Payload JSON malformé ou vide `{}` | Retourne une réponse HTTP 400 Bad Request avec message d'erreur clair : `{"error": "Réponses de test invalides ou manquantes"}`. |
| 6 | Route `/api/match` | Clé `GROQ_API_KEY` absente ou invalide dans l'environnement | Basculement transparent vers le moteur déterministe local ; renvoie un statut 200 avec les données togolaises valides et `executionMode: "fallback_deterministic"`. |
| 7 | Route `/api/match` | API Groq renvoie une erreur 429 (Rate Limit) ou 503 (Overload) | Interception de l'exception sans délai, log d'avertissement, et renvoi immédiat de la réponse calculée par le fallback local. |
| 8 | Route `/api/match` | L'IA tente d'insérer un emoji dans sa réponse JSON | Le parseur JSON applique un filtre de nettoyage regex supprimant tout emoji avant de renvoyer le payload au client. |
| 9 | Dashboard R3 | Rendu sur petit écran mobile (360px - 400px) | Disposition responsive : cartes en pile verticale, suppression des marges superflues, maintien de `min-height: 100dvh`. |
| 10 | Script `test-match.js` | Serveur web local éteint lors du lancement du script | Le script teste soit le handler interne directement, soit tente de contacter l'URL locale et affiche un message clair avec instructions de démarrage. |

---

## 8. Conclusion et Recommandations pour l'Implémentation

1. **Installation requise** : Installer `framer-motion` (ou package compatible React 19) dans `web/package.json`.
2. **Architecture des fichiers recommandée** :
   - `web/src/types/orientation.ts` : Types TypeScript complets (Question, RIASEC Scores, MatchResponse).
   - `web/src/data/orientationQuestions.ts` : Les 12 questions calibrées et métadonnées RIASEC.
   - `web/src/data/togoData.ts` : Référentiel authentique des métiers porteurs et universités/écoles agréées au Togo pour le fallback.
   - `web/src/app/api/match/route.ts` : Route Handler Next.js avec appel Groq et fallback déterministe.
   - `web/src/components/orientation/SwipeTestDeck.tsx` : Composant de swiping avec Framer Motion.
   - `web/src/components/orientation/OrientationResultsDashboard.tsx` : Dashboard des résultats avec ambre `#FAA100` et zéro emoji.
   - `web/src/app/orientation/page.tsx` : Page principale du module d'orientation liant test et résultats.
   - `web/test-match.js` : Script de test Node.js automatisé.
