# Audit de préparation à la production — 9 octobre 2026

## Conclusion et périmètre

**La version Next.js examinée ne devrait pas être mise en production en l'état.** Les problèmes prioritaires concernent les autorisations administrateur, l'intégrité des progressions, la compilation et la reproductibilité du déploiement. Un nettoyage cosmétique ne suffira pas.

Revue de l'arbre de travail local, y compris les fichiers modifiés et non suivis présents avant l'audit. Aucun code applicatif corrigé. Lecture des règles `.agents/rules`, des routes Next.js, schémas et migrations, parcours étudiants, portions du backend FastAPI, injection de dépendances Flutter et workflows de livraison. Le détail des deux applications Flutter n'a pas été audité exhaustivement.

Les constats sont établis par lecture du code et contrôles locaux. Aucune exploitation ni mutation d'une base distante, aucun appel aux services IA, aucune vérification des droits PostgreSQL réels ou du reverse proxy déployé. Les problèmes d'accès ci-dessous décrivent les protections absentes dans l'application ; leur exposition publique effective dépend du déploiement.

Priorités : **P0** = bloquer la mise en ligne du périmètre concerné ; **P1** = corriger avant une ouverture générale ; **P2** = dette de qualité ou d'exploitation à planifier. Les liens pointent vers les fichiers et lignes de l'état audité.

## Vérifications exécutées

| Contrôle | Résultat |
|---|---|
| TypeScript : `node node_modules/typescript/bin/tsc --noEmit --incremental false` dans `web` | Échec : 12 diagnostics dans les sources et 2 dans `.next/types/validator.ts` |
| ESLint : `npm.cmd run lint -- --format json --output-file ../audit-eslint.json` dans `web` | Échec : 195 erreurs et 75 avertissements ; dans `web/src` seul : 161 erreurs et 70 avertissements |
| Tests ciblés Python : progression, déblocage, examens, orientation | Non exécutés : le Python référencé par `backend/.venv` est absent ; le venv racine est également inutilisable ; Python système sans pytest |
| Recherche de références | Réalisée pour les candidats au code mort listés plus bas |
| Build complet, tests Flutter, tests navigateur, tests de charge | Non exécutés ; aucune validation de ces aspects n'est revendiquée |

Les deux erreurs `.next` mentionnent d'anciennes pages `student/evaluations`. Elles doivent être revérifiées après régénération du cache. Elles ne doivent pas être confondues avec les 12 diagnostics dans les sources.

ESLint n'est pas un compteur de bugs : une partie des alertes porte sur les apostrophes JSX, les imports inutilisés et les scripts CommonJS. Les défauts fonctionnels ci-dessous sont documentés séparément.

## Constats prioritaires

### 1. P0 — Écritures administrateur sans authentification

**Preuves :** [cours PUT/DELETE](D:/ActivEducation/web/src/app/api/admin/courses/[id]/route.ts:25), [création de leçon](D:/ActivEducation/web/src/app/api/admin/courses/[id]/lessons/route.ts:20), [modification/suppression de leçon](D:/ActivEducation/web/src/app/api/admin/courses/[id]/lessons/[lessonId]/route.ts:27), [création d'opportunité](D:/ActivEducation/web/src/app/api/admin/opportunities/route.ts:16), [suppression d'opportunité](D:/ActivEducation/web/src/app/api/admin/opportunities/[id]/route.ts:6).

Ces handlers écrivent avec `db` sans vérifier une session ni un rôle. Le middleware rafraîchit la session, mais ne refuse que l'accès anonyme à `/student` : [middleware](D:/ActivEducation/web/src/utils/supabase/middleware.ts:36). La suppression d'un cours entraîne les cascades prévues par le schéma.

**Correction :** garde serveur commune `requireAdmin` dans chaque route et contrôle des droits avant toute requête ; validation des entrées ; journal d'audit pour les mutations. **Validation :** anonyme → 401, étudiant → 403, administrateur → succès, sans mutation pour les deux premiers cas. Protéger seulement le layout ne protège pas les API.

### 2. P1 — Un étudiant peut créer des cours et lire la liste des utilisateurs

**Preuves :** [POST cours](D:/ActivEducation/web/src/app/api/admin/courses/route.ts:28), [page utilisateurs](D:/ActivEducation/web/src/app/admin/utilisateurs/page.tsx:8).

La présence d'une session suffit. La page utilisateurs envoie au client tous les enregistrements `users`, dont les emails. Le dashboard admin ne vérifie même pas la session : [dashboard](D:/ActivEducation/web/src/app/admin/page.tsx:10).

**Correction :** vérifier le rôle serveur ; limiter les colonnes retournées et paginer. Tester explicitement les pages serveur avec un compte étudiant.

### 3. P1 — Attribution d'XP contrôlée par le client et rejouable

**Preuve :** [route XP](D:/ActivEducation/web/src/app/api/user/xp/route.ts:16).

Tout utilisateur connecté choisit `xpToAdd` ; aucun événement métier, preuve de réussite, plafond ou clé d'idempotence n'est exigé. La séquence lecture puis écriture perd également des incréments lors de requêtes concurrentes. [L'orientation](D:/ActivEducation/web/src/app/api/orientation/generate/route.ts:116) ajoute 200 XP à chaque sauvegarde, sans vérifier une récompense précédente et sans recalculer le niveau.

**Correction :** calcul des gains exclusivement serveur à partir d'événements validés ; unicité de la récompense ; transaction contenant l'événement, la progression et l'incrément atomique. Tester les répétitions et la concurrence.

### 4. P1 — Validation de leçon sans contrôle de la leçon

**Preuve :** [complete-lesson](D:/ActivEducation/web/src/app/api/student/courses/complete-lesson/route.ts:16).

La route vérifie seulement la présence de `courseId`, `lessonId` et d'une inscription. Elle accepte un identifiant de leçon inventé ou appartenant à un autre cours. Aucune vérification des prérequis ni des réponses du quiz. Le pourcentage est ensuite calculé avec le nombre brut d'identifiants : [page cours](D:/ActivEducation/web/src/app/student/cours/page.tsx:38), donc il peut dépasser 100 %. `status` et `completedAt` ne sont pas mis à jour à la fin du cours.

**Correction :** valider UUID, existence, appartenance, publication et conditions de réussite côté serveur ; progression relationnelle et transactionnelle ; état terminé calculé sur les vraies leçons du cours.

### 5. P1 — Inscriptions dupliquées et mises à jour concurrentes non fiables

**Preuves :** [schéma courseProgress](D:/ActivEducation/web/src/db/schema.ts:44), [inscription](D:/ActivEducation/web/src/app/api/student/courses/enroll/route.ts:22).

Pas de clé primaire ni d'unicité `(user_id, course_id)`. Deux appels parallèles peuvent tous deux constater l'absence d'inscription puis insérer. Deux validations de leçon peuvent écraser le JSON `completedLessons` de l'autre requête. La table `explorerCareerPrograms` n'a pas non plus d'unicité sur son couple de clés.

**Correction :** dédupliquer puis ajouter des contraintes composites ; insertion avec gestion du conflit ; table de complétions avec unicité utilisateur/leçon. Tester deux inscriptions et deux complétions simultanées.

### 6. P1 — Le frontend affiche une réussite malgré un échec de sauvegarde

**Preuve :** [completeActiveLesson](D:/ActivEducation/web/src/app/student/cours/CoursesClient.tsx:151).

L'interface marque la leçon terminée avant la réponse serveur ; elle augmente l'XP local même si l'API XP échoue. L'appel de complétion ne vérifie pas `response.ok`. La célébration est ensuite affichée. Une recharge révèle la perte de progression. L'XP et la complétion passent par deux requêtes indépendantes.

**Correction :** endpoint métier unique et atomique ; afficher le résultat confirmé, ou prévoir un vrai mécanisme de rollback et de reprise pour l'optimisme UI. Tester réseau coupé et réponses 400/500.

### 7. P1 — Compilation TypeScript en échec

**Preuves :** [erreurs Zod](D:/ActivEducation/web/src/app/api/admin/courses/route.ts:48), [Navbar](D:/ActivEducation/web/src/app/orientation/page.tsx:72), [animations](D:/ActivEducation/web/src/app/page.tsx:91), [messages chat](D:/ActivEducation/web/src/components/AidaChatWidget.tsx:78).

Diagnostics source : cinq accès `ZodError.errors` incompatibles avec les types installés, une utilisation de props non acceptées par Navbar, cinq incompatibilités de `Variants` Framer Motion, un message `UIMessage` contenant `content`. Les `as any` et `@ts-ignore` présents dans le chat masquent en outre d'autres incompatibilités.

**Correction :** utiliser les contrats des versions installées (`issues` pour Zod), typer les variants et migrer le chat ; obtenir un typecheck propre puis exécuter un vrai build de production.

### 8. P1 — Chat AÏDA incompatible avec son SDK

**Preuves :** [client](D:/ActivEducation/web/src/components/AidaChatWidget.tsx:36), [réponse serveur](D:/ActivEducation/web/src/app/api/chat/route.ts:35).

Le client utilise l'ancien format `content`, des options historiques `api/initialMessages/body` et rend `m.content`. Le code du SDK installé utilise des messages à `parts` et un transport par défaut de flux UI ; le serveur retourne un flux texte brut. Cette incompatibilité est distincte de la seule erreur TypeScript visible.

**Correction :** choisir un contrat de transport cohérent, convertir les messages pour le modèle et rendre les parties textuelles ; vérifier l'envoi, le streaming, l'historique, l'effacement et les erreurs en navigateur.

### 9. P1 — API IA sans quotas applicatifs

**Preuves :** [chat](D:/ActivEducation/web/src/app/api/chat/route.ts:7), [génération orientation](D:/ActivEducation/web/src/app/api/orientation/generate/route.ts:38).

Le chat ne vérifie pas l'authentification. L'orientation continue volontairement sans session. Pas de limite applicative de fréquence, de taille de conversation ni de budget utilisateur sur ces handlers. Les protections du backend Python ne s'appliquent pas à ces routes Next.js indépendantes.

**Correction :** politique explicite d'accès invité, quotas par utilisateur/IP, limites de taille et de tokens, délais et concurrence bornés. Vérifier un dépassement de quota sans appeler le fournisseur réel.

### 10. P1 — CI Next.js absente et workflow de production incohérent

**Preuves :** [frontend CI](D:/ActivEducation/.github/workflows/frontend-ci.yml:3), [appel du workflow](D:/ActivEducation/.github/workflows/deploy-prod.yml:28), [déclencheurs backend](D:/ActivEducation/.github/workflows/backend-ci.yml:3).

La CI frontend ne vise que Flutter. `web` n'a pas de script de tests dans `package.json`. Le workflow de production appelle `backend-ci.yml` via `uses`, mais ce dernier ne déclare pas `workflow_call`. Cet appel ne constitue donc pas un workflow réutilisable valide. Les tests Flutter ont `continue-on-error: true`. Les checks mypy et Safety backend sont également consultatifs ; les tests pytest backend sont bien bloquants avec un seuil de couverture de 48 %.

**Correction :** ajouter un pipeline Next.js avec installation figée, lint, typecheck, tests métier et build ; rendre le workflow backend réutilisable correctement ou revoir l'orchestration ; transmettre explicitement les secrets nécessaires ; rétablir progressivement les gates non bloquantes.

### 11. P1 — Les migrations versionnées ne reconstruisent pas le schéma Next.js

**Preuves :** [migration initiale](D:/ActivEducation/web/supabase/migrations/0000_cooing_satana.sql:9), [schéma courant](D:/ActivEducation/web/src/db/schema.ts:19), [migration manuelle explorateur](D:/ActivEducation/web/migrate_orientation.js:6).

Les deux migrations numérotées ne créent pas le schéma courant : absence notamment de `lessons`, des tables explorateur, d'`opportunities` et de `completed_lessons`. Des scripts ponctuels et des modifications directes compensent cet écart hors du journal Drizzle. Le script explorateur absorbe ses erreurs sans fixer un code de sortie en échec.

**Correction :** établir une baseline compatible avec l'existant, intégrer les évolutions dans une chaîne de migrations vérifiable, tester une base vide et une montée de version. Ne pas appliquer aveuglément un `push` sur la production ; la règle locale de synchronisation ne remplace pas un historique reproductible.

## Incohérences fonctionnelles et architecturales

### 12. P1 — Deux sources de vérité pour les mêmes fonctionnalités

**Preuves :** [users Next.js](D:/ActivEducation/web/src/db/schema.ts:5), [user_profiles Python](D:/ActivEducation/backend/app/repositories/users_repository.py:47), [elearning_courses Python](D:/ActivEducation/backend/app/repositories/elearning_repository.py:43).

Next.js utilise `users`, `courses`, `course_progress` ; FastAPI utilise `user_profiles`, `elearning_courses`, `elearning_enrollments` et sa propre progression. La coexistence n'est pas en soi un défaut, mais aucune stratégie de convergence n'est établie dans les parcours examinés. Les workflows et Docker Compose livrent Flutter/FastAPI, alors que les règles récentes visent Next.js/Drizzle. Un changement visible dans un produit ne modifie pas automatiquement l'autre.

**Correction :** décider du périmètre réellement servi en production, nommer le propriétaire des données et définir une migration ou une API commune. Mettre à jour README, runbooks et déploiement ; ne pas supprimer Flutter sans décision explicite.

### 13. P1 — Rôles incohérents en majuscules et minuscules

**Preuves :** [schéma](D:/ActivEducation/web/src/db/schema.ts:10), [contrôle explorateur](D:/ActivEducation/web/src/app/api/admin/explorer/careers/route.ts:49), [affichage](D:/ActivEducation/web/src/app/admin/utilisateurs/UtilisateursClient.tsx:64).

Le schéma documente `STUDENT/ADMIN`, les APIs explorateur exigent exactement `admin`, l'interface accepte les deux formes. Un utilisateur affiché administrateur avec `ADMIN` sera refusé par ces APIs. Le comptage étudiant ne compte que `STUDENT`.

**Correction :** convention unique, migration des données existantes, contrainte de base et garde partagée. Ne pas normaliser seulement l'affichage.

### 14. P1 — Brouillons accessibles hors administration

**Preuves :** [fiche métier](D:/ActivEducation/web/src/app/student/explorer/metier/[id]/page.tsx:25), [détail cours backend](D:/ActivEducation/backend/app/repositories/elearning_repository.py:95), [route publique backend](D:/ActivEducation/backend/app/api/v1/endpoints/elearning.py:93).

La fiche métier filtre le slug mais pas `isPublished`, y compris les formations liées. Le détail cours Python filtre l'ID mais pas `is_published` et est appelé par une route à authentification optionnelle utilisant le repository admin. Les GET admin Next.js exposent également des listes non filtrées sans garde.

**Correction :** politique de publication commune sur listes, détails et relations ; accès aux brouillons réservé aux routes autorisées. Tester l'accès direct par identifiant et slug.

### 15. P1 — Profil, CV et email de résultat simulés

**Preuves :** [profil](D:/ActivEducation/web/src/app/student/profil/page.tsx:60), [CV](D:/ActivEducation/web/src/app/student/profil/page.tsx:72), [email résultat](D:/ActivEducation/web/src/app/student/orientation/resultats/page.tsx:142).

La sauvegarde du profil ne fait qu'attendre puis afficher `saved`. Le CV stocke seulement un nom dans l'état React. Le résultat d'orientation marque l'email envoyé sans appel réseau. L'avatar persiste une URL `blob:` temporaire dans localStorage, pas un fichier durable.

**Correction :** brancher des opérations persistantes réelles et afficher les erreurs ; désactiver les actions non implémentées au lieu d'annoncer un succès. Tester une recharge et une autre session.

### 16. P1 — Historique et orientation partagés entre comptes sur un navigateur

**Preuves :** [historique chat](D:/ActivEducation/web/src/components/AidaChatWidget.tsx:18), [résultats prioritaires en localStorage](D:/ActivEducation/web/src/app/student/orientation/resultats/page.tsx:102), [déconnexion](D:/ActivEducation/web/src/components/Navbar.tsx:93).

Les clés de stockage ne contiennent pas l'identifiant utilisateur. Les résultats locaux sont retournés avant toute lecture serveur. La déconnexion n'efface pas ces données. Après A puis B sur le même navigateur, les résultats de A peuvent être présentés à B ; l'historique du chat utilise la même clé globale.

**Correction :** source de vérité serveur, cache lié à l'identité et invalidation au changement de compte. Tester explicitement A → déconnexion → B.

### 17. P2 — Page Parcours branchée sur un contrat inexistant

**Preuves :** [appel GET](D:/ActivEducation/web/src/app/student/parcours/page.tsx:34), [route XP POST uniquement](D:/ActivEducation/web/src/app/api/user/xp/route.ts:7).

La page appelle GET `/api/user/xp` alors que seul POST existe : 405 attendu. Elle lit en outre `xp` et `rankTitle` plutôt que `xpPoints`. Elle conserve donc ses valeurs initiales malgré les gains réels.

**Correction :** utiliser `/api/user` et un DTO partagé, puis tester l'affichage après un gain confirmé.

### 18. P1 — Une opportunité explicitement non publiée devient publiée

**Preuve :** [création opportunité](D:/ActivEducation/web/src/app/api/admin/opportunities/route.ts:36).

`isPublished: body.isPublished || true` transforme `false` en `true`. Un brouillon demandé par l'administrateur devient public.

**Correction :** validation booléenne et défaut explicite sûr (`false`), préserver une valeur fournie à `false`. Tester ce cas séparément.

### 19. P1 — Backend asynchrone effectuant des entrées/sorties synchrones

**Preuves :** [repository async](D:/ActivEducation/backend/app/repositories/elearning_repository.py:35), [lecture profil](D:/ActivEducation/backend/app/repositories/users_repository.py:36), [pseudo-sommeil non bloquant](D:/ActivEducation/backend/app/db/supabase_client.py:50).

Les fonctions `async def` exécutent directement le client Supabase synchrone. `_non_blocking_sleep` attend `.result()` sur le thread courant ; déplacer `sleep` dans un thread puis attendre synchroniquement ne libère pas la boucle événementielle. Une requête lente ou en retry retarde les autres requêtes du worker.

**Correction :** client async ou déport explicite des opérations synchrones dans un pool borné ; `await asyncio.sleep` dans un retry async ; politique de retry limitée aux erreurs transitoires. Mesurer la concurrence avec une dépendance lente simulée. Ne pas annoncer de gain chiffré sans mesure.

### 20. P2 — Gestion d'erreurs qui masque les défaillances

**Preuves :** [fallback orientation](D:/ActivEducation/web/src/app/api/orientation/generate/route.ts:122), [erreur SQL retournée](D:/ActivEducation/web/src/app/api/admin/courses/[id]/route.ts:45).

Une sauvegarde d'orientation ratée peut retourner un succès ; le catch externe génère même un résultat avec des réponses vides. Plusieurs APIs admin renvoient directement `error.message`, potentiellement technique. Les mutations sans validation Zod ne distinguent pas entrée invalide, ressource absente et panne interne.

**Correction :** contrats d'erreur stables, statuts adaptés, messages publics neutres et logs corrélés ; distinguer calcul réussi, mode dégradé et sauvegarde effective. Valider tailles, UUID, enums et contenu des leçons.

## Code mort et dette de maintenance

### 21. P2 — Composants et fixtures sans consommateur identifié

La recherche de références dans les sources ne trouve pas de consommateur pour [CourseCatalog](D:/ActivEducation/web/src/components/CourseCatalog.tsx:22), [ProgressionDashboard](D:/ActivEducation/web/src/components/ProgressionDashboard.tsx:23), ni [mockData](D:/ActivEducation/web/src/data/mockData.ts:3). Ce sont des **candidats au code mort**, pas une preuve d'absence d'usage externe. Vérifier les imports dynamiques et tests avant suppression. Le catalogue inutilisé contient notamment des boutons sans action.

Dans Flutter, [ProfileRepositoryImpl](D:/ActivEducation/activ_education_app/lib/features/profile/data/repositories/profile_repository_impl.dart:7) renvoie un faux profil et reste enregistré dans l'injection de dépendances. Cependant la page profil actuelle utilise `AuthBloc` et `GamificationRepository` ; les références à `ProfileBloc` observées se limitent à sa définition et à l'enregistrement généré. **Ne pas conclure que la page actuelle affiche Jean Dupont** : il s'agit d'une chaîne héritée probablement dormante, à retirer ou reconnecter après validation.

La déclaration `aiConversations` n'a pas de consommateur trouvé dans `web/src` ; cela ne justifie pas de supprimer la table ou ses données sans inventaire.

### 22. P2 — Données fictives encore présentes dans des composants actifs

[AidaChatWidget](D:/ActivEducation/web/src/components/AidaChatWidget.tsx:24) contient le nom Kossi, une école, un niveau et des réalisations codés en dur. Même une fois le transport réparé, ce contexte doit provenir du profil authentifié. Les résultats d'orientation disposent aussi d'un modèle statique ; celui-ci est signalé dans l'UI par `isDefaultModel`, donc il ne faut pas le décrire comme entièrement caché. Les erreurs serveur ne devraient néanmoins pas être assimilées à l'absence d'un résultat.

**Correction :** respecter la règle locale « No Hidden Mocks », séparer démo et application, charger des données réelles et afficher des états vides honnêtes.

### 23. P2 — Typage et composants volumineux rendent les régressions faciles

ESLint relève notamment 67 usages explicites de `any` et 46 variables/imports inutilisés sur son périmètre complet. [CoursesClient](D:/ActivEducation/web/src/app/student/cours/CoursesClient.tsx:151) combine catalogue, progression, récompenses et lecteur de quiz. Les contrôles de rôles et la transformation des données sont dispersés.

**Correction :** DTO validés aux frontières, types JSONB explicites, service métier de complétion, composant de lecture autonome. Prioriser les frontières métier plutôt qu'un objectif arbitraire de taille de fichier ; ne pas remplacer `any` par des assertions non vérifiées.

### 24. P2 — Charte UI et accessibilité appliquées de façon inégale

**Preuve :** [widget AÏDA](D:/ActivEducation/web/src/components/AidaChatWidget.tsx:95).

Présence de `shadow-xl`, `shadow-2xl`, grands arrondis et dégradés malgré les règles flat design du dépôt. Des boutons avec icône seule, notamment ouverture/fermeture du chat, n'ont pas de nom accessible. Les alertes ESLint montrent aussi des usages de `<img>` et de liens HTML internes à revoir selon leur contexte.

**Correction :** composants UI partagés, noms accessibles et navigation clavier ; vérification visuelle. Ce chantier vient après l'intégrité des données et les autorisations.

## Ordre de remédiation et critères de sortie

1. **Fermer les accès incorrects** : garde admin commune sur toutes les routes et pages ; matrice anonyme/étudiant/admin ; restriction des brouillons ; quotas IA.
2. **Fiabiliser les écritures** : complétion et récompense atomiques et idempotentes, contraintes d'unicité, validation métier, absence de faux succès.
3. **Rendre le déploiement reproductible** : architecture cible et source de vérité explicites ; migrations rejouables ; workflow réutilisable valide ; pipeline Next.js ; typecheck, lint et build propres.
4. **Terminer les parcours exposés** : chat compatible SDK, profil/CV/email réellement persistants, stockage isolé par compte, Parcours branché sur le bon contrat.
5. **Nettoyer et mesurer** : retrait des candidats morts après vérification, async backend réel, pagination, observabilité, conformité UI et documentation.

Avant une ouverture générale, exiger des tests d'intégration qui couvrent les refus d'accès, la lecture d'un brouillon, la double soumission d'une leçon, la concurrence d'inscriptions, l'échec réseau, le changement de compte et la reconstruction sur base vide. La présence de tests unitaires ou d'une CI verte sur l'ancien périmètre ne suffit pas.

## Limites et points à confirmer

- Vérifier quelle application est effectivement exposée aux utilisateurs ; les défauts Next.js ne prouvent pas qu'ils sont déployés sur le site actuel.
- Inspecter les rôles PostgreSQL, RLS et protections du proxy sur un environnement de test ; aucune hypothèse de leur configuration réelle n'est présentée comme vérifiée.
- Réparer les environnements Python, relancer les tests backend puis les tests Flutter. L'échec de lancement local n'est pas un échec fonctionnel de ces tests.
- Tester migrations, sauvegarde/restauration, charge et parcours navigateur avant de conclure à la préparation production.
- Aucun scan de dépendances actualisé ni pentest dynamique effectué ; aucune absence de vulnérabilités supplémentaires n'est garantie par cette revue.
