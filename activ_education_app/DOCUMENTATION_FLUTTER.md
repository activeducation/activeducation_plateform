# Documentation — App Flutter étudiant (`activ_education_app`)

> Documentation exhaustive de l'application mobile/web **étudiant** d'ActivEducation.
> Couvre l'architecture, le démarrage, chaque couche, le réseau, le stockage,
> le routing, l'état, et le rôle de chaque dossier/fichier clé.
>
> Public : développeurs Flutter (onboarding & maintenance), audit/reprise.
> Dernière mise à jour : 2026-06.
>
> Pour la vue projet globale (backend, DB, infra), voir `docs/DOCUMENTATION.md`.

---

## Table des matières

1. [Présentation & responsabilités](#1-présentation--responsabilités)
2. [Stack & dépendances](#2-stack--dépendances)
3. [Arborescence complète](#3-arborescence-complète)
4. [Démarrage de l'application (bootstrap)](#4-démarrage-de-lapplication-bootstrap)
5. [Injection de dépendances (get_it + injectable)](#5-injection-de-dépendances)
6. [La couche réseau (Dio + AuthInterceptor)](#6-la-couche-réseau)
7. [Le stockage de fichiers & données locales](#7-le-stockage-de-fichiers--données-locales)
8. [Routing & guards (go_router)](#8-routing--guards)
9. [Clean Architecture : anatomie d'une feature](#9-clean-architecture--anatomie-dune-feature)
10. [Gestion d'état (BLoC & Cubit)](#10-gestion-détat-bloc--cubit)
11. [Le dossier `core/`](#11-le-dossier-core)
12. [Le dossier `shared/` & le package `shared_core`](#12-le-dossier-shared--le-package-shared_core)
13. [Les features en détail](#13-les-features-en-détail)
14. [Thème, design system & assets](#14-thème-design-system--assets)
15. [Build, configuration & exécution](#15-build-configuration--exécution)
16. [Conventions & pièges connus](#16-conventions--pièges-connus)
17. [Index des fichiers de fondation](#17-index-des-fichiers-de-fondation)

---

## 1. Présentation & responsabilités

`activ_education_app` est l'app **étudiant** : tests d'orientation, catalogue
e-learning, assistant IA (AÏDA), annuaire écoles/opportunités/mentors,
gamification (XP/niveau/streak), espace partenaire.

- **Cible** : Flutter Web (déployée), mais le code reste multiplateforme
  (Android/iOS gérés : orientation portrait forcée hors web, stockage Keychain/
  Keystore).
- **Communique** uniquement avec le **backend FastAPI** en REST/JSON (jamais
  avec PostgreSQL directement). L'auth transite par les tokens Supabase relayés
  au backend.
- **169 fichiers Dart** dans `lib/` (~144 en `features/`, 16 en `core/`,
  3 en `router/`, 4 en `shared/`).

---

## 2. Stack & dépendances

Déclarées dans `pubspec.yaml`. Rôles :

| Package | Rôle dans l'app |
|---|---|
| `flutter_bloc` / `bloc` | Gestion d'état (BLoC + Cubit) |
| `get_it` + `injectable` | Injection de dépendances (DI) — code généré |
| `dio` | Client HTTP (avec intercepteur d'auth) |
| `supabase_flutter` | Auth Supabase côté client |
| `flutter_secure_storage` | Tokens chiffrés (Keychain/Keystore/DPAPI) |
| `shared_preferences` | Métadonnées non sensibles + caches simples |
| `hive` / `hive_flutter` | **Déclaré mais non utilisé** (voir §7) |
| `go_router` | Routing déclaratif + guards |
| `freezed_annotation` + `json_annotation` | Modèles immutables + (dé)sérialisation |
| `json_serializable` / `freezed` (dev) | Génération de code modèles |
| `dartz` | `Either<Failure, Success>` (erreurs typées sans exceptions remontées à l'UI) |
| `equatable` | Égalité de valeur (états BLoC, entities) |
| `cached_network_image` | Images réseau avec cache |
| `flutter_svg`, `lottie` | Vectoriel + animations |
| `google_fonts` + police bundlée | Typographie « Hanken Grotesque » (bundlée, voir §14) |
| `iconsax` | Icônes |
| `flutter_animate`, `shimmer`, `percent_indicator`, `fl_chart` | UI / loaders / graphes |
| `url_launcher` | Ouvrir liens externes (PDF, vidéos) |
| `connectivity_plus` | État réseau |
| `intl` + `flutter_localizations` | i18n (fr/en) |
| `logger` | Logs |
| `sentry_flutter` | Monitoring (conditionnel via `SENTRY_DSN`) |
| `uuid` | Génération d'identifiants |

> **Code généré** : `injection_container.config.dart` (DI) et les `*.g.dart` /
> `*.freezed.dart` (modèles). Régénérer avec
> `flutter pub run build_runner build --delete-conflicting-outputs`.

---

## 3. Arborescence complète

```
activ_education_app/
├── lib/
│   ├── main.dart                 # Point d'entrée (bootstrap)
│   ├── app.dart                  # MaterialApp.router + providers globaux
│   ├── core/                     # Fondations transverses (16 fichiers)
│   │   ├── auth/                 # token_storage, auth_interceptor, auth (barrel)
│   │   ├── constants/            # api_endpoints, app_colors, app_typography, app_spacing, constants (barrel)
│   │   ├── di/                   # injection_container(.dart/.config.dart), register_module
│   │   ├── observability/        # sentry_bootstrap
│   │   ├── services/             # services transverses
│   │   ├── theme/                # app_theme, theme (barrel)
│   │   ├── utils/                # utilitaires
│   │   └── widgets/              # app_input_decoration, maintenance_overlay
│   ├── router/
│   │   ├── app_router.dart       # Config GoRouter (~67 lignes de routes)
│   │   ├── auth_guard.dart       # AuthGuard + RoleGuard + AuthGuardMixin
│   │   └── widgets/main_shell.dart  # Shell de navigation (sidebar/bottombar)
│   ├── shared/widgets/           # Widgets UI réutilisables (boutons, cards, inputs)
│   └── features/                 # 14 features (voir §13)
│       └── <feature>/
│           ├── domain/{entities,repositories,usecases}/
│           ├── data/{models,datasources,repositories}/
│           └── presentation/{bloc|cubit,pages,widgets}/
├── assets/
│   ├── fonts/HankenGrotesque.ttf
│   ├── images/  · icons/  · animations/
├── web/                          # index.html, manifest.json, favicon, icons/
├── pubspec.yaml
└── test/ · integration_test/
```

---

## 4. Démarrage de l'application (bootstrap)

### `main.dart` — séquence exacte

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();        // (1) bind Flutter

  if (!kIsWeb) {                                     // (2) mobile uniquement
    await SystemChrome.setPreferredOrientations([    //     portrait forcé
      DeviceOrientation.portraitUp, portraitDown]);
  }

  await configureDependencies();                     // (3) DI : get_it.init() + TokenStorage.init()

  await initSentryAndRun(                            // (4) Sentry si DSN, sinon passthrough
    release: 'activ-education-app@1.0.0',
    appRunner: () => runApp(
      wrapWithSentryIfEnabled(const ActivEducationApp()),
    ),
  );
}
```

1. **`ensureInitialized()`** : initialise le binding Flutter (obligatoire avant
   tout appel asynchrone natif).
2. **Orientation** : verrouillée en portrait sur mobile (ignoré sur web).
3. **`configureDependencies()`** (`core/di/injection_container.dart`) : appelle
   `getIt.init()` (enregistre tout le graphe DI généré) **puis**
   `TokenStorage.init()` (charge SharedPreferences + migre d'éventuels tokens
   legacy). C'est ici que `@preResolve` de `SharedPreferences` est résolu.
4. **`initSentryAndRun()`** (`core/observability/sentry_bootstrap.dart`) : si
   `--dart-define=SENTRY_DSN=...` est fourni, exécute l'app dans une zone Sentry ;
   sinon exécute directement. `wrapWithSentryIfEnabled` est un passthrough (voir
   §16).

### `app.dart` — racine de l'arbre de widgets

`ActivEducationApp` = `MaterialApp.router` :

- **Thème** : `AppTheme.lightTheme`, `themeMode: light` (pas de dark mode actif).
- **Routing** : `routerConfig: AppRouter.router` (go_router).
- **`builder`** (englobe toutes les pages) :
  - `MaintenanceOverlay` — affiche un voile « maintenance » si l'API
    `/settings/public` renvoie `maintenance_mode = true`.
  - `MultiBlocProvider` — fournit deux blocs **globaux** :
    - `AuthBloc` (`lazy: false`) — instancié **immédiatement** et déclenche
      `AuthCheckRequested` au démarrage (détermine si l'utilisateur est déjà
      connecté).
    - `PartnerBloc` (`lazy: true`) — instancié à la demande.
- **i18n** : delegates Material/Widgets/Cupertino, locales `fr_FR` (défaut) et
  `en_US`.

> Les autres blocs (Course, Lesson, Orientation, Chat, Gamification…) sont
> fournis **localement** par les pages qui les utilisent, pas globalement.

---

## 5. Injection de dépendances

### Principe

`get_it` est le **service locator** ; `injectable` génère le code
d'enregistrement à partir d'annotations. Le singleton global est `getIt`
(`core/di/injection_container.dart`).

```dart
final getIt = GetIt.instance;

@InjectableInit(initializerName: 'init', preferRelativeImports: true, asExtension: true)
Future<void> configureDependencies() async {
  await getIt.init();              // graphe généré (injection_container.config.dart)
  await getIt<TokenStorage>().init();
}
```

### Annotations utilisées

- `@injectable` → enregistrement **factory** (nouvelle instance à chaque résolution).
- `@lazySingleton` → instance unique, créée à la 1ʳᵉ demande.
- `@singleton` + `@preResolve` → singleton **résolu au démarrage** (ex.
  `SharedPreferences`, asynchrone).
- `@LazySingleton(as: Interface)` → lie une implémentation à son interface
  (ex. `AuthRepositoryImpl` enregistré comme `AuthRepository`).
- `@Named('x')` → distingue deux instances du même type.

### `register_module.dart` — les fournisseurs manuels

Module `@module` qui déclare ce que injectable ne peut pas auto-générer :

| Fourni | Type | Détail |
|---|---|---|
| `prefs` | `SharedPreferences` | `@singleton @preResolve` (async) |
| `secureStorage` | `FlutterSecureStorage` | `@lazySingleton` (AndroidOptions encrypted, iOS first_unlock) |
| `refreshDio` | `Dio` `@Named('refreshClient')` | client **sans** intercepteur (refresh tokens), timeouts 10s |
| `apiDio` | `Dio` `@Named('apiClient')` | client **principal** + `AuthInterceptor`, timeouts 30s, `LogInterceptor` en debug seulement |

> **Pourquoi deux clients Dio ?** Le `refreshClient` sert à rafraîchir le token
> **sans** passer par l'`AuthInterceptor` — sinon un 401 pendant le refresh
> relancerait un refresh → récursion infinie.

### Résolution dans le code

```dart
final bloc = getIt<CourseBloc>();              // factory
final storage = getIt<TokenStorage>();          // lazySingleton
final dio = getIt<Dio>(instanceName: 'apiClient');
```

> **Règle** : ne jamais instancier ces objets « à la main » ; toujours passer
> par `getIt`. Après modif d'une classe annotée → relancer `build_runner`.

---

## 6. La couche réseau

### Configuration de l'URL (`core/constants/api_endpoints.dart`)

`ApiEndpoints.baseUrl` est résolu via `_resolveBaseUrl()` :

1. `--dart-define=API_BASE_URL=...` (prioritaire, utilisé en prod).
2. Fallback dev : `http://localhost:8000` (web/desktop), `http://10.0.2.2:8000`
   (émulateur Android — alias de `localhost` de la machine hôte).

Toutes les routes sont des constantes `static const` préfixées par
`apiV1 = '/api/v1'` (ex. `login = '$apiV1/auth/login'`). Le fichier centralise
**toutes** les URLs de l'API.

> ⚠️ **Convention** : l'app étudiant attend `API_BASE_URL` **sans** `/api/v1`
> (le préfixe est ajouté par les constantes). Le dashboard admin, lui, l'inclut.

### `AuthInterceptor` (`core/auth/auth_interceptor.dart`)

Intercepteur Dio attaché au client principal. Comportement :

**`onRequest`** :
1. Si route **publique** (`/auth/login`, `/auth/register`, `/auth/refresh`,
   `/health`, `/announcements`, `/settings/public`, `/orientation/mobile/`) →
   passe sans token.
2. Sinon, vérifie l'expiration du token (`TokenStorage.isTokenExpired`, buffer
   5 min). Si expiré → **refresh proactif** via `refreshClient`.
3. Si le refresh échoue :
   - **Route à auth optionnelle** (`/elearning/courses`, `/elearning/lessons`,
     `/mentors`, `/opportunities`, `/schools`) → la requête part **sans token**
     (le contenu public ne casse pas quand la session expire).
   - Sinon → rejet avec un `401` synthétique.
4. Attache `Authorization: Bearer <token>` si disponible.

**`onError`** : sur `401` (route non publique) → tente un refresh, puis **rejoue
la requête une fois** avec le nouveau token.

**Lock anti-concurrence** : `_isRefreshing` empêche plusieurs refresh simultanés.

### Pattern d'appel (datasource)

Chaque datasource « remote » reçoit `@Named('apiClient') Dio` et mappe les
erreurs Dio en exceptions métier :

```dart
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;
  AuthRemoteDataSourceImpl(@Named('apiClient') this._dio);

  Future<AuthResultModel> login(String email, String password) async {
    try {
      final response = await _dio.post(ApiEndpoints.login, data: {...});
      return AuthResultModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);   // -> AuthException typée
    }
  }
}
```

---

## 7. Le stockage de fichiers & données locales

L'app utilise **trois** mécanismes de persistance, chacun avec un rôle précis :

### a) `flutter_secure_storage` — données sensibles

`TokenStorage` (`core/auth/token_storage.dart`, `@lazySingleton`) y stocke les
**access & refresh tokens** (chiffrés : Keychain iOS / Keystore Android /
DPAPI Web). Clés : `auth_access_token`, `auth_refresh_token`.

Détails notables :
- **Migration automatique** : au 1ᵉʳ accès, d'anciens tokens stockés en clair
  dans SharedPreferences (versions ≤ 1.x) sont **transférés** vers le stockage
  sécurisé puis supprimés du stockage clair (`_migrateLegacyTokensIfNeeded`).
- **Expiration** : `isTokenExpired()` applique un **buffer de 5 minutes** (le
  token est considéré expiré 5 min avant l'échéance réelle → refresh anticipé).
- **Échec silencieux** : si le stockage échoue, l'app continue de fonctionner
  sans persistance (mode dégradé).

### b) `shared_preferences` — métadonnées & caches simples

Stocke ce qui n'est **pas** sensible :
- `auth_token_expiry` (timestamp), `auth_user_id`, `auth_user_role` (utilisé par
  le `RoleGuard`).
- `cached_user` (JSON du profil, `AuthRepositoryImpl`) — permet un affichage
  immédiat au démarrage avant la revalidation réseau.
- Historique de chat AÏDA : `ChatLocalDataSource`
  (`features/ai_chat/data/datasources/chat_local_datasource.dart`) sérialise les
  messages et le `session_id` par utilisateur (clés préfixées par `userId`).

### c) Assets bundlés (lecture seule)

Déclarés dans `pubspec.yaml > flutter > assets` :
- `assets/images/` — images de l'app.
- `lib/features/orientation/data/local/` — dossier d'assets locaux orientation
  (contient un `.gitkeep.json` placeholder ; sert de bundle de données locales).
- `assets/fonts/HankenGrotesque.ttf` — police bundlée.
- `assets/icons/`, `assets/animations/` — présents physiquement.

> ⚠️ **Hive est déclaré dans `pubspec.yaml` mais N'EST PAS utilisé** : aucun
> `Hive.init`, `openBox` ni `@HiveType` dans `lib/`. Toute la persistance passe
> par SharedPreferences + flutter_secure_storage. (Dépendance à retirer ou à
> exploiter — voir §16.)

> **Pas de gestion de fichiers utilisateur** (upload/download de fichiers
> locaux) dans l'app étudiant : les médias (images de cours, avatars) sont des
> **URLs réseau** chargées via `cached_network_image`, et les PDF/vidéos de
> leçon sont ouverts via `url_launcher`. L'upload de fichiers existe côté
> **admin** (`/admin/upload`), pas ici.

---

## 8. Routing & guards

### `app_router.dart`

`GoRouter` unique (`AppRouter.router`). Deux niveaux :

- **Routes plates** (hors shell) : `/` (splash), `/login`, `/register`,
  `/onboarding/*`, `/orientation/test`, `/orientation/results`,
  `/orientation/career`, `/chat`.
- **`ShellRoute`** : enveloppe les routes « principales » dans
  `MainShellWrapper` (sidebar desktop / bottom-bar mobile) :
  `/home`, `/orientation`, `/elearning`, `/mentors`, `/schools`, `/profile`,
  `/elearning/course/:id`, `/elearning/lesson/:id`, `/opportunities`,
  `/partner`, `/partner/organization/create`, `/partner/organization/:orgId`,
  `/partner/beneficiary/create/:orgId`, `/partner/beneficiary/:id`.

Les paramètres de route (`:id`, `:orgId`) et les objets complexes passés via
`state.extra` alimentent les pages (ex. `CourseDetailPage(courseId, initialCourse)`).

### `redirect` global → guards (`auth_guard.dart`)

Le `redirect` de GoRouter chaîne deux guards :

```dart
redirect: (context, state) async {
  final authRedirect = await AuthGuard.redirect(context, state);
  if (authRedirect != null) return authRedirect;
  return RoleGuard.redirect(context, state);
}
```

**`AuthGuard`** — décide selon l'état d'auth (`TokenStorage.hasValidTokens()`) :
- Routes **publiques** : `/`, `/login`, `/register`, `/forgot-password`,
  `/reset-password`, `/onboarding/*`.
- **Préfixes publics** (contenu accessible sans login) : `/home`, `/orientation`,
  `/elearning`, `/schools`, `/chat`. Seul `/profile` (et le reste) exige l'auth.
- Logique :
  - non authentifié + route protégée → `/login` ;
  - authentifié + route d'auth (`/login`,`/register`) → `/home` ;
  - `/` (splash) → `/home` si connecté, sinon `/onboarding`.

**`RoleGuard`** — protège par rôle :
- `_roleProtectedPrefixes = { '/partner': ['partner_admin','admin','super_admin'] }`.
- Lit le rôle depuis `TokenStorage.getUserRole()`. Si le rôle ne correspond pas
  → redirige vers `/home`.

**`AuthGuardMixin`** — mixin optionnel pour protéger un `StatefulWidget`
individuellement (vérifie l'auth en `initState`, redirige vers `/login`).

---

## 9. Clean Architecture : anatomie d'une feature

Chaque feature riche suit **3 couches** (exemple `auth/`, le plus complet) :

```
auth/
├── domain/                         ← cœur métier, sans dépendance Flutter/réseau
│   ├── entities/user.dart          • User, UserProfile, AuthTokens, AuthResult (objets purs)
│   ├── repositories/auth_repository.dart   • CONTRAT (interface abstraite)
│   └── usecases/                   • LoginUseCase, RegisterUseCase, LogoutUseCase, GetCurrentUserUseCase
│       login_usecase.dart            (1 cas d'usage = 1 classe « callable »)
├── data/                           ← implémentation concrète
│   ├── models/user_model.dart      • DTO (fromJson/toJson) + .toEntity()
│   ├── datasources/                • AuthRemoteDataSource(Impl) : appels Dio bruts
│   │   auth_remote_data_source.dart
│   └── repositories/               • AuthRepositoryImpl : implémente le contrat domain
│       auth_repository_impl.dart     orchestre datasource + stockage + mapping erreurs
└── presentation/                   ← UI
    ├── bloc/                       • AuthBloc + AuthEvent + AuthState
    ├── pages/                      • login_page, register_page, splash_page
    └── widgets/                    • brand_panel, login_form, wide/narrow_layout, stat_pill
```

### Le flux de données (descendant puis remontant)

```
UI (page)  ── dispatch event ──▶  BLoC
   ▲                                │ appelle
   │ rebuild selon State            ▼
   │                             UseCase ───▶ Repository (interface)
   │                                              │ impl
   │                                              ▼
   │                                       RepositoryImpl
   │                                          ├──▶ RemoteDataSource (Dio → backend)
   │                                          └──▶ TokenStorage / SharedPreferences
   │                                              │
   └──────── State (Authenticated/Error) ◀── Either<Failure, Success>
```

### Gestion d'erreurs avec `dartz`

Les repositories ne **lancent pas** d'exceptions vers l'UI : ils renvoient
`Either<AuthFailure, T>` (`Left` = échec, `Right` = succès). Les datasources
lancent des exceptions typées (`AuthException`), que le repository **mappe** en
`AuthFailure` (`_mapAuthException` : unauthorized→invalidCredentials,
conflict→emailAlreadyExists, network/timeout→networkError…). Le BLoC fait
`.fold(onFailure, onSuccess)` pour émettre l'état.

> Toutes les features ont `domain/data/presentation`, **sauf `gamification`** qui
> n'a pas de `domain` séparé (modèle directement en `data/models`) — choix
> assumé vu sa simplicité (voir §13).

---

## 10. Gestion d'état (BLoC & Cubit)

10 blocs/cubits au total :

| Composant | Type | Feature | Rôle |
|---|---|---|---|
| `AuthBloc` | Bloc | auth | login/register/logout/refresh/check, états Authenticated/Unauthenticated/Error/RegistrationSuccess. **Global** (app.dart). |
| `CatalogBloc` | Bloc | elearning | liste des cours (catalogue) |
| `CourseBloc` | Bloc | elearning | détail cours, inscription (états Loaded/Enrolling/Enrolled/AuthRequired/Error) |
| `LessonBloc` | Bloc | elearning | chargement & complétion de leçon |
| `OrientationBloc` | Bloc | orientation | liste des tests |
| `TestSessionBloc` | Bloc | orientation | déroulé d'un test (questions/réponses/soumission) |
| `ChatBloc` | Bloc | ai_chat | conversation AÏDA |
| `PartnerBloc` | Bloc | partner | organisations/bénéficiaires. **Global** (app.dart, lazy). |
| `ProfileBloc` | Bloc | profile | profil utilisateur |
| `GamificationCubit` | **Cubit** | gamification | XP/niveau/streak — `load()`/`refresh()`/`reset()` |

### BLoC vs Cubit — quand l'un, quand l'autre

- **BLoC** (events → states) pour les flux à transitions multiples et traçables.
  Ex. `AuthBloc` : `on<AuthLoginRequested>`, `on<AuthLogoutRequested>`…
- **Cubit** (méthodes directes) pour les cas simples. `GamificationCubit` expose
  `load()`/`refresh()`/`reset()` sans events.

### Cas particulier : `GamificationCubit`

- Enregistré en **`@lazySingleton`** → instance **partagée** toute la session.
- Fourni par `home_page` via `BlocProvider.value` ; **ne doit pas** être `close()`
  par une page (sinon le StreamController est fermé définitivement → crash au
  prochain `getIt<GamificationCubit>()`).
- `reset()` est appelé par `AuthBloc` au **logout** pour qu'un nouvel utilisateur
  ne voie pas le XP de l'ancien.
- Rafraîchi (`refresh()`) après complétion de leçon (`lesson_page` →
  `BlocListener`).

---

## 11. Le dossier `core/`

Fondations transverses (non liées à une feature) :

| Sous-dossier / fichier | Rôle |
|---|---|
| `auth/token_storage.dart` | Stockage sécurisé tokens + migration + expiration (§7a) |
| `auth/auth_interceptor.dart` | Intercepteur Dio (Bearer, refresh, routes optionnelles) (§6) |
| `auth/auth.dart` | Barrel (ré-exporte le module auth) |
| `constants/api_endpoints.dart` | **Toutes** les URLs backend + résolution baseUrl (§6) |
| `constants/app_colors.dart` | Palette de couleurs |
| `constants/app_typography.dart` | Styles de texte (police Hanken Grotesque bundlée) |
| `constants/app_spacing.dart` | Échelle d'espacement / rayons |
| `constants/constants.dart` | **Barrel** : ré-exporte colors+typography+spacing+endpoints (`import '.../constants.dart'` suffit) |
| `di/injection_container.dart` | `getIt` + `configureDependencies()` |
| `di/injection_container.config.dart` | **Généré** par build_runner (graphe DI) |
| `di/register_module.dart` | Fournisseurs manuels (prefs, secureStorage, 2× Dio) |
| `observability/sentry_bootstrap.dart` | Init Sentry conditionnel + passthrough |
| `theme/app_theme.dart` | `ThemeData` clair |
| `theme/theme.dart` | Barrel thème |
| `widgets/maintenance_overlay.dart` | Voile maintenance global (lit `/settings/public`) |
| `widgets/app_input_decoration.dart` | Décoration commune des champs de saisie |
| `services/`, `utils/` | Dossiers réservés (actuellement **vides** — emplacements prévus pour services/utilitaires transverses) |

---

## 12. Le dossier `shared/` & le package `shared_core`

- **`lib/shared/widgets/`** : composants UI réutilisables **propres à cette app** :
  - `buttons/gradient_button.dart` — bouton dégradé (CTA principal, avec états
    loading/disabled/arrow).
  - `cards/glass_card.dart` — carte « glassmorphism ».
  - `inputs/custom_search_bar.dart`, `inputs/filter_chip_bar.dart`.
- **`packages/shared_core`** (dépendance `path:` dans pubspec) : package Dart
  séparé factorisant du code **commun aux deux apps Flutter** (étudiant + admin).
  À utiliser pour tout code partagé inter-apps.

---

## 13. Les features en détail

> Format : rôle · fichiers clés · état · backend appelé.

### `auth`
Connexion / inscription / refresh / profil. Référence Clean Architecture complète
(§9). Bloc global. Backend : `/auth/*`.

### `onboarding`
Parcours d'accueil (profil, intérêts, objectifs) avant la 1ʳᵉ connexion. Routes
`/onboarding/*` (publiques). Pages dédiées par étape.

### `home`
Tableau de bord étudiant. `home_page.dart` assemble des **sections** (widgets) :
`hero_header` (barre gamification XP/niveau/streak temps réel),
`announcements_section`, `orientation_cta`, `aida_card`, `tests_section`,
`elearning_section`, `schools_section`, `opportunities_section`,
`partner_section`. Fournit le `GamificationCubit` (singleton) via `BlocProvider.value`.

### `orientation`
Tests d'orientation + résultats. `OrientationBloc` (liste), `TestSessionBloc`
(déroulé). `test_execution_page` refactorisée en parts
(`test_execution/view_and_progress`, `question_widgets`, `slider_question`).
`results_page`, `career_detail_page`. Backend : `/orientation/*`.

### `elearning`
Catalogue → cours → leçon. Blocs : `CatalogBloc`, `CourseBloc`, `LessonBloc`.
Pages refactorisées en parts :
- `course_detail_page` → `course_detail/{hero_section, info_sections, module_section, bottom_and_states}`.
- `lesson_page` → `lesson/{content_section, content_types, completion_section}`.
Widgets : `course_card`, `lesson_type_badge`, `quiz_widget`. Modèles avec mapping
snake_case↔camelCase (`course_model`). Backend : `/elearning/*` (complétion de
leçon déclenche le rafraîchissement gamification).

### `gamification`
XP / niveau / streak / leaderboard. **Pas de couche domain** : `GamificationProfile`
(model) en `data/models`, `GamificationRemoteDataSource` (Dio),
`GamificationRepository`, et `GamificationCubit` (presentation/cubit).
Affiché dans `home/hero_header`. Backend : `/gamification/profile`, `/leaderboard`.

### `ai_chat` (AÏDA)
Assistant conversationnel. `ChatBloc`, `chat_page` refactorisée en parts
(`chat/{auth_required_screen, chat_view, message_widgets}`). Persistance locale de
l'historique via `ChatLocalDataSource` (SharedPreferences). Backend :
`/chat/message`, `/chat/message/stream`, `/chat/session/{id}`.

### `schools`
Annuaire d'écoles + programmes. `school_directory_page`, widgets `school_card`,
`program_item`, `description_tab`. Lecture publique. Backend : `/schools`.

### `opportunities`
Bourses / stages. `opportunities_page`. Backend : `/opportunities`.

### `mentors`
Annuaire de mentors (lecture). `mentors_page`, `mentor_model`. Backend : `/mentors`.

### `mentoring`
Feature de **mise en relation/mentorat** (couche complète domain/data/presentation)
— distincte de `mentors` (simple annuaire).

### `messaging`
Messagerie (conversations/messages). Couches data/presentation.

### `partner`
Espace partenaire / organisations / bénéficiaires. `PartnerBloc` (global lazy).
Pages : `create_organization_page`, `organization_dashboard_page`,
`beneficiary_form_page`, `beneficiary_list_item`. Nav conditionnée par rôle
(`RoleGuard` sur `/partner`). Backend : `/partner/organizations/*`.

### `profile`
Profil utilisateur (consultation/édition). `ProfileBloc`, `profile_page`.
Backend : `/auth/me` (GET/PATCH).

---

## 14. Thème, design system & assets

### Thème
- `core/theme/app_theme.dart` → `AppTheme.lightTheme` (Material 3, clair).
- **Pas de `fontFamily` global littéral** dans le thème : la police « Hanken
  Grotesque » est appliquée via les `TextStyle` (`app_typography.dart`) — choix
  délibéré pour éviter un crash de chargement de police (voir §16).

### Design system (`core/constants/`)
- `app_colors.dart` — couleurs (primary, secondary, surfaces dark/light,
  couleurs gamification xpGold/streakFire…, statuts success/warning/error).
- `app_typography.dart` — styles `display/headline/title/body/label` + styles
  spéciaux (hero, stats, badge…), tous en `fontFamily: 'Hanken Grotesque'`.
- `app_spacing.dart` — échelle d'espacements et rayons.

### Assets
- **Police** : `assets/fonts/HankenGrotesque.ttf` (bundlée localement, déclarée
  dans `pubspec.yaml > fonts`). Voir §16 pour l'historique du choix.
- **Images/icônes/animations** : `assets/images/`, `assets/icons/`,
  `assets/animations/`.
- **Web** : `web/index.html`, `web/manifest.json`, `web/favicon.png`,
  `web/icons/Icon-{192,512,maskable-*}.png` — favicon et icônes PWA aux couleurs
  ActivEducation (remplacement du branding Flutter par défaut).

---

## 15. Build, configuration & exécution

### Développement

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs   # DI + modèles
flutter run -d chrome                                              # web (dev)
# baseUrl par défaut en dev : http://localhost:8000 (backend local)
```

### Build web production

```bash
flutter build web --release --no-tree-shake-icons \
  --dart-define=API_BASE_URL=https://api.activeducationhub.com
# (optionnel) --dart-define=SENTRY_DSN=...  pour activer Sentry
```

- `--no-tree-shake-icons` : conserve les icônes dynamiques (iconsax).
- `--dart-define=API_BASE_URL` : **sans** `/api/v1` (cf. §6).
- Sortie : `build/web/` (servie par nginx en prod ; **gitignorée**).

### Variables de build (`--dart-define`)

| Clé | Effet |
|---|---|
| `API_BASE_URL` | URL du backend (sinon localhost) |
| `SENTRY_DSN` | active Sentry (sinon désactivé) |
| `SENTRY_ENVIRONMENT` | environnement Sentry (défaut `production`) |

---

## 16. Conventions & pièges connus

| Sujet | Détail | À retenir |
|---|---|---|
| **build_runner obligatoire** | DI (`injection_container.config.dart`) et modèles (`*.g.dart`/`*.freezed.dart`) sont générés. | Après toute modif d'une classe injectable/modèle → relancer build_runner et committer les fichiers générés. |
| **API_BASE_URL sans `/api/v1`** | L'app ajoute `/api/v1` via les constantes ; l'admin non. | Inverser donne un « Not Found » au login. |
| **Deux clients Dio** | `apiClient` (avec intercepteur) vs `refreshClient` (sans). | Ne jamais router le refresh par l'`apiClient` (récursion). |
| **GamificationCubit singleton** | Ne pas `close()` depuis une page ; `reset()` au logout. | Sinon crash « Cannot add new events after calling close ». |
| **Hive non utilisé** | Dépendance déclarée mais aucun usage réel. | Persistance = SharedPreferences + secure storage. À nettoyer ou exploiter. |
| **Police bundlée** | `GoogleFonts.getFont('Hanken Grotesque')` échouait (le vrai nom Google Fonts est « Hanken Grotesk »). | Police **bundlée** dans `assets/fonts/`. Ne pas repasser au fetch runtime. |
| **Pas de fontFamily global** | Mettre un nom google_fonts en `fontFamily` du thème crashait au 1ᵉʳ frame. | Police appliquée via les `TextStyle`. |
| **Routes à auth optionnelle** | Catalogue/mentors/écoles/opportunités accessibles sans token. | L'`AuthInterceptor` laisse passer sans token si la session expire. |
| **dark mode** | `themeMode: light` figé. | Pas de thème sombre actif (les couleurs « dark » servent aux héros/sidebars). |
| **Pages volumineuses** | Découpées en `part`/`part of` (course_detail, lesson, test_execution, chat). | Widgets privés inchangés, fichiers physiques séparés. |

---

## 17. Index des fichiers de fondation

| Fichier | Rôle |
|---|---|
| `lib/main.dart` | Bootstrap (binding, DI, Sentry, runApp) |
| `lib/app.dart` | `MaterialApp.router` + providers globaux + maintenance overlay |
| `lib/core/di/injection_container.dart` | `getIt` + `configureDependencies()` |
| `lib/core/di/register_module.dart` | Fournisseurs DI manuels (prefs, secure, 2× Dio) |
| `lib/core/di/injection_container.config.dart` | Graphe DI **généré** |
| `lib/core/constants/api_endpoints.dart` | Toutes les URLs API + baseUrl |
| `lib/core/auth/token_storage.dart` | Stockage tokens sécurisé + migration + expiration |
| `lib/core/auth/auth_interceptor.dart` | Intercepteur Dio (Bearer, refresh, routes optionnelles) |
| `lib/router/app_router.dart` | Config GoRouter (routes + shell) |
| `lib/router/auth_guard.dart` | AuthGuard + RoleGuard + mixin |
| `lib/router/widgets/main_shell.dart` | Shell de navigation (sidebar/bottombar/FAB AÏDA) |
| `lib/core/theme/app_theme.dart` | Thème clair |
| `lib/core/widgets/maintenance_overlay.dart` | Voile maintenance global |
| `lib/features/auth/...` | Référence Clean Architecture complète |
| `lib/features/home/presentation/pages/home_page.dart` | Tableau de bord (assemble les sections) |
| `lib/features/gamification/presentation/cubit/gamification_cubit.dart` | XP/niveau/streak (singleton) |

---

*Document maintenu à la main. À mettre à jour à chaque évolution structurelle
de l'app (nouvelle feature, changement de DI/routing/réseau/stockage).*
