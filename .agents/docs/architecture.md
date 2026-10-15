# Documentation Technique de la Plateforme

Ce dossier contient les informations d'architecture pour permettre au projet de scaler de façon propre.

- **Frontend** : Next.js 14+ (App Router), TailwindCSS, React.
- **Backend** : Route Handlers (`/api`), Node.js, Drizzle ORM.
- **Base de données** : PostgreSQL (hébergé sur Supabase).
- **Gamification** : Modèle de calcul basé sur des points XP par action, stocké dans la table `users`.

Pour modifier la base de données, la règle absolue est de passer par `drizzle-kit push` pour éviter les incohérences.
