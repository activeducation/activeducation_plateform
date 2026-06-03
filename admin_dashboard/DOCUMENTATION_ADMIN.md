# Documentation — Dashboard admin (`admin_dashboard`)

> Documentation exhaustive de l'application **back-office** d'ActivEducation
> (admins, super-admins, et portail écoles).
>
> Public : développeurs Flutter (onboarding & maintenance), audit/reprise.
> Dernière mise à jour : 2026-06.
>
> Voir aussi : `docs/DOCUMENTATION.md` (vue projet globale) et
> `activ_education_app/DOCUMENTATION_FLUTTER.md` (app étudiant).

---

## Table des matières

1. [Rôle & différences avec l'app étudiant](#1-rôle--différences-avec-lapp-étudiant)
2. [Stack & dépendances](#2-stack--dépendances)
3. [Arborescence complète](#3-arborescence-complète)
4. [Démarrage (bootstrap)](#4-démarrage-bootstrap)
5. [Injection de dépendances (get_it MANUEL)](#5-injection-de-dépendances-get_it-manuel)
6. [Couche réseau (`ApiClient` + AuthInterceptor)](#6-couche-réseau)
7. [Authentification, rôles & stockage](#7-authentification-rôles--stockage)
8. [Routing & contrôle d'accès par rôle](#8-routing--contrôle-daccès-par-rôle)
9. [Le shell & la navigation](#9-le-shell--la-navigation)
10. [Architecture des features](#10-architecture-des-features)
11. [Gestion d'état (BLoC)](#11-gestion-détat-bloc)
12. [Le dossier `core/`](#12-le-dossier-core)
13. [Le dossier `shared/` (design system back-office)](#13-le-dossier-shared)
14. [Les features en détail](#14-les-features-en-détail)
15. [Le portail école (sous-application)](#15-le-portail-école)
16. [Build, configuration & exécution](#16-build-configuration--exécution)
17. [Conventions & pièges connus](#17-conventions--pièges-connus)
18. [Index des fichiers de fondation](#18-index-des-fichiers-de-fondation)

---

## 1. Rôle & différences avec l'app étudiant

`admin_dashboard` est le **back-office** : gestion des utilisateurs, écoles,
carrières, tests d'orientation, e-learning, gamification (badges/défis),
opportunités, mentors, organisations partenaires, réglages, journal d'audit, et
un **portail école** séparé.

**Différences structurelles importantes avec `activ_education_app`** (à connaître
avant de coder) :

| Aspect | App étudiant | Dashboard admin |
|---|---|---|
| **DI** | `injectable` + build_runner (code généré) | **`get_it` 100 % manuel** (enregistrement explicite, **pas** de build_runner pour la DI) |
| **Réseau** | 2× `Dio` (`apiClient`/`refreshClient`) + intercepteur riche | 1× wrapper **`ApiClient`** autour d'un `Dio`, intercepteur **simple** |
| **API_BASE_URL** | **sans** `/api/v1` (préfixe ajouté par les constantes) | **avec** `/api/v1` (défaut `https://localhost:8000/api/v1`) |
| **Refresh token** | refresh proactif + rejeu de requête | **pas de refresh** : un 401 → redirection `/login` |
| **Auth optionnelle** | oui (contenu public) | non (tout le back-office exige l'auth) |
| **Routing** | 1 router statique + `AuthGuard`/`RoleGuard` | router créé par fonction + redirect inline (rôles) |
| **Thème** | `AppTheme.lightTheme` | `AdminTheme.light` |
| **Public** | étudiants | admin / super_admin / school_admin |

> ⚠️ La DI manuelle signifie : **aucun `flutter pub run build_runner` n'est requis
> pour la DI** ici (contrairement à l'app étudiant). Les modèles peuvent toujours
> utiliser des `*.g.dart` générés, mais le graphe de dépendances est écrit à la
> main dans `injection_container.dart`.

---

## 2. Stack & dépendances

| Package | Rôle |
|---|---|
| `flutter_bloc` / `bloc` | Gestion d'état (BLoC) |
| `get_it` | Service locator (**enregistrement manuel**) |
| `dio` | Client HTTP (encapsulé par `ApiClient`) |
| `go_router` | Routing + redirect par rôle |
| `flutter_secure_storage` | Tokens chiffrés |
| `shared_preferences` | Métadonnées (rôle, email, school_id…) |
| `google_fonts` + police bundlée | Typo « Hanken Grotesque » |
| `fl_chart` | Graphiques du dashboard |
| `data_table_2` | Tables de données paginées |
| `file_picker` | Sélection de fichiers (upload contenu) |
| `equatable` | Égalité de valeur (états, failures) |
| `intl` | Formatage dates/nombres |
| `sentry_flutter` | Monitoring conditionnel |

> Note : l'admin **n'a pas** `injectable`/`injectable_generator` dans sa chaîne
> DI. `build_runner` reste présent pour la sérialisation des modèles si besoin,
> mais n'est pas une dépendance de la DI.

---

## 3. Arborescence complète

```
admin_dashboard/
├── lib/
│   ├── main.dart                 # Bootstrap
│   ├── app.dart                  # MaterialApp.router (AdminApp)
│   ├── core/                     # Fondations (12 fichiers)
│   │   ├── auth/                 # token_storage, auth_interceptor
│   │   ├── constants/            # admin_constants, api_endpoints, app_colors, app_spacing, app_typography
│   │   ├── di/injection_container.dart   # DI MANUELLE (getIt + register...)
│   │   ├── error/failures.dart   # AdminFailure
│   │   ├── network/api_client.dart       # wrapper Dio
│   │   ├── observability/sentry_bootstrap.dart
│   │   └── theme/admin_theme.dart
│   ├── router/admin_router.dart  # createAdminRouter() + redirect rôles
│   ├── shared/
│   │   ├── layouts/admin_shell_layout.dart  # Sidebar + zone contenu
│   │   └── widgets/              # admin_button, admin_data_table, confirm_dialog,
│   │                             # admin_snackbar, empty_state, loading_overlay
│   └── features/                 # 13 features (voir §14)
├── assets/fonts/HankenGrotesque.ttf
├── web/                          # index.html, manifest, favicon, icons
└── pubspec.yaml
```

87 fichiers Dart (`core` 12, `router` 1, `shared` 7, `features` 65).

---

## 4. Démarrage (bootstrap)

### `main.dart`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();          // DI manuelle + TokenStorage.init()
  await initSentryAndRun(
    release: 'admin-dashboard@1.0.0',
    appRunner: () => runApp(wrapWithSentryIfEnabled(const AdminApp())),
  );
}
```

Plus simple que l'app étudiant : pas de verrouillage d'orientation (back-office =
desktop/web). `configureDependencies()` initialise **TokenStorage** puis
enregistre tout le graphe à la main.

### `app.dart`

```dart
class AdminApp extends StatefulWidget {...}
class _AdminAppState extends State<AdminApp> {
  late final _adminRouter = createAdminRouter();   // router créé une fois
  Widget build() => MaterialApp.router(
    title: 'ActivEducation Admin',
    theme: AdminTheme.light,
    routerConfig: _adminRouter,
  );
}
```

`AdminApp` est un `StatefulWidget` (le router est instancié une seule fois dans
`_AdminAppState`). **Pas de `MultiBlocProvider` global** : chaque page fournit ses
blocs localement (via `getIt`).

---

## 5. Injection de dépendances (get_it MANUEL)

C'est **la** différence majeure avec l'app étudiant. Aucune annotation, aucun
code généré : tout est enregistré explicitement dans
`core/di/injection_container.dart`.

```dart
final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Core : singletons eager
  final tokenStorage = TokenStorage();
  await tokenStorage.init();
  getIt.registerSingleton<TokenStorage>(tokenStorage);

  final apiClient = ApiClient(tokenStorage);
  getIt.registerSingleton<ApiClient>(apiClient);

  // Par feature : repository (lazySingleton) + usecases + bloc (factory)
  getIt.registerLazySingleton<UsersRepository>(
    () => UsersRepositoryImpl(getIt<ApiClient>()),
  );
  getIt.registerFactory(() => UsersBloc(getIt<GetUsersUseCase>(), ...));
  // ... idem pour schools, careers, tests, gamification, dashboard, elearning
}
```

Conventions d'enregistrement :
- `registerSingleton` → `TokenStorage`, `ApiClient` (créés au démarrage).
- `registerLazySingleton` → les repositories (1 instance, à la demande).
- `registerFactory` → les blocs et usecases (nouvelle instance par usage).

> **Ajouter une feature** = écrire à la main les `register...` dans
> `injection_container.dart` (importer repo/usecases/bloc en tête de fichier).
> Oublier un enregistrement → erreur runtime `Object/factory not registered`.

---

## 6. Couche réseau

### `ApiClient` (`core/network/api_client.dart`)

Fin wrapper autour de `Dio` :

```dart
class ApiClient {
  late final Dio dio;
  ApiClient(this._tokenStorage) {
    dio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl, headers: {...}));
    dio.interceptors.add(AuthInterceptor(_tokenStorage));
    if (kDebugMode) dio.interceptors.add(LogInterceptor(...));
  }
  Future<Response<T>> get<T>(...)    => dio.get<T>(...);
  Future<Response<T>> post<T>(...)   => dio.post<T>(...);
  Future<Response<T>> put<T>(...)    => dio.put<T>(...);
  Future<Response<T>> patch<T>(...)  => dio.patch<T>(...);
  Future<Response<T>> delete<T>(...) => dio.delete<T>(...);
}
```

Les repositories reçoivent `ApiClient` (pas `Dio` directement) et appellent
`_api.get('/admin/users')`, etc.

### URL de base (`core/constants/api_endpoints.dart`)

```dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL', defaultValue: 'https://localhost:8000/api/v1');
```

> ⚠️ **L'admin attend `API_BASE_URL` AVEC `/api/v1`** (le défaut l'inclut). En
> prod : `--dart-define=API_BASE_URL=https://api.activeducationhub.com/api/v1`.
> Omettre `/api/v1` → « Not Found » au login (piège historique réel).

### `AuthInterceptor` (`core/auth/auth_interceptor.dart`) — version simple

```dart
class AuthInterceptor extends Interceptor {
  onRequest:  // attache 'Authorization: Bearer <token>' si présent
  onError:    // si 401 → context.go('/login')   (PAS de refresh)
}
```

Contrairement à l'app étudiant, **pas de refresh proactif ni de rejeu** : un
back-office est utilisé en session active ; un token expiré renvoie simplement au
login.

---

## 7. Authentification, rôles & stockage

### `TokenStorage` (`core/auth/token_storage.dart`)

- **Tokens** (access/refresh) → `flutter_secure_storage` (chiffré), avec un
  **cache mémoire** hydraté au `init()` (`_accessTokenCache`/`_refreshTokenCache`)
  pour des accès synchrones (utile dans le `redirect` du router).
- **Métadonnées** → `shared_preferences` : `admin_user_role`, email, nom,
  `schoolId`, `schoolName`, userId.
- **Migration legacy** : comme l'app étudiant, déplace d'anciens tokens en clair
  vers le stockage sécurisé au 1ᵉʳ `init()`.

### Getters d'état & de rôle (clés pour les guards)

```dart
bool get isLoggedIn    => accessToken != null && accessToken!.isNotEmpty;
bool get isSuperAdmin  => userRole == 'super_admin';
bool get isSchoolAdmin => userRole == 'school_admin' && schoolId != null;
String? get userRole, userEmail, userName, schoolId, schoolName, userId;
```

> Ces getters sont **synchrones** (lisent le cache mémoire / SharedPreferences),
> ce qui permet au `redirect` GoRouter d'être synchrone.

### Rôles reconnus
`student`, `admin`, `super_admin` (`AdminConstants.userRoles`) + `school_admin`
(portail école). Le back-office « classique » exige `admin`/`super_admin` ;
certaines routes sont **super_admin only** (voir §8).

### Gestion d'erreurs
`core/error/failures.dart` : `AdminFailure extends Equatable implements
Exception` (`message`, `statusCode`). Les repositories renvoient/échouent avec
des `AdminFailure` mappées depuis les erreurs Dio.

---

## 8. Routing & contrôle d'accès par rôle

`router/admin_router.dart` — `createAdminRouter()` retourne un `GoRouter`. Le
contrôle d'accès est **inline dans le `redirect`** (pas de classes Guard
séparées comme l'app étudiant) :

```dart
redirect: (context, state) {
  final path = state.matchedLocation;
  final ts = getIt<TokenStorage>();

  // 1. Portail école : exige login + rôle school_admin
  if (path.startsWith('/school-portal') && path != '/school-portal/login') {
    if (!ts.isLoggedIn || !ts.isSchoolAdmin) return '/school-portal/login';
  }
  // 2. Back-office : exige login
  else if (path != '/login' && path != '/school-portal/login') {
    if (!ts.isLoggedIn) return '/login';
    if (path == '/login') return '/dashboard';
  }
  if (path.startsWith('/school-portal')) return null;

  // 3. Routes super_admin uniquement
  const superAdminOnly = ['/settings', '/audit-log', '/announcements'];
  if (superAdminOnly.contains(path) && !ts.isSuperAdmin) return '/dashboard';

  return null;
}
```

### Trois niveaux d'accès
1. **Public** : `/login`, `/school-portal/login`.
2. **Authentifié (admin/super_admin)** : tout le reste du back-office.
3. **super_admin uniquement** : `/settings`, `/audit-log`, `/announcements`.
4. **school_admin** : branche `/school-portal/*` (sous-application séparée).

### Carte des routes (back-office)

| Domaine | Routes |
|---|---|
| Dashboard | `/dashboard` |
| Utilisateurs | `/users` · `/users/:id` |
| Écoles | `/schools` · `/schools/new` · `/schools/:id/edit` |
| Carrières | `/careers` · `/careers/sectors` · `/careers/new` · `/careers/:id/edit` |
| Tests | `/tests` · `/tests/new` · `/tests/:id/edit` |
| Gamification | `/gamification/achievements` · `/gamification/challenges` |
| Mentors | `/mentors` |
| E-learning | `/elearning/courses` · `/courses/new` · `/courses/:id/edit` |
| Opportunités | `/opportunities` · `/new` · `/:id/edit` |
| Partenaires | `/partner/organizations` |
| Réglages★ | `/settings` |
| Annonces★ | `/announcements` |
| Audit★ | `/audit-log` |

★ = super_admin uniquement.

### Portail école (routes séparées)
`/school-portal/login` · `/school-portal/dashboard` · `/school-portal/courses`
(+ `/new`, `/:id/edit`) · `/school-portal/profile`.

---

## 9. Le shell & la navigation

`shared/layouts/admin_shell_layout.dart` — `AdminShellLayout` enveloppe toutes
les routes du back-office (via `ShellRoute`) :

- **`_Sidebar`** verticale fixe avec sections (`_SidebarSection` : DASHBOARD,
  CONTENU, …) et items `_SidebarItem` (icône + label + path), surlignant la route
  active.
- Items : Dashboard, Utilisateurs, (CONTENU) Écoles, Carrières, Secteurs, Tests,
  Opportunités, Mentors, E-learning, Gamification, (selon rôle) Réglages,
  Annonces, Audit.
- Zone de contenu = `child` de la route active.

> La visibilité de certains items dépend du rôle (super_admin pour
> settings/annonces/audit), cohérente avec le `redirect`.

---

## 10. Architecture des features

Le pattern **n'est pas uniforme** (contrairement à l'app étudiant). Deux profils :

**A. Clean Architecture (domain/data/presentation)** — pour les features CRUD
riches : `users`, `schools`, `careers`, `orientation_tests`, `elearning`,
`gamification`, `dashboard`.

```
features/users/
├── domain/
│   ├── entities/        # objets métier
│   ├── repositories/    # interface UsersRepository
│   └── usecases/        # GetUsersUseCase, DeactivateUserUseCase
├── data/
│   ├── models/          # DTO (fromJson)
│   └── repositories/    # UsersRepositoryImpl(ApiClient)
└── presentation/
    ├── bloc/            # UsersBloc
    └── (pages)          # UsersListPage, UserDetailPage
```

**B. Presentation-only** — pour les features simples (lecture/affichage, peu de
logique) : `mentors`, `opportunities`, `settings`, `school_portal`, `auth`
(bloc + data, sans domain), `partner` (domain + presentation, sans data).

| Feature | domain | data | presentation | bloc |
|---|:--:|:--:|:--:|:--:|
| auth | – | ✓ | ✓ | ✓ |
| users | ✓ | ✓ | ✓ | ✓ |
| schools | ✓ | ✓ | ✓ | ✓ |
| careers | ✓ | ✓ | ✓ | ✓ |
| orientation_tests | ✓ | ✓ | ✓ | ✓ |
| elearning | ✓ | ✓ | ✓ | ✓ |
| gamification | ✓ | ✓ | ✓ | ✓ |
| dashboard | ✓ | ✓ | ✓ | – |
| partner | ✓ | – | ✓ | – |
| mentors | – | – | ✓ | – |
| opportunities | – | – | ✓ | – |
| settings | – | – | ✓ | – |
| school_portal | – | – | ✓ | – |

> Choix pragmatique : on n'ajoute les couches domain/data que là où la logique le
> justifie. À garder cohérent quand on étend une feature.

---

## 11. Gestion d'état (BLoC)

6 blocs (pas de Cubit) :

| Bloc | Feature | Rôle |
|---|---|---|
| `UsersBloc` | users | liste/désactivation d'utilisateurs |
| `SchoolsBloc` | schools | CRUD écoles |
| `CareersBloc` | careers | CRUD carrières |
| `TestsBloc` | orientation_tests | CRUD tests d'orientation |
| `CoursesBloc` | elearning | CRUD cours e-learning |
| `AchievementsBloc` | gamification | badges/défis |

Pattern : la page récupère son bloc via `getIt<XxxBloc>()`, dispatch des events
(`LoadX`, `CreateX`, `DeleteX`…), et `BlocBuilder`/`BlocListener` reconstruisent
l'UI / affichent les `AdminSnackbar`. Les blocs appellent les **usecases** (quand
la feature en a) ou directement le **repository**.

> `dashboard` et `partner` n'ont pas de bloc : la page consomme le repository via
> un `FutureBuilder` ou un state local.

---

## 12. Le dossier `core/`

| Fichier | Rôle |
|---|---|
| `auth/token_storage.dart` | Tokens (secure) + métadonnées (prefs) + getters de rôle synchrones |
| `auth/auth_interceptor.dart` | Bearer + redirection login sur 401 (sans refresh) |
| `network/api_client.dart` | Wrapper Dio (get/post/put/patch/delete) + intercepteur + log debug |
| `constants/api_endpoints.dart` | baseUrl (avec `/api/v1`) + URLs |
| `constants/admin_constants.dart` | appName/version, pagination, listes de réf. (userRoles, schoolTypes, testTypes, questionTypes, jobDemands) |
| `constants/app_colors/app_spacing/app_typography.dart` | Design tokens |
| `di/injection_container.dart` | **DI manuelle** (getIt + register…) |
| `error/failures.dart` | `AdminFailure` |
| `observability/sentry_bootstrap.dart` | Sentry conditionnel + passthrough |
| `theme/admin_theme.dart` | `AdminTheme.light` (Material 3, police via textTheme) |

---

## 13. Le dossier `shared/`

Design system back-office réutilisable :

- `layouts/admin_shell_layout.dart` — shell (sidebar + contenu).
- `widgets/buttons/admin_button.dart` — bouton standard.
- `widgets/data_table/admin_data_table.dart` — table de données (pagination,
  tri) — brique centrale des écrans de liste.
- `widgets/dialogs/confirm_dialog.dart` — confirmation (suppression…).
- `widgets/feedback/admin_snackbar.dart` — notifications.
- `widgets/feedback/empty_state.dart` — état vide.
- `widgets/feedback/loading_overlay.dart` — voile de chargement.

---

## 14. Les features en détail

### `auth`
Login back-office + login portail école. `bloc/` + `data/` (pas de domain).
Pages `LoginPage`, `SchoolLoginPage`. Stocke tokens + rôle + (pour école)
schoolId. **Pas d'auto-inscription ni de reset public** (choix de sécurité).

### `dashboard`
Page d'accueil avec KPIs et graphiques (`fl_chart`). `domain`+`data` (repository),
pas de bloc. Backend : `/admin/dashboard`.

### `users`
Liste paginée + détail + désactivation. Clean Architecture complète
(`GetUsersUseCase`, `DeactivateUserUseCase`, `UsersBloc`). Backend : `/admin/users`.

### `schools`
CRUD écoles (liste, création, édition). `SchoolsBloc`. Backend : `/admin/schools`.

### `careers`
CRUD carrières + secteurs. `CareersBloc`. Pages `CareersListPage`, `SectorsPage`,
`CareerFormPage`. Backend : `/admin/careers`.

### `orientation_tests`
Éditeur de tests (questions/options). `TestsBloc`. Pages `TestsListPage`,
`TestEditorPage`. Backend : `/admin/tests`.

### `elearning`
CRUD cours/modules/leçons. `CoursesBloc`. Upload de contenu (`file_picker` →
`/admin/upload`). Backend : `/admin/elearning`.

### `gamification`
Gestion des badges (`achievements`) et défis (`challenges`). `AchievementsBloc`.
Backend : `/admin/gamification`.

### `opportunities`
CRUD opportunités. Presentation-only. Backend : `/admin/opportunities`.

### `mentors`
Gestion/consultation mentors. Presentation-only. Backend : `/admin/mentors`.

### `partner`
Liste & approbation des organisations partenaires (`OrganizationsListPage` :
`admin_data_table`, statuts, approbation). `domain`+`presentation`. Backend :
`/admin/partner` + `/partner/organizations`.

### `settings` ★super_admin
Réglages globaux (`app_settings`). Presentation-only. Backend : `/admin` (settings).

### `school_portal`
Sous-application pour les `school_admin` (voir §15).

> ★ Réglages, Annonces et Journal d'audit sont **super_admin uniquement**
> (le journal d'audit s'appuie sur `admin_audit_log`).

---

## 15. Le portail école

Branche `/school-portal/*` — une **sous-application dans le dashboard**, destinée
aux `school_admin` (gestionnaires d'établissement), distincte du back-office
admin :

- **Accès** : exige `isLoggedIn && isSchoolAdmin` (rôle `school_admin` **et**
  `schoolId` non nul). Login dédié `/school-portal/login`.
- **Écrans** : `dashboard` (stats de l'école), `courses` (CRUD des cours de
  l'école : liste/new/edit), `profile` (profil de l'établissement).
- **Backend** : endpoints `/school/*` (auth, courses, modules, lessons,
  dashboard, profile) — séparés des endpoints `/admin/*`.

> C'est volontairement cloisonné : un `school_admin` ne voit que **son** école,
> pas le back-office global.

---

## 16. Build, configuration & exécution

### Développement
```bash
flutter pub get
flutter run -d chrome
# baseUrl défaut : https://localhost:8000/api/v1
```
> Pas de `build_runner` requis pour la DI (manuelle). Le lancer seulement si des
> modèles `*.g.dart` doivent être régénérés.

### Build web production
```bash
flutter build web --release --no-tree-shake-icons \
  --dart-define=API_BASE_URL=https://api.activeducationhub.com/api/v1
```

> ⚠️ **Le `/api/v1` est OBLIGATOIRE ici** (à l'inverse de l'app étudiant).

### Variables de build
| Clé | Effet |
|---|---|
| `API_BASE_URL` | URL backend **avec** `/api/v1` |
| `SENTRY_DSN` | active Sentry |

---

## 17. Conventions & pièges connus

| Sujet | Détail | À retenir |
|---|---|---|
| **DI manuelle** | Pas d'`injectable`/build_runner pour le graphe. | Enregistrer chaque repo/usecase/bloc à la main dans `injection_container.dart`. |
| **API_BASE_URL avec `/api/v1`** | Le défaut l'inclut ; l'app étudiant non. | Omettre `/api/v1` → « Not Found » au login. |
| **Pas de refresh token** | 401 → `/login` direct. | Sessions back-office courtes ; pas de rejeu de requête. |
| **Accès par rôle inline** | Logique dans le `redirect` du router. | Modifier les listes `superAdminOnly` / la branche `/school-portal` au bon endroit. |
| **Portail école cloisonné** | `school_admin` + `schoolId` requis. | Tester l'accès avec un compte école réel. |
| **Pattern non uniforme** | Certaines features sans domain/data. | N'ajouter les couches que si la logique le justifie ; rester cohérent. |
| **Police bundlée** | « Hanken Grotesque » dans `assets/fonts/`, appliquée via `textTheme`. | Ne pas remettre un `fontFamily` global google_fonts (crash au 1ᵉʳ frame). |

---

## 18. Index des fichiers de fondation

| Fichier | Rôle |
|---|---|
| `lib/main.dart` | Bootstrap (DI, Sentry, runApp) |
| `lib/app.dart` | `AdminApp` + `MaterialApp.router` |
| `lib/core/di/injection_container.dart` | **DI manuelle** (tout le graphe) |
| `lib/core/network/api_client.dart` | Wrapper Dio |
| `lib/core/auth/token_storage.dart` | Tokens + rôles (getters synchrones) |
| `lib/core/auth/auth_interceptor.dart` | Bearer + redirect 401 |
| `lib/core/constants/api_endpoints.dart` | baseUrl (avec `/api/v1`) + URLs |
| `lib/core/constants/admin_constants.dart` | Constantes & listes de référence |
| `lib/core/error/failures.dart` | `AdminFailure` |
| `lib/core/theme/admin_theme.dart` | Thème back-office |
| `lib/router/admin_router.dart` | Routes + contrôle d'accès par rôle |
| `lib/shared/layouts/admin_shell_layout.dart` | Sidebar + navigation |
| `lib/shared/widgets/data_table/admin_data_table.dart` | Brique des écrans de liste |
| `lib/features/users/...` | Référence Clean Architecture (CRUD) |

---

*Document maintenu à la main. À mettre à jour à chaque évolution structurelle du
back-office (nouvelle feature, changement DI/routing/rôles, nouvel écran).*
