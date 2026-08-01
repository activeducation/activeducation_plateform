# Design system & guidelines — Frontend Web + Landing

> **Objectif** : faire passer le frontend Next.js (étudiant) et la landing page de « fonctionnel et coloré » à « professionnel et humanisé », **sans casser la palette de couleurs existante** ni l'alignement avec l'app mobile Flutter.
>
> **Périmètre** : `frontend/src/` (Next.js) + `landing/index.html` (statique).
> **Hors périmètre** (décidé avec l'utilisateur) : app mobile Flutter, dashboard admin Flutter.

---

## 1. Diagnostic de l'existant

### Ce qui marche déjà très bien ✅
- **Palette riche et cohérente** (cf. `docs/PALETTE_COULEURS.md`) : 3 bleus dégradés, 3 oranges, états sémantiques, 6 catégories d'orientation, thème sombre préparé.
- **Typographie** : Hanken Grotesque — choix moderne, lisible, bien adaptée au mobile.
- **Identité gamifiée** assumée (XP, streak, niveau, rangs or/argent/bronze) — différenciant vs concurrents académiques.
- **Alignement mobile ↔ web** déjà en place sur les 7 pages M1-M7 et les 32+ améliorations D1-D32.
- **Conventions d'images** propres (`onError` silencieux, `thumbnail_url` partout).
- **Token design** déjà branchés dans `globals.css` (`@theme inline` avec `--color-brand-*`).

### Ce qui peut monter en gamme 🎯
| # | Constat | Impact perçu |
|---|---------|--------------|
| 1 | Aucun système d'**espacement** explicite (tout en `px-4`, `gap-2` ad-hoc) | Rythme visuel irrégulier entre pages |
| 2 | Pas de **hiérarchie typographique** définie (tailles H1/H2/body/caption flottent) | Manque de « respiration », titres écrasés |
| 3 | Cartes avec `border` simple et `rounded-2xl` partout — peu de profondeur | Aspect « plat » vs concurrents (Khan Academy, Duolingo) |
| 4 | **Splash** d'accueil très orné mais pas de vraie animation d'onboarding avec mascotte | Première impression peut faire « vieille app » |
| 5 | Aucun **état vide** (empty state) ni squelette de chargement explicite | Moments d'attente déroutent |
| 6 | Pas d'**illustration** ni mascotte propre — juste émojis et icônes Lucide | Manque de chaleur humaine |
| 7 | Couleurs de catégories (sciences/lettres/etc.) présentes mais peu exploitées dans l'UI | Catalogue métiers/écoles paraît monochrome |
| 8 | CTA primaire toujours bleu, CTA secondaire pas hiérarchisé | Conversion moins efficace |
| 9 | Ombres CSS basiques (`shadow-nav` etc.) | Cartes « collées » au fond |
| 10 | Pas de feedback **tactile** au tap (active:scale, micro-bounce) | Application parait « Web », pas « App » |

---

## 2. Principes directeurs

Trois principes à garder en tête pour chaque décision :

1. **« Sophistiqué, pas clinquant »** — privilégie la profondeur subtile (ombres douces, surfaces empilées) aux dégradés agressifs. On n'est pas Duolingo pour enfants, on est le « LinkedIn de l'orientation africaine ».
2. **« Humain d'abord »** — chaque écran doit avoir un visage, un prénom ou un témoignage, jamais juste un titre froid. La gamification célèbre la **personne**, pas l'XP.
3. **« Une couleur par intention »** — la palette actuelle le permet déjà : bleu = plateforme, orange = encouragement/personnel, vert = succès, violet = niveau, rouge = streak/chaleur. Ne mélange pas.

### Références visuelles (à montrer à un graphiste)
- **Khan Academy** : cartes matières avec icônes illustrées colorées, barre de progression fine, hiérarchie typographique forte.
- **Duolingo Path** : onboarding narratif avec mascotte, « leçons » qui avancent comme un jeu de société.
- **Notion / Linear** : profondeur par empilement de surfaces (5 niveaux d'élévation), ombres très diffuses.
- **African Leadership University (ALU)** : chaleur, photos vraies, témoignages vidéo.
- **Coursera** : rigueur des pages « catalogue », filtres riches, sections clairement étiquetées.

---

## 3. Refinements de la palette (sans la casser)

### 3.1 Échelle de bleus — clarifier l'usage

| Token | Hex | Usage exclusif |
|-------|-----|---------------|
| `brand-primary` | `#3133DD` | CTA principal, liens actifs |
| `brand-primary-mid` | `#2322D3` | CTA primaire au survol |
| `brand-primary-dark` | `#0E00C8` | CTA pressé (`active:scale`) |
| `brand-primary-light` | `#6062E8` | Dégradé, halo, focus ring |
| `brand-primary-surface` | `#E1E0FF` | Fond de pill/tag bleu, hover sur item |
| `brand-primary-surface2` | `#C0C1FF` | Bordure 1.5px sur surface bleu clair |

**Règle** : ne JAMAIS utiliser `brand-primary` pour un texte long (trop saturé). Pour le texte sur fond bleu, utiliser `#FFFFFF` ou `on-blue-2` (`#D6D7F7`).

### 3.2 Échelle d'orange — restreindre l'usage

L'orange est déjà omniprésent. **Nouveau périmètre** :
- ✅ Bouton « Continuer », « Démarrer », « Reprendre » (call-to-action d'engagement)
- ✅ Badges de streak, jauges XP animées
- ✅ Notifications importantes
- ❌ Plus jamais comme couleur principale d'un écran entier (laisse le bleu dominer)
- ❌ Plus jamais en texte long (fatigue oculaire)

### 3.3 Ajouter 3 neutres doux (manquants pour la profondeur)

| Token | Hex | Rôle |
|-------|-----|------|
| `neutral-50` | `#FAFAFB` | Surface d'élévation 0 (légèrement + chaud que `--bg`) |
| `neutral-100` | `#F0F0F3` | Élévation 1 — cartes au-dessus de `--bg` |
| `neutral-200` | `#E8E8EC` | Séparateurs dans surfaces empilées |

Ces neutres remplacent progressivement les `--brand-surface-light` et `--brand-surface-low` qui font trop « teinté bleu » et alourdissent les pages blanches.

### 3.4 Palette gamification — hiérarchiser

Aujourd'hui : or `#FFD700`, argent `#C0C0C0`, bronze `#CD7F32` en pied de page.
**Mieux** : utiliser la palette uniquement pour les **podiums** (top 3 leaderboard) et les **badges ronds** (avatar + level). Partout ailleurs, utiliser le **violet** `#8B5CF6` pour le niveau et le **vert menthe** `#34D399` pour la XP bar. Cela libère l'or pour son usage prestigieux.

---

## 4. Système d'espacement & grille

Adopter une **base 4** explicite (en `rem` pour respecter les préférences d'accessibilité) :

```
--space-1: 0.25rem   (4px)   — entre icône et label
--space-2: 0.5rem    (8px)   — gap de pile courte
--space-3: 0.75rem   (12px)  — gap standard de composants
--space-4: 1rem      (16px)  — padding carte, gap de section
--space-5: 1.5rem    (24px)  — entre blocs d'une section
--space-6: 2rem      (32px)  — entre sections majeures
--space-8: 3rem      (48px)  — séparation hero → contenu
--space-10: 4rem     (64px)  — aération de fin de page
```

**Largeur max de contenu** : `max-w-5xl` (1024px) pour le contenu principal, `max-w-3xl` (768px) pour les pages de formulaire/quiz, `max-w-prose` (65ch) pour les pages de contenu long (mentor profil, carrière détail).

**Padding latéral mobile** : `px-5` (20px) sur mobile, `px-8` sur tablette+, jamais `px-4` (16px) qui est trop étroit pour le pouce africain dominant.

---

## 5. Hiérarchie typographique

Définir 6 niveaux maximum, à utiliser systématiquement :

| Niveau | Tailwind | Usage | Exemple |
|--------|----------|-------|---------|
| **display** | `text-4xl font-extrabold tracking-tight` | Héros, splash | « Découvre ta voie » |
| **h1** | `text-3xl font-bold` | Titre de page | « Orientation » |
| **h2** | `text-xl font-semibold` | Titre de section | « Tests recommandés pour toi » |
| **h3** | `text-base font-semibold` | Titre de carte | Nom d'école, nom de cours |
| **body** | `text-sm leading-relaxed` | Paragraphe | Description, méta |
| **caption** | `text-xs text-brand-text-tertiary` | Méta, labels | « il y a 2 jours », « 3 leçons » |

**Line height** : `leading-relaxed` (1.625) pour le body, `leading-tight` (1.25) pour les titres.

**Letter spacing** : `-0.02em` sur display et h1 (effet « pro »), `0` ailleurs.

---

## 6. Profondeur par empilement (5 niveaux)

C'est l'ingrédient manquant pour passer de « plat » à « professionnel ». Cinq surfaces, du fond vers l'avant :

```
Niveau 0 : bg              #FBF8FF   fond de page
Niveau 1 : surface         #FFFFFF   carte au repos
Niveau 2 : elevated        #FFFFFF   + shadow-1  → carte au survol
Niveau 3 : floating        #FFFFFF   + shadow-2  → modal, drawer
Niveau 4 : overlay         #FFFFFF   + shadow-3  → dropdown menu
```

Trois ombres à utiliser (très diffuses, légèrement teintées bleu) :

```css
--shadow-1: 0 1px 2px rgba(49,51,221,0.04), 0 1px 1px rgba(49,51,221,0.06);
--shadow-2: 0 4px 8px rgba(49,51,221,0.06), 0 2px 4px rgba(49,51,221,0.04);
--shadow-3: 0 12px 24px rgba(49,51,221,0.08), 0 4px 8px rgba(49,51,221,0.04);
--shadow-nav: 0 -2px 12px rgba(49,51,221,0.06);
```

(La bottom nav utilise déjà `shadow-nav` — on harmonise le reste.)

---

## 7. Composants à (re)créer

| Composant | Où | Pourquoi | Priorité |
|-----------|----|---|---|
| `<MascotteSparkle />` | nouveau, SVG inline | Petit personnage qui apparaît dans empty states, onboarding, résultats. Donne une « voix » à la plateforme. Style : mascotte géométrique, dégradé bleu→orange, 2 versions d'expression. | **P0** |
| `<HumanizedEmptyState icon title body cta />` | nouveau | Remplace tous les `« Aucun résultat »` actuels. Toujours : illustration + phrase encourageante + CTA si pertinent. | **P0** |
| `<Skeleton />` (4 variantes) | nouveau | Carré, ligne, cercle, carte. Animation shimmer bleu-clair. Remplace les `loading...` nus. | **P0** |
| `<SectionHeader title subtitle action />` | déjà existant (`section-header.tsx`), à enrichir | Ajouter une prop `accent` qui pose un petit bloc de couleur catégorie à gauche. | **P1** |
| `<Button variant size />` | nouveau, remplacer tous les `<button>` ad-hoc | 5 variantes : `primary` (bleu) / `secondary` (outline bleu) / `accent` (orange) / `ghost` (texte seul) / `danger`. 3 tailles. États `hover`/`active`/`disabled` explicites. | **P0** |
| `<Card variant />` | nouveau, remplacer `<div className="bg-white rounded-2xl">` | 3 variantes : `flat` (juste bordure) / `elevated` (ombre) / `interactive` (ombre + cursor + scale au tap). | **P0** |
| `<Avatar name src size />` | nouveau | Initiales colorées basées sur le hash du nom + image optionnelle. Utilisé partout (mentors, classement, profil, écoles). | **P1** |
| `<ProgressBar variant value />` | nouveau | 3 variantes : `xp` (vert), `streak` (orange feu), `level` (violet). Animation de remplissage. | **P2** |
| `<CategoryChip category />` | nouveau | Petit chip avec un point de couleur et l'icône de la catégorie (Sciences, Lettres, etc.). Rend la page orientation vivante. | **P1** |
| `<BottomSheet />` | nouveau | Pour les filtres sur mobile. Animation spring, drag handle, ferme au tap backdrop. | **P2** |
| `<Toast />` | nouveau | Pour les succès/erreurs fugaces. 4 variantes. Auto-dismiss 3s. | **P2** |

---

## 8. Maquettes ASCII des écrans clés

### 8.1 Accueil (`/`)

```
┌─────────────────────────────────────────────┐
│  [≡] ActivEducation         [🔍] [🔔] [👤]  │  ← header fin, 56px
├─────────────────────────────────────────────┤
│                                             │
│  Bonjour, Kossi 👋                          │  ← display, vert menthe
│  Continue ton ascension : Niveau 4 — Éclaireur│
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │ [XP BAR VERT] ██████████░░░  340/500│  │  ← progress XP animée
│  │ 🔥 12 jours  •  🏆 Top 14%        │  │  ← streak + rang
│  └──────────────────────────────────────┘  │
│                                             │
│  Suggestions pour toi                  ›   │  ← h2
│  ┌────────┐ ┌────────┐ ┌────────┐           │
│  │ [Ico]  │ │ [Ico]  │ │ [Ico]  │ ←→         │
│  │ Test   │ │ Cours  │ │ Mentor │           │  ← 3 cards colorées
│  │ RIASEC │ │ Python │ │ Aïcha  │           │     catégorie
│  │ ⏱ 5min │ │ ⭐ 4.8 │ │ ✓Dispo │           │
│  └────────┘ └────────┘ └────────┘           │
│                                             │
│  Reprendre où tu t'es arrêté         ›      │
│  ┌──────────────────────────────────────┐  │
│  │ [▓▓▓▓░░░░]  Module 3 / 7            │  │  ← card interactive
│  │ Les variables Python                 │  │     avec progression
│  │ Cours · Introduction à la program.  │  │
│  │                          [Reprendre →]│  │
│  └──────────────────────────────────────┘  │
│                                             │
│  Annonces de la communauté         ›        │
│  • Bourse Mastercard 2026 — date limite 30/07│
│  • Nouveau cours : Design Thinking         │
│                                             │
│  Mentor de la semaine                        │
│  ┌──────────────────────────────────────┐  │
│  │ [👤 Aïcha]  « J'ai trouvé ma voie    │  │  ← témoignage humain
│  │ Ingénieure chez Google. Mon conseil :│  │     (chaleur)
│  │ ose envoyer des messages aux mentors.»│
│  │                         [Lui parler →]│  │
│  └──────────────────────────────────────┘  │
│                                             │
│ [🏠]  [🧭]  [📚]  [💬]  [👤]                 │  ← bottom nav
└─────────────────────────────────────────────┘
```

**Différences vs actuel** : header plus aéré, salutation personnalisée en haut, mentor de la semaine en bas, catégories colorées sur les suggestions, jauge XP avec libellé explicite.

### 8.2 Onboarding (étape 1 sur 5)

```
┌─────────────────────────────────────────────┐
│  ● ● ● ● ○                       Passer ×  │  ← stepper 5 dots
├─────────────────────────────────────────────┤
│                                             │
│          [Illustration Sparkle]             │  ← mascotte
│           (SVG local, 180×180)              │     qui sourit
│                                             │
│  Bienvenue sur ActivEducation               │  ← display
│  Ton orientation commence ici.              │
│                                             │
│  En 5 étapes, on va :                       │  ← list à puces
│   ✓ Découvrir ce qui te passionne           │     avec ✓ bleus
│   ✓ Identifier les métiers faits pour toi   │
│   ✓ Trouver les écoles qui te correspondent │
│   ✓ Rencontrer des mentors                  │
│   ✓ Créer ton plan d'avenir                 │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │          Commencer →                  │  │  ← CTA orange
│  └──────────────────────────────────────┘  │
│                                             │
│  2 min • 100% gratuit • 12 000+ élèves     │  ← réassurance
└─────────────────────────────────────────────┘
```

### 8.3 Page cours détail (`/cours/[id]`)

```
┌─────────────────────────────────────────────┐
│  [←]   Introduction à Python      [♡] [⋯]  │
├─────────────────────────────────────────────┤
│  ┌──────────────────────────────────────┐  │
│  │      [Hero image / cover]             │  │  ← cover 16:9
│  │      (thumbnail_url)                  │  │     avec gradient
│  │                                      │  │     overlay sombre
│  │  🐍 PROGRAMMATION                    │  │  ← category chip
│  │  Introduction à Python               │  │     cyan
│  │  ⭐ 4.8  •  1 240 élèves  •  6 leçons │  │  ← meta en blanc
│  └──────────────────────────────────────┘  │
│                                             │
│  Description                                │
│  Apprends les bases de Python en 2h...     │  ← Voir plus / moins
│  Ce cours couvre les variables, conditions, │     (déjà fait en D6+)
│  boucles et fonctions.                      │
│                                             │
│  Progression           [██░░░░░░] 18%       │
│                                             │
│  Modules                                    │
│  ┌──────────────────────────────────────┐  │
│  │ ✓ 1. Bienvenue               5 min ✓ │  │  ← accordéons
│  │ ▶ 2. Les variables          12 min   │  │     fermés par
│  │ ○ 3. Les conditions         15 min   │  │     défaut
│  │ ○ 4. Les boucles            18 min   │  │
│  │ ○ 5. Les fonctions          20 min   │  │
│  │ ○ 6. Quiz final             10 min   │  │
│  └──────────────────────────────────────┘  │
│                                             │
│  Ce que tu vas apprendre                    │
│  ✓ Écrire ton premier programme             │
│  ✓ Utiliser variables et conditions         │
│  ✓ Créer une fonction                       │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │   ▶  Reprendre — Module 2 (12 min)   │  │  ← sticky CTA
│  └──────────────────────────────────────┘  │     en bas
└─────────────────────────────────────────────┘
```

### 8.4 Profil (`/profil`)

```
┌─────────────────────────────────────────────┐
│  Mon profil                          [⋯]    │
├─────────────────────────────────────────────┤
│        ┌──────┐                             │
│        │  KK  │  Kossi Mensah              │  ← avatar
│        └──────┘  Niveau 4 — Éclaireur  ⓘ  │     initiales
│                  🌍 Lomé, Togo              │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │  ✦  340 XP       🔥  12 jours        │  │  ← stats
│  │  🏆  Top 14%     🎯  3/12 métiers    │  │     2×2 grid
│  └──────────────────────────────────────┘  │
│                                             │
│  [XP BAR] ████████████░░  340/500           │  ← progress
│                                             │
│  Mes badges (5)                       ›    │
│  ◯ ◯ ◯ ◯ ◯                                 │  ← circular badges
│                                             │
│  Réalisations récentes               ›     │
│  ✓ Premier test d'orientation complété     │
│  ✓ Premier mentor contacté                 │
│  ✓ Cours Python démarré                    │
│                                             │
│  Défis en cours                       ›     │
│  🔥 5 jours de plus pour valider le défi    │
│  📚 Termine 2 cours cette semaine          │
│                                             │
│  Paramètres                                 │
│  • Notifications                            │
│  • Confidentialité                          │
│  • Déconnexion                              │  ← dialog de
│                                             │     confirmation
└─────────────────────────────────────────────┘
```

### 8.5 Landing page (refonte)

Actuellement la landing est une **page de 2000+ lignes en pur HTML/CSS** dans un seul `index.html`. Refonte recommandée :

```
┌─────────────────────────────────────────────┐
│  [Logo]  Accueil  Carrières  Écoles  [→ Connexion] │
├─────────────────────────────────────────────┤
│  HERO (image à droite, texte à gauche)       │
│  ┌─────────────────┐  ┌─────────────────┐  │
│  │ Découvre ta voie│  │ [Mockup app]    │  │
│  │ Joue ton avenir │  │   iPhone +      │  │
│  │                 │  │   illustration  │  │
│  │ [Commencer gra- │  │   mascotte      │  │
│  │  tuitement →]   │  │   Sparkle       │  │
│  │                 │  │                 │  │
│  │ 12 000+ élèves  │  │                 │  │
│  │ 40+ métiers     │  │                 │  │
│  │ 100% gratuit    │  │                 │  │
│  └─────────────────┘  └─────────────────┘  │
├─────────────────────────────────────────────┤
│  « Ce que tu vas trouver »                  │
│  [Card] Tests d'orientation   [card image]  │
│  [Card] Catalogue métiers     [card image]  │
│  [Card] Annuaire écoles       [card image]  │
│  [Card] Mentorat 1-to-1       [card image]  │
├─────────────────────────────────────────────┤
│  « Comment ça marche »  — 3 étapes          │
│  1. Teste-toi    2. Découvre   3. Agis       │
│  [icônes illustrées colorées]               │
├─────────────────────────────────────────────┤
│  Témoignages (3 photos + 3 citations)       │
│  ← photo Kossi, Ingénieur  ← photo Aïcha   │
│  ← photo Yao, Médecin                        │
├─────────────────────────────────────────────┤
│  Chiffres clés (4 stats animées au scroll)  │
│  12 000+ | 40+ | 100% | 5                   │
│  élèves  métiers gratuit langues           │
├─────────────────────────────────────────────┤
│  CTA final (bandeau bleu gradient)          │
│  « Ton avenir commence aujourd'hui »        │
│  [Créer mon compte gratuit →]                │
├─────────────────────────────────────────────┤
│  Footer                                     │
│  Logo | Contact | À propos | Légal | Social │
└─────────────────────────────────────────────┘
```

**Refonte technique proposée** : extraire la landing en **4 composants** :
1. `landing/index.html` minimal (100 lignes : meta + `<div id="root">`)
2. CSS dans `landing/landing.css` (séparer du inline)
3. Image hero en SVG (mockup app) plutôt qu'en JPEG
4. Polices déjà en Hanken Grotesque — bon choix, à conserver

---

## 9. Micro-interactions & feedback

| Action | Feedback attendu | Implémentation |
|--------|------------------|----------------|
| Tap sur carte | `scale(0.98)` 100ms | Tailwind `active:scale-[0.98] transition` |
| Tap sur CTA primaire | scale + assombrissement | `active:scale-95 active:bg-brand-primary-dark` |
| Chargement | Skeleton shimmer bleu | composant `<Skeleton />` |
| Réussite (test, mentor contacté) | Toast vert + confetti léger | `<Toast variant="success" />` |
| Streak atteint | Animation feu + son (opt-in) | Lottie ou CSS keyframes |
| Nouveau badge | Modal plein écran avec animation scale | composant `<BadgeUnlockModal />` |
| Hover sur carte | élévation 1 → 2 | Tailwind `hover:shadow-2` |

**Règle** : **toujours** un feedback visible en < 100ms après action. Jamais d'écran qui « ne réagit pas ».

---

## 10. États vides (empty states) à humaniser

Aujourd'hui : « Aucun résultat » ou « Loading... ». Demain, 4 templates :

| Contexte | Visuel | Texte |
|----------|--------|-------|
| Pas encore de test fait | Mascotte Sparkle avec panneau « ? » | « On n'a pas encore exploré ensemble. Lance ton premier test, ça prend 5 min ! » + CTA |
| Aucun mentor trouvé | Sparkle avec jumelles | « Aucun mentor ne correspond. Élargis ta recherche ou propose un sujet qui t'intéresse. » |
| Pas de cours commencé | Sparkle avec livre ouvert | « Ton catalogue est vide pour l'instant. Découvre les cours qui matchent avec ton profil. » + CTA |
| Erreur réseau | Sparkle avec panneau attention | « On a du mal à joindre le serveur. Vérifie ta connexion et réessaye. » + bouton Réessayer |

**Règle d'or** : un empty state n'est **jamais** une absence d'information, c'est une **invitation à l'action**.

---

## 11. Accessibilité (garde-fous)

- **Contraste minimum** : 4.5:1 pour le texte normal, 3:1 pour le gros texte. Le bleu `#3133DD` sur fond blanc : ✅ (7.2:1). Le orange `#FAA100` sur fond blanc : ⚠️ 2.8:1 — ne JAMAIS l'utiliser pour du texte long, seulement pour des pill/CTA.
- **Cibles tactiles** : 44×44px minimum pour tous les boutons, liens et chips.
- **Focus visible** : ring de 2px `brand-primary-light` sur tous les éléments focusables.
- **`prefers-reduced-motion`** : désactiver les animations shimmer, confettis, parallaxe.
- **Alt text** : systématique sur images, vide pour décoratives.
- **Langue** : `lang="fr"` sur `<html>`, attributs `aria-label` sur icônes-bouton.

---

## 12. Plan d'implémentation par phases

### Phase 1 — Fondations (1-2 jours)
- [ ] Ajouter tokens d'espacement, ombres, neutres doux dans `globals.css`
- [ ] Créer `<Button />`, `<Card />`, `<Skeleton />`, `<HumanizedEmptyState />` dans `components/ui/`
- [ ] Migrer les 5 pages les plus visitées (accueil, cours, profil, orientation, écoles) sur ces composants

### Phase 2 — Identité (2-3 jours)
- [ ] Designer la mascotte Sparkle (SVG, 2 expressions, palette officielle)
- [ ] Ajouter `<CategoryChip />`, `<Avatar />`, `<ProgressBar />`
- [ ] Refondre la page d'accueil (cf. maquette 8.1)
- [ ] Refondre l'onboarding 5 étapes (cf. maquette 8.2)

### Phase 3 — Polish (1-2 jours)
- [ ] Micro-interactions partout (active:scale, hover:shadow)
- [ ] Toast + BottomSheet
- [ ] Remplacer tous les empty states
- [ ] Vérifier l'accessibilité (Lighthouse, axe)

### Phase 4 — Landing (1 jour, peut être externalisé à un graphiste)
- [ ] Mockup hero en SVG
- [ ] Photos témoignages (3-5 vrais élèves — pas stock)
- [ ] Refonte `landing/index.html` avec la structure 8.5

---

## 13. Anti-patterns à éviter

- ❌ **Dégradé bleu plein écran** en fond de page (vu dans le splash — OK, mais pas dans le contenu)
- ❌ **Émojis comme décoration principale** dans les headers de section
- ❌ **Boutons oranges partout** — réserver l'orange aux CTA d'engagement (« Commencer », « Reprendre »)
- ❌ **Texte blanc sur fond bleu clair** (#E1E0FF) — illisible, garder bleu foncé
- ❌ **Animations > 300ms** sur des éléments interactifs (sensation de lenteur)
- ❌ **Modal pour confirmer une action triviale** (préférer Toast)
- ❌ **« Loading... »** comme seul feedback — toujours un skeleton
- ❌ **Redirection après action** sans message de succès

---

## 14. Métriques de succès

Après implémentation, on devrait observer :
- **Lighthouse Accessibility** ≥ 95
- **Lighthouse Performance** ≥ 90 (déjà bon, ne pas dégrader)
- **Time to Interactive** sur accueil < 2.5s en 3G
- **Taux de complétion onboarding** (5 étapes) ≥ 70% (vs ~40% typique)
- **Engagement semaine 1** ≥ 3 sessions (vs 1.5 actuel si mesurable)
- **NPS visuel** — tester avec 5 élèves cibles : « Cette appli te donne envie de revenir ? »

---

## Sources d'inspiration (à montrer à un graphiste externe)

- [Khan Academy](https://www.khanacademy.org) — cartes matières, progression fine
- [Duolingo Path](https://www.duolingo.com) — onboarding narratif, gamification adulte
- [Coursera](https://www.coursera.org) — rigueur catalogue, filtres riches
- [Linear](https://linear.app) — profondeur par empilement, micro-interactions
- [Notion](https://www.notion.so) — densité d'information sans surcharge
- [African Leadership University](https://www.alueducation.com) — chaleur africaine, témoignages
- [Awwwards — catégorie Education](https://www.awwwards.com/websites/education/) — veille continue
