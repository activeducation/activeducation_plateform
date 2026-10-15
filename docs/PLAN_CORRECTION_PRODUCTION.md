# Plan de correction production

Travail sur le périmètre Next.js actuel, avec maintien des applications Flutter/FastAPI existantes. Les tables Next.js et legacy ne seront pas fusionnées implicitement. Les données distantes ne sont pas modifiées par les vérifications locales.

## Lots et critères de validation

1. **Autorisations et contrats API** : garde admin unique, erreurs publiques neutres, validation des entrées, publication respectée. Refus anonyme/étudiant et succès admin testés.
2. **Progression et récompenses** : lectures et écritures sous verrou utilisateur dans une transaction ; inscription idempotente ; validation des leçons/prérequis/quiz ; gain serveur ; UI confirmée par la réponse. Tests de répétition, concurrence et rollback.
3. **Schéma et migrations** : contraintes reflétées dans Drizzle, déduplication préservant les leçons, migrations reproductibles, suppression du script SQL dangereux. Validation sur PostgreSQL local si disponible, jamais avec les identifiants distants du `.env`.
4. **Parcours exposés** : chat compatible avec le SDK, limites serveur partagées, données du profil réelles, stockage isolé par compte, sauvegarde réelle du nom. Retrait des faux succès des fonctionnalités sans service opérationnel.
5. **Livraison et maintenance** : CI Next.js, workflow backend réutilisable, contrôle TypeScript, lint, build et tests. Réduction des fichiers et scripts morts identifiés ; documentation des limites restantes.

## Suivi

- Plan établi ; exécution en cours.
- Les preuves et limites seront consignées à la fin, sans déclarer une migration distante ou un déploiement effectués.
