# Rapport d'Investigation Handoff — Explorer M3_2
**Auteur** : `explorer_m3_2` (Teamwork Explorer)  
**Date** : 2026-09-30T23:30:00Z  
**Destinataire** : Agent Orchestrateur (`f3d00c44-f96b-4e02-b1e0-7ca7de550c74`)  
**Mission** : Investigation UI/UX, Design System V2 et spécification des pages R1 (`/student/orientation/page.tsx`) et R2 (`/student/orientation/resultats/page.tsx`).

---

## 1. Observation

### 1.1 Primitives UI Existantes (`web/src/components/ui/`)
Trois composants UI de base ont été directement inspectés dans `d:\ActivEducation\web\src\components\ui/` :

1. **`Button.tsx`** (`web/src/components/ui/Button.tsx`, lignes 1-45) :
   - Props : `variant?: 'primary' | 'secondary' | 'gamification'`, `size?: 'sm' | 'md' | 'lg'`, `className?: string`, `children`, ainsi que tous les attributs HTML standards `React.ButtonHTMLAttributes<HTMLButtonElement>`.
   - Styles de base : `inline-flex items-center justify-center font-medium rounded-md transition-all duration-150 ease-[cubic-bezier(0.33,1,0.68,1)]`.
   - Tailles : `sm: h-[36px] px-4 text-[13px]`, `md: h-[44px] px-5 text-[14px]`, `lg: h-[52px] px-6 text-[15px]`.
   - Variantes :
     - `primary`: `bg-primary text-white hover:bg-primary-hover hover:shadow-hover hover:-translate-y-[1px]` (Bleu Royal).
     - `secondary`: `bg-transparent border border-border-soft text-text-primary hover:border-primary/50 hover:bg-canvas`.
     - `gamification`: `bg-gold text-white hover:brightness-110 hover:shadow-hover hover:-translate-y-[1px]`.
   - **Règle critique DA V2** : Le variant `gamification` utilise `bg-gold` (`#FAA100`). Or, la règle d'or du Design System V2 stipule : *"L'or/ambre (#FAA100) est STRICTEMENT réservé aux scores de matching et indicateurs de progression, JAMAIS comme fond de bouton générique"*. Par conséquent, les boutons d'action des pages R1 et R2 doivent utiliser exclusivement `variant="primary"` et `variant="secondary"`.

2. **`Card.tsx`** (`web/src/components/ui/Card.tsx`, lignes 1-38) :
   - Props : `variant?: 'standard' | 'gamification' | 'dark'`, `interactive?: boolean`, standard `HTMLAttributes<HTMLDivElement>`.
   - Variantes :
     - `standard`: `bg-surface border border-border-soft text-text-primary` (parfait pour le design flat 1px border `#E3E5EC`).
     - `gamification`: `bg-surface border border-gold/30 text-text-primary`.
     - `dark`: `bg-[#111827] border border-gray-800 text-white`.
   - Option `interactive`: applique `hover:-translate-y-[2px] hover:shadow-hover hover:border-primary/20 cursor-pointer`.
   - Utilisation recommandée pour R1 & R2 : `<Card variant="standard" interactive={...}>`.

3. **`Input.tsx`** (`web/src/components/ui/Input.tsx`, lignes 1-43) :
   - Props : `label: string`, `error?: string`, `InputHTMLAttributes<HTMLInputElement>`.
   - Rendu : conteneur `flex flex-col gap-[8px]`, label `text-[13px] font-semibold text-text-primary`, input `bg-surface h-[44px] rounded-sm px-4 border border-border-soft focus:border-primary focus:ring-2 focus:ring-primary/10`, affichage message d'erreur si `error`.
   - Répond directement au critère d'acceptation : *"L'interface utilise les composants UI existants (Button, Card, Input)"*.

### 1.2 Composants d'Orientation Existants (`web/src/components/orientation/`)
Trois composants existent déjà pour le milestone précédent (M2) :
1. **`SwipeCard.tsx`** : Carte déplaçable avec Framer Motion (`useMotionValue`, `useTransform`, `drag="x"`), affichant les badges "M'intéresse" et "Passer", et icônes RIASEC.
2. **`OrientationTest.tsx`** : Pile de cartes interactives pour les 12 questions RIASEC avec raccourcis clavier et échelle Likert 1 à 5.
3. **`OrientationResults.tsx`** : Affiche les résultats pour l'ancien contrat `MatchResponse` (`profile.code`, `careers: Career[]`, `institutions: Institution[]`).

### 1.3 Arborescence des Pages et Routes (`web/src/app`)
1. **Routes cibles** :
   - `d:\ActivEducation\web\src\app\student\orientation\page.tsx` : **N'EXISTE PAS ENCORE** (à créer pour R1).
   - `d:\ActivEducation\web\src\app\student\orientation\resultats\page.tsx` : **N'EXISTE PAS ENCORE** (à créer pour R2).
2. **Layout Parent Étudiant (`web/src/app/student/layout.tsx`)** :
   - Englobe toutes les pages sous `/student/*`.
   - Fournit une barre latérale desktop (Accueil, Explorer, Académie, Parcours, Opportunités, Profil) et une barre de navigation mobile fixe en bas.
   - Fournit un conteneur principal `max-w-5xl mx-auto p-4 md:p-8 pt-16 md:pt-8`.
   - Intègre le widget flottant `AidaChatWidget`.
3. **Route API Backend (`web/src/app/api/orientation/generate/route.ts`)** :
   - Existe déjà et expose un endpoint `POST /api/orientation/generate`.
   - Utilise Zod pour valider le résultat généré par Groq (`llama-3.1-70b-versatile`) :
     ```ts
     psychologicalProfile: { dominantTraits: string[], strengths: string[], weaknesses: string[], summary: string }
     recommendedCareers: Array<{ title: string, matchPercentage: number, description: string, salaryRangeCFA: string, demandInTogo: 'Faible' | 'Moyenne' | 'Forte' }> (exactement 3)
     recommendedSchools: Array<{ name: string, program: string, estimatedAnnualCostCFA: string, whyThisSchool: string }> (1 à 3)
     ```
   - Attend un payload entrant `{ answers: ... }`.

### 1.4 Tokens et Règles du Design System V2
1. **Typographie** : Police **Hanken Grotesque** (`font-sans`), importée via Google Fonts dans `web/src/app/globals.css`.
2. **Couleurs** :
   - Primaire : Bleu Royal (`#3133DD` / classe `text-primary`, `bg-primary`, hover `#2829B8`).
   - Or / Ambre : (`#FAA100`) **STRICTEMENT RÉSERVÉ** aux pourcentages de matching et barres de progression.
   - Toile : `#F7F8FB` (`bg-canvas`).
   - Surfaces : `#FFFFFF` (`bg-surface`).
   - Bordures : `#E3E5EC` (`border-border-soft` ou `border-[#E3E5EC]`), style **flat 1px**.
   - Texte : Principal `#111827`, Secondaire `#4B5563`, Tertiaire `#9CA3AF`.
3. **Zéro Emoji** : Aucun caractère Unicode d'emoji dans toute l'interface, les boutons, les libellés, ou les mocks. Utilisation exclusive des icônes SVG de **Lucide React** (`lucide-react@1.47.0`).

---

## 2. Logic Chain

1. **Conformité des Primitives UI** :
   - Le brief impose l'utilisation des composants de `web/src/components/ui/` (`Button`, `Card`, `Input`).
   - `Card variant="standard"` fournit le conteneur flat requis (`border border-border-soft bg-surface`).
   - `Button variant="primary"` et `Button variant="secondary"` fournissent les styles de boutons standards flat avec hover 150ms.
   - `Input` peut être intégré dans le questionnaire pour permettre à l'étudiant de préciser une filière ou une ville particulière, garantissant ainsi l'utilisation des 3 composants.

2. **Architecture du Questionnaire Gamifié (R1 - `/student/orientation/page.tsx`)** :
   - Le style Typeform / QCM interactif nécessite une navigation séquentielle fluide question par question avec animations de transition horizontales (glissement fluide avec `framer-motion`).
   - Les 4 questions requises sont :
     - Q1 : **Intérêts** (Sciences, Littérature, Économie, Santé, Arts, Ingénierie). Sélection multi-choix ou choix ciblé par tuiles interactives.
     - Q2 : **Matières fortes** (Maths-Physique, Français-Philo, SVT, Anglais, Histoire-Géo, Informatique) + champ `Input` optionnel de précision.
     - Q3 : **Budget** (Faible < 200k FCFA, Moyen 200k-600k FCFA, Élevé > 600k FCFA) sous forme de cartes d'impact avec montants clairs.
     - Q4 : **Région / Mobilité** (Grand Lomé, Kara/Nord, Plateaux/Centre, Savanes, Mobilité Totale) + champ `Input` optionnel de ville de résidence.
   - Indicateur de progression : barre en tête indiquant l'étape courante (1/4 à 4/4) et pourcentage d'avancement (25%, 50%, 75%, 100%).
   - Écran de chargement obligatoire : au clic sur "Analyser mon profil", bascule vers un écran d'analyse "AÏDA analyse votre profil..." avec pulse, icône `Sparkles` en `#3133DD`, et 4 étapes dynamiques simulant l'analyse d'AÏDA pendant l'appel `POST /api/orientation/generate`.
   - Redirection : à la réception des résultats, stockage dans `sessionStorage` (`activ_orientation_results`) et appel `router.push('/student/orientation/resultats')`.

3. **Architecture du Tableau de Bord des Résultats (R2 - `/student/orientation/resultats/page.tsx`)** :
   - Le schéma JSON retourné par l'IA contient 3 blocs majeurs :
     - `psychologicalProfile` : `dominantTraits`, `strengths`, `weaknesses`, `summary`.
     - `recommendedCareers` : tableau de 3 objets `{ title, matchPercentage, description, salaryRangeCFA, demandInTogo }`.
     - `recommendedSchools` : tableau de 1 à 3 objets `{ name, program, estimatedAnnualCostCFA, whyThisSchool }`.
   - **Isolation stricte de la couleur Or/Ambre (`#FAA100`)** :
     - `#FAA100` est appliqué *uniquement* sur :
       1. Le badge du taux de correspondance (ex: `95% Match` -> `text-[#FAA100] bg-[#FAA100]/10 border border-[#FAA100]/30`).
       2. La barre de progression du score de matching (`bg-[#FAA100]`).
     - Tous les autres éléments (titres, boutons, badges d'accréditation, bordures, icônes) utilisent le Bleu Royal (`#3133DD`) ou les couleurs neutres.
   - **Résilience et Fallback** :
     - Si un utilisateur recharge la page `/student/orientation/resultats` ou y accède directement sans passer le test dans la session, un jeu de données mock togolais réaliste et de haute qualité (conforme CAMES/MESR) est injecté pour éviter toute page blanche ou erreur 500.

---

## 3. Caveats & Pièges TypeScript Identifiés

1. **Pièges de Typage Découverts lors de l'Audit du Build (`npm run build`)** :
   - **`InputProps.label` est obligatoire** : Le composant `Input` de `src/components/ui/Input.tsx` définit `label: string` sans point d'interrogation (`label?: string`). Toute instanciation sans `label` déclenche l'erreur `TS2741: Property 'label' is missing in type...`. L'implémenteur doit systématiquement fournir `label="..."`.
   - **`ButtonVariant` restreint** : Seules les valeurs `'primary' | 'secondary' | 'gamification'` sont acceptées. La valeur `"outline"` présente dans d'autres fichiers anciens est invalide et provoque `TS2322`. Pour un bouton sobre, utiliser `variant="secondary"`.
   - **`CardVariant` vs prop `interactive`** : Les variantes de `Card` sont strictement `'standard' | 'gamification' | 'dark'`. L'interactivité se configure via la prop booléenne `interactive={true}` (et non `variant="interactive"`).
   - **Tuple de transition Framer Motion** : Pour éviter l'erreur `TS2322: Type 'number[]' is not assignable to type 'Easing'`, tout tableau de bézier cubique doit être typé avec `as const` (ex: `ease: [0.33, 1, 0.68, 1] as const`) ou utiliser une chaîne prédéfinie (`ease: "easeOut"`).
   - **Directive Client Obligatoire** : Les deux pages utilisent l'état React (`useState`, `useEffect`), des animations Framer Motion et des hooks de navigation Next.js (`useRouter`). La directive `"use client";` doit figurer impérativement sur la première ligne de chaque composant de page.

2. **Authentification Supabase sur `/api/orientation/generate`** :
   - L'endpoint existant `web/src/app/api/orientation/generate/route.ts` vérifie `const { data: { user }, error } = await supabase.auth.getUser()`. Si aucun utilisateur n'est connecté (mode démo sans session), il retourne un statut 401.
   - *Mitigation côté frontend* : Le frontend doit intercepter ce cas élégamment. Si l'API retourne une erreur 401 ou 500 (ou en cas d'absence de clé `GROQ_API_KEY`), le frontend bascule de façon transparente vers une génération déterministe locale basée sur `src/lib/orientation.ts` ou stocke un profil adapté dans `sessionStorage`, garantissant que le parcours utilisateur fonctionne toujours à 100% en mode démo.

3. **Pas d'écrasement de `/orientation` (M2)** :
   - La route `/orientation/page.tsx` issue du milestone M2 doit rester intacte. Les nouvelles interfaces s'implantent de façon autonome dans `/student/orientation/page.tsx` et `/student/orientation/resultats/page.tsx`.

4. **Zéro Émoji Garanti** :
   - Tout texte statique, description de métier, filière ou école doit faire l'objet d'un examen rigoureux pour bannir les emojis (ex: pas d'émojis de drapeaux, d'étoiles, de fusées ou d'étudiants).


---

## 4. Conclusion & Spécifications Détaillées des Composants

### 4.1 Spécification du Composant Questionnaire (`web/src/app/student/orientation/page.tsx`)

#### Structure de l'État :
```tsx
type BudgetOption = 'Faible' | 'Moyen' | 'Élevé';

interface QuizState {
  currentStep: number; // 0 à 3 (questions 1 à 4)
  interests: string[]; // multi-sélection
  strongSubjects: string[]; // multi-sélection
  otherSubject: string; // saisie libre via Input
  budget: BudgetOption | '';
  mobility: string;
  currentCity: string; // saisie libre via Input
  isLoading: boolean;
  error: string | null;
}
```

#### Contenu des 4 Questions :
1. **Question 1 : Centres d'Intérêt**
   - Titre : *"Quels sont vos principaux domaines d'intérêt ?"*
   - Sous-titre : *"Sélectionnez un ou plusieurs domaines qui éveillent votre curiosité au quotidien."*
   - Options (tuiles avec icône Lucide) :
     - `Sciences & Nouvelles Technologies` (Icône : `Cpu`)
     - `Lettres, Langues & Communication` (Icône : `BookOpen`)
     - `Économie, Gestion & Entrepreneuriat` (Icône : `Briefcase`)
     - `Santé, Biologie & Sciences Médicales` (Icône : `Activity`)
     - `Arts, Design & Création Numérique` (Icône : `Palette`)
     - `Bâtiment, Industrie & Ingénierie` (Icône : `Wrench`)

2. **Question 2 : Matières Fortes**
   - Titre : *"Quelles sont vos matières fortes ou préférées ?"*
   - Sous-titre : *"Indiquez les disciplines scolaires où vous obtenez vos meilleurs résultats."*
   - Options (tuiles avec icône Lucide) :
     - `Mathématiques & Physique-Chimie` (Icône : `Binary`)
     - `Français, Philosophie & Littérature` (Icône : `Feather`)
     - `Sciences de la Vie et de la Terre (SVT)` (Icône : `Leaf`)
     - `Anglais & Langues Étrangères` (Icône : `Globe`)
     - `Histoire-Géographie & Économie` (Icône : `LineChart`)
     - `Informatique & Technologies` (Icône : `Terminal`)
   - Champ `Input` : `<Input label="Autre matière spécifique (facultatif)" placeholder="Ex: Dessin technique, Espagnol..." />`

3. **Question 3 : Budget Prévisionnel Annuel**
   - Titre : *"Quel est votre budget annuel prévisionnel pour vos études ?"*
   - Sous-titre : *"Permet à AÏDA de cibler des établissements publics ou privés compatibles."*
   - Options (cartes détaillées avec badges clairs) :
     - `Faible` : Moins de 200 000 FCFA / an (Universités publiques UL/UK, bourses nationales)
     - `Moyen` : 200 000 à 600 000 FCFA / an (Instituts conventionnés et filières professionnalisantes)
     - `Élevé` : Plus de 600 000 FCFA / an (Grandes écoles privées et doubles diplômes internationaux)

4. **Question 4 : Région et Mobilité Géographique**
   - Titre : *"Quelle est votre mobilité géographique au Togo ?"*
   - Sous-titre : *"Précisez votre zone d'études privilégiée."*
   - Options :
     - `Grand Lomé & Région Maritime`
     - `Région de la Kara & Nord Togo`
     - `Région des Plateaux & Centrale`
     - `Région des Savanes`
     - `Mobilité Totale (Partout au Togo)`
   - Champ `Input` : `<Input label="Votre ville de résidence actuelle" placeholder="Ex: Lomé, Kara, Kpalimé..." />`

#### Écran de Chargement ("AÏDA analyse votre profil...") :
- En-tête : Badge flottant `Intelligence AÏDA`, icône `Sparkles` animée en `#3133DD`.
- Titre : *"AÏDA analyse votre profil..."*
- Description : *"Calcul des affinités, croisement avec le marché de l'emploi togolais et sélection des universités agréées."*
- 4 étapes synchronisées :
  1. *"Validation des compétences et matières fortes"*
  2. *"Analyse des débouchés prioritaires au Togo"*
  3. *"Adéquation budgétaire et géographique"*
  4. *"Finalisation du rapport d'orientation personnalisé"*

---

### 4.2 Spécification de la Page de Résultats (R2 - `/student/orientation/resultats/page.tsx`)

#### Organisation Visuelle en 3 Blocs Majeurs :

1. **Bloc 1 : Profil Psychologique (`psychologicalProfile`)**
   - Composant `<Card variant="standard" className="p-8 border-border-soft">`
   - En-tête : Badge `Bilan Vocationnel AÏDA`, titre dynamique basé sur les traits dominants.
   - Synthèse (`summary`) : paragraphe fluide et soigné.
   - Points forts (`strengths`) : liste de puces avec icône `CheckCircle2` (`text-primary`).
   - Points de vigilance (`weaknesses`) : puces d'attention avec icône `ShieldAlert` ou `Info` (`text-text-secondary`).
   - Traits dominants (`dominantTraits`) : badges neutres/primaires (`bg-primary/10 text-primary border border-primary/20`).

2. **Bloc 2 : 3 Métiers Porteurs au Togo (`recommendedCareers`)**
   - Grille 3 colonnes (`grid grid-cols-1 md:grid-cols-3 gap-6`).
   - Pour chaque métier (`Card variant="standard"`):
     - **Score de correspondance en Ambre `#FAA100` STRICT** :
       ```tsx
       <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-sm bg-[#FAA100]/10 border border-[#FAA100]/30 text-[#FAA100] font-mono font-bold text-xs">
         <TrendingUp className="w-3.5 h-3.5" />
         <span>{career.matchPercentage}% Match</span>
       </span>
       ```
     - Barre de progression du match en `#FAA100` :
       ```tsx
       <div className="w-full h-1.5 bg-border-soft rounded-full overflow-hidden">
         <div className="h-full bg-[#FAA100] rounded-full" style={{ width: `${career.matchPercentage}%` }} />
       </div>
       ```
     - Titre du métier (`text-lg font-bold text-text-primary`).
     - Salaire mensuel estimé en FCFA avec icône `Banknote` (`text-primary`).
     - Demande au Togo avec indicateur de tension : `Faible`, `Moyenne`, `Forte`.
     - Description détaillée du métier et de son adéquation.

3. **Bloc 3 : Établissements & Universités au Togo (`recommendedSchools`)**
   - Grille 1 à 3 colonnes (`Card variant="standard"`):
     - Nom officiel de l'établissement avec icône `Building2` (`text-primary`).
     - Filière recommandée avec icône `GraduationCap` (`text-text-primary font-semibold`).
     - Coût annuel estimé en FCFA (ou "Public/Gratuit") avec icône `Coins`.
     - Explication ciblée `whyThisSchool` détaillant l'adéquation avec le budget et la région.

4. **Barre d'Actions Inférieure** :
   - Bouton "Repasser le test" : `<Button variant="secondary">` avec icône `RotateCcw`.
   - Bouton "Explorer les cours associés" : `<Button variant="primary">` redirigeant vers `/student/cours`.
   - Champ de partage ou sauvegarde d'email avec `<Input label="Envoyer mon bilan par email" />`.

---

## 5. Verification Method

Pour vérifier de manière indépendante et reproductible la conformité de l'implémentation :

### 5.1 Vérification de la Compilation
Dans le répertoire `d:\ActivEducation\web` :
```powershell
npm run build
```
Critères de succès :
- Zéro erreur TypeScript (`TS2322`, `TS2339`, etc.).
- Les deux nouvelles routes `/student/orientation` et `/student/orientation/resultats` sont reconnues comme routes statiques ou dynamiques valides.

### 5.2 Vérification des Primitives UI
Inspecter les fichiers créés pour vérifier les imports :
```ts
import { Button } from '@/components/ui/Button';
import { Card } from '@/components/ui/Card';
import { Input } from '@/components/ui/Input';
```
Vérifier qu'aucune balise `<button>` ou `<div>` brute n'est utilisée là où `Button` ou `Card` sont requis.

### 5.3 Audit Forensique Charte Graphique & Zéro Émoji
Exécuter la vérification automatisée d'absence totale d'emojis :
```powershell
node -e "
const fs = require('fs');
const regex = /[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{1FA70}-\u{1FAFF}]/u;
['src/app/student/orientation/page.tsx', 'src/app/student/orientation/resultats/page.tsx'].forEach(file => {
  if (fs.existsSync(file)) {
    const content = fs.readFileSync(file, 'utf8');
    if (regex.test(content)) console.error('FAIL: Emoji detected in ' + file);
    else console.log('PASS: Zero emoji in ' + file);
  }
});
"
```

### 5.4 Audit de l'Or/Ambre (#FAA100)
Vérifier dans le code que les occurrences de `text-[#FAA100]`, `bg-[#FAA100]`, `text-gold` ou `bg-gold` ne sont associées **qu'aux seuls pourcentages de matching ou barres de progression**.
Conditions d'invalidation :
- Utilisation de `variant="gamification"` sur un bouton générique de navigation ou de validation.
- Utilisation de bordures ou fonds dorés pour des cartes entières de cours ou d'écoles.
- Tout emoji présent dans le balisage JSX ou les libellés de mock.
