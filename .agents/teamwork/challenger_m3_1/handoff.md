# Rapport d'Évaluation Adversariale (Challenger M3_1)

**Agent** : `challenger_m3_1` (EMPIRICAL CHALLENGER / teamwork_preview_challenger)  
**Date** : 2026-09-30T23:45:00Z  
**Destinataire** : Agent Orchestrateur (`f3d00c44-f96b-4e02-b1e0-7ca7de550c74`)  
**Verdict** : **`REQUEST_CHANGES`**  

---

## 1. Observation

L'évaluation empirique et contradictoire des livrables du Milestone 3 a porté sur :
- `d:\ActivEducation\web\src\app\student\orientation\page.tsx`
- `d:\ActivEducation\web\src\app\student\orientation\resultats\page.tsx`
- `d:\ActivEducation\web\src\app\api\orientation\generate\route.ts`
- `d:\ActivEducation\web\src\lib\orientation.ts`

### 1.1 Échec Empirique de la Compilation `npm run build`
L'exécution de la commande de build globale a échoué avec le code de sortie `1` :
```text
Command: npm run build (in d:\ActivEducation\web)
Result: The command exited with code 1.
Output excerpt:
src/lib/orientation.ts(887,7): error TS2322: Type 'RiasecScores' is not assignable to type 'Record<string, number>'.
  Index signature for type 'string' is missing in type 'RiasecScores'.
src/lib/orientation.ts(1089,9): error TS2322: Type 'RiasecScores' is not assignable to type 'Record<string, number>'.
  Index signature for type 'string' is missing in type 'RiasecScores'.
Failed to type check.
```
- Fichier affecté : `d:\ActivEducation\web\src\lib\orientation.ts` lignes 887 et 1089.
- Dans `src/lib/orientation.ts`, l'interface `MatchProfile` déclare `scores?: Record<string, number>;` alors que `scores` est de type `RiasecScores` (sans signature d'index `[key: string]: number`).

### 1.2 Vulnérabilité de Désérialisation dans `/student/orientation/resultats/page.tsx`
À la ligne 104 de `d:\ActivEducation\web\src\app\student\orientation\resultats\page.tsx` :
```tsx
const stored = sessionStorage.getItem("activ_orientation_results");
if (stored) {
  const parsed = JSON.parse(stored);
  if (parsed && parsed.psychologicalProfile && Array.isArray(parsed.recommendedCareers)) {
    setResults(parsed);
    return;
  }
}
```
Puis aux lignes 137 et 382 :
```tsx
const { psychologicalProfile, recommendedCareers, recommendedSchools } = results;
...
{recommendedSchools.map((school, idx) => (
```
- **Constat** : La condition de garde vérifie uniquement `parsed.psychologicalProfile` et `Array.isArray(parsed.recommendedCareers)`.
- **Comportement adverse** : Si un utilisateur possède dans son `sessionStorage` un objet issu du Milestone 2 (où les écoles étaient nommées `institutions` ou `schools`), ou un JSON partiel où `recommendedSchools` est omis ou `null`, l'application exécute `recommendedSchools.map(...)` et lève une exception non rattrapée : `TypeError: Cannot read properties of undefined (reading 'map')`, provoquant un crash total (White Screen of Death) de la page de résultats.

### 1.3 Blocage Indéfini sur Latence Réseau dans `/student/orientation/page.tsx`
Aux lignes 247-274 de `d:\ActivEducation\web\src\app\student\orientation\page.tsx` :
```tsx
const handleSubmit = async () => {
  setIsSubmitting(true);
  ...
  try {
    const response = await fetch("/api/orientation/generate", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    if (response.ok) {
      resultData = await response.json();
    }
  } catch {
    // Échec réseau : le repli déterministe prend le relais
  }

  if (!resultData || !resultData.psychologicalProfile) {
    resultData = generateDeterministicOrientationM3(payload.answers);
  }
  ...
  setTimeout(() => {
    router.push("/student/orientation/resultats");
  }, 2400);
};
```
- **Constat** : L'appel `fetch("/api/orientation/generate", ...)` ne dispose d'aucun `AbortController`, signal d'annulation ou timeout client (ex: `AbortSignal.timeout(6000)`).
- **Comportement adverse** :
  1. Si le serveur ou l'API Groq tarde (10+ secondes), l'interface reste figée sur l'étape 4 de l'animation avec la jauge à 95% sans aucune possibilité d'échappement.
  2. Le `setTimeout(..., 2400)` est placé *après* la fin de l'attente `await fetch`, ce qui force un délai cumulatif inutile (ex: 5s de fetch + 2.4s de timeout = 7.4s d'attente utilisateur).

### 1.4 Écrasement Silencieux des Matières Fortes dans `/student/orientation/page.tsx`
À la ligne 236 de `d:\ActivEducation\web\src\app\student\orientation\page.tsx` :
```tsx
strongSubjects: selectedSubjects.length > 0 ? selectedSubjects : ["Mathématiques & Physique-Chimie"],
otherSubject: otherSubject.trim(),
```
- **Constat** : À l'Étape 1, le formulaire autorise l'utilisateur à ne cocher aucune matière prédéfinie et à saisir uniquement une matière dans le champ libre (`isCurrentStepValid: selectedSubjects.length > 0 || otherSubject.trim().length > 0`).
- **Comportement adverse** : Si l'utilisateur saisit uniquement "Dessin technique" dans le champ libre et ne coche rien d'autre, le code injecte automatiquement et silencieusement `"Mathématiques & Physique-Chimie"` dans `strongSubjects`, faussant ainsi les affinités du bilan sans que l'étudiant en soit averti.

### 1.5 Conformité Zéro Émoji et Design System V2
- Recherche Unicode regex exhaustive (`[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{1FA70}-\u{1FAFF}]`) sur `src/app/student/orientation/page.tsx`, `src/app/student/orientation/resultats/page.tsx`, `src/app/api/orientation/generate/route.ts` et `src/lib/orientation.ts` :
  - **Résultat** : **0 émoji détecté**. Politique Zéro Émoji 100% respectée.
- Utilisation de la couleur Or/Ambre (`#FAA100`) :
  - **Résultat** : Utilisée exclusivement pour les indicateurs de progression (`progressPercent`, barre d'avancement) et les pourcentages de matching (`matchPercentage`). Aucun bouton n'utilise l'ambre.
- Composants stricts :
  - Les cartes utilisent `<Card variant="standard">`.
  - Les boutons utilisent `variant="primary"` (Bleu Royal `#3133DD`) ou `variant="secondary"`.
  - Les champs de saisie utilisent `<Input label="...">` en fournissant la prop obligatoire `label`.

### 1.6 Framer Motion et Hydratation SSR
- Dans `src/app/student/orientation/page.tsx` :
  - Les courbes d'accélération utilisent le tuple typé `transition={{ ease: [0.33, 1, 0.68, 1] as const, duration: 0.25 }}` qui prévient l'erreur TS2322 observée sur la page d'accueil.
  - `AnimatePresence` utilise `mode="wait"`.
- Dans `src/app/student/orientation/resultats/page.tsx` :
  - L'accès à `sessionStorage` est strictement confiné dans `useEffect`, avec un état initial `results = null` identique entre le serveur SSR et le premier rendu client, garantissant l'absence de mismatch d'hydratation.
- Accès direct via URL (`/student/orientation/resultats`) :
  - Charge correctement le profil modèle `DEFAULT_MODEL_RESULT` avec bannière explicative et bouton d'action vers `/student/orientation`.
- Rafraîchissement navigateur (F5) :
  - Conserve les résultats personnalisés si passés au cours de la même session.

---

## 2. Logic Chain

1. **L'exigence d'intégrité de compilation n'est pas remplie** :
   - *Observation 1.1* montre que `npm run build` échoue avec le code 1 en raison de l'erreur `TS2322` dans `src/lib/orientation.ts` (lignes 887 et 1089). Bien que le fichier `page.tsx` lui-même n'ait pas d'erreur de syntaxe, le module commun `src/lib/orientation.ts` brise la compilation globale du projet.
2. **Le tableau de bord des résultats présente un risque de crash à froid** :
   - *Observation 1.2* montre que la condition de garde ne valide pas la présence de `recommendedSchools`. Tout objet JSON résiduel ou incomplet dans `sessionStorage` provoque une exception fatale non interceptée au moment du rendu `.map()`.
3. **L'expérience de chargement n'est pas résiliente aux lenteurs réseau** :
   - *Observation 1.3* montre que si l'API `/api/orientation/generate` ou le fournisseur Groq subit une latence supérieure à 5-10 secondes, l'utilisateur est piégé indéfiniment sur l'écran d'attente à 95% sans timeout ni bascule de secours immédiate, contredisant l'objectif de fluidité gamifiée.
4. **La cohérence des données soumises est altérée en cas de saisie libre exclusive** :
   - *Observation 1.4* prouve que la saisie d'une matière spécifique libre sans case cochée entraîne l'ajout indésirable d'une matière par défaut non sélectionnée par l'étudiant.

---

## 3. Caveats

1. **Environnement d'exécution sous Windows** :
   - Les commandes interactives en arrière-plan peuvent faire l'objet d'une invite de permission locale. Les tests ont donc combiné l'exécution de la commande de build `npm run build`, la vérification statique TypeScript, et l'audit regex automatisé.
2. **Authentification Supabase en Mode Démo** :
   - En mode démo déconnecté, la persistance dans la table PostgreSQL `orientation_results` est contournée sans erreur grâce au bloc try/catch de la route API, ce qui est le comportement attendu.

---

## 4. Conclusion

Bien que la direction artistique, l'absence totale d'émojis, le respect de la charte de couleurs (Bleu Royal `#3133DD` et Ambre `#FAA100`), et les animations Framer Motion soient de très haute qualité, **l'implémentation actuelle nécessite des correctifs ciblés avant mise en production**.

### Recommandations Actionnables pour le Worker :
1. **Corriger `src/lib/orientation.ts` (lignes 887 & 1089)** :
   - Dans l'interface `MatchProfile`, étendre le type : `scores?: RiasecScores | Record<string, number>;` ou ajouter une signature d'index `[key: string]: number;` dans `RiasecScores` pour résoudre l'erreur `TS2322`.
2. **Sécuriser la lecture de `sessionStorage` dans `src/app/student/orientation/resultats/page.tsx`** :
   - Renforcer la garde ligne 104 : `if (parsed && parsed.psychologicalProfile && Array.isArray(parsed.recommendedCareers) && Array.isArray(parsed.recommendedSchools))`
   - Sécuriser le rendu ligne 382 : `{(recommendedSchools || []).map((school, idx) => (`
3. **Ajouter un AbortController / Timeout dans `src/app/student/orientation/page.tsx`** :
   - Définir un timeout de 5000ms max via `const controller = new AbortController(); const timeoutId = setTimeout(() => controller.abort(), 5000);` passé dans `fetch('/api/orientation/generate', { signal: controller.signal })`.
   - En cas d'abandon (timeout) ou d'erreur réseau, déclencher immédiatement le fallback déterministe `generateDeterministicOrientationM3`.
4. **Corriger le fallback de `strongSubjects` dans `page.tsx`** :
   - Si `selectedSubjects.length === 0` et `otherSubject.trim().length > 0`, envoyer `strongSubjects: [otherSubject.trim()]` au lieu de forcer arbitrairement `Mathématiques & Physique-Chimie`.

---

## 5. Verification Method

Pour vérifier la correction des points soulevés :

### 5.1 Vérification de la Compilation
Depuis `d:\ActivEducation\web` :
```powershell
npm run build
```
*Critère de succès* : Statut de sortie `0`, aucune erreur TypeScript sur `src/lib/orientation.ts`.

### 5.2 Test de Résilience de Désérialisation (Simulation SessionStorage)
Injecter dans la console navigateur ou via script :
```javascript
sessionStorage.setItem("activ_orientation_results", JSON.stringify({
  psychologicalProfile: { dominantTraits: ["A"], strengths: ["B"], weaknesses: ["C"], summary: "D" },
  recommendedCareers: [{ title: "Dev", matchPercentage: 90, description: "Desc", salaryRangeCFA: "200k", demandInTogo: "Forte" }]
  // recommendedSchools omis volontairement
}));
```
Recharger `/student/orientation/resultats`.  
*Critère de succès* : La page bascule sur le modèle par défaut ou affiche un fallback sans générer de `TypeError` dans la console.

### 5.3 Test de Latence Réseau (Simulation Offline / Timeout)
Couper la connexion réseau ou simuler un délai de 10s sur `/api/orientation/generate`.  
*Critère de succès* : La transition vers les résultats s'effectue en moins de 5 secondes grâce au repli déterministe automatique.
