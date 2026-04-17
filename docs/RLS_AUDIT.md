# Audit Row Level Security (RLS) — ActivEducation

**Date de l'audit :** 2026-04-17
**Dernière MAJ :** 2026-04-17 — Étapes 1, 2 et 3 exécutées. Migration 007 prête pour déploiement staging (Étape 4).
**Statut :** ✅ Migration `007_reenable_rls` disponible. Reste à déployer en staging + valider.

---

## 1. État actuel

La migration `004_admin_fixes_rls.py` désactive RLS sur :

| Table | RLS | Contenu sensible ? |
|---|---|---|
| `user_profiles` | ❌ OFF | **OUI** — données utilisateur |
| `user_test_sessions` | ❌ OFF | **OUI** — résultats de tests personnels |
| `user_achievements` | ❌ OFF | OUI |
| `user_challenges` | ❌ OFF | OUI |
| `orientation_tests` | ❌ OFF | Non (contenu public) |
| `test_questions` | ❌ OFF | Non |
| `question_options` | ❌ OFF | Non |
| `careers` | ❌ OFF | Non |
| `career_sectors` | ❌ OFF | Non |
| `schools` | ❌ OFF | Moyen (certains champs admin) |
| `challenges` | ❌ OFF | Non |

---

## 2. Modèle d'exposition actuel

- **Flutter apps** : n'utilisent PAS le SDK Supabase directement. Tout passe par le backend FastAPI (vérifié via grep `supabase` dans `activ_education_app/lib/` et `admin_dashboard/lib/` — aucun résultat).
- **Backend** : utilise la clé Anon (`SUPABASE_KEY`) dans tous les repositories via `get_supabase_client()`. La clé `service_role` est configurée (`SUPABASE_SERVICE_ROLE_KEY`) mais le client admin `get_admin_supabase_client()` n'est pas réellement utilisé par les repositories.

**Conséquence** : la sécurité repose entièrement sur le backend (dépendances FastAPI `get_current_user_id`, `get_current_admin`). La clé Anon dispose d'un accès total à la base grâce à la désactivation de RLS.

---

## 3. Risques

1. **Fuite de la clé Anon** : même si la clé Anon est déployée uniquement côté serveur actuellement, elle est destinée à être publique par design. Tout leak (fichier `.env` commité, image Docker sur registre public, backup non chiffré) donnerait un accès total à la base.
2. **Compromission du VPS backend** : pas de deuxième ligne de défense. L'attaquant a l'Anon key = full DB access.
3. **Bypass du backend** : un futur script, un integrations partner ou un debug tool qui se connecterait directement à Supabase avec la clé Anon contournerait toutes les vérifications FastAPI.

---

## 4. Plan de re-activation RLS

**Étape 1 — Migrer les repositories admin vers `service_role`** ✅ **FAIT (2026-04-17)**

Tous les repos `app/repositories/admin/*.py` ainsi que `app/repositories/school_admin_repository.py` utilisent désormais `get_admin_supabase_client()`. La clé `service_role` bypasse RLS par design. Tests : 49/49 backend + 23/23 school_admin verts.

Repos migrés :
- `admin/users_admin_repository.py`
- `admin/schools_repository.py`
- `admin/careers_repository.py`
- `admin/tests_repository.py`
- `admin/stats_repository.py`
- `school_admin_repository.py`

**Étape 2 — Migrer les repositories utilisateur vers un modèle RLS-friendly** ✅ **FAIT (2026-04-17, Option A)**

Repos migrés vers `get_admin_supabase_client()` :
- `users_repository.py` (profils utilisateur)
- `orientation_repository.py` (sessions/résultats de tests)
- `elearning_repository.py` (inscriptions, progression, enrollments)

Repos laissés en Anon (lecture publique uniquement — smoke test RLS à l'Étape 3) :
- `schools_repository.py`
- `knowledge_base_repository.py`

**Corrections sécurité complémentaires appliquées pendant la migration :**
- `orientation_repository.complete_test_session()` : ajout du filtre `.eq("user_id", user_id)` en plus de `.eq("id", session_id)`. Empêche un utilisateur A de compléter la session d'un utilisateur B si `session_id` fuite.
- Suppression de `orientation_repository.save_test_responses()` (dead code, sans filtre user_id).
- Suppression de `users_repository.search()` (dead code, exposait emails utilisateur + risque injection via `or_(f"email.ilike.%{query}%...")` avec input non-échappé).

Le backend reste la première ligne de défense (dépendances `get_current_user_id`, `get_current_admin`). Quand RLS sera activé (Étape 3), elle fournira un **filet "fail-closed"** pour tout bug futur.

**Étape 3 — Écrire les policies RLS** ✅ **FAIT (2026-04-17)**

Migration Alembic créée : [`backend/alembic/versions/007_reenable_rls.py`](../backend/alembic/versions/007_reenable_rls.py).

Policies appliquées :
- **Lecture publique** (anon + authenticated) : `orientation_tests`, `test_questions`, `question_options`, `careers`, `career_sectors`, `school_programs`.
- **Schools** : lecture publique conditionnelle (`is_active = true AND is_verified = true` si la colonne existe, sinon `is_active = true`).
- **Self-access** (FOR ALL via `auth.uid()`) : `user_profiles` (id), `user_test_sessions`, `user_achievements`, `user_challenges`, `test_results`, `user_favorite_careers`, `user_points`, `elearning_user_progress`, `elearning_enrollments`.
- **Admin-only** (RLS ON sans policy publique — service_role bypass uniquement) : `challenges`, `school_admin_profiles`, `elearning_courses`, `elearning_modules`, `elearning_lessons`, `elearning_lesson_content`, `app_settings`.

Caractéristiques de la migration :
- **Idempotente** : chaque policy est `DROP IF EXISTS` + `CREATE`, tolère les tables absentes via `DO $$ ... EXCEPTION WHEN undefined_table THEN NULL; END $$`.
- **Downgrade complet** : retour à l'état post-004 (RLS désactivé partout).
- **Tolère `is_verified` manquant** : introspection via `information_schema.columns` puis `EXECUTE format(...)`.

**Étape 4 — Tests d'intégration**

Avant de merger la migration :
1. Déployer sur staging.
2. Tester chaque feature utilisateur (login, test d'orientation, dashboard, admin).
3. Vérifier qu'aucun endpoint ne retourne 403/401 inattendu.
4. Tester un accès direct Supabase avec la clé Anon → doit être restreint.

---

## 5. Timeline suggérée

| Jalon | Effort | Dépendance |
|---|---|---|
| Étape 1 (admin repos → service_role) | 0.5 j | Aucune |
| Étape 2 (user repos, option A) | 1 j | Étape 1 |
| Étape 3 (migration Alembic) | 0.5 j | Étape 2 |
| Étape 4 (tests staging + déploiement) | 1 j | Étape 3 |
| **Total** | **~3 jours** | |

Bloquant pour toute ouverture publique de la clé Anon (ex : intégration partenaire, SDK tiers, app mobile utilisant Supabase SDK directement).

---

## 6. Responsable

À assigner lors de la prochaine revue de sécurité trimestrielle.
