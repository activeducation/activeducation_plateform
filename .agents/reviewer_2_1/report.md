# Milestone 2 Review & Adversarial Audit Report: Module d'Orientation Scolaire & Professionnelle

**Auteur** : `reviewer_2_1` (Reviewer & Adversarial Critic)  
**Date** : 2026-09-22T15:08:00Z  
**Codebase cible** : `d:\ActivEducation\web`  
**Milestone** : M2 (Module d'Orientation Scolaire & Professionnelle End-to-End)  

---

## 1. Review Summary

**Verdict** : **APPROVE**

Les livrables de la Milestone 2 satisfont l'intégralité des exigences fonctionnelles, techniques, ergonomiques et visuelles définies dans `ORIGINAL_REQUEST.md` (§ 2026-09-22T11:31:59Z) et `PROJECT.md`. Aucun motif d'invalidation ni violation d'intégrité n'a été détecté.

| Périmètre | Statut | Observations clés |
|---|---|---|
| **R1. Test Interactif Gamifié** | **CONFORME** | Swipe tactile/souris fluide via `framer-motion`, résistance élastique, rotation dynamique `[-18, 18]` deg, pile de 3 cartes avec `AnimatePresence`, 12 questions RIASEC étalonnées, contrôles complets (boutons Passer/Aimer, échelle Likert 1-5, raccourcis clavier). |
| **R2. Matching IA & Fallback Togo** | **CONFORME** | Route Handler `/api/match`, intégration Groq (`llama-3.3-70b-versatile`) avec persona AÏDA et timeout 9s, bascule transparente vers un moteur déterministe hors-ligne exploitant les 16 métiers porteurs et 111 établissements MESR/CAMES togolais. |
| **R3. Tableau de Bord de Résultats** | **CONFORME** | Profil psychologique Holland complet (traits, forces, conseil AÏDA), exactement 3 métiers d'avenir avec salaires FCFA réels, exactement 3 écoles togolaises agréées, design flat DA V2. |
| **Règle Stricte Ambre (#FAA100)** | **CONFORME** | L'ambre `#FAA100` est réservé **exclusivement** aux scores de matching (`% Match`) et aux jauges de progression RIASEC dans le dashboard. Aucune utilisation en fond de bouton ou ornementation abusive. |
| **Règle Absolue Zéro Emoji** | **CONFORME** | 0 emoji dans l'ensemble des fichiers source, métadonnées, mock data et réponses d'API. Iconographie 100% assurée par les SVG `lucide-react`. Assainissement préventif actif via `stripEmojis` et `sanitizeObject`. |
| **Mises à jour des Composants UI** | **CONFORME** | `Card.tsx` supporte explicitement `variant?: 'standard' | 'gamification' | 'dark'` et `interactive`. `Navbar.tsx` intègre le lien « Orientation » et les ancres de navigation. `page.tsx` intègre les CTA et la bannière M2. |
| **Contrôle d'Intégrité Anti-Triche** | **INTÈGRE** | Aucune réponse en dur (hardcoded outputs), aucune façade factice, aucun résultat de test falsifié, algorithme de notation Holland réel et dynamique. |

---

## 2. Verified Claims

1. **Intégration de Framer Motion & Gestes de Glisser** :
   - Fichier : `web/src/components/orientation/SwipeCard.tsx`
   - Vérification : Import et utilisation de `motion.div`, `useMotionValue(0)`, `useTransform` pour `rotate` et `opacity`, physique de drag (`drag="x"`, `dragElastic={0.7}`). Badges flottants « M'intéresse » (vert/primaire) et « Passer » asservis à l'offset de déplacement horizontal.
   - Résultat : **PASS**

2. **Accessibilité Clavier & Ergonomie Hybride** :
   - Fichier : `web/src/components/orientation/OrientationTest.tsx`
   - Vérification : Écouteur d'événements `keydown` gérant `ArrowLeft` (Passer / 1), `ArrowRight` (Aimer / 5), touches `1` à `5` (Likert direct), `Backspace` / `z` (Retour à la question précédente). Boutons d'action clairs pour les utilisateurs sur écran non tactile ou sans souris à glisser.
   - Résultat : **PASS**

3. **Questionnaire RIASEC 12 Items Entrelacés** :
   - Fichier : `web/src/lib/orientation.ts` (lignes 106-203)
   - Vérification : 12 questions (`q1` à `q12`), exactement 2 questions par dimension Holland : Réaliste (q1, q7), Investigateur (q2, q8), Artistique (q3, q9), Social (q4, q10), Entreprenant (q5, q11), Conventionnel (q6, q12).
   - Résultat : **PASS**

4. **Résultats d'Orientation & Spécificité Togolaise** :
   - Fichiers : `web/src/components/orientation/OrientationResults.tsx`, `web/src/lib/orientation.ts`
   - Vérification : Exactement 3 métiers restitués avec salaires en FCFA (ex: `250 000 - 850 000 FCFA / mois`), secteur, compétences requises et débouché. Exactement 3 établissements togolais accrédités MESR Togo / CAMES (ex: Université de Lomé, IAI-Togo, ESGIS, EAMAU).
   - Résultat : **PASS**

5. **Usage Restreint de l'Ambre (#FAA100)** :
   - Fichier : `web/src/components/orientation/OrientationResults.tsx`
   - Vérification : Recherche systématique de `#FAA100` et `gold`. Présent uniquement aux lignes 114 (pourcentage dimensionnel RIASEC), 123 (jauge de progression RIASEC) et 168 (badge `% Match` des carrières). Absent des boutons, bannières et arrière-plans généraux.
   - Résultat : **PASS**

6. **Absence Totale d'Emojis (Zéro Emoji Rule)** :
   - Fichiers : Analyse regex `[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{1FA70}-\u{1FAFF}]` sur l'ensemble du dossier `web/src` et `web/test-match.js`.
   - Vérification : 0 occurrence trouvée. Présence de fonctions de filtrage automatique `stripEmojis()` et `sanitizeObject()` dans le pipeline de données `/api/match`.
   - Résultat : **PASS**

7. **Primitif `Card.tsx` et Navigation** :
   - Fichiers : `web/src/components/ui/Card.tsx`, `web/src/components/Navbar.tsx`, `web/src/app/page.tsx`
   - Vérification : Typage `CardProps` étendu avec `variant?: 'standard' | 'gamification' | 'dark'` et `interactive?: boolean`. Navbar avec lien « Orientation » actif vers `/orientation`. Page d'accueil avec bouton héro « Passer le Test d’Orientation IA » et section promotionnelle M2.
   - Résultat : **PASS**

---

## 3. Adversarial Challenges & Stress Testing

### Challenge 1 : Risque de blocage réseau en environnement isolé (Sans clé Groq)
- **Hypothèse testée** : Si l'API Groq est injoignable, si le jeton est manquant ou si la requête expire (timeout), l'utilisateur pourrait se retrouver bloqué sur un écran de chargement infini.
- **Vérification du code** : `generateGroqMatch` dans `orientation.ts` intègre un `AbortController` (timeout de 9 secondes), vérifie la présence de `GROQ_API_KEY` dès l'entrée, et encapsule l'appel dans un bloc `try...catch` qui bascule instantanément sur `generateDeterministicMatch(scores)`.
- **Statut** : **ROBUSTE (Résolu par conception)**

### Challenge 2 : Risque de triche ou résultat en dur (Integrity Check)
- **Hypothèse testée** : Le moteur pourrait-il renvoyer toujours le même profil et les mêmes carrières sans tenir compte des réponses utilisateur ?
- **Vérification du code** : La fonction `calculateRiasecScores` effectue une normalisation réelle (0-100) en cumulant les notes des questions par dimension. Un profil avec de fortes notes en `S` génère le profil « Facilitateur Humain », tandis qu'un profil avec de fortes notes en `I` génère « Analyste Stratégique ». Les métiers sont classés par compatibilité pondérée.
- **Statut** : **INTÈGRE (Aucune triche détectée)**

### Challenge 3 : Injection ou payloads malformés sur `/api/match`
- **Hypothèse testée** : Envoi d'un corps JSON vide, partiel, ou contenant des formats inattendus (chaînes au lieu de nombres, clés de questions absentes).
- **Vérification du code** : Le Route Handler capture les erreurs JSON (`try...catch`), `calculateRiasecScores` attribue une note neutre (3) par défaut en l'absence de réponse et borne les valeurs entre 1 et 5.
- **Statut** : **ROBUSTE**

---

## 4. Minor Observations & Recommendations (Non-blocking)

1. **Typographie dans Tailwind CSS v4** :
   Dans `globals.css`, la police Hanken Grotesque est définie sur `--font-sans: "Hanken Grotesque", system-ui, sans-serif;` et appliquée à `body`. Certains composants utilisent la classe utilitaire `font-display`. Bien qu'elle hérite de la police Hanken Grotesque du body sans rupture visuelle, l'ajout explicite de `--font-display: "Hanken Grotesque", system-ui, sans-serif;` dans `@theme` pourra parfaire la déclaration des tokens à terme.
2. **Animation tactile sur terminaux mobiles étroits** :
   Le seuil de swipe fixé à 100px (`swipeThreshold = 100`) est bien calibré. Sur très petits écrans (< 360px de large), les boutons physiques d'action « Passer » et « M'intéresse » situés juste sous la carte offrent une alternative immédiate et sécurisante.

---

## 5. Audit Verdict

**APPROVE** — Le travail livré par `worker_m2` est d'un niveau technique et graphique exemplaire, rigoureusement aligné sur les contraintes académiques togolaises et les exigences strictes de la plateforme ActivEducation.
