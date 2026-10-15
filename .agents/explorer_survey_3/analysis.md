# Analyse Architecturale & Design System — ActivEducation (R1 & R2)

**Auteur** : `explorer_survey_3` (teamwork_preview_explorer)  
**Date** : 2026-09-22  
**Statut** : Rapport d'investigation complet  
**Fichiers de référence analysés** :
- `d:\ActivEducation\DESIGN.md` (Spécification maître du Design System)
- `d:\ActivEducation\.agents\ORIGINAL_REQUEST.md` (Cahier des charges & critères d'acceptation)
- `d:\ActivEducation\web\src\app\globals.css` (Configuration Tailwind v4 `@theme`)
- `d:\ActivEducation\web\src\app\page.tsx` (Page d'accueil existante avec violations identifiées)
- `d:\ActivEducation\web\src\components\ui\Button.tsx`, `Card.tsx`, `Input.tsx` (Composants UI autorisés)
- `d:\ActivEducation\backend\app\schemas\elearning.py`, `seed_elearning.sql` & `CAHIER_DES_CHARGES_GAMIFICATION.md` (Données métiers réelles)

---

## 1. Résumé Exécutif & Constats Majeurs

1. **Localisation des spécifications** : Le document maître est situé à la racine du projet (`d:\ActivEducation\DESIGN.md`). Il établit un univers visuel fort : **"Académie de haute altitude"**, alliant rigueur institutionnelle (Bleu Royal `#1060CF`) et récompense d'élite (Or Ambré `#F2A423`).
2. **Violation majeure détectée dans l'existant** : `d:\ActivEducation\web\src\app\page.tsx` (lignes 11–25) implémente un **hero centré classique** (`text-center`, colonne unique centrée), ce qui est formellement interdit par `DESIGN.md` (§5 et §7) et viole le critère d'acceptation explicite de `ORIGINAL_REQUEST.md`.
3. **Règle absolue sur l'usage de la couleur Or (Gold)** :
   - **Interdiction formelle dans R1 (Catalogue de cours)** : Aucun tag, badge, bouton, fond ou carte du catalogue ne doit utiliser l'or. Les cartes de cours doivent obligatoirement être instanciées avec `<Card variant="standard">`.
   - **Autorisation exclusive dans R2 (Tableau de bord de progression)** : L'or est strictement réservé aux récompenses, au niveau de l'étudiant, au score XP, au streak et au bouton de validation de progression (`<Button variant="gamification">`).
4. **Exigence Mock Data** : Des structures TypeScript typées et des jeux de données réalistes ancrés dans le contexte ouest-africain (Togo, Côte d'Ivoire, Sénégal...) sont requis pour satisfaire simultanément la présentation du catalogue de cours (R1) et le dashboard de progression (R2).

---

## 2. Contraintes de Layout & Architecture Visuelle

### 2.1 Pourquoi le hero centré classique est strictement interdit

Dans `DESIGN.md`, section 1 (*Visual Theme & Atmosphere*), le concept directeur stipule :
> *"Variance asymétrique : 7/10 — Layouts en splits et décalages calculés, jamais de symétrie parfaite."* (l. 15)  
> *"Ni scolaire, ni corporate — quelque chose entre un dashboard d'athlète de haut niveau et un cabinet d'orientation d'élite."* (l. 12)

Les sections 5 et 7 formalisent cette interdiction de manière péremptoire :
- **Section 5 — Hero section** (l. 183) :  
  `"Jamais de héros centré. Layout split-screen systématique :"`
  - *Colonne gauche (55%)* : Headline Sora display, sous-titre Outfit, CTA unique.
  - *Colonne droite (45%)* : Visuel de produit, screenshot de l'app, ou composition de cartes UI animées (pas une photo stock).
- **Section 7 — Anti-Patterns / Interdictions absolues** (l. 252) :  
  `"- Aucun héros centré avec texte + bouton en colonne verticale centrée"`  
  `"- Aucune grille 3 colonnes identiques pour les features"`  
  `"- Aucun height: 100vh — uniquement min-height: 100dvh"`
- **ORIGINAL_REQUEST.md — Acceptance Criteria** (l. 30) :  
  `"- [ ] Le layout n'utilise pas un format hero centré classique (qui est interdit par le DESIGN.md)."`

**Justification ergonomique et narrative** :  
Un hero centré traditionnel produit un effet statique de "template SaaS générique". ActivEducation exige une disposition asymétrique qui guide immédiatement le regard de l'étudiant d'un côté vers la promesse pédagogique (titre dynamique Sora) et de l'autre vers une preuve concrète tangible (composition d'interfaces réelles : aperçu d'un cours et jauge de niveau).

### 2.2 Structure de Layout Imposée

Toute page ou section principale doit se conformer aux paramètres géométriques suivants :

| Paramètre | Spécification DESIGN.md | Classes CSS / Tailwind suggérées |
|---|---|---|
| **Conteneur maximal** | `max-width: 1400px`, centré avec `margin: auto` | `max-w-[1400px] mx-auto w-full` |
| **Padding horizontal** | `clamp(1.5rem, 5vw, 3.5rem)` | `px-[clamp(1.5rem,5vw,3.5rem)]` |
| **Espacement vertical de sections** | `clamp(4rem, 8vw, 8rem)` | `py-[clamp(4rem,8vw,8rem)]` ou `gap-16` / `gap-20` |
| **Structure Hero** | Split-screen asymétrique 55% / 45% | `grid grid-cols-1 lg:grid-cols-12 gap-8 lg:gap-12 items-center` (7 cols gauche / 5 cols droite) |
| **Colonne Hero Gauche (55%)** | Alignement gauche, Headline Sora display tracking négatif, sous-titre max 65ch, CTA bleu | `<div className="lg:col-span-7 flex flex-col items-start text-left">` |
| **Colonne Hero Droite (45%)** | Composition asymétrique de cartes UI animées / preview | `<div className="lg:col-span-5 relative flex flex-col gap-4">` |
| **Section Catalogue R1** | Grille responsive asymétrique (2 ou 3 colonnes selon breakpoint, évitant la régularité monotone) | `grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6` |
| **Section Progression R2** | Format Bento ou split 2 colonnes (Carte statut gamification + liste d'accomplissements) | `grid grid-cols-1 lg:grid-cols-3 gap-8` (1 col KPI gamifié + 2 cols leçons/badges) |

---

## 3. Règles Strictes de la Palette de Couleurs (Gold vs. Primary Blue)

### 3.1 Rôles Sémantiques Fondamentaux

Le Design System repose sur une dichotomie stricte et non négociable :
- **Bleu Royal (`#1060CF`)** = **L'Autorité & L'Action.** C'est la couleur dominante de navigation, des boutons d'action principale, des liens et des filtres.
- **Or Ambré (`#F2A423`)** = **La Récompense & Le Jeu.** C'est la couleur exclusive du succès mérité : points d'expérience (XP), niveau franchi, flamme de streak, badges débloqués et podium.

Citations directes de `DESIGN.md` :
- Ligne 53 : `"--color-gold: #F2A423 — Gamification exclusivement. XP, badges, streaks, récompenses, podium. Jamais sur les boutons d'action standard."`
- Lignes 67–68 : `"Règle absolue : L'or #F2A423 est réservé à la mécanique de jeu. Un badge de progression, un score XP, une flamme de streak. Jamais un CTA 'S'inscrire' ou 'Continuer'. Cette séparation crée un langage visuel immédiatement lisible."`
- Lignes 276–280 :  
  `"- L'or #F2A423 ne doit jamais apparaître sur un bouton d'action standard (S'inscrire, Continuer, Envoyer)."`  
  `"- Le bleu #1060CF ne doit jamais apparaître sur un élément de score XP ou badge de récompense."`  
  `"- Ces deux couleurs ont des rôles sémantiques opposés et complémentaires — les mélanger brise le langage visuel."`

### 3.2 Matrice d'application stricte : Catalogue R1 vs. Progression R2

| Élément d'interface | Rôle / Périmètre | Or autorisé ? | Couleur / Composant requis | Justification DESIGN.md / ORIGINAL_REQUEST |
|---|---|:---:|---|---|
| **Carte de cours** | R1 (Catalogue) | ❌ **NON** | `<Card variant="standard">` (`bg-surface`, bordure `primary/10`, `shadow-card`) | Explicitement requis par l'audit : `variant="standard"` sans or |
| **Bouton d'action cours** ("Commencer", "Voir le cours") | R1 (Catalogue) | ❌ **NON** | `<Button variant="primary">` ou `<Button variant="secondary">` | Les CTA standard doivent être bleus |
| **Tags de catégorie cours** ("Informatique", "Business") | R1 (Catalogue) | ❌ **NON** | Fond `primary-surface` (`#E8F0FE`), texte `primary` (`#1060CF`) | Aucun or hors gamification |
| **Pill de difficulté cours** ("Débutant", "Intermédiaire") | R1 (Catalogue) | ❌ **NON** | Fond `surface-alt` (`#EEF2FA`), texte `text-secondary` (`#4A6280`) | Éléments neutres |
| **Métadonnées de durée** (icône horloge, 45 min) | R1 (Catalogue) | ❌ **NON** | `text-text-secondary`, police `JetBrains Mono` | Données techniques sobres |
| **Affichage du gain XP sur carte cours** ("+100 XP") | R1 (Catalogue) | ❌ **NON** | `text-text-secondary font-mono` (pas de pastille ou fond or dans le catalogue classique) | Garde le catalogue neutre et propre |
| **Jauge de Niveau étudiant** | R2 (Progression) | ✅ **OUI** | `text-gold-dark`, bordures légères or | Indicateur de palier de jeu |
| **Compteur XP Total** | R2 (Progression) | ✅ **OUI** | `text-gold-dark font-mono font-bold` | Score de récompense |
| **Flamme & Jours de Streak** | R2 (Progression) | ✅ **OUI** | Accent or (`#F2A423`) / icône flamme | Mécanique d'assiduité gamifiée |
| **Carte récapitulative de statut** | R2 (Progression) | ✅ **OUI** | `<Card variant="gamification">` (`bg-gold-surface border-gold/25`) | Conteneur officiel de gamification |
| **Badges de succès débloqués** | R2 (Progression) | ✅ **OUI** | Bordure or `rgba(242,164,35,0.40)`, ombre or douce | Médailles et accomplissements |
| **Barre de progression XP** | R2 (Progression) | ⚠️ Mixte | Track `#EEF2FA`, Fill dégradé vert émeraude `#34D399` → `#10B981`, micro-détails ou shimmer or | Conforme DESIGN.md §4 (l. 152) |
| **Bouton de validation de niveau** | R2 (Progression) | ✅ **OUI** | `<Button variant="gamification">` (dégradé or `#CC8800` → `#F2A423`) | Réservé exclusivement à la validation d'un palier |

---

## 4. Spécification des Mock Data

### 4.1 Exigences pour le Catalogue de Cours (R1)

Le catalogue doit présenter une sélection réaliste de cours en phase avec les filières d'avenir en Afrique de l'Ouest (Technologies numériques, Entrepreneuriat local, Orientation post-bac, Sciences appliquées).

#### Modèle de données TypeScript recommandé :

```typescript
export type CourseCategory = 'Informatique' | 'Orientation' | 'Business' | 'Sciences';
export type CourseDifficulty = 'Débutant' | 'Intermédiaire' | 'Avancé';

export interface CourseMockItem {
  id: string;
  title: string;
  description: string;
  category: CourseCategory;
  difficulty: CourseDifficulty;
  durationMinutes: number;
  durationFormatted: string;
  lessonsCount: number;
  modulesCount: number;
  pointsReward: number; // XP gagné après complétion
  isPublished: boolean;
  partner?: string;
}
```

#### Dataset de référence (Catalogue R1) :

```typescript
export const MOCK_COURSES: CourseMockItem[] = [
  {
    id: "crs-001",
    title: "Introduction aux Métiers du Numérique",
    description: "Explore les opportunités de la tech en Afrique de l'Ouest : développement web, UX design, cybersécurité et data.",
    category: "Informatique",
    difficulty: "Débutant",
    durationMinutes: 45,
    durationFormatted: "45 min",
    lessonsCount: 4,
    modulesCount: 2,
    pointsReward: 100,
    isPublished: true,
    partner: "Initiative Tech Ouest-Africaine"
  },
  {
    id: "crs-002",
    title: "Préparer son Orientation Post-Bac",
    description: "Méthodologie concrète pour choisir sa filière universitaire, comparer les facultés et bâtir un projet académique solide.",
    category: "Orientation",
    difficulty: "Débutant",
    durationMinutes: 30,
    durationFormatted: "30 min",
    lessonsCount: 3,
    modulesCount: 2,
    pointsReward: 80,
    isPublished: true,
    partner: "Académie Régionale d'Orientation"
  },
  {
    id: "crs-003",
    title: "HTML5 & CSS3 Moderne pour Débutants",
    description: "Construis tes premières interfaces web réactives. Maîtrise les grilles CSS, flexbox et l'accessibilité sans prérequis.",
    category: "Informatique",
    difficulty: "Débutant",
    durationMinutes: 60,
    durationFormatted: "1h 00",
    lessonsCount: 5,
    modulesCount: 2,
    pointsReward: 120,
    isPublished: true,
  },
  {
    id: "crs-004",
    title: "Business Model Canvas & Entrepreneuriat Local",
    description: "Valide ton modèle économique et conçois une offre de services adaptée aux réalités du marché local ouest-africain.",
    category: "Business",
    difficulty: "Intermédiaire",
    durationMinutes: 75,
    durationFormatted: "1h 15",
    lessonsCount: 6,
    modulesCount: 3,
    pointsReward: 150,
    isPublished: true,
  },
  {
    id: "crs-005",
    title: "Statistiques & Analyse de Données Décisionnelles",
    description: "Méthodes quantitatives indispensables pour l'aide à la décision en économie, sciences de l'ingénieur et recherche.",
    category: "Sciences",
    difficulty: "Intermédiaire",
    durationMinutes: 90,
    durationFormatted: "1h 30",
    lessonsCount: 6,
    modulesCount: 2,
    pointsReward: 180,
    isPublished: true,
  },
  {
    id: "crs-006",
    title: "Gestion de Projet Agile & Outils Collaboratifs",
    description: "Pilote des projets numériques avec Scrum et Kanban. Favorise la collaboration en équipe et la livraison itérative.",
    category: "Business",
    difficulty: "Avancé",
    durationMinutes: 120,
    durationFormatted: "2h 00",
    lessonsCount: 8,
    modulesCount: 4,
    pointsReward: 200,
    isPublished: true,
  }
];
```

### 4.2 Exigences pour le Tableau de Bord de Progression (R2)

Le tableau de bord doit valoriser le parcours d'un étudiant fictif crédible (ex: "Kofi Mensah" ou "Amina Diallo") en évitant les noms génériques type "Jean Dupont" ou les valeurs rondes fantaisistes proscrites par `DESIGN.md` §7.

#### Modèle de données TypeScript recommandé :

```typescript
export interface CompletedLessonMock {
  id: string;
  title: string;
  courseTitle: string;
  category: CourseCategory;
  xpEarned: number;
  completedAgo: string;
  type: 'article' | 'video' | 'quiz';
}

export interface StudentAchievementMock {
  id: string;
  title: string;
  description: string;
  isUnlocked: boolean;
  unlockedAt?: string;
  iconType: 'first_step' | 'streak_week' | 'exam_passed' | 'tech_explorer';
}

export interface StudentProgressMock {
  student: {
    fullName: string;
    schoolLevel: string;
    location: string;
  };
  level: {
    current: number;
    title: string;
    nextLevel: number;
    progressPct: number; // ex: 85
  };
  xp: {
    current: number; // ex: 850
    nextLevelThreshold: number; // ex: 1000
    toNextLevel: number; // ex: 150
  };
  streak: {
    currentDays: number; // ex: 7
    longestDays: number; // ex: 14
    isActiveToday: boolean;
  };
  leaderboardRank: number; // ex: 3
  completedLessons: CompletedLessonMock[];
  achievements: StudentAchievementMock[];
}
```

#### Dataset de référence (Progression R2) :

```typescript
export const MOCK_STUDENT_PROGRESS: StudentProgressMock = {
  student: {
    fullName: "Amina Diallo",
    schoolLevel: "Terminale Scientifique / Prépa Informatique",
    location: "Lomé, Togo",
  },
  level: {
    current: 3,
    title: "Exploratrice Académique",
    nextLevel: 4,
    progressPct: 85,
  },
  xp: {
    current: 850,
    nextLevelThreshold: 1000,
    toNextLevel: 150,
  },
  streak: {
    currentDays: 7,
    longestDays: 14,
    isActiveToday: true,
  },
  leaderboardRank: 3,
  completedLessons: [
    {
      id: "lsn-c1",
      title: "Le paysage numérique en Afrique",
      courseTitle: "Introduction aux Métiers du Numérique",
      category: "Informatique",
      xpEarned: 15,
      completedAgo: "Aujourd'hui, 09:40",
      type: "article",
    },
    {
      id: "lsn-c2",
      title: "Évaluer tes compétences clés",
      courseTitle: "Préparer son Orientation Post-Bac",
      category: "Orientation",
      xpEarned: 20,
      completedAgo: "Hier, 16:15",
      type: "quiz",
    },
    {
      id: "lsn-c3",
      title: "Sélecteurs et cascade CSS",
      courseTitle: "HTML5 & CSS3 Moderne pour Débutants",
      category: "Informatique",
      xpEarned: 25,
      completedAgo: "Il y a 2 jours",
      type: "video",
    },
    {
      id: "lsn-c4",
      title: "Panorama des filières universitaires régionales",
      courseTitle: "Préparer son Orientation Post-Bac",
      category: "Orientation",
      xpEarned: 20,
      completedAgo: "Il y a 3 jours",
      type: "article",
    },
  ],
  achievements: [
    {
      id: "ach-1",
      title: "Premier Cap",
      description: "Premier cours terminé avec succès",
      isUnlocked: true,
      unlockedAt: "Il y a 5 jours",
      iconType: "first_step",
    },
    {
      id: "ach-2",
      title: "Semaine Assidue",
      description: "7 jours d'activité consécutive",
      isUnlocked: true,
      unlockedAt: "Aujourd'hui",
      iconType: "streak_week",
    },
    {
      id: "ach-3",
      title: "Score Parfait",
      description: "Résultat supérieur à 80% sur un examen",
      isUnlocked: true,
      unlockedAt: "Il y a 2 jours",
      iconType: "exam_passed",
    },
    {
      id: "ach-4",
      title: "Pionnier Tech",
      description: "Compléter 5 modules d'informatique",
      isUnlocked: false,
      iconType: "tech_explorer",
    },
  ]
};
```

---

## 5. Composants UI Existants & Règles d'Assemblage

Le projet dispose déjà des composants nécessaires dans `d:\ActivEducation\web\src\components\ui\` :

1. **`Button` (`src/components/ui/Button.tsx`)** :
   - `variant="primary"` : Fond bleu `#1060CF`, texte blanc, pilule. **À utiliser pour les CTA de cours R1.**
   - `variant="secondary"` : Transparent avec bordure bleue `border-primary/30`.
   - `variant="tertiary"` : Lien texte souligné discret.
   - `variant="gamification"` : Dégradé or `#CC8800` → `#F2A423`, texte sombre `#060E1E`, `shadow-gold`. **Strictement réservé à l'action de validation de progression R2.**
2. **`Card` (`src/components/ui/Card.tsx`)** :
   - `variant="standard"` : Fond `#FFFFFF`, bordure `primary/10`, `shadow-card`, `rounded-lg`. **Obligatoire pour les cartes de cours R1.**
   - `variant="gamification"` : Fond `gold-surface` (`#FFF5E0`), bordure `gold/25`, `shadow-gold`. **Autorisé et conseillé pour le conteneur KPI de progression R2.**
   - `variant="dark"` : Fond sombre translucide.
3. **`Input` (`src/components/ui/Input.tsx`)** :
   - Label en majuscules avec tracking augmenté `tracking-[1.2px]`, fond `surface-alt` (`#EEF2FA`), anneau de focus bleu primaire. Idéal pour un champ de recherche de cours dans le catalogue.

---

## 6. Synthèse des Écarts & Plan d'Action Recommandé pour l'Implémenteur

| Fichier cible | État Actuel | Action Requise |
|---|---|---|
| `web/src/app/page.tsx` | Contient un hero centré classique interdit (`text-center`, flex centré) et 2 cartes d'exemple statiques | 1. **Remplacer le hero** par un split-screen 55%/45% (titre Sora gauche, composition UI asymétrique droite).<br>2. **Intégrer R2 (Dashboard Progression)** avec niveau, XP, streak, barre émeraude, accomplissements et `<Card variant="gamification">`.<br>3. **Intégrer R1 (Catalogue Cours)** avec la liste de cours dans des `<Card variant="standard">`, badges neutres/bleus, bouton primaire. |
| `web/src/data/mockData.ts` (ou équivalent) | Inexistant | Créer le fichier de mock data contenant `MOCK_COURSES` et `MOCK_STUDENT_PROGRESS`. |
| Audit de conformité Or | Respecté dans les composants de base mais pas encore éprouvé sur catalogue | S'assurer qu'aucun sélecteur ou classe Tailwind contenant `gold`, `amber`, ou `#F2A423` ne soit présent dans la section du catalogue R1. |
