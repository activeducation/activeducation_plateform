# Inventaire des pages — Mobile, Frontend et Administration

Ce document recense les pages fonctionnelles actuellement déclarées dans les routeurs et les dossiers de pages du projet. Les chemins contenant `:id` ou `[id]` sont des pages dynamiques : elles affichent la ressource dont l'identifiant est placé dans l'URL. Les tableaux décrivent l'intention de chaque page ; le contenu exact varie suivant les données de l'API et le rôle de l'utilisateur.

## Palette de couleurs utilisée

L'application mobile Flutter, le frontend Next.js et la landing page partagent la même identité visuelle. Le dashboard admin reprend cette palette sur ses contenus, mais utilise une barre latérale plus sombre.

| Usage | Couleur | Code hexadécimal |
| --- | --- | --- |
| Couleur principale | Bleu indigo | `#3133DD` |
| Bleu clair | Indigo clair | `#6062E8` |
| Bleu intermédiaire | Indigo soutenu | `#2322D3` |
| Bleu foncé | Indigo profond | `#0E00C8` |
| Surface principale bleue | Lavande claire | `#E1E0FF` |
| Couleur secondaire / accent | Orange ambré | `#FAA100` |
| Orange clair | Ambre clair | `#FFB94D` |
| Orange foncé | Ambre foncé | `#D48700` |
| Surface orange | Crème orangée | `#FFF3E0` |
| Fond de page | Blanc légèrement lilas | `#FBF8FF` |
| Fond secondaire | Lilas très clair | `#F6F2FA` |
| Cartes | Blanc | `#FFFFFF` |
| Texte principal | Noir bleuté | `#1B1B20` |
| Texte secondaire | Gris bleuté | `#454556` |
| Texte discret | Gris moyen | `#767587` |
| Bordures | Gris lilas | `#E4E1E9` |
| Succès | Vert | `#10B981` |
| Avertissement | Orange | `#F59E0B` |
| Erreur | Rouge | `#EF4444` |
| Information | Bleu | `#3B82F6` |
| Barre XP | Vert menthe | `#34D399` |
| Streak | Orange feu | `#FF6B35` |
| Niveau | Violet | `#8B5CF6` |
| Médaille or | Or | `#FFD700` |
| Médaille argent | Argent | `#C0C0C0` |
| Médaille bronze | Bronze | `#CD7F32` |

Les dégradés les plus présents sont le dégradé principal `#3133DD → #6062E8`, le dégradé hero `#0E00C8 → #3133DD → #6062E8` et le dégradé de progression XP `#34D399 → #10B981`. Les catégories d'orientation utilisent aussi le cyan `#0891B2` (sciences), le rose `#DB2777` (littérature), le vert `#16A34A` (économie), le violet `#7C3AED` (technologie), l'orange `#F59E0B` (arts) et le rouge `#EF4444` (santé).

Dans le dashboard admin, la sidebar utilise `#121217` comme fond, `#1E1E26` comme surface secondaire, `#F3EFF7` pour le texte, `#3133DD` au survol et `#FAA100` pour l'élément actif. Le frontend Next.js propose aussi un thème sombre : fond `#12121A`, surfaces `#1E1E2A` / `#1A1A28`, texte `#EEEEF4` et bordures `#2E2E42`.

## Application mobile Flutter

L'application étudiant est située dans `activ_education_app/`. Après authentification, les rubriques Accueil, Orientation, Cours, Mentors, Écoles et Profil partagent une navigation basse et un bouton flottant AÏDA.

| Chemin / accès | Page | Description |
| --- | --- | --- |
| `/` | Démarrage | Vérifie la session et redirige vers la connexion, l'onboarding ou l'accueil. |
| `/login` | Connexion | Bandeau de marque, champs e-mail et mot de passe, affichage/masquage du mot de passe, validation et lien vers l'inscription. |
| `/register` | Inscription | Création de compte avec informations de profil, confirmation et critères de mot de passe, acceptation des conditions et lien de connexion. |
| `/onboarding` | Introduction | Présente ActivEducation et lance le parcours de personnalisation. |
| `/onboarding/profile` | Profil initial | Recueille les informations scolaires et personnelles de base. |
| `/onboarding/interests` | Centres d'intérêt | Permet de choisir plusieurs domaines d'intérêt sous forme de cartes. |
| `/onboarding/goals` | Objectifs | Demande l'objectif principal de l'utilisateur sur la plateforme. |
| `/onboarding/complete` | Fin d'onboarding | Confirme la personnalisation du compte et donne accès à l'accueil. |
| `/home` | Accueil | Tableau de bord étudiant : salutation, niveau, XP, streak, recherche, tests, cours, écoles, opportunités, annonces et carte AÏDA. |
| `/orientation` | Tests d'orientation | Liste des tests disponibles avec leur description et accès au lancement. |
| `/orientation/test` | Passage d'un test | Questionnaire avec progression, choix, cartes à emoji ou curseurs, puis soumission. Le test est transmis comme donnée de navigation. |
| `/orientation/results` | Résultats | Affiche le résultat, les profils ou domaines suggérés et les recommandations de métiers. |
| `/orientation/career` | Fiche métier | Présente un métier, ses compétences, formations, secteurs, perspectives et appels à l'action. |
| `/elearning` | Catalogue de cours | Recherche, catégories, cours à reprendre, cartes de cours et accès à la saga, aux succès et au classement. |
| `/elearning/course/:id` | Détail d'un cours | Hero du cours, description, informations pédagogiques, modules, leçons et accès à l'examen. |
| `/elearning/lesson/:id` | Leçon | Affiche une vidéo, un article, un PDF, un quiz ou un challenge et permet de valider la progression. |
| `/elearning/course/:id/exam` | Examen | Fait passer l'évaluation finale du cours et restitue le score obtenu. |
| `/elearning/saga` | Ma Saga | Visualise le parcours gamifié, le niveau, les XP, les missions et les étapes de progression. |
| `/elearning/success` | Succès | Regroupe XP total, niveau, streak, badges et défis. |
| `/elearning/leaderboard` | Classement | Affiche le podium, la liste classée et les XP des utilisateurs. |
| `/mentors` | Annuaire des mentors | Recherche, filtres par spécialité, profils de mentors et demande de mentorat. |
| `/mentors/apply` | Devenir mentor | Formulaire de candidature d'un professionnel souhaitant devenir mentor. |
| `/schools` | Annuaire des écoles | Recherche et filtres d'établissements, cartes avec type, statut, ville, frais, effectif et filières. |
| accès depuis une carte école | Fiche d'école | Détail avec présentation, filières, admission et contact dans des onglets. |
| `/profile` | Profil | Informations utilisateur, progression gamifiée, achievements, raccourcis et édition/déconnexion. |
| `/chat` | AÏDA | Conversation avec l'assistant d'orientation ; un écran alternatif demande la connexion si nécessaire. |
| `/search` | Recherche globale | Recherche d'écoles, métiers et cours, avec résultats regroupés par type. |
| `/opportunities` | Opportunités | Liste paginée d'offres, bourses, stages ou événements et chargement d'éléments supplémentaires. |
| `/partner/organization/create` | Créer une organisation | Formulaire réservé aux partenaires pour créer leur organisation. |
| `/partner/organization/:orgId` | Tableau de bord partenaire | Suivi d'une organisation et de ses bénéficiaires. |
| `/partner/beneficiary/create/:orgId` | Ajouter un bénéficiaire | Saisie d'un nouveau bénéficiaire pour l'organisation. |
| `/partner/beneficiary/:id?orgId=…` | Modifier un bénéficiaire | Édition d'un bénéficiaire existant dans le contexte de son organisation. |

## Frontend étudiant Next.js

Le frontend web est situé dans `frontend/src/app/`. Il reprend la majorité des parcours de l'application mobile avec une structure de routes Next.js et une présentation optimisée pour le navigateur.

| Chemin | Page | Description |
| --- | --- | --- |
| `/` | Accueil | Page d'accueil étudiant : aperçu de la progression, accès aux contenus, aux tests, aux opportunités et à AÏDA. |
| `/login` | Connexion | Formulaire de connexion au compte utilisateur. |
| `/register` | Inscription | Formulaire de création de compte et règles de mot de passe. |
| `/onboarding` | Introduction onboarding | Première étape de découverte de la plateforme. |
| `/onboarding/profile` | Profil onboarding | Collecte les informations de profil initiales. |
| `/onboarding/interests` | Intérêts onboarding | Sélection des domaines d'intérêt. |
| `/onboarding/goals` | Objectifs onboarding | Choix des objectifs d'orientation ou d'apprentissage. |
| `/onboarding/complete` | Onboarding terminé | Confirmation et transition vers l'espace étudiant. |
| `/profil` | Profil | Compte, identité, progrès, gamification et préférences utilisateur. |
| `/parametres` | Paramètres | Préférences et réglages liés au compte. |
| `/confidentialite` | Confidentialité | Informations et contrôles relatifs à la confidentialité. |
| `/classement` | Classement | Comparaison de la progression et des XP entre utilisateurs. |
| `/cours` | Catalogue de cours | Liste, recherche et filtres de contenus e-learning. |
| `/cours/[id]` | Détail d'un cours | Présentation d'un cours, modules, leçons, progression et actions de poursuite. |
| `/cours/[id]/exam` | Examen d'un cours | Questionnaire final, soumission et résultat de l'évaluation. |
| `/lecon/[id]` | Leçon | Consultation du contenu d'une leçon et mise à jour de l'avancement. |
| `/elearning/saga` | Ma Saga | Vue ludique de la progression et des missions. |
| `/elearning/success` | Succès | Badges, défis et statistiques de gamification. |
| `/ecoles` | Annuaire des écoles | Exploration et filtrage des établissements et formations. |
| `/ecoles/[id]` | Fiche d'école | Informations détaillées, filières, admission et moyens de contact d'un établissement. |
| `/mentors` | Annuaire des mentors | Recherche de mentors et consultation de leurs profils. |
| `/mentors/apply` | Candidature mentor | Formulaire pour devenir mentor. |
| `/orientation` | Orientation | Point d'entrée vers les tests, carrières et recommandations. |
| `/orientation/test/[id]` | Test d'orientation | Exécution d'un test identifié par son URL. |
| `/orientation/resultats` | Résultats d'orientation | Restitution des scores et recommandations de parcours. |
| `/orientation/career/[id]` | Fiche métier | Détail d'une carrière et des parcours associés. |
| `/opportunities` | Opportunités | Offres et occasions à saisir, organisées par type. |
| `/search` | Recherche | Recherche transversale de cours, métiers et établissements. |
| `/aida` | AÏDA | Interface web de discussion avec l'assistant. |

## Dashboard d'administration Flutter

Le back-office se trouve dans `admin_dashboard/`. Les pages standard utilisent une sidebar et exigent une session administrateur. Les pages Réglages, Annonces et Journal d'audit sont réservées au super-administrateur.

| Chemin | Page | Description |
| --- | --- | --- |
| `/login` | Connexion admin | Authentification des administrateurs au back-office. |
| `/dashboard` | Tableau de bord | Vue synthétique de l'activité et des indicateurs principaux de la plateforme. |
| `/users` | Utilisateurs | Table de recherche, filtrage et administration des comptes. |
| `/users/:id` | Détail utilisateur | Consultation d'un utilisateur, de son rôle, de son statut et de ses informations associées. |
| `/schools` | Établissements | Liste des écoles et accès aux actions de gestion. |
| `/schools/new` | Nouvel établissement | Formulaire de création d'une école ou université. |
| `/schools/:id/edit` | Modifier un établissement | Édition des informations, médias, programmes et données de l'établissement ciblé. |
| `/careers` | Métiers | Liste et gestion des fiches métiers. |
| `/careers/sectors` | Secteurs | Gestion des secteurs et catégories utilisés pour classer les métiers. |
| `/careers/new` | Nouveau métier | Création d'une fiche carrière. |
| `/careers/:id/edit` | Modifier un métier | Édition d'une fiche métier, de sa description, de ses compétences et recommandations. |
| `/tests` | Tests d'orientation | Liste des questionnaires d'orientation existants. |
| `/tests/new` | Nouveau test | Éditeur permettant de construire un test, ses questions et ses options. |
| `/tests/:id/edit` | Modifier un test | Édition d'un test d'orientation déjà créé. |
| `/gamification/achievements` | Badges / achievements | Gestion des badges et conditions de déblocage. |
| `/gamification/challenges` | Défis | Création et administration des défis et récompenses. |
| `/gamification/users` | Gamification utilisateurs | Consultation et gestion des données de gamification par utilisateur. |
| `/mentors` | Mentors | Liste et suivi des profils mentors. |
| `/mentors/applications` | Candidatures mentors | Traitement des demandes de professionnels pour devenir mentor. |
| `/elearning/courses` | Cours e-learning | Liste et pilotage du catalogue de cours. |
| `/elearning/courses/new` | Nouveau cours | Éditeur de cours, modules, leçons, médias et examens. |
| `/elearning/courses/:id/edit` | Modifier un cours | Édition complète d'un cours existant et de son contenu pédagogique. |
| `/opportunities` | Opportunités | Liste, statut et gestion des opportunités publiées. |
| `/opportunities/new` | Nouvelle opportunité | Création d'une offre, bourse, stage ou événement. |
| `/opportunities/:id/edit` | Modifier une opportunité | Édition d'une opportunité ciblée. |
| `/partner/organizations` | Organisations partenaires | Liste et gestion des organisations partenaires. |
| `/settings` | Réglages | Paramètres globaux de la plateforme, réservés au super-administrateur. |
| `/announcements` | Annonces | Publication et administration des annonces affichées aux utilisateurs. |
| `/audit-log` | Journal d'audit | Consultation des actions enregistrées pour la traçabilité. |

## Portail école

Le portail école fait partie du dashboard, mais possède son authentification, sa navigation et ses pages propres. Il est destiné aux comptes `school_admin`.

| Chemin | Page | Description |
| --- | --- | --- |
| `/school-portal/login` | Connexion établissement | Authentification d'un responsable d'école dans son espace dédié. |
| `/school-portal/dashboard` | Tableau de bord école | Vue des indicateurs et de l'activité associés à l'établissement. |
| `/school-portal/courses` | Cours de l'école | Liste des cours administrables par l'établissement. |
| `/school-portal/courses/new` | Nouveau cours école | Création d'un cours depuis le portail établissement. |
| `/school-portal/courses/:id/edit` | Modifier un cours école | Modification d'un cours spécifique de l'établissement. |
| `/school-portal/profile` | Profil de l'école | Gestion des informations publiques et du profil de l'établissement. |

## Remarques de navigation

- Les pages d'administration et du portail école sont protégées par rôle ; une URL seule ne donne pas accès à une page non autorisée.
- Les pages de détail et d'édition sont identifiées par un paramètre de route afin de réutiliser la même interface pour chaque ressource.
- Certaines vues mobiles, comme le détail d'une école, sont ouvertes directement depuis une carte plutôt que par une route URL publique distincte.
- Les écrans d'attente, d'erreur, de liste vide, de confirmation et les boîtes de dialogue ne sont pas comptés comme pages autonomes, mais font partie du comportement de ces pages.
