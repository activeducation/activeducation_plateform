---
description: Règles de Design System et d'UI pour ActivEducation
trigger: always_on
---

# Design System & UI Rules

Ce projet utilise une charte graphique (V2) très stricte que tous les développeurs (et agents IA) doivent respecter.

## Couleurs
- **Primary** : Bleu Royal (`#3133DD`)
- **Accent/Gold** : Ambre/Or (`#FAA100`)
- **Success** : Vert (`#00C853`)
- **Error** : Rouge (`#FF3D00`)

## Typographie
- La police principale est **Hanken Grotesque**.
- Utilisez `font-display` pour les titres, et la police par défaut pour le corps du texte.
- N'utilisez pas de polices serif ou ludiques.

## Esthétique générale
- **Flat Design uniquement** : Pas de grandes ombres portées (shadow-xl), pas de dégradés complexes, pas de glassmorphism excessif, pas de bordures arrondies énormes. Des lignes pures.
- **Zéro Emoji** : Les emojis (🚀, 🎓, etc.) sont strictement interdits dans l'interface utilisateur. Utilisez exclusivement la librairie d'icônes `lucide-react`.

## Composants
- Utilisez toujours les composants de `src/components/ui` (`Button`, `Card`, `Input`, etc.) plutôt que de recréer des éléments HTML de base avec des classes Tailwind.
- Le design doit paraître professionnel, institutionnel mais moderne (orienté étudiants et professionnels).
