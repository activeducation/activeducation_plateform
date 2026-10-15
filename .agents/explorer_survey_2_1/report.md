# Rapport d'Investigation Préparatoire : Module d'Orientation Scolaire ActivEducation Web

**Auteur** : `explorer_survey_2_1`  
**Date** : 2026-09-22  
**Statut** : Terminé  
**Cible** : `d:\ActivEducation\web`  

---

## 1. Synthèse Exécutive

Dans le cadre de l'extension de la plateforme **ActivEducation Web** pour le module d'Orientation Scolaire (Test gamifié Tinder-like/QCM, Matching IA Groq `/api/match`, et Dashboard de résultats des métiers/écoles au Togo), cette investigation a analysé en détail la pile technique, le respect de la charte graphique DA V2, les composants d'interface existants et l'architecture des routes.

### Points Clés Découverts :
1. **Packages UI & Motion** : `lucide-react` (^1.47.0) et `tailwindcss` (v4) sont installés et opérationnels. **`framer-motion` n'est PAS installé** dans `package.json`. Avec `react@19.2.8` et `next@16.3.5`, l'installation de `motion` / `framer-motion` ou une implémentation gestuelle optimisée doit être intégrée rigoureusement.
2. **Direction Artistique V2 (DA V2)** : La charte V2 supplante les anciennes directives de `DESIGN.md` (Sora/Outfit). Elle impose universellement la police **Hanken Grotesque**, la couleur primaire électrique **`#3133DD`**, l'ambre **`#FAA100`** pour les scores/progression/gamification, un style **flat design** (bordures discrètes `#E3E5EC`, ombres légères au hover), et l'**interdiction absolue de tout emoji**.
3. **Composants UI (`src/components/ui`)** : `Button` et `Input` sont immédiatement réutilisables. `Card` nécessite un ajustement de typage (`variant` n'est pas déclaré dans `CardProps` bien qu'utilisé dans les pages) et servira de base de conteneur visuel pour le composant `SwipeCard`.
4. **Organisation des Routes** : Création recommandée d'une route dédiée **`/orientation`** (`src/app/orientation/page.tsx`), adossée au Route Handler **`/api/match`** (`src/app/api/match/route.ts`), avec un point d'accès mis en avant dans la `Navbar` et le Hero de la page d'accueil (`/`).

---

## 2. Analyse Détaillée des 4 Questions

### Question 1 : Packages UI installés, Framer Motion, Lucide, Tailwind v4 et Typographie

#### 1.1 Inventaire des Dépendances (`web/package.json`)
```json
{
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
}
```

- **Framer Motion** : **Non installé**.
  - Absent de `dependencies` et `devDependencies`.
  - Le répertoire `node_modules/framer-motion` et `node_modules/motion` n'existe pas.
  - *Recommandation d'implémentation* : Le projet utilise React 19. Pour respecter le requirement R1 (*« utilisant Framer Motion ou similaire »*), installer `framer-motion@latest` / `motion` ou mettre en place un hook gestuel fluide (pointer/touch events avec physique spring CSS).
- **Lucide React** : **Installé (`^1.47.0`)**.
  - Omniprésent dans `Navbar.tsx`, `CourseCatalog.tsx`, et `ProgressionDashboard.tsx`.
  - C'est le vecteur exclusif d'iconographie, garantissant la règle stricte **« sans le moindre emoji »**.
- **Tailwind CSS v4** :
  - Utilise la nouvelle architecture Tailwind v4 (`@tailwindcss/postcss: ^4`, `tailwindcss: ^4`).
  - Aucun fichier `tailwind.config.js` ou `tailwind.config.ts`.
  - La configuration se fait intégralement par variables de thème CSS via `@theme` dans `src/app/globals.css`.
- **Typographie (Hanken Grotesque vs Sora/Outfit)** :
  - Dans `DESIGN.md` historique (avril 2026), le système prévoyait Sora (display) et Outfit (body).
  - Cependant, dans `src/app/globals.css` et dans le reste de l'écosystème ActivEducation (applications Flutter et Landing page), **Hanken Grotesque** est l'unique police officielle du design system :
    ```css
    @import url('https://fonts.googleapis.com/css2?family=Hanken+Grotesque:ital,wght@0,100..900;1,100..900&display=swap');
    ...
    --font-sans: "Hanken Grotesque", system-ui, sans-serif;
    ```
  - Le body dans `src/app/layout.tsx` porte `className="antialiased flex flex-col font-sans"`.
  - Les classes `font-display` et `font-mono` aperçues dans certains composants existants sont des résidus non définis dans Tailwind v4 ; tout le rendu typographique effectif s'appuie sur Hanken Grotesque.

---

### Question 2 : Spécifications de la Charte DA V2

La Direction Artistique V2 (DA V2) est le référentiel de design consolidé dans tout le projet (Flutter app `app_colors.dart`, Landing page `landing/index.html`, et `globals.css`).

#### 2.1 Piliers de la DA V2
1. **Couleur Primaire : `#3133DD`** (Bleu Roi / Indigo Électrique)
   - Hover : `#2829B8`
   - Surface primaire : `#E1E0FF`
   - Réservée aux actions principales, boutons CTA, indicateurs d'état actif, icônes structurelles.
2. **Couleur Ambre / Gamification : `#FAA100`** (Orange Vif / Ambre Gamifié)
   - Réservée aux mécaniques de score, progression XP, flammes de streak, badges, et **scores de correspondance métier/école**.
   - Règle stricte de séparation : L'or/ambre ne doit jamais être utilisé sur les boutons de navigation standard, et le bleu ne doit pas servir de jauge de score.
3. **Surfaces & Flat Design** :
   - Fond d'écran général (Canvas) : `#F7F8FB` (ou `#FBF8FF`).
   - Fond des cartes (Surface) : `#FFFFFF`.
   - Bordures nettes et sobres : `#E3E5EC` (`border border-border-soft`).
   - Ombres : Minimalistes (`--shadow-hover: 0 4px 12px rgba(0,0,0,0.05)`). Aucun effet néon, aucun dégradé violet saturé.
4. **Rayons de courbure (Border Radius)** :
   - `--radius-sm: 8px` (Chips, Badges, Inputs)
   - `--radius-md: 12px` (Boutons)
   - `--radius-lg: 16px` (Cartes standard)
   - `--radius-xl: 24px` (Modales, Conteneurs de test)
5. **Règles Anti-Patterns Absolues** :
   - **0 EMOJI** : Règle transversale absolue. Pas d'émojis dans les questions, les cartes, les boutons ou les profils. Utiliser des icônes SVG `lucide-react`.
   - **Pas de héros centré sans asymétrie**.
   - **Pas de dégradé violet / fuchsia**.

#### 2.2 Configuration dans Tailwind v4 / Next.js
Dans `src/app/globals.css`, les tokens DA V2 sont déjà définis :
```css
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

---

### Question 3 : Analyse des Composants UI (`src/components/ui`)

| Composant | Fichier | Props & États | Évaluation pour le Module d'Orientation |
|---|---|---|---|
| **Button** | `src/components/ui/Button.tsx` | `variant: 'primary' \| 'secondary' \| 'gamification'`, `size: 'sm' \| 'md' \| 'lg'` | **Réutilisable immédiatement** pour valider, passer une carte, relancer le test ou soumettre les réponses. Supporte nativement les couleurs DA V2 (`#3133DD` et `#FAA100`). |
| **Card** | `src/components/ui/Card.tsx` | `interactive?: boolean`, standard `HTMLAttributes` | **Réutilisable avec ajustement**. Sert de base structurelle pour l'affichage des filières, résultats et cartes de questions. *Attention* : `CardProps` n'inclut pas formellement `variant` dans son interface TypeScript alors que `page.tsx` passe `variant="standard"` et `variant="gamification"`. |
| **Input** | `src/components/ui/Input.tsx` | `label: string`, `error?: string`, standard `InputHTMLAttributes` | **Réutilisable** si le test demande des filtres ou des données utilisateur (nom de l'élève, série du BAC). |

#### Extension pour les Cartes à Swiper (Tinder-like)
Pour le test addictif à cartes swipables :
- Une carte Tinder nécessite des transformations dynamiques : translation X/Y au drag, rotation angulaire proportionnelle au déplacement, gestion de l'opacité et affichage d'un cachet dynamique de feedback (ex: badge vert/bleu "INTÉRESSÉ" vs badge gris/rouge "PAS POUR MOI").
- La pile de cartes nécessite un empilement en z-index avec effet d'échelle dégressive (ex: Carte 1: scale 1, Carte 2: scale 0.95, Carte 3: scale 0.90).
- **Stratégie recommandée** : Créer un composant dédié `src/components/orientation/SwipeCard.tsx` encapsulant les styles et le conteneur `Card`, couplé à une gestuelle fluide (Framer Motion / touch gestures), tout en proposant des boutons d'action alternatifs sous la carte (pour l'accessibilité desktop/clavier : bouton X "Non" et bouton Check "Oui").

---

### Question 4 : Organisation des Pages et Routes

#### 4.1 Architecture Recommandée
Il est fortement recommandé de créer une route dédiée **`/orientation`** plutôt que d'alourdir la page d'accueil `page.tsx` :

```
web/src/
├── app/
│   ├── api/
│   │   └── match/
│   │       └── route.ts          <-- Route Handler POST (Groq IA + Fallback local Togo)
│   ├── orientation/
│   │   └── page.tsx              <-- Page principale de l'expérience d'orientation
│   ├── globals.css
│   ├── layout.tsx
│   └── page.tsx                  <-- Ajout d'une bannière/CTA vers /orientation
├── components/
│   ├── orientation/
│   │   ├── OrientationContainer.tsx  <-- Orchestrateur d'état (Intro -> Test -> Loading -> Results)
│   │   ├── SwipeCard.tsx             <-- Carte interactive avec animations de swipe
│   │   ├── QcmQuestion.tsx           <-- Mode QCM alternatif / complémentaire
│   │   ├── MatchingLoader.tsx        <-- Écran d'analyse IA AÏDA animé
│   │   └── ResultsDashboard.tsx      <-- Tableau de bord des résultats (métiers & écoles Togo)
│   └── Navbar.tsx                    <-- Ajout du lien direct "Orientation"
```

#### 4.2 Pourquoi une Route Dédiée `/orientation` ?
1. **Immersion et Ergonomie** : Le passage de test nécessite un focus visuel sans distraction, en plein écran ou conteneur centré asymétrique, avec barre de progression du test.
2. **Performance et Découpage du Code** : La logique de swipe, de gestion d'état des réponses et d'appel API est isolée dans un composant client (`"use client"`), laissant la page d'accueil légère.
3. **Auditabilité et Tests** : L'agent auditeur indépendant et les utilisateurs peuvent accéder directement à `http://localhost:3000/orientation`.
4. **Point d'entrée depuis l'Accueil** : Le Hero et la barre de navigation de `page.tsx` doivent intégrer un bouton d'action direct : *"Passer le Test d'Orientation IA"* redirigeant vers `/orientation`.

#### 4.3 Spécification du Route Handler `/api/match` (Requirement R2)
- **Méthode** : `POST`
- **Body d'entrée attendu** :
  ```json
  {
    "answers": [
      { "questionId": "q1", "value": "positive", "domain": "tech" },
      { "questionId": "q2", "value": "positive", "domain": "science" }
    ],
    "educationLevel": "Terminale C/D",
    "interests": ["Programmation", "Résolution de problèmes"]
  }
  ```
- **Intégration Groq / AÏDA** :
  - Modèle : `llama-3.1-8b-instant` ou `mixtral-8x7b-32768`.
  - Endpoint REST : `https://api.groq.com/openai/v1/chat/completions`.
  - Clé API : `process.env.GROQ_API_KEY`.
- **Mécanisme de Fallback Robuste** :
  - Si `GROQ_API_KEY` n'est pas renseignée ou si l'API Groq est injoignable (timeout réseau), le handler bascule immédiatement sur un algorithme de scoring déterministe s'appuyant sur la base de connaissances togolaises (`seed_knowledge_base.py`).
  - Cela garantit une réponse 200 JSON immédiate et prévient tout échec du script de test automatisé `test-match.js`.
- **Format de Sortie Normalisé** (sans emoji) :
  ```json
  {
    "profile": {
      "title": "Profil Bâtisseur Technologique & Analytique",
      "summary": "Forte appétence pour la logique algorithmique, la conception de systèmes complexes et l'innovation numérique.",
      "traits": ["Esprit d'analyse", "Résolution méthodique", "Curiosité technique"]
    },
    "careers": [
      {
        "id": "c1",
        "title": "Ingénieur Logiciel & Cloud",
        "matchScore": 95,
        "description": "Conception et déploiement d'applications distribuées et systèmes cloud pour l'écosystème numérique africain.",
        "sector": "Technologies de l'Information",
        "growth": "Très forte demande au Togo et en Afrique de l'Ouest"
      },
      {
        "id": "c2",
        "title": "Data Scientist & Analyste IA",
        "matchScore": 91,
        "description": "Valorisation des données massives pour l'aide à la décision économique et institutionnelle.",
        "sector": "Data & Intelligence Artificielle",
        "growth": "Secteur émergent à fort potentiel"
      },
      {
        "id": "c3",
        "title": "Architecte Réseaux & Cybersécurité",
        "matchScore": 87,
        "description": "Protection des infrastructures critiques et sécurisation des échanges de données.",
        "sector": "Cybersécurité",
        "growth": "Priorité nationale stratégique"
      }
    ],
    "schools": [
      {
        "id": "s1",
        "name": "Université de Lomé - Faculté des Sciences",
        "type": "Public",
        "city": "Lomé",
        "accreditation": "CAMES, REESAO",
        "programs": ["Licence Génie Logiciel et IA", "Master Informatique"],
        "matchScore": 94
      },
      {
        "id": "s2",
        "name": "IPNET Institute of Technology",
        "type": "Privé agréé",
        "city": "Lomé",
        "accreditation": "Cisco Academy, Partenaire Microsoft",
        "programs": ["Génie Informatique", "Cybersécurité & Cloud"],
        "matchScore": 90
      },
      {
        "id": "s3",
        "name": "IAI-TOGO (Institut Africain d'Informatique)",
        "type": "Inter-États / Privé",
        "city": "Lomé",
        "accreditation": "CAMES",
        "programs": ["Ingénierie des Systèmes d'Information"],
        "matchScore": 88
      }
    ]
  }
  ```

#### 4.4 Dashboard des Résultats (Requirement R3)
- Utilisation de la couleur ambre **`#FAA100`** pour afficher les pourcentages de matching (ex: `95% de compatibilité`).
- Zéro emoji : utilisation d'icônes `Award`, `TrendingUp`, `GraduationCap`, `CheckCircle2`, `Building2`, `Sparkles`.
- Présentation en grille asymétrique :
  - Colonne gauche : Profil psychologique avec traits et synthèse AÏDA.
  - Colonne droite : Les 3 métiers d'avenir avec scores ambre `#FAA100`.
  - Section inférieure : Les 3 établissements agréés au Togo avec détails des filières et accréditations officielles.

---

## 3. Recommandations et Plan d'Action pour l'Équipe d'Implémentation

1. **Typage de `Card.tsx`** :
   Ajouter `variant?: 'standard' | 'gamification'` dans `CardProps` pour sécuriser la compilation TypeScript.
2. **Installation ou Polyfill de Motion** :
   Ajouter `framer-motion` (ou package `motion` compatible React 19) dans `package.json`, ou créer une couche gestuelle fluide native.
3. **Création du Script de Test Automatisé `web/test-match.js`** :
   Créer un script Node.js autonome exécutant un appel POST sur `/api/match` et validant la présence des clés `profile`, `careers` (longueur >= 3) et `schools` (longueur >= 3, Togo).
4. **Vérification Strict DA V2** :
   Vérifier avant toute livraison qu'aucun emoji Unicode n'a été inséré dans les composants TSX ou JSON de retour.
