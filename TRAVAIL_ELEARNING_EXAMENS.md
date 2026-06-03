# Travail réalisé — E-learning : cours, examens & badges

> Branche : **`feat/mentors-partners-applications`** (suite du travail mentors).
> Prêt pour ta revue.

---

## 🎯 Ce que tu avais demandé

> Pouvoir ajouter des cours depuis le dashboard admin, mettre le contenu et les
> ressources, **définir les règles et questions d'examen (QCM)**, un **badge
> offert après >80% à l'examen**, et **une image par cours** affichée dans le
> catalogue.

**Tout est fait.** ✅

---

## ✨ Ce qui a été ajouté

### 1. Image du cours (catalogue) — upload depuis l'admin
- Dans l'éditeur de cours : bouton **« Téléverser une image »** → l'image part
  vers **Supabase Storage** (bucket `elearning`) → l'URL est remplie
  automatiquement, avec **aperçu**. (Un champ « coller une URL » reste possible
  en repli.)
- L'image apparaît sur la carte du cours dans le catalogue (le champ
  `thumbnail_url` était déjà utilisé par l'app — il est maintenant facile à
  renseigner).

### 2. Examen QCM par cours (admin)
- Dans l'éditeur de cours (en édition) : section **« Examen final (QCM) »** →
  bouton **« Gérer l'examen »**.
- L'éditeur d'examen permet de définir :
  - le **titre**, le **score de passage** (défaut **80%**), le **XP bonus**,
    le **titre et l'icône du badge** ;
  - les **questions QCM** : ajout/suppression, options multiples, **marquer la
    bonne réponse** (minimum 2 options + 1 correcte par question).
- Sauvegarde en une fois (l'examen + ses questions).

### 3. Passer l'examen (app étudiant) + badge
- Quand l'étudiant a terminé toutes les leçons d'un cours, le bouton du bas
  devient **« Passer l'examen »**.
- Écran d'examen : QCM (sans les bonnes réponses, évidemment), soumission.
- Écran de résultat :
  - **≥ score de passage (80%)** → 🎉 **badge débloqué** + **XP bonus** affichés ;
  - **< 80%** → score + bouton **« Réessayer »**.
- Le badge et le XP ne sont crédités **qu'à la première réussite** (idempotent).

### 4. Le badge réutilise la gamification existante
Le badge est un **achievement** (table `user_achievements`, type
`course_badge:{course_id}`) — cohérent avec le système de gamification déjà en
place (XP/niveau/streak/leaderboard). Le XP bonus passe par la RPC atomique
`award_xp` et invalide le cache gamification.

---

## ⚙️ Ce qu'il reste à faire de TON côté

### Appliquer la migration (OBLIGATOIRE)
```powershell
$env:DATABASE_URL = "postgresql://postgres.<ref>:<pwd>@aws-<n>-<region>.pooler.supabase.com:5432/postgres"
cd backend
alembic upgrade head    # applique 015 (mentors) + 016 (examens)
```
> Sans ça, les écrans d'examen renverront « table manquante ».

### Vérifier le bucket Supabase Storage `elearning`
L'upload d'image écrit dans un bucket **`elearning`**. Assure-toi qu'il existe et
est **public** dans Supabase (Storage → New bucket → `elearning`, public). Les
autres buckets (`schools`, `careers`…) existent déjà sur le même modèle.

---

## ✅ Validation effectuée

- **Backend** : app FastAPI s'importe (les 3 routes examen présentes), ruff
  clean, **164 tests passent** (+6 tests de scoring d'examen ajoutés).
- **App étudiant** : `flutter analyze` sans erreur + **build web release OK**.
- **Dashboard admin** : `flutter analyze` sans erreur + **build web release OK**.
- Migration 016 : compile, une seule head, idempotente.

---

## 📦 Commits (sur `feat/mentors-partners-applications`)

- `feat(elearning)` — backend examens QCM + badge ≥80% (migration 016)
- `feat(admin)` — upload image cours + éditeur d'examen
- `feat(app)` — passer l'examen + recevoir le badge

---

## 🔌 Détails techniques

**Nouvelles tables (migration 016)** : `course_exams`, `exam_questions`,
`user_exam_attempts`. Bucket `elearning` ajouté à l'upload.

**Endpoints ajoutés** :
- Admin : `GET/PUT/DELETE /admin/elearning/courses/{id}/exam`
- Étudiant : `GET /elearning/courses/{id}/exam` (sans réponses),
  `POST /elearning/courses/{id}/exam/submit`

**Réutilisé sans réinventer** : `QuizWidget` (app), `user_achievements` (badge),
`award_xp` (XP), upload Supabase Storage, `admin_data_table`/dialogs.

**Scoring** : score = points obtenus / points totaux × 100. Le badge + XP ne
sont attribués qu'à la **première** réussite (vérification `has_passed_before`).
Best-effort : l'attribution du badge/XP ne casse jamais l'enregistrement de la
tentative.

---

## 🧭 Workflow complet (de bout en bout)

1. **Admin** crée un cours → téléverse une image → ajoute modules & leçons →
   « Gérer l'examen » → questions QCM + score 80% + badge → publie.
2. **Étudiant** suit le cours, termine les leçons → « Passer l'examen » →
   répond → **≥80% = badge + XP** 🎉.

Bonne revue ! 🙌
