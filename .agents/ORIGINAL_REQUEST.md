# Original User Request

## 2026-09-22T10:27:06Z

Construire l'interface web Next.js du catalogue de cours E-learning et le tableau de bord de progression étudiant, en respectant le Design System.

Working directory: d:\ActivEducation\web
Integrity mode: demo

## Requirements

### R1. Catalogue de cours (Mock Data)
L'interface du catalogue doit afficher une liste de cours E-learning en utilisant des données fictives (mocks) pour valider le layout et le design.

### R2. Tableau de bord de progression (Mock Data)
L'interface doit afficher la progression d'un étudiant fictif (niveau, XP, leçons terminées) en se basant sur des données statiques.

### R3. Cohérence du Design System
L'équipe doit utiliser exclusivement les composants UI déjà créés (`Button`, `Card`, `Input` dans `src/components/ui`) et respecter les classes utilitaires Tailwind (couleurs `primary`, `gold`, polices `font-display`).

## Acceptance Criteria

### Vérification Technique
- [ ] Le projet compile sans erreur (`npm run build`).

### Vérification Visuelle et Design (Agent-as-judge)
Un agent auditeur indépendant vérifiera que :
- [ ] L'or (gold) n'est utilisé que pour la progression (R2) et jamais pour le catalogue de cours classique.
- [ ] Les cartes de cours utilisent le composant `<Card variant="standard">`.
- [ ] Le layout n'utilise pas un format hero centré classique (qui est interdit par le DESIGN.md).

## 2026-09-22T11:31:59Z

Construire le module d'Orientation Scolaire de bout en bout : interface de test gamifiée, intégration IA pour le matching, et tableau de bord de résultats métiers/écoles au Togo.

Working directory: d:\ActivEducation\web
Integrity mode: demo

## Requirements

### R1. Interface de Test Ludique (Swiping/QCM)
Créer une interface de passage de test d'orientation addictive (ex: cartes à swiper type Tinder ou QCM interactif fluide) utilisant Framer Motion ou similaire. L'interface doit respecter la nouvelle Direction Artistique (Hanken Grotesque, flat design, composants stricts).

### R2. Logique de Matching IA (Groq / AÏDA)
Créer un Route Handler Next.js (`/api/match`) qui prend les réponses de l'étudiant en entrée, interroge l'API Groq (llama3 ou mixtral), et retourne un profil psychologique, 3 métiers porteurs, et 3 établissements au Togo (universités/écoles agréées).

### R3. Tableau de Bord des Résultats
Construire l'UI affichant les résultats retournés par l'IA de façon visuelle et claire, en utilisant l'ambre (#FAA100) pour les scores de correspondance/progression, et sans le moindre emoji.

## Acceptance Criteria

### Vérification Technique (Automatisée)
- [ ] Le projet compile sans erreur (`npm run build`).
- [ ] Un script de test Node.js (`test-match.js`) appelle l'API `/api/match` avec de fausses réponses et vérifie qu'elle répond un JSON valide avec métiers et écoles au Togo.

### Vérification Visuelle et Design (Agent-as-judge)
Un agent auditeur indépendant vérifiera que :
- [ ] Les animations sont présentes, fluides, et ludiques (swipe ou transitions).
- [ ] La charte graphique V2 est strictement respectée (Hanken Grotesque, `#3133DD`, bordures flat).

## 2026-09-30T23:21:56Z

Construire l'interface web Next.js du test d'Orientation par IA (AÏDA), en deux parties.

Working directory: d:\ActivEducation\web
Integrity mode: demo

## Requirements

### R1. Interface de Test Ludique (/student/orientation/page.tsx)
Créer une interface de questionnaire gamifié (style Typeform ou QCM interactif) utilisant Framer Motion si possible. L'étudiant doit répondre à quelques questions clés :
1. Intérêts (Ex: Aimes-tu les sciences, la littérature, etc.)
2. Matières fortes
3. Budget (Faible, Moyen, Élevé)
4. Région / Mobilité

À la fin du test, un écran de chargement "AÏDA analyse votre profil..." doit s'afficher, pendant que ça appelle `POST /api/orientation/generate` avec les réponses.

### R2. Tableau de Bord des Résultats (/student/orientation/resultats/page.tsx)
Construire l'UI affichant le JSON retourné par l'IA.
Le JSON a la structure suivante :
- `psychologicalProfile` (dominantTraits, strengths, weaknesses, summary)
- `recommendedCareers` (Array of {title, matchPercentage, description, salaryRangeCFA, demandInTogo})
- `recommendedSchools` (Array of {name, program, estimatedAnnualCostCFA, whyThisSchool})

L'affichage doit être très propre, utiliser la couleur primary (bleu royal) et gold (ambre) de notre charte, et aucune émoji.

## Acceptance Criteria

- [ ] L'interface utilise les composants UI existants (Button, Card, Input).
- [ ] Le design est flat, police Hanken Grotesque.
- [ ] Le frontend envoie correctement les données à l'API et redirige vers la page de résultats ou l'affiche conditionnellement une fois terminé.
