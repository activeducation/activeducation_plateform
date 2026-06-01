# Cahier des charges — Gamification réelle (Niveau / Streak / XP)

> **Contexte** : sur l'écran d'accueil de l'app étudiant, la barre de gamification
> (Niveau, Streak, XP, barre de progression) affiche **les mêmes valeurs pour
> tous les utilisateurs** (Niv. 3, Streak 7, 850 XP). Ces valeurs sont **codées
> en dur** dans l'UI. Le but de ce ticket : les rendre **réelles, par
> utilisateur, et évolutives** quand l'étudiant complète des leçons / examens.

---

## 1. Diagnostic précis de l'existant (NE PAS re-deviner — c'est vérifié)

### 1.1 Côté Flutter (app étudiant)

| Élément | État | Fichier |
|---|---|---|
| Affichage hero (valeurs hardcodées) | ❌ en dur | `lib/features/home/presentation/widgets/hero_header.dart` (lignes ~118–184) |
| Modèle de données gamification | ✅ existe, complet | `lib/features/gamification/data/models/gamification_profile.dart` |
| DataSource HTTP | ✅ existe, branchée | `lib/features/gamification/data/datasources/gamification_remote_datasource.dart` |
| Repository (+ DI `@LazySingleton`) | ✅ existe, enregistré | `lib/features/gamification/data/repositories/gamification_repository.dart` |
| Endpoints API déclarés | ✅ existent | `lib/core/constants/api_endpoints.dart` (`gamificationProfile`, `leaderboard`…) |
| **BLoC / Cubit gamification** | ❌ **MANQUANT** | — |
| Branchement HeroHeader → données | ❌ **MANQUANT** | `home_page.dart` instancie juste `HeroHeader()` sans données |

> **Conséquence** : toute la couche data Flutter est **déjà écrite et injectable**.
> Il **ne reste qu'à** créer un Cubit/Bloc qui appelle
> `GamificationRepository.getMyProfile()` et brancher le `HeroHeader` dessus.
> **Ne pas réécrire** le model / datasource / repository.

### 1.2 Côté backend (FastAPI)

| Élément | État | Fichier |
|---|---|---|
| `GET /gamification/profile` (lecture) | ✅ réel, calcule niveau + streak | `app/api/v1/endpoints/gamification.py` |
| Formule de niveau O(1) (cap 100) | ✅ correcte | `_calculate_level()` même fichier |
| `GET /gamification/leaderboard` | ✅ réel (trie par `total_xp`) | idem |
| Attribution de points à la complétion de leçon | ⚠️ écrit dans **`user_points`** | `app/repositories/elearning_repository.py` (~l.554) |
| **Attribution XP sur `user_profiles.total_xp`** | ❌ **JAMAIS écrit** | — |
| **Attribution XP sur complétion de test/examen** | ❌ **INEXISTANT** | `app/api/v1/endpoints/orientation.py` |
| Incrément du streak au login | ❌ **INEXISTANT** (login pose juste `last_login_at`) | `app/repositories/users_repository.py` (~l.151) |
| `leaderboard_rank` du profil | ❌ toujours `None` | `gamification.py` l.119 |

### 1.3 LE BUG CENTRAL (à comprendre avant de coder)

Il y a **deux "monnaies" déconnectées** :

```
Complétion leçon  ──►  table user_points (points_balance / total_earned)
                                   ▲
                                   │  AUCUN LIEN
                                   ▼
GET /gamification/profile  ──►  lit user_profiles.total_xp  ◄── jamais écrit, colonne
                                                                  même pas définie en migration
```

- La colonne `user_profiles.total_xp` **n'est créée dans AUCUNE migration**
  (`alembic/versions/001…013`). L'endpoint fait `user_profile.get("total_xp", 0)`
  → renvoie donc **toujours 0** (ou null) en prod.
- Les points de leçon partent dans **`user_points`**, une table séparée jamais lue
  par la gamification.
- L'UI masquait tout ça en affichant **850 en dur**.

> **Incohérence de schéma à connaître** : la migration `001_initial_schema.sql`
> crée une table `profiles` avec `xp_points` / `level`. **Mais tout le code
> applicatif** utilise la table **`user_profiles`** avec `total_xp` /
> `current_streak` / `last_login_at`. **La table réelle utilisée partout est
> `user_profiles`** (cf. `gamification.py`, `users_repository.py`,
> `users_admin_repository.py`). Le bloc `profiles`/`xp_points` de la migration 001
> est mort — **ne pas s'en servir comme référence.**

---

## 2. Décision d'architecture (source de vérité unique)

**Règle d'or : UNE seule source de vérité pour le XP = `user_profiles.total_xp`.**

On **abandonne pas** `user_points` (il sert au "solde dépensable" / boutique
future), mais le **XP total cumulé affiché** vit sur `user_profiles`. Les deux
peuvent coexister :
- `user_points.total_earned` = points gagnés (historique / solde).
- `user_profiles.total_xp` = XP cumulé qui pilote le **niveau** et le **leaderboard**.

> Dans ce projet, **chaque point gagné = +1 XP**. Donc à chaque attribution de
> points, on incrémente **aussi** `user_profiles.total_xp` du même montant, dans
> **la même transaction logique**.

Cela évite de réécrire l'endpoint de lecture (qui lit déjà `total_xp`) et garde
le leaderboard cohérent (il trie déjà par `total_xp`).

---

## 3. Travail à réaliser — découpé en lots

### LOT 1 — Migration DB (Alembic) — *prérequis, à faire en premier*

Créer **une seule** migration `014_gamification_xp_streak.py` (idempotente,
`IF NOT EXISTS`, suit le style des migrations 008–013) qui :

1. Ajoute sur `user_profiles` les colonnes manquantes :
   ```sql
   ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS total_xp      INTEGER NOT NULL DEFAULT 0;
   ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS current_streak INTEGER NOT NULL DEFAULT 0;
   ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS longest_streak INTEGER NOT NULL DEFAULT 0;
   -- last_login_at existe déjà (migration 003/006) — NE PAS recréer.
   ```
   > Vérifier d'abord avec `\d user_profiles` lesquelles existent déjà
   > (`current_streak` peut déjà exister). N'ajouter que celles qui manquent.

2. Crée une **fonction RPC atomique** pour incrémenter le XP **sans race
   condition** (deux complétions simultanées ne doivent pas s'écraser) :
   ```sql
   CREATE OR REPLACE FUNCTION award_xp(p_user_id UUID, p_amount INTEGER)
   RETURNS INTEGER
   LANGUAGE sql
   AS $$
     UPDATE user_profiles
     SET total_xp = total_xp + p_amount,
         updated_at = NOW()
     WHERE id = p_user_id
     RETURNING total_xp;
   $$;
   ```
   > **Pourquoi RPC et pas un `SELECT … then UPDATE`** : éviter le pattern
   > lecture-puis-écriture non atomique (déjà présent et risqué dans
   > `elearning_repository.py` pour `user_points`). L'incrément doit être fait
   > **côté base** (`total_xp = total_xp + n`), jamais `total_xp = <valeur lue> + n`.

3. `downgrade()` propre (DROP FUNCTION ; ne PAS dropper les colonnes si elles
   préexistaient — préférer un downgrade no-op documenté pour les colonnes afin
   de ne pas perdre de données).

**Définition de "fini"** : `alembic upgrade head` passe en local et en staging ;
`SELECT award_xp('<uuid>', 10);` renvoie le nouveau total.

---

### LOT 2 — Backend : écrire le XP au bon endroit

#### 2.1 Complétion de leçon (`elearning_repository.py`, `mark_lesson_complete`)
- **Garder** l'attribution existante à `user_points`.
- **Ajouter** : après l'attribution des points, appeler la RPC `award_xp(user_id, points_reward)`.
- **Idempotence obligatoire** : si la leçon était **déjà** `completed`, **ne PAS**
  re-créditer le XP. Vérifier le statut **avant** d'attribuer (la fonction marque
  déjà `status=completed` — encadrer pour ne créditer qu'à la 1re complétion).
- Invalider le cache (voir LOT 4).

#### 2.2 Complétion de test/examen d'orientation (`orientation.py`)
- Aujourd'hui : **0 XP**. Définir une règle simple et documentée, ex :
  - +50 XP à la **première** soumission complète d'un test d'orientation.
  - (Optionnel) bonus selon complétude, mais **règle unique et idempotente**.
- Appeler `award_xp` à la complétion, **une seule fois** par test
  (clé d'idempotence = `user_id + test_id`, vérifier qu'aucun XP n'a déjà été
  attribué pour ce test — sinon réattribution à chaque re-soumission).

#### 2.3 Streak au login (`users_repository.py`, là où `last_login_at` est posé)
Implémenter la logique d'incrément **avant** d'écraser `last_login_at` :
```
days = date(now) - date(last_login_at)   # en jours calendaires, pas en heures
si days == 0 :  streak inchangé          # déjà connecté aujourd'hui
si days == 1 :  current_streak += 1      # jour consécutif
si days >= 2 :  current_streak = 1       # streak cassé, on repart à 1
longest_streak = max(longest_streak, current_streak)
puis: last_login_at = now
```
> **Attention fuseau horaire** : comparer en **jours calendaires** (date), pas en
> `.days` d'un `timedelta` d'heures. Le code de lecture actuel dans
> `gamification.py` utilise `(now - last_login).days` — l'aligner sur la même
> définition pour éviter deux calculs divergents. **Idéalement, le calcul du
> streak vit à UN seul endroit** (au login) ; l'endpoint de lecture ne fait que
> **lire** `current_streak`, il ne le recalcule plus.

#### 2.4 (Optionnel, si temps) `leaderboard_rank`
Renseigner le rang du user dans `/profile` (rang = position dans le tri
`total_xp DESC`). Sinon laisser `None` explicitement (le front gère déjà l'absence).

**Définition de "fini" LOT 2** : compléter une leçon via l'API augmente
`total_xp` exactement de `points_reward` **une seule fois** ; re-compléter
n'ajoute rien ; un 2e jour de connexion consécutif passe le streak à 2.

---

### LOT 3 — Flutter : Cubit + branchement UI

#### 3.1 Créer un `GamificationCubit` (préférer Cubit, plus simple qu'un Bloc ici)
Emplacement : `lib/features/gamification/presentation/cubit/gamification_cubit.dart`
- États : `GamificationInitial` / `GamificationLoading` / `GamificationLoaded(profile)` / `GamificationError(message)`.
- Méthode `load()` → `repository.getMyProfile()`.
- Méthode `refresh()` (re-appel, utilisée après complétion de leçon).
- Enregistrer dans la DI **comme les autres** (factory `@injectable`) puis lancer
  `flutter pub run build_runner build --delete-conflicting-outputs`.
  > Respecter le pattern d'injection existant ; **ne pas instancier à la main**
  > `GetIt` hors du module généré.

#### 3.2 Brancher le `HeroHeader`
- Dans `home_page.dart` : fournir le `GamificationCubit` (via `BlocProvider`) et
  déclencher `load()` à l'ouverture de l'accueil.
- Le `HeroHeader` **a déjà** un `BlocBuilder<AuthBloc>` pour le prénom/initiales —
  **garder ça**. Ajouter par-dessus un `BlocBuilder<GamificationCubit>` (ou un
  `BlocSelector`) pour les stats.
- **Remplacer les valeurs en dur** par les vraies :
  | En dur actuel | Source réelle |
  |---|---|
  | `'Niv. 3'` | `profile.stats.currentLevel` |
  | `'7'` (streak) | `profile.stats.currentStreak` |
  | `'850'` (XP) | `profile.stats.totalXp` |
  | `'Progression vers Niveau 4'` | `'Progression vers Niveau ${currentLevel + 1}'` |
  | `'850 / 1 000 XP'` | `'${totalXp} / ${profile.nextLevelXp} XP'` |
  | `widthFactor: 0.85` | `profile.levelProgress` (déjà calculé dans le model, clampé 0..1) |

#### 3.3 États non-chargés (anti "écran vide / faux chiffres")
- **Loading** : afficher un skeleton/shimmer (le package `shimmer` est déjà une
  dépendance) sur la barre de stats — **jamais** les anciennes valeurs en dur.
- **Error / offline** : afficher des stats neutres (`Niv. —`, `0`, barre vide) +
  possibilité de retry silencieux. **Ne jamais** réafficher 850/7/3.
- **Nouvel utilisateur (0 XP)** : doit afficher Niv. 1, 0 XP, streak 0, barre à 0 —
  et **c'est normal** (c'est précisément le comportement attendu).

#### 3.4 Rafraîchissement après gain de XP
Quand l'utilisateur termine une leçon (écran e-learning, après le `POST
/lessons/{id}/complete` réussi), appeler `gamificationCubit.refresh()` pour que
l'accueil reflète le nouveau XP. (Si refresh global compliqué, au minimum
recharger au retour sur l'accueil.)

**Définition de "fini" LOT 3** : deux comptes différents voient des chiffres
différents ; un compte neuf voit Niv. 1 / 0 XP ; après une leçon complétée, le XP
augmente à l'écran.

---

### LOT 4 — Cohérence du cache (sinon bug "le chiffre ne bouge pas")

Le backend cache le profil sous la clé `gamification:profile:{user_id}`
(`gamification.py` l.55, TTL `TTL_GAMIFICATION`).

> **Piège** : si on attribue du XP sans invalider ce cache, l'UI continuera à
> montrer l'ancienne valeur jusqu'à expiration du TTL → l'utilisateur croira que
> "ça ne marche pas".

**Obligation** : **chaque** chemin qui modifie `total_xp` ou `current_streak`
(complétion leçon, complétion test, login/streak) doit **invalider**
`gamification:profile:{user_id}` (et le cas échéant les clés leaderboard
`gamification:leaderboard:*`). Centraliser cette invalidation dans une petite
fonction utilitaire pour ne pas l'oublier.

---

## 4. Garde-fous anti-régression / anti-dette technique

À respecter impérativement (sinon le ticket recrée des bugs ailleurs) :

1. **Ne pas toucher** au model/datasource/repository Flutter existants : ils sont
   corrects et déjà injectés. On **ajoute** un Cubit, on ne refactore pas la data.
2. **Source de vérité unique** : le XP affiché = `user_profiles.total_xp`. Ne pas
   introduire une 3e source. Si on lit `user_points` quelque part pour l'affichage,
   on crée une nouvelle incohérence — interdit.
3. **Incréments atomiques côté base** (`total_xp = total_xp + n` via RPC), jamais
   `lire puis écrire` côté Python (race condition garantie en prod multi-requêtes).
4. **Idempotence** sur toutes les attributions (leçon déjà complétée / test déjà
   soumis ⇒ 0 XP supplémentaire). Tester explicitement le cas "double complétion".
5. **Calcul du streak à UN seul endroit** (au login). L'endpoint de lecture ne
   recalcule pas — il lit. Sinon deux logiques divergentes.
6. **Invalidation de cache systématique** à chaque écriture de XP/streak.
7. **Migration idempotente** (`IF NOT EXISTS`) + testée `upgrade`/`downgrade` en
   staging avant prod. Vérifier d'abord les colonnes déjà présentes.
8. **Pas de valeurs en dur de secours** dans l'UI : les états loading/erreur ont
   leur propre rendu neutre, ils ne réutilisent pas 850/7/3.
9. **Tests** :
   - Backend : test unitaire `award_xp` (incrément + idempotence leçon), test
     streak (J+0 / J+1 / J+2).
   - Flutter : test du Cubit (loading → loaded / error) avec repository mocké
     (`mocktail` + `bloc_test` sont déjà des dev_dependencies).
10. **CI** : `flutter analyze` et les tests backend doivent rester verts. Lancer
    `build_runner` et **committer** les fichiers générés (`.config.dart`).

---

## 5. Ordre d'exécution recommandé

1. **LOT 1** (migration + RPC) → déployer en staging, vérifier.
2. **LOT 2** (écritures backend + streak + invalidation cache) → tester via API
   (curl/Postman) que `total_xp` bouge réellement.
3. **LOT 4** (cache) en même temps que LOT 2.
4. **LOT 3** (Cubit + UI) une fois que l'API renvoie de vraies valeurs.
5. Recette finale avec **2 comptes distincts** + **1 compte neuf** + **complétion
   d'1 leçon** observée à l'écran.

---

## 6. Critères de recette (ce que le PO/QA vérifie)

- [ ] Deux utilisateurs différents voient des XP/niveau/streak **différents**.
- [ ] Un compte fraîchement créé voit **Niv. 1 / 0 XP / Streak 0 / barre vide**.
- [ ] Compléter une leçon augmente le XP **du montant `points_reward`**, visible à
      l'écran après refresh, **et une seule fois** (re-compléter n'ajoute rien).
- [ ] Compléter un test d'orientation attribue le XP prévu, une seule fois.
- [ ] Se connecter 2 jours consécutifs fait passer le streak de 1 → 2 ; sauter un
      jour le remet à 1 ; `longest_streak` garde le record.
- [ ] La barre "Progression vers Niveau N+1" et le ratio `XP / nextLevelXp`
      correspondent au niveau réel.
- [ ] En mode hors-ligne / erreur API : rendu neutre, **aucune** valeur en dur.
- [ ] `flutter analyze` vert, tests backend verts, migration rejouable.

---

### Annexe — fichiers à modifier (récapitulatif)

**Backend**
- `alembic/versions/014_gamification_xp_streak.py` *(nouveau)*
- `app/repositories/elearning_repository.py` *(award_xp + idempotence + invalidation)*
- `app/api/v1/endpoints/orientation.py` *(award_xp sur complétion test)*
- `app/repositories/users_repository.py` *(logique streak au login)*
- `app/api/v1/endpoints/gamification.py` *(lecture seule du streak ; option rank)*
- utilitaire commun d'invalidation de cache *(nouveau, petit)*

**Flutter**
- `lib/features/gamification/presentation/cubit/gamification_cubit.dart` *(nouveau)*
- `lib/features/home/presentation/pages/home_page.dart` *(BlocProvider + load)*
- `lib/features/home/presentation/widgets/hero_header.dart` *(remplacer le hardcode)*
- DI : régénérer `injection_container.config.dart` via build_runner
- e-learning : déclencher `refresh()` après complétion de leçon
- Tests : `test/features/gamification/…`
