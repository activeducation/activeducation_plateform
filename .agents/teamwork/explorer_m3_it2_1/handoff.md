# Rapport d'Investigation Technique — Résolution TS2322 (orientation.ts)

**Agent** : `explorer_m3_it2_1` (teamwork_preview_explorer)  
**Date** : 2026-09-30T23:50:00Z  
**Destinataire** : Agent Orchestrateur (`f3d00c44-f96b-4e02-b1e0-7ca7de550c74`)  
**Fichier Cible** : `d:\ActivEducation\web\src\lib\orientation.ts`  
**Objet** : Analyse de l'erreur TypeScript `TS2322` aux lignes 887 et 1089 et recommandation de correctif pour `npm run build`

---

## 1. Observation

### 1.1 Contexte et Localisation des Erreurs de Compilation
Lors de la vérification de la compilation du projet Next.js (`npm run build` / `next build` avec `tsconfig.json` sous `strict: true`), le compilateur TypeScript signale deux erreurs bloquantes `TS2322` :

```text
src/lib/orientation.ts(887,7): error TS2322: Type 'RiasecScores' is not assignable to type 'Record<string, number>'.
  Index signature for type 'string' is missing in type 'RiasecScores'.
src/lib/orientation.ts(1089,9): error TS2322: Type 'RiasecScores' is not assignable to type 'Record<string, number>'.
  Index signature for type 'string' is missing in type 'RiasecScores'.
Failed to type check.
```

### 1.2 Examen du Code Source dans `web/src/lib/orientation.ts`

#### A. Définition de `RiasecScores` (Lignes 76-83) :
```typescript
export interface RiasecScores {
  R: number; // Réaliste
  I: number; // Investigateur
  A: number; // Artistique
  S: number; // Social
  E: number; // Entreprenant
  C: number; // Conventionnel
}
```
L'interface `RiasecScores` est déclarée avec le mot-clé `interface` et ne définit que 6 propriétés fixes de type `number`. Aucune signature d'index (`[key: string]: number;`) n'y figure.

#### B. Définition de `MatchProfile` (Lignes 85-94) :
```typescript
export interface MatchProfile {
  code: string;
  title: string;
  description: string;
  summary?: string; // Alias
  dominantTraits: string[];
  strengths: string[];
  advice: string;
  scores?: Record<string, number>;
}
```
La propriété `scores` est typée comme un dictionnaire générique `Record<string, number> | undefined`.

#### C. Ligne 887 dans `generateDeterministicMatch` (Lignes 877-888) :
```typescript
export function generateDeterministicMatch(scores: RiasecScores): MatchResponse {
  // ...
  const response: MatchResponse = {
    success: true,
    profile: {
      code,
      title: stripEmojis(archetype.title),
      description: stripEmojis(archetype.description),
      summary: stripEmojis(archetype.description),
      dominantTraits: dominantTraits.map(stripEmojis),
      strengths: archetype.strengths.map(stripEmojis),
      advice: stripEmojis(archetype.advice),
      scores, // <-- Ligne 887 : Assignation de scores (type RiasecScores) dans profile.scores (attendu: Record<string, number>)
    },
    // ...
```

#### D. Ligne 1089 dans `generateGroqMatch` (Lignes 1075-1090) :
```typescript
export async function generateGroqMatch(
  scores: RiasecScores,
  context?: { schoolLevel?: string; serieBac?: string; city?: string }
): Promise<MatchResponse> {
  // ...
    const result: MatchResponse = {
      success: true,
      profile: {
        code: stripEmojis(String(parsed.profile.code || code)),
        title: stripEmojis(String(parsed.profile.title || 'Profil Stratégique & Technologique')),
        description: stripEmojis(String(parsed.profile.description || parsed.profile.summary || 'Profil d’excellence.')),
        summary: stripEmojis(String(parsed.profile.summary || parsed.profile.description || 'Profil d’excellence.')),
        dominantTraits: Array.isArray(parsed.profile.dominantTraits)
          ? parsed.profile.dominantTraits.map((t: unknown) => stripEmojis(String(t)))
          : [topTraits],
        strengths: Array.isArray(parsed.profile.strengths)
          ? parsed.profile.strengths.map((s: unknown) => stripEmojis(String(s)))
          : ['Rigueur analytique', 'Autonomie'],
        advice: stripEmojis(String(parsed.profile.advice || 'Poursuivez un cursus d’enseignement supérieur adapté.')),
        scores, // <-- Ligne 1089 : Assignation de scores (type RiasecScores) dans profile.scores (attendu: Record<string, number>)
      },
      // ...
```

---

## 2. Logic Chain

1. **Règle de Typage TypeScript (`strict: true`)** :
   - En TypeScript, le type utilitaire standard `Record<string, number>` équivaut à `{ [x: string]: number }`, c'est-à-dire un type requérant formellement une signature d'index de chaîne de caractères.
   - Une déclaration via `interface RiasecScores { R: number; ... }` est un type ouvert (open interface) qui ne génère **pas** de signature d'index implicite `[key: string]: number`, même si l'ensemble de ses propriétés nommées est de type `number` (comportement officiel documenté dans la FAQ TypeScript).
2. **Origine directe de l'erreur TS2322** :
   - Dans `generateDeterministicMatch` (ligne 819) et `generateGroqMatch` (ligne 928), l'argument `scores` est explicitement typé `RiasecScores`.
   - Aux lignes 887 et 1089, l'objet littéral instanciant l'interface `MatchProfile` reçoit la propriété `scores`.
   - TypeScript tente de vérifier si `RiasecScores` est assignable à `Record<string, number> | undefined`.
   - Constatant l'absence de signature d'index sur `interface RiasecScores`, TypeScript rejette l'affectation avec `TS2322: Index signature for type 'string' is missing in type 'RiasecScores'`.
3. **Analyse des Options de Résolution** :
   - **Option 1 : Ajouter la signature d'index `[key: string]: number;` dans `RiasecScores`** :
     - Rend `RiasecScores` directement sous-type de `Record<string, number>`.
     - Résout immédiatement l'erreur aux lignes 887 et 1089.
     - Sécurise également d'autres passages du code : `calculateRiasecScores` (ligne 637) acceptant `providedScores?: Record<string, number>` et `matchOrientation` (ligne 1106) acceptant `scores?: Record<string, number>`.
   - **Option 2 : Étendre le type dans `MatchProfile` : `scores?: RiasecScores | Record<string, number>;`** :
     - Exprime explicitement dans l'interface `MatchProfile` que le profil psychologique stocke prioritairement les scores dimensionnels RIASEC typés, tout en restant ouvert à un dictionnaire générique (utile lors de la désérialisation JSON).
     - Résout également l'erreur aux lignes 887 et 1089 car `scores: RiasecScores` satisfait directement le premier membre de l'union.
   - **Option 3 : La Combinaison Synergique (Approche Recommandée)** :
     - Appliquer à la fois l'index signature `[key: string]: number;` dans `RiasecScores` ET l'union `scores?: RiasecScores | Record<string, number>;` dans `MatchProfile`.
     - *Pourquoi ?* Cette approche offre la robustesse maximale : elle garantit une compatibilité structurelle totale avec tous les consommateurs de `Record<string, number>` tout en offrant aux développeurs et aux outils d'analyse statique l'autocomplétion et la clarté sémantique sur `profile.scores`.
4. **Vérification d'Impact sur les Consommateurs Aval** :
   - `web/src/components/orientation/OrientationResults.tsx` :
     Ligne 40 : `const scores = profile.scores as Record<string, number> | undefined;`
     Ligne 104-106 : `scores[dim] ?? scores[riasecLabels[dim]] ?? 50;`
     -> Avec l'Option 3, ce code fonctionne sans modification et sans avertissement.
   - `web/src/app/api/match/route.ts` :
     Ligne 16 : `const scores = (body.scores || body.dimensionScores) as Record<string, number> | undefined;`
     -> Entièrement compatible.
   - Scripts de test (`test-match.js`, `test-orientation-generate.js`) :
     -> Fonctionnent sans la moindre régression.

---

## 3. Caveats

1. **Isolation du Rôle (Explorer en Mode Read-Only)** :
   - Conformément aux consignes de l'archétype `explorer`, ce rapport ne modifie pas directement les fichiers du projet. La proposition est formalisée sous forme d'un diff patch précis et univoque à destination de l'agent implémenteur (`worker`).
2. **Autres Corrections Requises pour l'Itération 2** :
   - Bien que le présent rapport se focalise sur l'erreur `TS2322` demandée par le dispatch, le worker devra également intégrer les correctifs identifiés lors de la Gate 1 (`GATE_STATUS.md`), notamment :
     - L'alignement des IDs de carrières dans `generateDeterministicOrientationM3` (lignes 1197-1217) avec `TOGO_CAREERS_CATALOG`.
     - La sécurisation de `Array.isArray(parsed.recommendedSchools)` dans `web/src/app/student/orientation/resultats/page.tsx`.

---

## 4. Conclusion & Recommandation Actionnable

### 4.1 Diagnostic
L'erreur de compilation `TS2322` aux lignes 887 et 1089 de `web/src/lib/orientation.ts` est due à l'incompatibilité de type entre l'interface nominale `RiasecScores` (sans signature d'index) et la propriété `MatchProfile.scores` typée `Record<string, number>`.

### 4.2 Recommandation : Le Correctif le Plus Propre

Modifier `web/src/lib/orientation.ts` aux lignes 76-94 comme suit :

#### Code Actuel (Avant) :
```typescript
// Lignes 76-94 de web/src/lib/orientation.ts
export interface RiasecScores {
  R: number; // Réaliste
  I: number; // Investigateur
  A: number; // Artistique
  S: number; // Social
  E: number; // Entreprenant
  C: number; // Conventionnel
}

export interface MatchProfile {
  code: string;
  title: string;
  description: string;
  summary?: string; // Alias
  dominantTraits: string[];
  strengths: string[];
  advice: string;
  scores?: Record<string, number>;
}
```

#### Code Recommandé (Après) :
```typescript
// Lignes 76-94 de web/src/lib/orientation.ts
export interface RiasecScores {
  [key: string]: number;
  R: number; // Réaliste
  I: number; // Investigateur
  A: number; // Artistique
  S: number; // Social
  E: number; // Entreprenant
  C: number; // Conventionnel
}

export interface MatchProfile {
  code: string;
  title: string;
  description: string;
  summary?: string; // Alias
  dominantTraits: string[];
  strengths: string[];
  advice: string;
  scores?: RiasecScores | Record<string, number>;
}
```

### 4.3 Diff Patch Formel pour le Worker :
```diff
--- a/web/src/lib/orientation.ts
+++ b/web/src/lib/orientation.ts
@@ -76,6 +76,7 @@ export interface Institution {
 }
 
 export interface RiasecScores {
+  [key: string]: number;
   R: number; // Réaliste
   I: number; // Investigateur
   A: number; // Artistique
@@ -90,7 +91,7 @@ export interface MatchProfile {
   dominantTraits: string[];
   strengths: string[];
   advice: string;
-  scores?: Record<string, number>;
+  scores?: RiasecScores | Record<string, number>;
 }
 
 export interface MatchResponse {
```

---

## 5. Verification Method

Pour vérifier de manière indépendante et reproductible la validité de ce correctif :

### 5.1 Vérification Statique TypeScript
Depuis le répertoire `d:\ActivEducation\web` :
```powershell
npx tsc --noEmit
```
**Critère de succès** : Aucune erreur `TS2322` aux lignes 887 et 1089. Code de sortie `0`.

### 5.2 Vérification du Build Next.js
Depuis le répertoire `d:\ActivEducation\web` :
```powershell
npm run build
```
**Critère de succès** : Génération réussie de toutes les routes statiques et dynamiques (`/orientation`, `/student/orientation`, `/student/orientation/resultats`, `/api/match`, `/api/orientation/generate`) sans `Failed to type check`. Code de sortie `0`.

### 5.3 Exécution des Tests Automatisés
Depuis le répertoire `d:\ActivEducation\web` :
```powershell
node test-match.js
node test-orientation-generate.js
```
**Critère de succès** : 100% des assertions réussies, code de sortie `0`.
