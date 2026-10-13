# Contre-audit du rapport de résolution — 9 octobre 2026

## Verdict

**Le rapport de résolution n'est pas validé.** Des corrections réelles ont été apportées, mais plusieurs affirmations sont contredites par le code et les contrôles exécutés. Deux régressions fonctionnelles importantes ont été introduites dans l'explorateur administrateur et la complétion des cours. L'intégrité concurrente des récompenses n'est toujours pas garantie.

Référence examinée : HEAD `61b6e35`, comprenant le commit de correction `37c4569`. Arbre de travail propre au début de cette contre-vérification. Le rapport de résolution a été transmis dans la conversation. Aucun code applicatif modifié pendant cette revue ; seuls ce rapport, le résultat ESLint et un script de reproduction isolé ont été ajoutés.

Attention à la comparaison Git : le commit de correction contient également des fichiers qui existaient déjà sous forme non suivie lors du premier audit. Tout ajout Git de ce commit n'est donc pas automatiquement une correction nouvelle.

## Vérification des cinq affirmations du rapport

| Affirmation | Verdict | Preuve |
|---|---|---|
| Toutes les API admin vérifient le rôle ADMIN | Confirmé sur les 23 handlers actuels, avec régression fonctionnelle dans l'explorateur | 46 vérifications isolées anonyme/étudiant aboutissent à 401/403 ; les quatre POST explorateur rejettent aussi les admins |
| Le layout admin est protégé côté serveur | Confirmé par lecture | `requireAdmin()` puis redirection dans le Server Component |
| La route XP arbitraire est supprimée | Confirmé | Fichier absent, mais deux consommateurs de son URL subsistent |
| Complétion, XP et niveau calculés atomiquement et sûrement | Partiel et incorrect pour la concurrence | Les deux écritures sont dans une transaction, mais les lectures et décisions sont avant celle-ci ; complétion totale calculée sur un champ absent |
| L'UI attend la confirmation avant la célébration | Faux | Modification optimiste, ancien appel XP, absence de contrôle du statut de complétion, célébration malgré l'échec |
| Les contraintes UNIQUE sont définitivement prises en compte | Non démontré pour la base ; incomplet dans le dépôt | Script SQL présent, mais contraintes absentes du schéma Drizzle et des migrations ; exécution réelle non vérifiée |
| L'orientation ne récompense que la première génération | Vrai en séquence normale, faux en concurrence | Deux premières requêtes concurrentes peuvent attribuer 400 XP |
| Le compilateur valide désormais les sources | Faux | TypeScript sort avec code 1 sur `AidaChatWidget.tsx:79` |

## Défauts prioritaires et régressions

### R1 — P1 — Toutes les créations de l'explorateur refusent les administrateurs

**Régression de la correction d'autorisation.** [requireAdmin](D:/ActivEducation/web/src/utils/auth.ts:17) exige exactement `ADMIN`. Après cette garde, les quatre POST conservent leur ancien contrôle exigeant exactement `admin` : [métiers](D:/ActivEducation/web/src/app/api/admin/explorer/careers/route.ts:55), [domaines](D:/ActivEducation/web/src/app/api/admin/explorer/domains/route.ts:56), [formations](D:/ActivEducation/web/src/app/api/admin/explorer/programs/route.ts:58), [établissements](D:/ActivEducation/web/src/app/api/admin/explorer/schools/route.ts:57).

Aucune valeur stable du rôle ne satisfait les deux contrôles. `ADMIN` passe la première garde puis reçoit 403 ; `admin` reçoit 403 dès la première garde. Huit exécutions isolées des vrais handlers reproduisent ces refus.

**À corriger :** supprimer les anciens contrôles redondants, conserver une convention de rôle et migrer les valeurs existantes. Tester aussi le succès administrateur, pas seulement le refus étudiant.

### R2 — P1 — Une seule leçon terminée suffit à terminer tout le cours

**Nouvelle régression.** [complete-lesson:55](D:/ActivEducation/web/src/app/api/student/courses/complete-lesson/route.ts:55) filtre les leçons par `l.isPublished`, alors que [le schéma lessons](D:/ActivEducation/web/src/db/schema.ts:32) ne contient pas ce champ. La liste devient vide, puis `[].every(...)` retourne `true`.

Conséquence : toute première complétion valide écrit `status: COMPLETED` et `completedAt`, même avec d'autres leçons à suivre. Reproduit avec un cours de deux leçons. L'import dynamique `require` et les `any` ont empêché le typage de détecter ce mauvais contrat.

**À corriger :** définir la règle métier à partir des champs réellement disponibles, utiliser un import typé de `lessons`, vérifier l'ensemble des leçons requises et tester la première, l'avant-dernière et la dernière complétion.

### R3 — P1 — Le frontend n'a pas reçu la correction annoncée

[CoursesClient:162](D:/ActivEducation/web/src/app/student/cours/CoursesClient.tsx:162) joue le son et marque la leçon comme terminée avant toute réponse réseau. [L'ancien POST XP](D:/ActivEducation/web/src/app/student/cours/CoursesClient.tsx:193) reste présent alors que sa route a été supprimée. Le chemin d'erreur ajoute quand même les cristaux localement. [L'appel de complétion](D:/ActivEducation/web/src/app/student/cours/CoursesClient.tsx:211) ne vérifie ni `res.ok` ni le résultat contenant `newXp/newLevel`. La célébration est déclenchée ensuite même si la sauvegarde a été refusée.

Cause identifiée : [patch_coursesclient.js:6](D:/ActivEducation/web/patch_coursesclient.js:6) recherche une fonction avec un timeout de `2500`, alors que le composant a `4000`. La regex ne correspond pas au fichier actuel. Le script ne vérifie pas le remplacement et affiche néanmoins « Patched CoursesClient.tsx ». L'absence de correspondance a été reproduite sans exécuter ce script de modification.

**À corriger :** modifier le composant réellement exécuté, appeler uniquement la complétion, utiliser les valeurs de réponse et ne célébrer qu'une réussite confirmée. Tester 400, 401, 500 et interruption réseau. Ajouter une assertion aux scripts de transformation ou retirer ces scripts ponctuels après usage.

### R4 — P1 — La transaction ne supprime pas les pertes de progression et d'XP

[La progression est lue avant la transaction](D:/ActivEducation/web/src/app/api/student/courses/complete-lesson/route.ts:33), et les XP proviennent du profil chargé par `requireAuth`. La transaction à la ligne 59 écrit des valeurs absolues déjà calculées. Elle garantit le regroupement des écritures, pas l'absence de conflit entre décisions fondées sur le même ancien état.

Exemple reproduit en mémoire avec les vrais handlers : L1 et L2, 50 XP chacune, sont validées simultanément. Les deux requêtes répondent 200 ; il ne reste qu'une leçon enregistrée et 50 XP, au lieu de deux et 100 XP. Ce scénario est compatible avec des transactions PostgreSQL qui sérialisent les écritures mais appliquent ces valeurs préalablement calculées. Il n'a pas été exécuté contre la base distante.

**À corriger :** verrouillage et lectures dans la transaction, ou enregistrements de complétion/reward uniques et incréments atomiques ; stratégie cohérente pour les écritures d'XP venant aussi de l'orientation. Ajouter des tests concurrentiels sur PostgreSQL de test.

### R5 — P1 — La première récompense d'orientation reste rejouable en concurrence

[orientation/generate:110](D:/ActivEducation/web/src/app/api/orientation/generate/route.ts:110) effectue séparément : lecture de l'existence d'un résultat, insertion d'un résultat, lecture des XP, écriture des XP. Pas de transaction ou contrainte d'événement unique liant la récompense à cette décision.

Deux requêtes peuvent constater « aucun bilan ». Si la seconde lit les XP après la récompense de la première, le total augmente deux fois. Un ordonnancement contrôlé en mémoire reproduit **400 XP au lieu de 200**. Un autre ordonnancement peut écraser des gains concurrents. De plus, si l'insertion réussit mais l'attribution d'XP échoue, les tentatives ultérieures voient déjà un résultat et ne réparent pas la récompense manquante.

**À corriger :** événement de récompense unique par utilisateur/type, insertion de l'événement et gain atomiques, stratégie de reprise. La simple vérification préalable réduit la répétition séquentielle ; elle ne garantit pas l'idempotence.

### R6 — P1 — Le nettoyage SQL peut perdre des progressions et masquer son échec

[fix_db.js:9](D:/ActivEducation/web/fix_db.js:9) supprime les inscriptions dupliquées selon `ctid`, sans fusionner les `completed_lessons`. Si les doublons portent des leçons différentes, le nettoyage abandonne la progression d'une des lignes. `ctid` ne constitue pas une règle métier de conservation.

Les erreurs de création des contraintes sont absorbées ; [la sortie est forcée à 0](D:/ActivEducation/web/fix_db.js:39), même après une erreur. Les suppressions et l'ajout de contrainte ne forment pas une transaction commune. Le message d'exécution du script ne suffit donc pas à prouver une migration réussie.

Les contraintes ne figurent toujours pas dans [le schéma Drizzle](D:/ActivEducation/web/src/db/schema.ts:44), ni dans les migrations numérotées. Même si elles ont été appliquées sur une base, elles ne sont pas reproductibles depuis ce dépôt. La route [enroll:23](D:/ActivEducation/web/src/app/api/student/courses/enroll/route.ts:23) garde son SELECT puis INSERT : avec UNIQUE, une collision sera probablement retournée en 500, sans gestion idempotente.

**À corriger :** migration versionnée, fusion contrôlée et transactionnelle des progressions, contraintes présentes dans le modèle, erreur non nulle en cas d'échec et `ON CONFLICT` adapté. L'application de ce script sur la base réelle n'a pas été vérifiée et le script n'a pas été exécuté pendant l'audit.

### R7 — P1 — La compilation échoue encore dans les sources

Commande : `node node_modules/typescript/bin/tsc --noEmit --incremental false`, exécutée dans `web`.

Résultat exact :

```text
src/components/AidaChatWidget.tsx(79,9): error TS2353:
Object literal may only specify known properties, and 'content' does not exist
in type 'UIMessage<unknown, UIDataTypes, UITools>'.
```

Les cinq erreurs Zod, les erreurs de variants Framer Motion et la mauvaise prop Navbar ne ressortent plus ; les deux diagnostics de cache Next.js ont également disparu. C'est un progrès réel, mais **le contrôle sort toujours avec code 1**. Le `@ts-ignore` déplacé à la ligne 75 ne corrige pas le contrat incompatible.

**À corriger :** migrer réellement le chat vers les messages et le transport du SDK installé. Le serveur produit encore un flux texte, le client utilise encore l'ancien format `content` et les options historiques. Ne pas déclarer le build validé sur la seule correction de certains diagnostics.

### R8 — P1/P2 — Les règles pédagogiques restent incomplètes

La nouvelle route vérifie correctement existence, appartenance et inscription. Elle ne vérifie toujours pas `courses.isPublished`, les prérequis ou la réussite du quiz. Un étudiant inscrit peut compléter directement la seconde leçon d'un cours dépublié : reproduit isolément avec réponse 200 et attribution de points.

[La récompense](D:/ActivEducation/web/src/app/api/student/courses/complete-lesson/route.ts:48) utilise `lesson.rewardXp || 50` : une récompense explicitement fixée à zéro donne 50 XP. Reproduit également. C'est une erreur de la nouvelle logique serveur, même si la même mauvaise valeur par défaut existait dans l'ancien client.

**À corriger :** valider les règles pédagogiques serveur, les types UUID et les valeurs de récompense ; préserver un zéro valide avec une règle de défaut explicite.

## Suivi des 24 constats du premier audit

« Corrigé dans le code » n'implique pas validation en environnement déployé. Les preuves détaillées des éléments persistants restent dans [l'audit initial](D:/ActivEducation/docs/AUDIT_PRODUCTION_2026-10-09.md).

| N° initial | Sujet | État après correction |
|---|---|---|
| 1 | API admin ouvertes | Gardes ajoutées aux 23 handlers ; refus anonyme/étudiant vérifiés isolément |
| 2 | Création de cours par étudiant / lecture admin | Garde API et layout serveur ajoutés ; vérifier les parcours réels |
| 3 | XP choisis par le client / rejouables | Route arbitraire supprimée ; concurrence non résolue |
| 4 | Leçon inexistante ou étrangère acceptée | Corrigé pour existence/appartenance ; prérequis absents et nouvelle complétion prématurée |
| 5 | Doublons et conflits concurrents | Script SQL seulement ; schéma/migrations incomplets ; pertes de mise à jour persistantes |
| 6 | Faux succès UI de complétion | Non corrigé ; consommateur d'une API maintenant supprimée |
| 7 | Compilation TypeScript | Améliorée, mais toujours en échec |
| 8 | Chat incompatible SDK | Non corrigé |
| 9 | Quotas/authentification des API IA | Non corrigé dans les handlers |
| 10 | CI Next.js et workflow réutilisable | Non corrigé ; aucun changement des workflows |
| 11 | Migrations non reproductibles | Non corrigé ; aucun changement des migrations versionnées |
| 12 | Sources de vérité concurrentes | Non traité ; aucune convergence backend/Next.js documentée par ce correctif |
| 13 | Casse des rôles | Aggravé par deux contrôles incompatibles |
| 14 | Accès direct aux brouillons | GET admin maintenant gardés ; filtres de publication étudiant/backend non corrigés |
| 15 | Profil, CV, email simulés | Non corrigé |
| 16 | Stockage partagé entre comptes | Non corrigé ; mêmes clés localStorage |
| 17 | GET XP inexistant dans Parcours | Toujours incorrect ; l'URL entière est désormais absente, donc 404 au lieu de 405 attendu auparavant |
| 18 | `isPublished: false` devient true | Non corrigé : `body.isPublished || true` reste à opportunities/route.ts:41 |
| 19 | I/O synchrones dans le backend async | Non traité ; aucun changement backend dans ce correctif |
| 20 | Erreurs masquées / détails SQL exposés | Non corrigé ; le nouveau script SQL ajoute une sortie 0 même en échec |
| 21 | Candidats au code mort | Non traités ; ne pas supprimer sans vérification d'usage |
| 22 | Mocks actifs | Non corrigé, notamment contexte utilisateur codé en dur du chat |
| 23 | Typage et dette de composants | Partiel ; lint en hausse, `require`/`any` dans la complétion masque le champ inexistant |
| 24 | Charte UI et accessibilité | Non traité |

## Résultats des contrôles

| Contrôle | Avant | Maintenant |
|---|---|---|
| TypeScript sources | 12 diagnostics | 1 diagnostic, toujours bloquant |
| TypeScript cache `.next` | 2 diagnostics | Aucun diagnostic observé |
| ESLint total | 195 erreurs / 75 avertissements | 211 erreurs / 76 avertissements |
| ESLint `web/src` | 161 erreurs / 70 avertissements | 170 erreurs / 71 avertissements |

Les totaux ESLint ne sont pas des nombres de bugs fonctionnels. Une partie de la hausse vient des scripts ajoutés, mais la hausse existe également dans `src`.

[Résultat ESLint complet](D:/ActivEducation/docs/REVERIFICATION_ESLINT_2026-10-09.json).

Le [script de reproduction](D:/ActivEducation/docs/reverify-production.cjs) transpile et exécute les handlers actuels avec Supabase et la base remplacés par des dépendances en mémoire. Il ne charge aucun `.env` et ne fait aucun appel externe. Commande depuis la racine :

```text
node docs/reverify-production.cjs
```

Résultats observés :

- 46 refus d'accès attendus : 23 handlers × anonyme/étudiant.
- 8 refus administrateur indésirables : 4 POST explorateur × ADMIN/admin.
- Cours de deux leçons terminé après la première : reproduit.
- Leçon étrangère rejetée sans gain XP : confirmé.
- Répétition séquentielle d'une leçon sans double gain : confirmé.
- Seconde leçon sans prérequis d'un cours dépublié acceptée : reproduit.
- Récompense zéro convertie en 50 : reproduit.
- Deux complétions concurrentes : une progression et 50 XP perdus dans le modèle mémoire.
- Deux premières orientations concurrentes : 400 XP attribués dans un ordonnancement contrôlé en mémoire.
- Regex du patch UI : aucune correspondance avec le composant actuel ; appel XP supprimé toujours présent.

Ce script documente des **reproductions de défauts** : sa sortie 0 signifie que les observations attendues ont été reproduites, pas que l'application est conforme. Les scénarios concurrents doivent ensuite être portés dans une suite d'intégration PostgreSQL ; le substitut mémoire n'est pas une implémentation complète des transactions SQL.

## Décision de livraison

Ne pas accepter la formule « toutes les P0/P1 sont corrigées ». Une formulation fidèle serait : « Les gardes administrateur et plusieurs erreurs de typage ont été corrigées ; la complétion et les récompenses ont été partiellement refondues, mais des régressions fonctionnelles, des conflits concurrents et plusieurs constats initiaux restent ouverts. »

Ordre recommandé : corriger R1/R2/R3, rendre les récompenses réellement idempotentes et concurrentes, transformer R6 en migration sûre, obtenir TypeScript et CI verts, puis fermer explicitement chaque constat initial avec une preuve de validation.

Limites : pas de build complet, test navigateur, test PostgreSQL distant ni nouveau test Flutter/backend pendant cette contre-vérification. Leur réussite n'est pas revendiquée. Aucun script de nettoyage SQL n'a été lancé et aucune donnée utilisateur n'a été modifiée.
