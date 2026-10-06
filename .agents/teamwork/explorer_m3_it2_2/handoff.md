# Rapport d'Investigation & Handoff — Explorer M3_It2_2

**Auteur** : `explorer_m3_it2_2` (teamwork_preview_explorer)  
**Date** : 2026-09-30T23:51:30Z  
**Cible** : `web/src/lib/orientation.ts` (lignes 206-479 & 1185-1225)  
**Objet** : Résolution intégrale de la discordance d'identifiants métiers dans `generateDeterministicOrientationM3` et formule canonique de scoring pour les 16 métiers togolais.

---

## 1. Observation

### 1.1. Référentiel Source : `TOGO_CAREERS_CATALOG`
Dans `d:\ActivEducation\web\src\lib\orientation.ts` (lignes 206 à 479), le catalogue officiel définit exactement **16 métiers** accrédités pour le Togo et la zone UEMOA :

| # | Ligne | Identifiant Canonique (`id`) | Titre Exact (`title`) | Secteur (`sector`) | Code RIASEC | Demande Togolaise (`demand`) | Fourchette Salariale (`salary`) |
|---|---|---|---|---|---|---|---|
| 1 | 208 | `dev-web-mobile` | Développeur Web & Mobile / Ingénieur Cloud | Technologie & IT | `IRE` | Tres Forte | 250 000 - 850 000 FCFA / mois |
| 2 | 225 | `data-analyst-ia` | Data Analyst & Spécialiste IA | Technologie & IT | `ICE` | Tres Forte | 300 000 - 900 000 FCFA / mois |
| 3 | 242 | `cybersecurite-reseaux` | Architecte Réseaux & Cybersécurité | Technologie & IT | `IRC` | Tres Forte | 350 000 - 1 000 000 FCFA / mois |
| 4 | 259 | `ingenieur-btp-civil` | Ingénieur Génie Civil & BTP | Ingénierie & BTP | `RIE` | Tres Forte | 350 000 - 1 200 000 FCFA / mois |
| 5 | 276 | `architecte-urbaniste` | Architecte & Urbaniste | Architecture & Design | `AIR` | Forte | 300 000 - 1 100 000 FCFA / mois |
| 6 | 293 | `ingenieur-agronome` | Ingénieur Agronome & Agroalimentaire | Agriculture & Environnement | `RIE` | Tres Forte | 250 000 - 750 000 FCFA / mois |
| 7 | 310 | `medecin-sante` | Médecin Généraliste / Spécialiste | Santé & Soins | `ISR` | Tres Forte | 400 000 - 1 200 000 FCFA / mois |
| 8 | 327 | `pharmacien-biologiste` | Pharmacien & Biologiste Médical | Santé & Pharmacie | `ICS` | Forte | 350 000 - 850 000 FCFA / mois |
| 9 | 344 | `comptable-auditeur` | Comptable & Auditeur Financier | Finance & Gestion | `CEI` | Tres Forte | 250 000 - 850 000 FCFA / mois |
| 10 | 361 | `banquier-analyste` | Analyste Bancaire & Gestionnaire de Risque | Banque & Assurance | `CEI` | Forte | 300 000 - 950 000 FCFA / mois |
| 11 | 378 | `marketing-digital` | Responsable Marketing Digital & E-Commerce | Commerce & Médias | `EAS` | Forte | 200 000 - 700 000 FCFA / mois |
| 12 | 395 | `entrepreneur-innovation` | Entrepreneur & Chef de Projet Innovant | Entrepreneuriat & Innovation | `EIS` | Tres Forte | 250 000 - 1 500 000 FCFA / mois |
| 13 | 412 | `enseignant-formateur` | Enseignant / Formateur Académique | Éducation & Formation | `SAI` | Tres Forte | 180 000 - 550 000 FCFA / mois |
| 14 | 429 | `juriste-affaires` | Juriste d’Entreprise & Conseiller Fiscal | Droit & Administration | `ECI` | Forte | 250 000 - 900 000 FCFA / mois |
| 15 | 446 | `designer-graphique` | Designer Graphique & UI/UX | Création & Médias | `AIS` | Forte | 180 000 - 650 000 FCFA / mois |
| 16 | 463 | `responsable-rh` | Responsable Ressources Humaines | Management & RH | `SEC` | Forte | 250 000 - 800 000 FCFA / mois |

---

### 1.2. État du Code dans `generateDeterministicOrientationM3`
Dans `web/src/lib/orientation.ts` (lignes 1197 à 1217) :
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

### 1.3. Bilan Quantitatif des Anomalies
1. **Identifiants valides et concordants** : **5 seulement** (`dev-web-mobile`, `data-analyst-ia`, `cybersecurite-reseaux`, `pharmacien-biologiste`, `comptable-auditeur`).
2. **Identifiants divergents (slugs dérivés des titres)** : **8 métiers**
   - `ingenieur-btp-genie-civil` au lieu de `ingenieur-btp-civil`
   - `medecin-sante-publique` au lieu de `medecin-sante`
   - `ingenieur-agronome-agroalimentaire` au lieu de `ingenieur-agronome`
   - `analyste-financier-banque` au lieu de `banquier-analyste`
   - `charge-communication-digitale` au lieu de `marketing-digital`
   - `charge-affaires-pme` au lieu de `entrepreneur-innovation`
   - `designer-graphique-ui-ux` au lieu de `designer-graphique`
   - `juriste-droit-affaires` au lieu de `juriste-affaires`
3. **Métiers officiels totalement omis** : **3 métiers**
   - `architecte-urbaniste` (absent)
   - `enseignant-formateur` (absent)
   - `responsable-rh` (absent)
4. **Identifiants fantômes (inexistants dans `TOGO_CAREERS_CATALOG`)** : **3 identifiants**
   - `ingenieur-telecom-iot`
   - `ingenieur-energies-renouvelables` (issu des cartes d'exploration de `src/app/student/explorer/page.tsx:110`)
   - `chef-projet-logistique-portuaire` (issu de `src/app/student/explorer/metier/[id]/page.tsx:63`)

---

## 2. Logic Chain

### 2.1. Origine Cognitive du Bug
L'auteur de la fonction `generateDeterministicOrientationM3` a écrit les conditions `if (career.id === '...')` de mémoire en se basant sur les intitulés descriptifs en français (ex: "Ingénieur Génie Civil & BTP" -> `ingenieur-btp-genie-civil`, "Designer Graphique & UI/UX" -> `designer-graphique-ui-ux`, "Médecin Généraliste / Spécialiste" -> `medecin-sante-publique`), sans vérifier les `id` textuels stricts déclarés à la ligne 206 du même fichier. Il a également amalgamé des métiers des pages d'exploration statiques (`energies-renouvelables`, `logistique`).

### 2.2. Conséquence Directe : Biais Systémique Silencieux
1. À la ligne 1186, `TOGO_CAREERS_CATALOG.map((career) => ...)` itère sur les 16 métiers du catalogue.
2. Chaque métier démarre avec `score = 50`.
3. Pour les 11 métiers dont l'identifiant ne concorde pas, aucune condition n'est satisfaite : leur score reste figé à **50**.
4. Les 3 métiers Tech (`dev-web-mobile`, `data-analyst-ia`, `cybersecurite-reseaux`) reçoivent un bonus par défaut de `+10`, `+8`, `+6` même lorsque `isTech` est faux (lignes 1197-1199). Leurs scores minimums sont donc de **60, 58, 56**.
5. Lors du tri décroissant `scoredCareers.sort((a, b) => b.score - a.score)` (ligne 1222), les métiers Tech l'emportent systématiquement sur les métiers BTP, Santé, Arts, Droit ou RH dont le score est bloqué à 50.

### 2.3. Découverte Cruciale de l'Explorer : L'Écueil du Chevauchement de Tokens (Au-delà du simple renommage)
L'analyse approfondie de la proposition initiale de `challenger_m3_2` révèle un problème subsidiaire mais critique :
Dans `orientation.ts` (lignes 1177-1195) :
```typescript
const allTokens = [...interestList, ...subjectList, otherSubject, mobilityStr, cityStr].join(' ').toLowerCase();

const isTech = /informatique|technol|science|math|physique|code|web|data|ia|cloud|numérique|robot/i.test(allTokens);
const isHealth = /santé|médec|biolog|svt|pharma|chimie|soin|vie/i.test(allTokens);
```

Si l'on remplace simplement les identifiants sans corriger les tokens :
1. **Profil Santé** : L'étudiant choisit l'intérêt *"Santé, Biologie & Sciences Médicales"* et la matière *"Sciences de la Vie et de la Terre (SVT)"*.
   - Le mot `"science"` est présent dans le texte de l'intérêt et de la matière.
   - Par conséquent, la regex `isTech` (`/science/`) devient **VRAIE** !
   - `dev-web-mobile` reçoit `50 + 40 = 90`.
   - `medecin-sante` reçoit `50 + 40 = 90`.
   - `dev-web-mobile` étant situé à l'index 0 du tableau `TOGO_CAREERS_CATALOG`, il devance `medecin-sante` (index 6) en cas d'égalité lors du tri stable JavaScript !
   - L'étudiant en santé reçoit encore `Développeur Web & Mobile` en choix #1 !
2. **Profil Arts & Design** : L'étudiant choisit *"Arts, Design & Création Numérique"*.
   - Le mot `"numérique"` active la regex `isTech`.
   - `dev-web-mobile` (index 0) égale `designer-graphique` (index 14) à 90 points et prend la première place.
3. **Profil BTP & Ingénierie** : L'étudiant choisit *"Bâtiment, Industrie & Ingénierie"* et *"Mathématiques & Physique-Chimie"*.
   - Le mot `"chimie"` active `isHealth`.
   - Les mots `"math"` et `"physique"` activent `isTech`.
   - `dev-web-mobile`, `ingenieur-btp-civil` et `medecin-sante` sont tous à 90 points !

### 2.4. Règle de Résolution : Découplage Intérêt Principal vs Matière Forte
Pour garantir une séparation nette sans faux positifs :
- **Niveau 1 (Intérêt Principal - Poids Élevé +42 à +46)** : Déterminé à partir de `interestList` uniquement (les 6 options explicites du formulaire).
- **Niveau 2 (Affinité Matières / Mots-clés - Poids Modéré +24 à +30)** : Déterminé à partir des matières et compétences secondaires.
- **Niveau 3 (Demande Nationale MESR / Togo - Poids +3 à +5)** : Tiré du champ `demand` officiel du catalogue (`Tres Forte` = +5, `Forte` = +3).

---

## 3. Caveats

- **Mode Groq en Production** : Lorsque l'API Groq est opérationnelle avec une clé valide, le LLM génère directement le JSON structuré. Toutefois, le mode déterministe est le filet de sécurité fondamental (mode démo sans connexion, résilience en cas de quota dépassé ou panne réseau). Il se doit d'être 100% fiable.
- **Options de l'UI** : Les labels de `web/src/app/student/orientation/page.tsx` (`INTEREST_OPTIONS` et `SUBJECT_OPTIONS`) sont figés et respectés dans la solution proposée.
- **Principe de Lecture Seule** : En tant qu'explorer, aucune modification directe du code source applicatif n'a été effectuée ; la solution ci-dessous est fournie sous forme de patch directement applicable par l'implémenteur.

---

## 4. Conclusion & Solution Clé en Main

### 4.1. Mapping Canonique Exhaustif (16 / 16 Métiers)

| # | ID Canonique dans `TOGO_CAREERS_CATALOG` | Domaine Principal | Condition Déclenchée | Score Intérêt | Score Matières/Secondaire | Score Demande |
|---|---|---|---|---|---|---|
| 1 | `dev-web-mobile` | Tech & Numérique | `interestTech` / `hasTech` | +45 | +30 | +5 |
| 2 | `data-analyst-ia` | Tech & Numérique | `interestTech` / `hasTech` | +42 | +28 (+8 si Eco) | +5 |
| 3 | `cybersecurite-reseaux` | Tech & Numérique | `interestTech` / `hasTech` | +40 | +25 (+5 si Eng) | +5 |
| 4 | `ingenieur-btp-civil` | Ingénierie & BTP | `interestEng` / `hasEng` | +45 | +30 (+5 si Math/Phys) | +5 |
| 5 | `architecte-urbaniste` | Ingénierie & Arts | `interestEng` ou `interestArt` | +42 | +28 | +3 |
| 6 | `ingenieur-agronome` | Agro-industrie / Bio | `interestHealth` ou `interestEng` | +40 | +26 | +5 |
| 7 | `medecin-sante` | Santé & Soins | `interestHealth` / `hasHealth` | +46 | +30 | +5 |
| 8 | `pharmacien-biologiste` | Santé & Pharmacie | `interestHealth` / `hasHealth` | +43 | +28 | +3 |
| 9 | `comptable-auditeur` | Finance & Gestion | `interestEco` / `hasEco` | +45 | +30 | +5 |
| 10 | `banquier-analyste` | Banque & Assurance | `interestEco` / `hasEco` | +42 | +28 | +3 |
| 11 | `marketing-digital` | Commerce & Médias | `interestEco` ou `interestComm` | +40 | +26 | +3 |
| 12 | `entrepreneur-innovation` | Entrepreneuriat | `interestEco` / `hasEco` | +39 | +25 (+8 si Tech) | +5 |
| 13 | `enseignant-formateur` | Éducation & Formation | `interestComm` / `hasComm` | +42 | +26 | +5 |
| 14 | `juriste-affaires` | Droit & Administration | `interestComm` ou `interestEco` | +45 | +28 | +3 |
| 15 | `designer-graphique` | Arts & Design | `interestArt` / `hasArt` | +45 | +30 | +3 |
| 16 | `responsable-rh` | Management & RH | `interestEco` ou `interestComm` | +38 | +24 | +3 |

---

### 4.2. Code Patch Recommandé pour `web/src/lib/orientation.ts`
Remplacer les lignes 1177 à 1220 de `web/src/lib/orientation.ts` par le bloc suivant :

```typescript
  const interestText = interestList.join(' ').toLowerCase();
  const subjectText = subjectList.join(' ').toLowerCase();
  const otherText = otherSubject.toLowerCase();
  const allTokens = `${interestText} ${subjectText} ${otherText} ${mobilityStr} ${cityStr}`.toLowerCase();

  // 1. Détection ciblée de l'intérêt principal de l'étudiant (Priorité Haute)
  const interestTech = /sciences?\s*(?:&|et)?\s*nouvelles?\s*technologies?|sciences-tech|informatique|numérique/i.test(interestText);
  const interestEng = /bâtiment|industrie|ingénierie|ingenierie-btp|génie\s*civil/i.test(interestText);
  const interestHealth = /santé|biologie|sciences?\s*médicales?|sante-bio|médecine/i.test(interestText);
  const interestEco = /économie|gestion|entrepreneuriat|economie-gestion|finance|commerce/i.test(interestText);
  const interestArt = /arts?|design|création\s*numérique|arts-design|visuel/i.test(interestText);
  const interestComm = /lettres?|langues?|communication|lettres-langues|droit/i.test(interestText);

  // 2. Détection complémentaire basée sur les matières fortes et le texte libre
  const hasTech = interestTech || /informatique|code|web|data|intelligence\s*artificielle|\bia\b|cloud|robot|cybersécur/i.test(allTokens) || (/math/i.test(subjectText) && !interestHealth && !interestComm);
  const hasEng = interestEng || /génie\s*civil|bâtiment|btp|chantier|mécanique|énergie|architecture|urbanisme/i.test(allTokens);
  const hasHealth = interestHealth || /médec|pharma|biolog|svt|santé|soin|clinique/i.test(allTokens);
  const hasEco = interestEco || /compta|financ|banque|audit|entrepre|pme|fiscal|commerce|vente/i.test(allTokens);
  const hasArt = interestArt || /design|graphi|ui|ux|illustration|ergonomie|visuel|multimédia/i.test(allTokens);
  const hasComm = interestComm || /droit|jurid|avocat|enseign|formateur|littérat|philo|journal|rh\b|ressources\s*humaines/i.test(allTokens);

  // Attribution de scores aux 16 métiers du catalogue togolais
  const scoredCareers = TOGO_CAREERS_CATALOG.map((career) => {
    let score = 50;

    // 1. Technologie & IT
    if (career.id === 'dev-web-mobile') {
      score += interestTech ? 45 : (hasTech ? 30 : 0);
      if (hasArt) score += 5;
    }
    if (career.id === 'data-analyst-ia') {
      score += interestTech ? 42 : (hasTech ? 28 : 0);
      if (hasEco) score += 8;
    }
    if (career.id === 'cybersecurite-reseaux') {
      score += interestTech ? 40 : (hasTech ? 25 : 0);
      if (hasEng) score += 5;
    }

    // 2. Ingénierie, BTP & Architecture
    if (career.id === 'ingenieur-btp-civil') {
      score += interestEng ? 45 : (hasEng ? 30 : 0);
      if (/math|physique/i.test(subjectText)) score += 5;
    }
    if (career.id === 'architecte-urbaniste') {
      score += (interestEng || interestArt) ? 42 : ((hasEng || hasArt) ? 28 : 0);
    }
    if (career.id === 'ingenieur-agronome') {
      score += (interestHealth || interestEng) ? 40 : ((hasHealth || hasEng || /agri|tové|bio/i.test(allTokens)) ? 26 : 0);
    }

    // 3. Santé & Soins
    if (career.id === 'medecin-sante') {
      score += interestHealth ? 46 : (hasHealth ? 30 : 0);
    }
    if (career.id === 'pharmacien-biologiste') {
      score += interestHealth ? 43 : (hasHealth ? 28 : 0);
    }

    // 4. Finance, Banque & Entrepreneuriat
    if (career.id === 'comptable-auditeur') {
      score += interestEco ? 45 : (hasEco ? 30 : 0);
    }
    if (career.id === 'banquier-analyste') {
      score += interestEco ? 42 : (hasEco ? 28 : 0);
    }
    if (career.id === 'entrepreneur-innovation') {
      score += interestEco ? 39 : (hasEco ? 25 : 0);
      if (interestTech || hasTech) score += 8;
    }

    // 5. Création, Médias & Communication
    if (career.id === 'designer-graphique') {
      score += interestArt ? 45 : ((hasArt || hasTech) ? 30 : 0);
    }
    if (career.id === 'marketing-digital') {
      score += (interestEco || interestComm || interestArt) ? 40 : ((hasEco || hasComm || hasArt) ? 26 : 0);
    }

    // 6. Droit, Administration, Éducation & RH
    if (career.id === 'juriste-affaires') {
      score += (interestComm || interestEco) ? 45 : ((hasComm || hasEco) ? 28 : 0);
    }
    if (career.id === 'enseignant-formateur') {
      score += interestComm ? 42 : (hasComm ? 26 : 0);
    }
    if (career.id === 'responsable-rh') {
      score += (interestEco || interestComm) ? 38 : ((hasEco || hasComm) ? 24 : 0);
    }

    // Bonus de demande nationale togolaise
    if (career.demand === 'Tres Forte') score += 5;
    else if (career.demand === 'Forte') score += 3;

    return { career, score };
  });
```

---

## 5. Verification Method

Pour vérifier de façon déterministe et indépendante les résultats attendus :

### 5.1. Test de Simulation des 6 Domaines
Exécuter la simulation suivante en évaluant `generateDeterministicOrientationM3` avec chacun des 6 profils types :

```javascript
// Test Profil Santé
const resHealth = generateDeterministicOrientationM3({
  interests: ['Santé, Biologie & Sciences Médicales'],
  strongSubjects: ['Sciences de la Vie et de la Terre (SVT)'],
});
// RÉSULTAT OBLIGATOIRE :
// top3[0].title === 'Médecin Généraliste / Spécialiste'
// top3[1].title === 'Pharmacien & Biologiste Médical'
// top3[2].title === 'Ingénieur Agronome & Agroalimentaire'

// Test Profil BTP
const resBTP = generateDeterministicOrientationM3({
  interests: ['Bâtiment, Industrie & Ingénierie'],
  strongSubjects: ['Mathématiques & Physique-Chimie'],
});
// RÉSULTAT OBLIGATOIRE :
// top3[0].title === 'Ingénieur Génie Civil & BTP'
// top3[1].title === 'Architecte & Urbaniste'

// Test Profil Arts & Design
const resArt = generateDeterministicOrientationM3({
  interests: ['Arts, Design & Création Numérique'],
  strongSubjects: ['Français, Philosophie & Littérature'],
});
// RÉSULTAT OBLIGATOIRE :
// top3[0].title === 'Designer Graphique & UI/UX'

// Test Profil Économie / Gestion
const resEco = generateDeterministicOrientationM3({
  interests: ['Économie, Gestion & Entrepreneuriat'],
  strongSubjects: ['Histoire-Géographie & Économie'],
});
// RÉSULTAT OBLIGATOIRE :
// top3[0].title === 'Comptable & Auditeur Financier'

// Test Profil Droit / Lettres
const resLaw = generateDeterministicOrientationM3({
  interests: ['Lettres, Langues & Communication'],
  strongSubjects: ['Français, Philosophie & Littérature'],
});
// RÉSULTAT OBLIGATOIRE :
// top3[0].title === 'Juriste d’Entreprise & Conseiller Fiscal'
```

### 5.2. Critères d'Invalidation
La solution est invalidée si :
1. Un profil Santé pur reçoit un métier Tech dans son Top 2.
2. Un profil BTP pur ne place pas `Ingénieur Génie Civil & BTP` en choix #1.
3. Un profil Arts & Design ne place pas `Designer Graphique & UI/UX` en choix #1.
4. L'un des 16 identifiants utilisés ne figure pas mot pour mot dans `TOGO_CAREERS_CATALOG`.
