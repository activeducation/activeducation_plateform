# Application mobile — Login et Écoles

Ce document décrit les écrans de l'application Flutter sur mobile (largeur inférieure à 720 px), y compris les écrans de détail et les parcours conditionnels. Les contenus affichés dans les listes et les fiches proviennent de l'API ; les noms, images, statistiques et compteurs peuvent donc varier.

## Page de connexion

La page de connexion est construite en deux zones verticales, sans barre de navigation.

En haut, un bandeau compact occupe la largeur de l'écran. Son fond est un dégradé indigo allant d'un bleu profond à un bleu plus clair. Il contient une icône d'école blanche dans un carré arrondi bleu, puis le nom **ActivEducation** et la signature : « Découvrez votre voie, jouez votre avenir. » Les textes sont blancs afin de rester lisibles sur le bandeau.

La partie inférieure est une grande surface claire, séparée visuellement du bandeau par deux angles supérieurs très arrondis. Elle est défilable lorsque la hauteur disponible est réduite. Le formulaire commence avec le titre **Connexion**, suivi de « Bienvenue ! Connectez-vous pour continuer. »

Le formulaire comprend :

- un champ **Adresse email**, avec l'indication `vous@exemple.com` et une icône d'enveloppe ;
- un champ **Mot de passe**, avec des points de masquage, une icône de cadenas et un bouton œil pour afficher ou masquer le mot de passe ;
- le bouton principal **Se connecter**, en dégradé bleu ;
- un séparateur horizontal portant le libellé **OU** ;
- la phrase « Pas encore de compte ? » suivie du lien bleu **S'inscrire**.

Les champs affichent une validation : l'adresse e-mail est obligatoire et doit respecter un format e-mail, tandis que le mot de passe est obligatoire. Pendant l'authentification, le bouton est remplacé par un indicateur de chargement. Une erreur de connexion est signalée par un message flottant rouge ; une connexion réussie redirige vers l'accueil.

## Page « Annuaire des Écoles »

Cette page, accessible depuis l'onglet **Écoles** de la navigation mobile, utilise un fond blanc légèrement lilas. L'en-tête est centré et contient le titre **Annuaire des Ecoles**, puis une petite signature sur deux couleurs : **ACTIV** en bleu et **EDUCATION** en orange. Une icône de réglages apparaît à droite.

Sous l'en-tête, une zone de recherche permet de saisir « Rechercher une ecole, un BTS... ». Elle possède une icône de loupe, un fond clair et une bordure discrète. Elle est suivie d'une rangée horizontale défilable de filtres en pastilles : **Toutes**, **Universite**, **Grande Ecole**, **Institut** et **Centre de Formation**. Le filtre sélectionné est bleu avec un texte blanc ; le filtre par défaut est « Toutes ».

La liste est rafraîchissable par glissement vers le bas. Chaque école apparaît dans une carte blanche aux coins arrondis :

- un bandeau visuel de 100 px affiche son logo ou, à défaut, une icône de bâtiment sur un dégradé doux ;
- deux badges sont superposés au bandeau : le statut **Publique** (bleu) ou **Privee** (orange), et le type d'établissement sur fond blanc ;
- le contenu présente une icône de bâtiment, le nom de l'école, puis sa ville avec une épingle de localisation ;
- une courte description peut être affichée sur deux lignes au maximum ;
- la carte peut aussi indiquer la fourchette de frais et le nombre d'étudiants, avec des icônes dédiées ;
- les accréditations éventuelles sont montrées dans de petites pastilles vertes ;
- deux actions concluent la carte : **Details**, en contour, et **Voir filieres**, en bouton bleu avec flèche.

Un appui sur une carte ou sur l'une de ses actions ouvre la fiche détaillée de l'établissement. Pendant le chargement, un indicateur circulaire bleu est affiché. En cas d'échec réseau, l'écran montre une icône de connexion, le message « Impossible de charger les ecoles. Verifiez votre connexion. » et le bouton **Reessayer**. Si aucun résultat ne correspond, une icône de bâtiment et « Aucune ecole trouvee » sont affichés.

La barre de navigation inférieure reste visible sur cette page avec les accès Accueil, Orientation, Cours, Mentors, Écoles et Profil. Un bouton flottant AÏDA est également présent au-dessus de la barre pour ouvrir l'assistant conversationnel.

### Fiche d'une école

Depuis une carte, la fiche d'établissement présente une image de couverture ou un visuel de remplacement, le logo, le nom, la ville et les badges de type et de statut. Des indicateurs synthétisent notamment l'année de fondation, le nombre d'étudiants, les frais ou les accréditations lorsque ces données existent. Quatre onglets organisent la suite : **Description**, **Filières**, **Admission** et **Contact**. Ils donnent accès au texte de présentation, aux programmes et leurs niveaux/durées, aux conditions d'admission, puis à l'adresse et aux moyens de contact actionnables (téléphone, e-mail, site web). Une action de retour est disponible dans l'en-tête.

## Écrans d'accès et d'inscription

### Écran de démarrage

L'écran de démarrage affiche l'identité ActivEducation sur le fond indigo de la marque pendant la vérification de la session. Il oriente ensuite automatiquement vers la connexion, l'onboarding ou l'accueil suivant l'état du compte.

### Création de compte

La page d'inscription est une page claire, défilable, avec un bouton retour, le titre de bienvenue et un formulaire. Elle demande le nom complet, l'adresse e-mail, le mot de passe et sa confirmation. Des critères de sécurité du mot de passe et une case d'acceptation des conditions guident l'utilisateur. Le bouton principal crée le compte ; un lien permet de revenir à la connexion. Les erreurs de saisie et de création sont affichées dans le flux de l'interface.

## Onboarding

Le parcours d'onboarding est composé de cinq pages à fond clair, avec une progression et des actions de retour ou de poursuite.

### Introduction

La première page présente la promesse de la plateforme avec un visuel illustré, un titre de découverte de l'orientation et de la gamification, puis un bouton pour commencer. Un lien permet de passer directement à l'étape suivante lorsque cela est proposé.

### Profil

La page **Profil** recueille les informations de base nécessaires à la personnalisation : nom, niveau d'études et informations de contexte scolaire. Les champs et sélecteurs sont regroupés dans un formulaire, avec un bouton **Continuer** en bas de page.

### Centres d'intérêt

La page **Centres d'intérêt** invite l'utilisateur à sélectionner plusieurs domaines illustrés par des icônes ou des emojis. Les choix actifs se distinguent par la couleur de marque. Un compteur ou un texte d'aide rappelle de sélectionner les domaines qui attirent l'utilisateur, avant de poursuivre.

### Objectifs

La page **Objectifs** propose des cartes de choix pour indiquer l'intention principale : explorer des métiers, trouver une formation, progresser grâce aux cours ou être accompagné. Les cartes sélectionnées sont mises en évidence et le bouton de continuation enregistre le choix.

### Fin de l'onboarding

La page finale confirme que le profil est prêt. Une illustration de réussite, un message encourageant et un bouton d'accès à l'accueil terminent le parcours. Un petit récapitulatif peut rappeler la personnalisation effectuée.

## Navigation principale

Après connexion, les pages principales partagent une barre inférieure blanche : **Accueil**, **Orientation**, **Cours**, **Mentors**, **Écoles** et **Profil**. L'onglet actif est coloré en bleu. Le bouton flottant AÏDA reste disponible à droite au-dessus de cette barre pour accéder au chat. Les comptes partenaires obtiennent en plus un accès **Partenaire**.

## Accueil

L'accueil est une page de découverte défilable. Son en-tête coloré salue l'utilisateur et met en avant les éléments de gamification : niveau, série d'activité (*streak*) et XP. Une recherche permet de chercher une école ou un métier. Les sections suivantes donnent des raccourcis vers les tests d'orientation, les cours, des établissements, les opportunités et les annonces. Une carte AÏDA propose aussi des suggestions de questions telles que les filières, les métiers adaptés ou les écoles au Togo. Les cartes de chaque section ouvrent leur contenu associé et les liens « voir tout » mènent aux annuaires complets.

## Orientation

### Liste des tests

La page **Tests d'Orientation** affiche les tests disponibles dans une liste de cartes. Chaque carte décrit le test, son objectif et éventuellement sa durée ou son nombre de questions. Un appui lance le test choisi. Les états de chargement, d'erreur et de liste vide sont prévus.

### Passage d'un test

La page de test affiche une barre de progression, le numéro de la question et son énoncé. Selon le type de question, l'utilisateur sélectionne une ou plusieurs réponses, choisit une carte avec emoji ou règle un curseur. Les actions **Précédent** et **Suivant** permettent de parcourir le questionnaire ; la dernière action envoie les réponses pour calculer le résultat.

### Résultats d'orientation

La page de résultats présente un résumé du test et les domaines ou métiers les plus compatibles. Elle met en avant un score ou un pourcentage, puis propose des recommandations sous forme de cartes. Des boutons orientent vers la fiche d'un métier, un nouveau test ou la recherche d'établissements.

### Fiche métier

La fiche métier affiche une couverture ou une illustration, le nom du métier, sa catégorie et une description. Elle détaille les compétences, formations, secteurs, perspectives et informations salariales disponibles. Des appels à l'action dirigent vers les écoles, les formations ou les tests pertinents.

## E-learning

### Catalogue des cours

Le catalogue est une page défilable avec un en-tête e-learning, une recherche « Rechercher un cours... » et des filtres par catégorie. Il propose des accès rapides à **Ma Saga**, **Succès** et **Classement**. Les cours sont présentés par cartes avec miniature, niveau, durée, progression, XP et informations de difficulté. Une section « Continuer » met en avant les cours déjà commencés ; le reste du catalogue est filtrable et ouvre les fiches de cours.

### Détail d'un cours

La fiche d'un cours comporte une grande zone hero avec miniature, titre et retour. Elle réunit une courte description, le niveau, la durée, les XP et le nombre de modules. Le contenu est organisé en modules et leçons ; chaque leçon montre son type (vidéo, article, quiz, PDF ou challenge), sa durée et son état de progression. Le bouton d'action lance ou reprend le cours. Un examen final est proposé lorsqu'il est disponible.

### Leçon

La page de leçon affiche son titre, son type et l'avancement. Le contenu est adapté au format : lecteur vidéo, texte enrichi, document, quiz ou défi. Les objectifs et consignes sont visibles, puis une action permet de valider la leçon. Une confirmation de complétion et les XP obtenus apparaissent lorsque la leçon est terminée ; l'utilisateur peut ensuite poursuivre le parcours.

### Examen d'un cours

L'examen montre la progression et une question à la fois. Il gère les questions à choix unique ou multiple, vrai/faux et association ou ordre selon les données du cours. Après soumission, un écran de résultat affiche le score, la réussite ou l'échec, les XP gagnés et les actions pour recommencer ou revenir au cours.

### Ma Saga

La page **Ma Saga** transforme la progression en parcours ludique. Un hero coloré présente le niveau, la barre XP et des statistiques (streak, succès, cours et rang). Une carte de mission ou une carte de progression montre les étapes déverrouillées, en cours ou verrouillées. Les actions conduisent vers la prochaine leçon, les succès ou le classement.

### Succès

La page **Succès** récapitule les récompenses de l'utilisateur : XP total, niveau et série d'activité. Une grille de badges affiche les succès obtenus et ceux restant à débloquer. Des cartes de défis précisent les actions à accomplir et les récompenses associées.

### Classement

La page de classement affiche un podium pour les meilleurs profils et une liste classée pour les autres. Les avatars sont colorés, les positions et XP sont visibles, et des états d'erreur proposent un bouton **Réessayer**. La période du classement peut être présentée dans l'en-tête.

## Mentors

### Annuaire des mentors

La page **Mentors** contient une recherche, des filtres par spécialité et une action pour devenir mentor. Les mentors sont affichés dans des cartes ou une fiche modale avec avatar, nom, domaine, bio, expérience, localisation et compétences. L'utilisateur peut demander un mentorat depuis la fiche. Des messages couvrent le chargement, l'absence de résultat et les erreurs réseau.

### Devenir mentor

Cette page affiche le titre **Devenir mentor** et une introduction « Partagez votre expérience ». Le formulaire collecte les informations professionnelles, spécialités, expérience, disponibilité et texte de présentation. Après envoi, un écran de confirmation indique que la candidature a été envoyée et permet de revenir dans l'application.

## Profil

Le profil rassemble les informations du compte sous un en-tête avec avatar, nom et e-mail. Une carte de gamification affiche le niveau, une barre XP, le streak, les badges et les défis. Des sections de statistiques, d'achievements et de raccourcis redirigent vers les tests, l'e-learning et les établissements. L'utilisateur peut modifier ses informations avec un formulaire dédié et se déconnecter via une boîte de dialogue de confirmation.

## AÏDA — assistant conversationnel

La page AÏDA est une conversation plein écran avec un en-tête, l'historique des messages et une zone de saisie en bas. Elle propose des suggestions pour démarrer la discussion et affiche les réponses sous forme de bulles formatées. Selon le contexte, AÏDA peut guider vers des métiers, filières, écoles ou cours. Si l'utilisateur n'est pas connecté, un écran dédié explique que la connexion est requise et propose de se connecter ou de créer un compte.

## Recherche globale

La page de recherche possède une barre dans l'en-tête avec l'indication « École, métier, cours... ». Avant toute requête, elle invite à rechercher une école, un métier ou un cours. Les résultats sont ensuite regroupés par catégorie, avec leur nombre, une icône, un titre, un sous-titre et un lien vers le contenu concerné. Les états de recherche en cours et d'absence de résultat sont affichés dans la zone principale.

## Opportunités

La page **Opportunités** liste les offres (stages, bourses, événements ou autres opportunités) dans des cartes. Chaque carte montre le type, le titre, l'organisation, la localisation et les informations utiles disponibles. Les résultats sont chargés progressivement grâce au bouton **Charger plus**. Un état vide informe l'utilisateur lorsqu'aucune opportunité n'est disponible.

## Espace partenaire

Ces pages sont visibles uniquement pour les rôles partenaire, administrateur ou super-administrateur.

### Création d'organisation

La page permet de créer une organisation partenaire. Elle contient les champs nom, description, personne de contact, e-mail, téléphone, adresse et ville. Le bouton de validation envoie le formulaire ; une confirmation affiche le code partenaire créé, tandis que les erreurs sont signalées par message.

### Tableau de bord d'organisation

Le tableau de bord présente l'organisation et ses statistiques dans des cartes. Il affiche la liste des bénéficiaires, leur statut et des actions pour les consulter, les modifier ou en créer un nouveau. Les compteurs permettent de visualiser rapidement l'activité de l'organisation.

### Formulaire bénéficiaire

Ce formulaire sert à ajouter ou modifier un bénéficiaire associé à l'organisation. Les informations personnelles et de suivi sont regroupées en champs de saisie. La page adapte son titre et son action selon qu'il s'agit d'une création ou d'une modification, puis confirme l'enregistrement ou affiche l'erreur retournée.
