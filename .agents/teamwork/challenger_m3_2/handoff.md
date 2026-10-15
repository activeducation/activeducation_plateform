# Rapport d'Audit Adversarial & Handoff — Challenger M3_2

**Auteur** : `challenger_m3_2` (teamwork_preview_challenger)  
**Date** : 2026-09-30T23:43:30Z  
**Verdict** : **REQUEST_CHANGES**  
**Niveau de Risque Global** : **HIGH** (Régression fonctionnelle critique sur le moteur de repli déterministe pour les filières non-technologiques)

---

## 1. Observation

### 1.1. Incohérence des identifiants Métiers dans `generateDeterministicOrientationM3`
Dans `d:\ActivEducation\web\src\lib\orientation.ts` :

Le catalogue officiel `TOGO_CAREERS_CATALOG` (lignes 206 à 479) définit les 16 métiers suivants avec leurs identifiants canoniques :
- Ligne 208 : `id: 'dev-web-mobile'`
- Ligne 225 : `id: 'data-analyst-ia'`
- Ligne 242 : `id: 'cybersecurite-reseaux'`
- Ligne 260 : `id: 'ingenieur-btp-civil'`
- Ligne 277 : `id: 'architecte-urbaniste'`
- Ligne 293 : `id: 'ingenieur-agronome'`
- Ligne 310 : `id: 'medecin-sante'`
- Ligne 327 : `id: 'pharmacien-biologiste'`
- Ligne 344 : `id: 'comptable-auditeur'`
- Ligne 361 : `id: 'banquier-analyste'`
- Ligne 378 : `id: 'marketing-digital'`
- Ligne 395 : `id: 'entrepreneur-innovation'`
- Ligne 412 : `id: 'enseignant-formateur'`
- Ligne 429 : `id: 'juriste-affaires'`
- Ligne 446 : `id: 'designer-graphique'`
- Ligne 464 : `id: 'responsable-rh'`

En revanche, dans la fonction `generateDeterministicOrientationM3` (lignes 1197 à 1217 de `src/lib/orientation.ts`), les conditions de calcul de score testent des identifiants non concordants :
```typescript
1197: if (career.id === 'dev-web-mobile') score += isTech ? 40 : 10;
1198: if (career.id === 'data-analyst-ia') score += isTech ? 38 : 8;
1199: if (career.id === 'cybersecurite-reseaux') score += isTech ? 36 : 6;
1200: if (career.id === 'ingenieur-telecom-iot') score += (isTech || isEng) ? 35 : 5;
1201: 
1202: if (career.id === 'ingenieur-btp-genie-civil') score += isEng ? 40 : 10;
1203: if (career.id === 'ingenieur-energies-renouvelables') score += (isEng || isTech) ? 38 : 8;
1204: if (career.id === 'chef-projet-logistique-portuaire') score += (isEco || isEng || allTokens.includes('port')) ? 37 : 12;
1205: 
1206: if (career.id === 'medecin-sante-publique') score += isHealth ? 40 : 5;
1207: if (career.id === 'pharmacien-biologiste') score += isHealth ? 38 : 5;
1208: if (career.id === 'ingenieur-agronome-agroalimentaire') score += (isHealth || isEng || /agri|tové|bio/i.test(allTokens)) ? 36 : 10;
1209: 
1210: if (career.id === 'comptable-auditeur') score += isEco ? 40 : 8;
1211: if (career.id === 'analyste-financier-banque') score += isEco ? 38 : 7;
1212: if (career.id === 'charge-affaires-pme') score += isEco ? 36 : 9;
1213: 
1214: if (career.id === 'designer-graphique-ui-ux') score += (isArt || isTech) ? 40 : 6;
1215: if (career.id === 'charge-communication-digitale') score += (isComm || isArt) ? 38 : 8;
1216: if (career.id === 'juriste-droit-affaires') score += isComm ? 39 : 7;
```

**Tableau comparatif des discordances :**
| ID Canonique dans `TOGO_CAREERS_CATALOG` | ID recherché dans `generateDeterministicOrientationM3` | Conséquence |
|---|---|---|
| `dev-web-mobile` | `dev-web-mobile` | ✅ Match |
| `data-analyst-ia` | `data-analyst-ia` | ✅ Match |
| `cybersecurite-reseaux` | `cybersecurite-reseaux` | ✅ Match |
| `ingenieur-btp-civil` | `ingenieur-btp-genie-civil` | ❌ **Échec silencieux** (score reste à 50) |
| `architecte-urbaniste` | *(absent du code)* | ❌ **Non géré** (score reste à 50) |
| `ingenieur-agronome` | `ingenieur-agronome-agroalimentaire` | ❌ **Échec silencieux** (score reste à 50) |
| `medecin-sante` | `medecin-sante-publique` | ❌ **Échec silencieux** (score reste à 50) |
| `pharmacien-biologiste` | `pharmacien-biologiste` | ✅ Match |
| `comptable-auditeur` | `comptable-auditeur` | ✅ Match |
| `banquier-analyste` | `analyste-financier-banque` | ❌ **Échec silencieux** (score reste à 50) |
| `marketing-digital` | `charge-communication-digitale` | ❌ **Échec silencieux** (score reste à 50) |
| `entrepreneur-innovation` | `charge-affaires-pme` | ❌ **Échec silencieux** (score reste à 50) |
| `enseignant-formateur` | *(absent du code)* | ❌ **Non géré** (score reste à 50) |
| `juriste-affaires` | `juriste-droit-affaires` | ❌ **Échec silencieux** (score reste à 50) |
| `designer-graphique` | `designer-graphique-ui-ux` | ❌ **Échec silencieux** (score reste à 50) |
| `responsable-rh` | *(absent du code)* | ❌ **Non géré** (score reste à 50) |
| *(Inexistant)* | `ingenieur-telecom-iot` | ⚠️ ID fantôme |
| *(Inexistant)* | `ingenieur-energies-renouvelables` | ⚠️ ID fantôme |
| *(Inexistant)* | `chef-projet-logistique-portuaire` | ⚠️ ID fantôme |

### 1.2. Absence de tests multi-profils dans `test-orientation-generate.js`
Dans `d:\ActivEducation\web\test-orientation-generate.js` (lignes 36 à 45) :
Le payload de test est exclusivement orienté Tech :
```javascript
const mockPayload = {
  answers: {
    interests: ['Sciences & Nouvelles Technologies', 'Bâtiment, Industrie & Ingénierie'],
    strongSubjects: ['Mathématiques & Physique-Chimie', 'Informatique & Technologies'],
    otherSubject: 'Robotique et Électronique',
    budget: 'Moyen',
    mobility: 'Grand Lomé & Région Maritime',
    currentCity: 'Lomé',
  },
};
```
Et les assertions (lignes 119 à 128) ne vérifient que le format : `length === 3`, `title.length > 3`, `salaryRangeCFA.includes('FCFA')`. Aucune assertion ne vérifie si les réponses retournées sont cohérentes avec le profil de l'étudiant. De ce fait, le script valide un test réussi alors même que le profil `Bâtiment, Industrie & Ingénierie` n'a pas déclenché `Ingénieur BTP` mais des métiers informatiques.

### 1.3. Règle absolue ZÉRO EMOJI (Vérification Regex empirique)
Recherche automatisée par expressions régulières :
- `[\x{1F300}-\x{1FAFF}\x{2600}-\x{27BF}]`
- `\p{Extended_Pictographic}`
- Caractères hors ASCII et hors alphabets latins étendus français : `[^\x00-\x7F\u00A0-\u024F\u2000-\u206F]`

Fichiers audités :
- `web/src/app/student/orientation/page.tsx` : **0 emoji détecté**
- `web/src/app/student/orientation/resultats/page.tsx` : **0 emoji détecté**
- `web/src/app/api/orientation/generate/route.ts` : **0 emoji détecté**
- `web/src/lib/orientation.ts` : **0 emoji détecté**
- `web/test-orientation-generate.js` : **0 emoji détecté**

Toutes les icônes de l'interface utilisent rigoureusement des composants vectoriels `lucide-react` (ex: `Sparkles`, `Cpu`, `Brain`, `Briefcase`, `Building2`, `TrendingUp`, `Coins`). La règle Zéro Emoji est respectée à 100%.

### 1.4. Salaires en FCFA & Établissements togolais authentiques
- Tous les métiers du catalogue `TOGO_CAREERS_CATALOG` comportent des salaires mensuels explicites en FCFA (ex: `250 000 - 850 000 FCFA / mois`).
- Tous les établissements recommandés dans les 4 branches budgétaires de `generateDeterministicOrientationM3` (lignes 1253 à 1325) sont officiels et accrédités au Togo :
  - Université de Lomé (UL) — Public
  - Université de Kara (UK) — Public
  - Institut Africain d’Informatique (IAI-Togo) — Inter-États / Public-Partenariat
  - École Supérieure de Gestion, d’Informatique et des Sciences (ESGIS) — Privé Agréé MESR / CAMES
- Les niveaux de demande sont strictement conformes à l'énumération Zod : `'Faible' | 'Moyenne' | 'Forte'`.

---

## 2. Logic Chain

1. **Prémisse 1** : L'API `/api/orientation/generate` bascule sur `generateDeterministicOrientationM3` dès que Groq n'est pas configuré, échoue ou retourne une erreur réseau (`route.ts`, ligne 101). Le frontend bascule également sur cette fonction en repli (`page.tsx`, ligne 262).
2. **Prémisse 2** : Dans `generateDeterministicOrientationM3`, chaque métier commence avec un score de base de 50 (lignes 1186-1187).
3. **Prémisse 3** : Les métiers Tech (`dev-web-mobile`, `data-analyst-ia`, `cybersecurite-reseaux`) reçoivent un bonus inconditionnel de +10, +8, +6 même lorsque `isTech` est faux (lignes 1197-1199), portant leur score minimum à 60, 58, 56.
4. **Prémisse 4** : Pour un étudiant choisissant `Santé, Biologie & Sciences Médicales` ou `Bâtiment, Industrie & Ingénierie` ou `Arts & Design` ou `Droit` :
   - `medecin-sante` a `career.id === 'medecin-sante'`. La ligne 1206 cherche `'medecin-sante-publique'`. Condition fausse -> son score reste à 50.
   - `ingenieur-btp-civil` a `career.id === 'ingenieur-btp-civil'`. La ligne 1202 cherche `'ingenieur-btp-genie-civil'`. Condition fausse -> son score reste à 50.
   - `designer-graphique` a `career.id === 'designer-graphique'`. La ligne 1214 cherche `'designer-graphique-ui-ux'`. Condition fausse -> son score reste à 50.
   - `juriste-affaires` a `career.id === 'juriste-affaires'`. La ligne 1216 cherche `'juriste-droit-affaires'`. Condition fausse -> son score reste à 50.
5. **Déduction** : Les métiers légitimes correspondant au profil de l'étudiant restent bloqués à un score de 50. Les métiers Tech obtiennent 60, 58, 56. Après tri par score décroissant (`scoredCareers.sort((a, b) => b.score - a.score)`, ligne 1222), le top 3 sélectionné pour cet étudiant non-tech est :
   1. `Développeur Web & Mobile` (60)
   2. `Data Analyst & Spécialiste IA` (58)
   3. `Architecte Réseaux & Cybersécurité` (56)
6. **Conclusion** : Le système d'orientation en mode déterministe échoue à orienter les étudiants togolais vers leurs filières d'excellence pour 11 des 16 métiers du catalogue.

---

## 3. Caveats

- **Connexion Groq en production** : Si une clé Groq valide est fournie et fonctionnelle avec accès internet, l'IA générative retourne des métiers via son prompt système. Cependant, ActivEducation est conçu pour fonctionner en mode démo / résilient sans dépendance externe obligatoire, et le fallback déterministe est le filet de sécurité officiel.
- **UI / Composants** : Le frontend `/student/orientation/page.tsx` et `/student/orientation/resultats/page.tsx` est remarquable de fidélité visuelle, utilise les composants stricts (`Button`, `Card`, `Input`), respecte l'interdiction des emojis et applique l'ambre `#FAA100` exclusivement pour les scores et la progression.
- **Non-modification par le challenger** : Conformément aux règles de l'archétype `critic`, aucune modification n'a été apportée aux fichiers sources par le challenger.

---

## 4. Conclusion & Recommandations

**Verdict** : **REQUEST_CHANGES**

Le code ne doit pas être validé en l'état sans corriger la concordance des identifiants dans `generateDeterministicOrientationM3`.

### Correctif Recommandé dans `web/src/lib/orientation.ts` :
Remplacer le bloc lignes 1200-1217 par la correspondance exacte des identifiants déclarés dans `TOGO_CAREERS_CATALOG` :
```typescript
    if (career.id === 'dev-web-mobile') score += isTech ? 40 : 10;
    if (career.id === 'data-analyst-ia') score += isTech ? 38 : 8;
    if (career.id === 'cybersecurite-reseaux') score += isTech ? 36 : 6;

    if (career.id === 'ingenieur-btp-civil') score += isEng ? 40 : 5;
    if (career.id === 'architecte-urbaniste') score += (isEng || isArt) ? 38 : 5;

    if (career.id === 'medecin-sante') score += isHealth ? 40 : 5;
    if (career.id === 'pharmacien-biologiste') score += isHealth ? 38 : 5;
    if (career.id === 'ingenieur-agronome') score += (isHealth || isEng || /agri|tové|bio/i.test(allTokens)) ? 36 : 8;

    if (career.id === 'comptable-auditeur') score += isEco ? 40 : 8;
    if (career.id === 'banquier-analyste') score += isEco ? 38 : 7;
    if (career.id === 'entrepreneur-innovation') score += isEco ? 36 : 9;
    if (career.id === 'responsable-rh') score += (isEco || isComm) ? 35 : 5;

    if (career.id === 'designer-graphique') score += (isArt || isTech) ? 40 : 5;
    if (career.id === 'marketing-digital') score += (isComm || isArt || isEco) ? 38 : 7;
    if (career.id === 'juriste-affaires') score += isComm ? 39 : 5;
    if (career.id === 'enseignant-formateur') score += isComm ? 37 : 5;
```

### Amélioration de `web/test-orientation-generate.js` :
Ajouter au moins un second cas de test dans le script pour un profil médical ou BTP afin de garantir que `generateDeterministicOrientationM3` retourne effectivement le métier de la filière demandée en première recommandation.

---

## 5. Verification Method

Pour vérifier indépendamment cette observation :
1. Inspecter `d:\ActivEducation\web\src\lib\orientation.ts` aux lignes 206-479 (déclaration de `TOGO_CAREERS_CATALOG`) et comparer avec les lignes 1197-1217 (`career.id === '...'`).
2. Évaluer l'appel de `generateDeterministicOrientationM3` avec un profil santé :
   ```javascript
   generateDeterministicOrientationM3({
     interests: ['Santé, Biologie & Sciences Médicales'],
     strongSubjects: ['Sciences de la Vie et de la Terre (SVT)'],
   });
   ```
   **Résultat observé** : `recommendedCareers[0].title` est `Pharmacien & Biologiste Médical`, mais `recommendedCareers[1]` est `Développeur Web & Mobile` au lieu de `Médecin Généraliste / Spécialiste`.
3. Avec un profil BTP :
   ```javascript
   generateDeterministicOrientationM3({
     interests: ['Bâtiment, Industrie & Ingénierie'],
     strongSubjects: ['Mathématiques & Physique-Chimie'],
   });
   ```
   **Résultat observé** : Le premier métier recommandé est `Développeur Web & Mobile` (60 points) et `Ingénieur Génie Civil & BTP` reste à 50 points et n'apparaît pas dans le Top 3.
