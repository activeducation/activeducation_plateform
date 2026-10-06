---
description: Normes de développement Next.js, React et Backend
trigger: always_on
---

# Architecture & Standards de Code

## Next.js (App Router)
- Tous les composants dans `src/app` sont des **Server Components** par défaut.
- Ajoutez la directive `"use client";` tout en haut du fichier *uniquement* si le composant a besoin d'interactivité (useState, useEffect, onClick).
- Privilégiez le chargement des données côté serveur (`fetch` dans les Server Components) quand c'est possible.

## Base de données (Drizzle ORM)
- Le schéma de la base est dans `src/db/schema.ts`.
- **Interdiction formelle de coder des données en dur (mocks / hardcoded)** dans l'application finale. Toute liste (cours, utilisateurs, opportunités) doit provenir de la base de données PostgreSQL (via `/api` ou Server Components).
- Les modifications de schéma nécessitent la commande `npx drizzle-kit push` (après avoir testé/validé).

## Conventions de Code
- **Pas de "vibes codeurs" brouillonnes** : Nommez les variables de manière claire, en anglais ou français cohérent.
- Gérez systématiquement les erreurs (try/catch sur les API, vérification que les tableaux ne sont pas `null` ou `undefined`).
- Conservez les fichiers propres et supprimez le code commenté mort avant de commit.
