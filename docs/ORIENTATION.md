# Le moteur d'orientation — guide du développeur

Ce document permet de **comprendre, reproduire, tester et améliorer** le système
de tests d'orientation d'ActivEducation. Il s'adresse à quelqu'un qui n'a jamais
touché ce code.

> **Règle d'or :** les défauts de ce moteur sont **silencieux**. Un test mal
> configuré ne lève aucune erreur — il renvoie simplement une liste de
> recommandations vide, et l'élève a répondu à 24 questions pour rien.
> Ne conclus jamais « ça marche » parce qu'il n'y a pas d'exception dans les logs :
> mesure (§6).

---

## Table des matières

1. [Modèle sous-jacent](#1-modèle-sous-jacent)
2. [Fichiers concernés](#2-fichiers-concernés)
3. [Modèle de données](#3-modèle-de-données)
4. [Le pipeline, étape par étape](#4-le-pipeline-étape-par-étape)
5. [Reproduire en local](#5-reproduire-en-local)
6. [Vérifier qu'un test produit des recommandations](#6-vérifier-quun-test-produit-des-recommandations)
7. [Créer ou modifier un test](#7-créer-ou-modifier-un-test)
8. [Ajouter une dimension](#8-ajouter-une-dimension)
9. [Pièges historiques — ne pas les réintroduire](#9-pièges-historiques)
10. [Limites connues et pistes d'amélioration](#10-limites-et-améliorations)

---

## 1. Modèle sous-jacent

Le socle est le **RIASEC** (modèle de Holland), standard en psychologie de
l'orientation. Six dimensions d'intérêts professionnels :

| Code | Trait (libellé interne) | En bref |
|---|---|---|
| R | `Réaliste` | concret, technique, manuel |
| I | `Investigateur` | analytique, scientifique |
| A | `Artistique` | créatif, expressif |
| S | `Social` | aide, enseignement, soin |
| E | `Entrepreneur` | leadership, persuasion, business |
| C | `Conventionnel` | organisation, rigueur, procédures |

**Le RIASEC est la langue pivot du système.** Les métiers ne sont indexés que
par ces six traits (plus quelques intelligences de Gardner). Tout autre test —
valeurs, aptitudes, ancres de carrière, VARK… — doit être **projeté** vers le
RIASEC pour pouvoir recommander des métiers (§4.3).

Les libellés canoniques sont **en français accentué** (`Réaliste`, pas
`Realiste`). Le moteur accepte en entrée les codes (`R`), l'anglais
(`Realistic`) et les variantes sans accent, et les normalise.

> Le **MBTI** est également implémenté, mais il est scientifiquement contesté
> (faible fidélité test-retest, pas de validité prédictive professionnelle).
> À utiliser comme complément d'engagement, **jamais** comme base d'une décision
> d'orientation.

---

## 2. Fichiers concernés

### Backend

| Fichier | Rôle |
|---|---|
| `backend/app/services/orientation_engine.py` | Scoring, interprétation, **table de projection** `DIMENSION_TO_RIASEC` |
| `backend/app/services/career_matcher.py` | Correspondance métiers + programmes scolaires |
| `backend/app/repositories/orientation_repository.py` | Accès Supabase (tests, métiers, programmes) |
| `backend/app/api/v1/endpoints/orientation.py` | Endpoints REST |
| `backend/app/schemas/orientation.py` | Contrats Pydantic (`TestSubmission`, `TestResult`, `CareerSummary`) |

### Tests et outillage

| Fichier | Rôle |
|---|---|
| `backend/tests/test_orientation_engine.py` | Scoring, baseline Likert, projection |
| `backend/tests/test_career_matcher.py` | Classement, déterminisme, repli |
| `backend/scripts/check_orientation_coverage.py` | **Diagnostic de couverture** (§6) |

### Migrations

| Migration | Contenu |
|---|---|
| `001_initial_schema.py` | Tables `orientation_tests`, `test_questions`, `careers`, `school_programs` |
| `017_seed_careers.py` | Seed des 42 métiers |
| `017a_fix_test_questions_category.py` | Aligne `test_questions.category` sur le code (§9.1) |

### Application Flutter

`activ_education_app/lib/features/orientation/` — `test_execution_page.dart`
(passation), `results_page.dart` (résultats), `career_detail_page.dart`.

---

## 3. Modèle de données

### `orientation_tests`
| Colonne | Notes |
|---|---|
| `type` | `riasec` \| `personality` \| `skills` \| `interests` \| `aptitude` — **détermine l'algorithme de scoring** |
| `is_active` | seuls les tests actifs sont exposés |

### `test_questions`
| Colonne | Notes |
|---|---|
| `category` | ⚠️ **La dimension mesurée.** Sans elle, la question est ignorée du scoring |
| `question_type` | `likert`, `multiple_choice`, `slider`, `thisOrThat`… |
| `order_index`, `section_title` | présentation |

> ⚠️ La migration `001` avait créé cette colonne sous le nom `riasec_dimension`,
> jamais lu par le code. La migration `017a` rétablit `category`. Voir §9.1.

### `careers`
| Colonne | Notes |
|---|---|
| `related_traits` | ⚠️ **Le champ de matching.** Vocabulaire RIASEC + Gardner |
| `sector_name` | utilisé pour rapprocher les programmes scolaires |
| `job_demand` | `high` \| `medium` \| `low` — sert au **départage** (§4.6) |
| `salary_avg_fcfa` | critère de départage secondaire |
| `education_path` | JSONB : `minimum_level`, `recommended_formations`, `schools_in_togo`… |

### `school_programs`
| Colonne | Notes |
|---|---|
| `name`, `description` | servent au rapprochement textuel |
| `degree_level` | ⚠️ le back-office écrit `level` — le code lit **les deux** (§9.3) |
| `riasec_fit`, `career_ids` | **prévus mais jamais alimentés** (absents de `ProgramCreate`) |

---

## 4. Le pipeline, étape par étape

```
Réponses Likert (1-5)
   ↓ ① scoring par dimension        normalize_likert()
Scores 0-100
   ↓ ② traits dominants (top 3)
Profil (ex. code "ISC")
   ↓ ③ projection RIASEC            project_to_riasec()
Traits pivots
   ↓ ④ récupération candidats       get_careers_by_traits()
   ↓ ⑤ score de correspondance      calculate_match_score()
   ↓ ⑥ classement + départage       _rank_within_tiers()
6 métiers
   ↓ ⑦ rapprochement écoles         get_matching_school_programs()
8 programmes
```

### 4.1 Scoring par dimension

Chaque question porte une `category`. On accumule le total et le nombre de
réponses par dimension, puis :

```
score(dim) = ((somme − n×LIKERT_MIN) / (n×(LIKERT_MAX−LIKERT_MIN))) × 100
           = ((somme − n) / (4n)) × 100        borné à [0, 100]
```

**Retrancher la baseline est essentiel.** Le minimum atteignable est `n×1`, pas
0. Sans cette soustraction, « pas du tout » partout donnait 20 % et « neutre »
60 % : l'échelle était écrasée sur 20-100 et gonflait tous les profils.

| Réponse uniforme | Score |
|---|---|
| 1 (pas du tout) | 0 % |
| 3 (neutre) | 50 % |
| 5 (tout à fait) | 100 % |

Trois variantes de scoring selon `type` :
- `riasec` → `_calculate_riasec` (normalise les libellés vers le français)
- `personality` → `_calculate_personality` (dichotomies MBTI `E-I`, `S-N`,
  `T-F`, `J-P` ; `gauche = ((moy−1)/4)×100`, `droite = 100−gauche`).
  **Si les catégories ne sont pas des dichotomies MBTI, repli sur le générique.**
- autres → `_calculate_generic`

### 4.2 Traits dominants

Tri décroissant, **top 3** avec score > 0. Le code de profil concatène les
initiales (`ISC`). L'interprétation en découle : résumé, forces (3 du trait
principal + 2 du secondaire), conseils, secteurs pondérés par les scores.

> Un score de 0 n'est jamais un trait dominant : un élève qui répond « pas du
> tout » partout n'obtient aucun profil — c'est voulu et honnête.

### 4.3 Projection RIASEC — le pont indispensable

```python
projected, projected_scores = project_to_riasec(dominant_traits, scores)
```

`DIMENSION_TO_RIASEC` (dans `orientation_engine.py`) associe chaque dimension de
test secondaire à un ou plusieurs traits RIASEC :

```python
"Leadership":  ["Entrepreneur"],
"Analytique":  ["Investigateur"],
"Kinesthésique": ["Réaliste"],
"Innovation":  ["Artistique", "Investigateur"],
```

Règles :
- un trait **déjà RIASEC** est conservé sous sa forme canonique ;
- un trait RIASEC atteint par plusieurs dimensions hérite du **meilleur** score ;
- la comparaison est **insensible aux accents, à la casse et aux séparateurs**
  (`Logico-Mathématique` ≡ `logico-mathematique`) ;
- une dimension absente de la table n'est **pas** projetée.

**Le profil affiché à l'élève n'est pas modifié** : il voit toujours
« Leadership ». La projection ne sert qu'à interroger le catalogue.

> Sans cette étape, 8 des 10 tests en production ne recommandaient **aucun**
> métier.

### 4.4 Récupération des candidats

```python
careers = await repo.get_careers_by_traits(search_traits, limit=CANDIDATE_POOL_LIMIT)
```

`overlaps()` PostgREST sur `related_traits`, enrichi de toutes les variantes
(français accentué, sans accent, anglais). `CANDIDATE_POOL_LIMIT = 500` est une
**borne de sécurité, pas une coupe de classement** : tout le catalogue est
scoré avant tri (§4.6).

### 4.5 Score de correspondance

```
recouvrement = |traits communs| / |traits utilisateur|
score_moyen  = moyenne des scores utilisateur sur les traits communs

match = recouvrement × 60 + (score_moyen / 100) × 40      borné à 100
```

60 % pour « combien de traits en commun », 40 % pour « à quel point ils sont
marqués ». Si aucun trait **dominant** ne correspond mais qu'un trait du profil
complet matche, le score est pondéré à **50 %** (correspondance faible).

### 4.6 Classement — `rank-then-truncate`

1. tri par `match_score` décroissant sur **tout** le pool ;
2. regroupement en tranches de ±`TIER_MARGIN` (8 pts) ;
3. à l'intérieur d'une tranche, **départage déterministe** :
   `demande d'emploi → salaire moyen → nom` ;
4. coupe à `MAX_RECOMMENDATIONS` (6).

> Le départage était auparavant un `random.shuffle` : deux élèves au profil
> identique obtenaient des résultats différents et l'ordre était injustifiable.
> **Ne réintroduis jamais d'aléatoire ici** — l'explicabilité est le cœur d'un
> outil d'orientation.

**Repli** : si aucun métier ne correspond (ex. test de maturité de projet, qui
ne mesure pas des intérêts), on renvoie les métiers les plus porteurs avec
`match_score = 0` et `matching_traits = []` — l'app peut ainsi distinguer une
suggestion de découverte d'une vraie correspondance.

### 4.7 Programmes scolaires

Les termes de recherche combinent :
- les `recommended_sectors` de l'interprétation (libellés éditoriaux) ;
- les `sector_name` et `name` des **métiers réellement recommandés** (vocabulaire
  de la base — la source de vérité).

Chaque programme reçoit un score de recouvrement de **mots significatifs**
(accents retirés, mots outils écartés : `de`, `des`, `licence`, `sciences`…),
puis les programmes sont **classés** — jamais filtrés. Un profil sans
correspondance obtient donc quand même des programmes, plutôt qu'une liste vide.

---

## 5. Reproduire en local

### 5.1 Installation

```bash
cd backend
python -m venv .venv && source .venv/bin/activate   # Windows : .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env        # renseigner SUPABASE_* et SECRET_KEY
```

### 5.2 Lancer les tests unitaires

Ils ne nécessitent **ni base ni réseau** :

```bash
cd backend
python -m pytest tests/test_orientation_engine.py tests/test_career_matcher.py -v
```

### 5.3 Exercer le moteur sans base

Le moteur est pur : on peut l'appeler directement.

```python
import asyncio
from app.services.orientation_engine import OrientationEngine, project_to_riasec
from app.schemas.orientation import TestType

engine = OrientationEngine()

responses = {"q1": "5", "q2": "4", "q3": "2"}
test_data = {"questions": [
    {"id": "q1", "category": "I"},   # Investigateur
    {"id": "q2", "category": "S"},   # Social
    {"id": "q3", "category": "R"},   # Réaliste
]}

result = asyncio.run(engine.calculate_result(TestType.RIASEC, responses, test_data))
print(result.scores)            # Investigateur 100.0, Social 75.0, Réaliste 25.0
print(result.dominant_traits)   # ['Investigateur', 'Social', 'Réaliste']
print(result.interpretation["profile_code"])          # 'ISR'
print(project_to_riasec(result.dominant_traits, result.scores)[0])
                                # ['Investigateur', 'Social', 'Réaliste'] (déjà RIASEC)
```

### 5.4 Appeler l'API

```bash
# Lister les tests (public)
curl -s "$API/api/v1/orientation/mobile/tests" | head -c 400

# Soumettre des réponses — {question_id: valeur}
curl -s -X POST "$API/api/v1/orientation/sessions/$TEST_ID/submit" \
  -H "Content-Type: application/json" \
  -d '{"responses": {"<question_uuid>": "5", "<question_uuid_2>": "3"}}'
```

L'authentification est **optionnelle** : les résultats sont toujours calculés,
mais la session n'est enregistrée (et l'XP attribué) que pour un utilisateur
connecté.

Réponse (`TestResult`) : `scores`, `dominant_traits`, `interpretation`,
`recommendations` (liste de `CareerSummary` avec `match_score` et
`matching_traits`), `matching_programs`.

---

## 6. Vérifier qu'un test produit des recommandations

C'est **la** vérification à faire après toute modification de test, de dimension
ou de métier.

```bash
cd backend
python scripts/check_orientation_coverage.py
python scripts/check_orientation_coverage.py --api https://api.mondomaine.com
```

Le script croise les dimensions de chaque test avec le vocabulaire réel de
`careers.related_traits` (projection comprise) et affiche :

```
TEST                                           Q  DIRECT  PROJETE  ETAT
------------------------------------------------------------------------
Test d'Interets Professionnels (RIASEC)       18       6        7  OK
Test des Valeurs Professionnelles             20       0        5  OK
Test de Maturite du Projet Professionnel      24       0        0  *** AUCUNE RECOMMANDATION ***
```

Il liste aussi les dimensions **sans projection** et retourne le **code 1** si
un test ne peut rien recommander — utilisable en CI ou en vérification
post-déploiement.

---

## 7. Créer ou modifier un test

Les questions se saisissent depuis le **back-office admin** (aucun seed en
base). Règles à respecter :

1. **Toujours renseigner `category`.** Une question sans catégorie est
   silencieusement ignorée du scoring.
2. **Vocabulaire cohérent.** Réutilise une dimension déjà connue, ou ajoute-la à
   `DIMENSION_TO_RIASEC` (§8).
3. **Assez de questions par dimension.** Un RIASEC fiable demande **6 à 10 items
   par dimension** (48-60 au total). En dessous de 5, le score est très sensible
   à une seule réponse.
4. **Équilibrer les dimensions.** Un nombre inégal de questions ne fausse pas le
   score (il est normalisé), mais une dimension à 2 items est beaucoup plus
   bruitée qu'une dimension à 8.
5. **Type de test correct.** `type` détermine l'algorithme : un test dont les
   catégories ne sont pas `E-I`/`S-N`/`T-F`/`J-P` ne doit pas être `personality`
   sans savoir qu'il basculera sur le scoring générique.
6. **Lancer le script de couverture** (§6).

---

## 8. Ajouter une dimension

Exemple : une nouvelle dimension `Négociation`.

1. Ouvrir `backend/app/services/orientation_engine.py`.
2. Ajouter l'entrée dans `DIMENSION_TO_RIASEC` :
   ```python
   "Négociation": ["Entrepreneur", "Social"],
   ```
3. Ajouter un test dans `tests/test_orientation_engine.py` :
   ```python
   def test_project_negociation():
       traits, _ = project_to_riasec(["Négociation"], {})
       assert traits == ["Entrepreneur", "Social"]
   ```
4. Vérifier : `pytest tests/test_orientation_engine.py` puis
   `python scripts/check_orientation_coverage.py`.

**Ne projette pas ce qui ne décrit pas des intérêts.** Le test de maturité de
projet (`ConnaissanceDeSoi`, `PlanAction`…) mesure l'avancement d'une démarche :
le projeter vers le RIASEC produirait des recommandations arbitraires. Il est
volontairement absent de la table et s'appuie sur le repli.

**Alternative :** enrichir `careers.related_traits` depuis le back-office pour
que les métiers portent directement la nouvelle dimension. C'est plus lourd
(50 métiers à éditer) mais plus fin que la projection.

---

## 9. Pièges historiques

Ces bugs ont réellement existé et étaient tous **silencieux**.

### 9.1 Dérive de schéma `riasec_dimension` / `category`
La migration `001` créait `riasec_dimension`, le code lisait `category` →
catégorie `None` → tous les scores à 0 → aucun trait dominant → **aucune
recommandation**. Corrigé par `017a` (idempotente, gère les 4 états possibles).

**Leçon :** plusieurs colonnes ont été ajoutées à la main en base, hors
migration. Toute base neuve reconstruite depuis les migrations peut donc
diverger de la production. Vérifier :
```sql
SELECT column_name FROM information_schema.columns
WHERE table_name = 'test_questions' AND column_name IN ('category','riasec_dimension');
```

### 9.2 Baseline Likert
`somme / (n×5)` au lieu de `(somme − n) / (4n)` → échelle écrasée sur 20-100.
Le MBTI, lui, retranchait déjà la baseline : les deux méthodes se
contredisaient. Verrouillé par un test paramétré couvrant toute l'échelle.

### 9.3 Accents et noms de colonnes
- `related_traits` contient les **deux** orthographes (`Réaliste`/`Realiste`,
  `Logico-Mathématique`/`Logico-Mathematique`) et `overlaps()` compare des
  chaînes **exactes** → la moitié des correspondances était perdue.
- `program_level` était lu via `level` alors que la migration crée
  `degree_level` → niveau toujours vide.

### 9.4 `truncate-then-rank`
`limit=25` sur une requête **non triée** : la base choisissait arbitrairement
quels métiers seraient évalués. Toujours scorer **puis** couper.

### 9.5 Aléatoire dans le classement
`random.shuffle` rendait les résultats irreproductibles et injustifiables.

### 9.6 Paramètre ignoré
`get_matching_school_programs(sector_names)` n'utilisait jamais `sector_names` :
tous les élèves recevaient les mêmes programmes. Un paramètre accepté mais
inutilisé est un bug muet — le compilateur ne dira rien.

---

## 10. Limites et améliorations

### Limites actuelles, en toute honnêteté

| Limite | Impact |
|---|---|
| RIASEC à **18 questions** (3/dimension) | Fiabilité faible : une seule réponse déplace le score de 33 % |
| `DIMENSION_TO_RIASEC` est un **jugement éditorial** | `Leadership → Entrepreneur` est raisonnable mais non validé statistiquement |
| **Aucune boucle de retour** | Impossible de savoir si une recommandation est utile |
| **MBTI** exposé comme test d'orientation | Scientifiquement contesté |
| Couverture inégale des traits | Certains profils ont beaucoup moins de métiers disponibles |
| `riasec_fit` / `career_ids` inexploités | Le matching école↔métier reste textuel, donc approximatif |

### Pistes, par rapport valeur/effort

1. **Étoffer le questionnaire RIASEC** (48-60 items, 8-10 par dimension) —
   *effort moyen, gain de fiabilité majeur*. C'est le maillon faible n°1.
2. **Enrichir le catalogue local** (écoles togolaises réelles, frais, voies
   d'admission) — *c'est le vrai avantage compétitif ; l'algorithme est une
   commodité*.
3. **Boucle de retour** : tracer les clics sur les métiers recommandés et un
   « ce métier m'intéresse » — sans mesure, aucune amélioration n'est pilotable.
4. **Alimenter `riasec_fit` et `career_ids`** sur les programmes (les ajouter à
   `ProgramCreate`) pour un rapprochement école↔métier exact plutôt que textuel.
5. **Seuil de significativité** entre traits dominants : si les traits 2 et 3
   sont séparés de moins de ~5 points, l'ordre n'a pas de sens statistique — le
   signaler plutôt que d'afficher un classement trompeur.
6. **Isoler le MBTI** du parcours d'orientation (le garder comme contenu ludique).
7. **Pondérer par la demande d'emploi locale** dans le score lui-même, pas
   seulement au départage.

### Ce qui ne doit pas changer

- Le RIASEC comme **langue pivot** : c'est ce qui rend le système extensible à
  de nouveaux tests sans réindexer les métiers.
- Le **déterminisme** du classement : même profil ⇒ mêmes résultats.
- **Classer plutôt que filtrer** (métiers de repli, programmes scolaires) : un
  écran vide est le pire résultat possible.
- La **transparence des scores** : `match_score = 0` et `matching_traits = []`
  signalent une suggestion de découverte, pas une correspondance.

---

*Modèle : RIASEC (Holland). Backend : FastAPI + Supabase. Voir aussi
`DEPLOYMENT.md` pour la mise en production et `docs/ARCHITECTURE.md` pour la
vue d'ensemble.*
