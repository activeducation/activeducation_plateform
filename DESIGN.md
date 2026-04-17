# Design System: ActivEducation

> EdTech d'orientation scolaire et professionnelle gamifiée.
> Plateforme africaine, ambition mondiale.

---

## 1. Visual Theme & Atmosphere

**Concept directeur : "Académie de haute altitude"**

L'interface respire la confiance de ceux qui savent où ils vont. Ni scolaire, ni corporate — quelque chose entre un dashboard d'athlète de haut niveau et un cabinet d'orientation d'élite. Chaque élément a sa place. Rien ne déborde. Le bleu cobalt est l'autorité. L'or ambré est la récompense.

- **Densité** : 5/10 — Équilibre entre contenu riche et respirations maîtrisées
- **Variance asymétrique** : 7/10 — Layouts en splits et décalages calculés, jamais de symétrie parfaite
- **Motion** : 6/10 — Fluidité naturelle, spring physics, révélations orchestrées

**Ambiance** : Salle de lecture moderne dans une bibliothèque universitaire africaine. Lumière naturelle froide sur des surfaces lisses. Accents chauds (or) uniquement sur les récompenses. Le reste est discipline et clarté.

---

## 2. Color Palette & Roles

### Surfaces & Fonds

| Nom               | Hex       | Rôle fonctionnel                                              |
|-------------------|-----------|---------------------------------------------------------------|
| Canvas Froid      | `#F5F7FC` | Fond principal — légèrement teinté bleu, jamais pur blanc    |
| Surface Carte     | `#FFFFFF` | Fond des cartes, modales, drawers                            |
| Surface Variante  | `#EEF2FA` | Fond des inputs, zones alternées                             |
| Fond Sombre       | `#060E1E` | Hero, sidebar, header sombre, splash screen                  |
| Surface Sombre    | `#0B1C3C` | Cartes sur fond sombre, secondary dark surface               |
| Bordure Sombre    | `rgba(255,255,255,0.07)` | Séparateurs sur fond sombre               |

### Textes

| Nom                | Hex       | Rôle                                                          |
|--------------------|-----------|---------------------------------------------------------------|
| Encre Principale   | `#0D1832` | Titres, labels, texte principal sur fond clair               |
| Encre Secondaire   | `#4A6280` | Descriptions, sous-titres, métadonnées                       |
| Encre Tertiaire    | `#8AAAC0` | Placeholders, texte désactivé, légendes                      |
| Encre Claire       | `#E4EEF8` | Texte principal sur fond sombre                              |
| Encre Mutée Sombre | `#7AA0BC` | Texte secondaire sur fond sombre                             |

### Couleurs de Marque

| Nom                 | Hex       | Rôle — règle d'usage stricte                                 |
|---------------------|-----------|---------------------------------------------------------------|
| Bleu Royal          | `#1060CF` | **Action principale.** Boutons, liens, focus rings, indicateurs actifs. Couleur dominante de l'interface. |
| Bleu Cobalt Foncé   | `#0A45A0` | Hover sur éléments bleus. Gradient sombre du bleu.           |
| Bleu Ciel           | `#4A8AE5` | Accents secondaires bleus, icônes, chips inactifs.           |
| Surface Bleue       | `#E8F0FE` | Fond léger sur éléments actifs en thème clair.               |
| **Or Ambré**        | `#F2A423` | **Gamification exclusivement.** XP, badges, streaks, récompenses, podium. Jamais sur les boutons d'action standard. |
| Or Foncé            | `#CC8800` | Hover sur éléments en or. Texte sur fond clair.              |
| Or Clair            | `#FFD166` | Highlights, reflets, micro-détails gamifiés.                 |
| Surface Or          | `#FFF5E0` | Fond léger sur notifications gamification.                   |

### Statuts Sémantiques

| Nom        | Hex       | Usage                        |
|------------|-----------|------------------------------|
| Succès     | `#16A34A` | Confirmation, complétion     |
| Attention  | `#EA8B08` | Avertissement neutre         |
| Erreur     | `#DC2626` | Échec, blocage               |
| Info       | `#1060CF` | Utilise la couleur primaire  |

**Règle absolue** : L'or `#F2A423` est réservé à la mécanique de jeu. Un badge de progression, un score XP, une flamme de streak. Jamais un CTA "S'inscrire" ou "Continuer". Cette séparation crée un langage visuel immédiatement lisible.

---

## 3. Typography Rules

### Stack typographique

| Rôle               | Police         | Raison du choix                                              |
|--------------------|----------------|--------------------------------------------------------------|
| **Display / Titres hero** | `Sora` | Géométrique, moderne, confiant. Parfait pour les headlines d'orientation et les titres d'écrans. Jamais vieilli. |
| **UI / Corps de texte** | `Outfit` | Chaleureux, lisible, légèrement arrondi sans être enfantin. Complémente Sora sans lui faire concurrence. |
| **Données numériques** | `JetBrains Mono` | Scores XP, classements, statistiques, dates. Les chiffres alignés en tabular figures créent la rigueur. |

### Hiérarchie typographique

```
Hero Display (Sora 800, 52–80px, tracking -2.5px, lh 1.06)
  └─ Titres section (Sora 700, 36–46px, tracking -1.2px, lh 1.15)
       └─ Titres card (Outfit 700, 20–24px, tracking -0.2px, lh 1.3)
            └─ Corps (Outfit 400, 15–16px, tracking 0, lh 1.65)
                 └─ Labels / UI (Outfit 500–600, 12–14px, tracking 0.2px)
                      └─ Données (JetBrains Mono 700, 14–28px, tabular-nums)
```

### Règles strictes

- Titres : `text-wrap: balance` — jamais de mot orphelin
- Paragraphes : `max-width: 65ch`, `text-wrap: pretty`
- Grands titres (display) : tracking négatif (`-1.5px` à `-2.5px`)
- Labels et overlines : tracking positif (`+1.2px` à `+2px`), uppercase, taille 11px
- Aucun gras général sur le corps de texte — la hiérarchie passe par la taille et la couleur, pas le bold partout

### Polices interdites

- `Inter` — trop générique, saturé dans les outils no-code
- `Roboto`, `Lato`, `Open Sans` — sans personnalité
- Toute police serif (`Georgia`, `Times New Roman`, `Garamond`) dans l'interface applicative

---

## 4. Component Stylings

### Boutons

**Primaire (action principale) :**
Fond bleu `#1060CF`, texte blanc, radius `100px` (pilule), Outfit SemiBold 14px. Ombre teintée bleue `0 4px 16px rgba(10,69,160,0.35)`. Au hover : `translateY(-2px)` + ombre renforcée. Au clic actif : `scale(0.97)`. Aucun glow extérieur néon.

**Secondaire (action alternative) :**
Fond transparent, bordure `1.5px solid rgba(16,96,207,0.30)`, texte bleu `#1060CF`. Hover : fond `rgba(16,96,207,0.06)`, bordure plus opaque. Même radius pilule.

**Tertiaire (lien action) :**
Texte bleu sans bordure. Underline pointillé au hover. Pas de fond.

**Bouton gamification (ex: "Valider mon niveau") :**
Fond dégradé or `#CC8800` → `#F2A423`. Texte `#060E1E` (marine très sombre). Ombre teintée or `0 4px 16px rgba(204,136,0,0.32)`. Réservé aux validations de progression uniquement.

**Règle absolue** : Jamais de `cursor: pointer` custom. Jamais de glow extérieur coloré. Feedback uniquement par transform + shadow.

### Cartes

Usage justifié uniquement quand l'élévation communique une hiérarchie.

**Carte standard (thème clair) :**
Fond `#FFFFFF`, bordure `1px solid rgba(16,96,207,0.10)`, radius `20px`, ombre `0 4px 20px rgba(13,24,50,0.07)`. Hover : `translateY(-4px)`, ombre intensifiée teintée bleu `0 12px 36px rgba(10,69,160,0.14)`. Bordure légèrement renforcée au hover.

**Carte de gamification (badge, streak, XP) :**
Fond `#FFF5E0`, bordure `1px solid rgba(242,164,35,0.25)`, ombre `0 4px 16px rgba(204,136,0,0.12)`. Hover : ombre renforcée or.

**Carte sur fond sombre (hero, sidebar) :**
Fond `rgba(255,255,255,0.04)`, bordure `1px solid rgba(255,255,255,0.07)`, radius `18px`. Hover : fond `rgba(16,96,207,0.08)`, bordure `rgba(16,96,207,0.30)`.

**Cartes à haute densité** (liste de mentors, résultats de test) : Remplacer les cartes individuelles par des lignes séparées d'un `border-top 1px` + padding vertical. Pas de shadow, pas de radius.

### Inputs & Formulaires

Label systématiquement **au-dessus** de l'input, Outfit 500 13px, couleur Encre Secondaire. Jamais de floating label (anachronique, peu accessible).

Input : fond `#EEF2FA`, bordure `1px solid transparent`, radius `12px`, padding `14px 16px`. Focus : bordure bleu `#1060CF` 1.5px + ring léger `0 0 0 3px rgba(16,96,207,0.10)`. Erreur : bordure rouge `#DC2626` + message inline en dessous, JetBrains Mono 12px rouge.

Placeholder : Encre Tertiaire `#8AAAC0`. Jamais de placeholder en lieu de label.

### Éléments de gamification

**Barre XP :**
Track fond `#EEF2FA` (thème clair) ou `rgba(255,255,255,0.08)` (sombre), hauteur 8px, radius 100px. Fill : dégradé `#34D399` → `#10B981`. Animation de remplissage au mount : `scaleX()` depuis 0 vers la valeur cible en 900ms, spring physics.

**Badge :**
Fond blanc ou surface sombre. Icône SVG custom centrée (aucun emoji). Bordure or `2px solid rgba(242,164,35,0.40)`. Radius `50%` ou squircle `(radius: 40%)`. Badge débloqué : ombre or douce. Badge verrouillé : désaturé, opacité 40%.

**Streak indicator :**
Chiffre en JetBrains Mono Bold, suffixe "j" en Outfit Regular. Indicateur visuel : rectangle vertical de couleur progressivement plus chaude selon la série (de `#4A8AE5` bleu froid pour 1 jour vers `#F2A423` or pour 7+ jours). Micro-animation : pulse infini à 4s de cycle sur l'indicateur actif.

**Classement (leaderboard) :**
Rang #1 : fond léger or `#FFF5E0`, icône podium SVG or. Rang #2 : fond `#F5F7FC`. Rang #3 : fond bronze doux. Chiffres de rang en JetBrains Mono 700.

### États vides & skeleton

**Skeleton loaders :** Formes exactes du contenu cible, fond `#EEF2FA`, animation shimmer `linear-gradient(90deg, transparent, rgba(255,255,255,0.7), transparent)` en boucle à 1.4s. Jamais de spinner circulaire générique.

**État vide :** Illustration SVG custom (aucun emoji, aucune photo stock). Titre en Sora 500, description en Outfit 400 max 50 chars. Un seul CTA bleu primaire.

**État d'erreur :** Message inline, jamais de modale d'alerte. Texte précis et actif : "Connexion impossible. Vérifier votre réseau." pas "Oups, quelque chose a mal tourné".

---

## 5. Layout Principles

### Philosophie

CSS Grid partout. Jamais de `calc()` en pourcentages pour les colonnes. `min-height: 100dvh` obligatoire sur toutes les sections plein écran — jamais `100vh` (bug iOS Safari).

Max-width conteneur : `1400px`, centré avec `margin: auto`. Padding horizontal : `clamp(1.5rem, 5vw, 3.5rem)`.

### Hero section

**Jamais de héros centré.** Layout split-screen systématique :
- Colonne gauche (55%) : Headline Sora display, sous-titre Outfit, CTA unique
- Colonne droite (45%) : Visuel de produit, screenshot de l'app, ou composition de cartes UI animées (pas une photo stock)

Le titre hero peut intégrer un élément visuel inline au niveau de la typographie — ex: une petite carte de profil élève incrustée entre deux mots du titre — mais uniquement si le visuel a une function narrative directe. Aucun élément ne se chevauche.

### Sections fonctionnelles

**Features :** Layout en zig-zag 2 colonnes alternantes (image gauche + texte droite, puis texte gauche + image droite). Aucun grille 3 colonnes identiques.

**Dashboard principal :** Sidebar gauche (240–280px fixe) + zone de contenu principale. Sidebar fond `#060E1E`. Jamais de top navigation sur desktop.

**Résultats et statistiques :** Grid 2 colonnes pour les KPIs larges. Ligne de stats numériques en JetBrains Mono avec labels en Outfit overline.

**Mentors / établissements :** Grille masonry 2–3 colonnes avec hauteurs variables selon contenu — jamais forcé à la même hauteur.

### Espacement

Espacement vertical de sections : `clamp(4rem, 8vw, 8rem)`.
Padding interne cards : `28px` (desktop) → `20px` (mobile).
Gap entre éléments de liste : `16px`.
Gap entre sections majeures d'une page : `80–120px`.

---

## 6. Motion & Interaction

### Moteur de base

Spring physics par défaut : `stiffness: 100, damping: 20`. Résultat : naturel et légèrement pesant, jamais linéaire.

Toutes les animations passent exclusivement par `transform` et `opacity`. Aucune animation de `top`, `left`, `width`, `height`, `color`, `background-color` directe.

Grain/noise : pseudo-élément `::before` en position `fixed`, `pointer-events: none`, `z-index: 999`. SVG feTurbulence. Opacité 0.025–0.04.

### Révélations au scroll

Éléments entrant dans le viewport : `translateY(28px) opacity(0)` → `translateY(0) opacity(1)`, durée 700ms, cubic-bezier `(0.22, 1, 0.36, 1)`.

Listes et grilles : cascade staggerée avec délai de `80ms` entre chaque élément. Jamais tout monté simultanément.

### Micro-interactions permanentes

**Streak actif :** Pulse doux à `scale(1.04)` en boucle 4s sur l'indicateur.
**Barre XP :** Shimmer gold qui traverse la barre toutes les 6s en idle.
**Bouton CTA principal :** Légère lueur bleue pulsante en `box-shadow` à 0.5 amplitude, 3s cycle — uniquement si aucune interaction n'a eu lieu depuis 8s (idle state).
**Notifications badge :** Micro-bounce `scale(1.2)` → `scale(1)` au mount, spring.

### Transitions de navigation

Entrée de page : `translateX(12px) opacity(0)` → position naturelle, 350ms. Pas de fade total sur toute la page.

Modales et drawers : slide-over depuis le bas sur mobile, slide-in depuis la droite sur desktop. Spring physics. Overlay backdrop `rgba(6,14,30,0.55)` avec blur `8px`.

---

## 7. Anti-Patterns — Interdictions absolues

### Visuels

- Aucun emoji dans l'interface applicative — icônes SVG custom uniquement
- Aucun dégradé violet/néon (`#7C3AED`, `#8B5CF6`, etc.) — pas de couleur hors palette
- Aucun glow extérieur coloré sur les boutons (`box-shadow: 0 0 20px #1060CF`) — ombres teintées uniquement, décalées
- Aucun fond pure noir `#000000` — Deep Navy `#060E1E` minimum
- Aucune photo stock "équipe diversifiée qui sourit" — illustrations SVG ou screenshots produit réels
- Aucune image Unsplash avec lien cassé — utiliser `picsum.photos/seed/{name}/W/H` uniquement si nécessaire

### Layout

- Aucun héros centré avec texte + bouton en colonne verticale centrée
- Aucune grille 3 colonnes identiques pour les features
- Aucun `height: 100vh` — uniquement `min-height: 100dvh`
- Aucun `z-index: 9999` arbitraire — échelle structurée documentée
- Aucun élément qui se chevauche par accident — séparation spatiale nette

### Typographie

- Aucune police `Inter` — trop associée aux produits SaaS génériques
- Aucune police serif dans l'interface applicative
- Aucun titre en majuscules intégrales sur plus de 3 mots
- Aucun texte gradient sur des titres de grande taille (>40px) — réservé aux micro-accents
- Aucun `font-weight: 900` sur du corps de texte

### Contenu

- Aucun chiffre rond inventé (`99%`, `50K+`, `100%`) — mesures organiques uniquement
- Aucun nom générique (`Jean Dupont`, `Marie Martin`, `Acme Corp`)
- Aucun placeholder latin (`Lorem ipsum`)
- Aucun cliché EdTech : "Transformez votre avenir", "Apprenez sans limites", "La révolution de l'éducation"
- Aucun message de succès avec `!` — confiance sobre : "Inscription confirmée." pas "Super, vous êtes inscrit !"
- Aucun "Oups !" dans les messages d'erreur — précision directe uniquement

### Couleurs de marque

- L'or `#F2A423` ne doit jamais apparaître sur un bouton d'action standard (S'inscrire, Continuer, Envoyer)
- Le bleu `#1060CF` ne doit jamais apparaître sur un élément de score XP ou badge de récompense
- Ces deux couleurs ont des rôles sémantiques opposés et complémentaires — les mélanger brise le langage visuel

---

## 8. Usage dans Google Stitch

Pour chaque nouveau prompt Stitch, commencer par :

> "Génère un écran [nom de l'écran] pour ActivEducation en respectant strictement ce DESIGN.md. Police Sora pour les titres, Outfit pour le corps, JetBrains Mono pour les données numériques. Fond principal `#F5F7FC`. Bleu primaire `#1060CF` pour toutes les actions. Or `#F2A423` uniquement pour les éléments de gamification. Aucun emoji. Aucune grille de 3 colonnes identiques. Layout asymétrique."

### Écrans à générer en priorité

1. **Home / Dashboard** — Header sombre + cards stats + barre XP + section tests recommandés
2. **Test d'orientation** — Progression step-by-step, barre de progression bleue, layout focus/centré
3. **Profil élève** — Stats gamification, badges, historique, leaderboard rank
4. **Catalogue mentors** — Grille masonry, filtres, cards mentor avec spécialité + disponibilité
5. **Résultats d'orientation** — Visualisation radar/bar chart, recommandations carrières
6. **Landing page** — Split-screen héro, stats organiques, features en zig-zag, formulaire waitlist
7. **Onboarding** — Flow 4 étapes, progression pilule, questions avec choix illustrés

---

## 9. Tokens de référence rapide

```
--color-primary:        #1060CF
--color-primary-dark:   #0A45A0
--color-primary-light:  #4A8AE5
--color-primary-surface:#E8F0FE

--color-gold:           #F2A423
--color-gold-dark:      #CC8800
--color-gold-light:     #FFD166
--color-gold-surface:   #FFF5E0

--color-canvas:         #F5F7FC
--color-surface:        #FFFFFF
--color-surface-alt:    #EEF2FA
--color-dark-base:      #060E1E
--color-dark-surface:   #0B1C3C

--color-text-primary:   #0D1832
--color-text-secondary: #4A6280
--color-text-tertiary:  #8AAAC0
--color-text-light:     #E4EEF8

--font-display:         'Sora', system-ui, sans-serif
--font-body:            'Outfit', system-ui, sans-serif
--font-mono:            'JetBrains Mono', monospace

--radius-sm:    8px
--radius-md:    12px
--radius-lg:    20px
--radius-xl:    28px
--radius-pill:  100px

--shadow-card:    0 4px 20px rgba(13,24,50,0.07)
--shadow-card-hover: 0 12px 36px rgba(10,69,160,0.14)
--shadow-blue:    0 4px 16px rgba(10,69,160,0.35)
--shadow-gold:    0 4px 16px rgba(204,136,0,0.32)

--transition-spring: cubic-bezier(0.22, 1, 0.36, 1)
--transition-ui:     cubic-bezier(0.4, 0, 0.2, 1)
--duration-fast:     200ms
--duration-normal:   320ms
--duration-reveal:   700ms
```

---

*Document généré le 14 avril 2026. À mettre à jour à chaque évolution majeure de l'identité visuelle.*
