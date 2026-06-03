# Travail réalisé — Mentors, Partenaires & Candidatures

> Branche : **`feat/mentors-partners-applications`**
> Réalisé pendant la nuit, prêt pour ta revue.

---

## 🎯 Ce que tu avais demandé

1. On ne pouvait pas ajouter de mentors ni de partenaires, ni les contrôler / leur assigner des tâches.
2. Permettre aux gens d'**envoyer leur candidature mentor** depuis l'app → reçue sur le **dashboard admin** **et** par **email** sur `activedutg@gmail.com` (modifiable, **pas codé en dur**).
3. Être ingénieux, sans long refactoring.

**Tout est fait.** ✅

---

## 🐞 Bugs corrigés

### Page « Partenaires » qui affichait « Impossible de charger les organisations »
**Cause** : la page appelait `getIt<Dio>()` — mais côté admin, `Dio` n'est pas
enregistré dans l'injection de dépendances (seul `ApiClient` l'est). L'appel
plantait avant même de contacter le serveur.
**Fix** : `getIt<ApiClient>().dio`. La route backend existait déjà → la page
charge maintenant les organisations. **Les partenaires fonctionnaient déjà**
de bout en bout (l'app crée une org → l'admin l'approuve) ; seul l'affichage
de la liste était cassé.

### « 0 mentors » dans l'admin
Ce n'était pas un bug : la table était simplement **vide** car **aucun moyen
d'en ajouter** n'existait. C'est désormais résolu (création directe +
candidatures).

---

## ✨ Nouvelles fonctionnalités

### 1. Candidature mentor depuis l'app étudiant
- Bouton **« Devenir mentor »** (FAB) sur la page Mentors.
- Formulaire complet (nom, email, téléphone, spécialité, expérience, LinkedIn,
  bio, motivation), **pré-rempli** avec le profil connecté.
- Envoie `POST /mentors/apply`. Écran de confirmation.

### 2. Réception côté admin
- Nouvelle page **« Candidatures »** (menu latéral, sous Mentors).
- Liste filtrable : **En attente / Approuvées / Rejetées**.
- **Approuver** → crée automatiquement le mentor + email de bienvenue au candidat.
- **Rejeter** → email courtois au candidat.

### 3. Réception par email (configurable, pas codé en dur)
- À chaque candidature, l'équipe reçoit un **email récapitulatif** + le candidat
  reçoit un **accusé de réception**.
- L'adresse destinataire est lue depuis la clé **`app_settings.notification_email`**
  (valeur par défaut `activedutg@gmail.com`), **modifiable à chaud** sans
  redéploiement (priorité sur la variable d'env `NOTIFICATION_EMAIL`).
- Service email **best-effort** : si le SMTP n'est pas configuré ou échoue, la
  candidature passe quand même (l'email ne bloque jamais rien).

### 4. Gestion & contrôle des mentors (admin)
- **« Créer un mentor »** directement (dialog).
- **Vérifier / Activer / Désactiver** (existait, désormais fonctionnel avec la
  colonne `is_active`).
- **Assigner des tâches** à un mentor : bouton « Tâches » → liste, ajout avec
  **priorité**, cocher = terminé.

### 5. Bonus — notification des nouvelles organisations partenaires
À chaque organisation partenaire créée depuis l'app, l'équipe reçoit aussi un
email (même mécanisme configurable).

---

## ⚙️ Ce qu'il reste à faire de TON côté (2 choses)

### A. Appliquer la migration en base (OBLIGATOIRE)
La nouvelle table des candidatures/tâches n'existe pas encore en prod. À lancer
(comme on l'a fait pour la 014) :

```powershell
$env:DATABASE_URL = "postgresql://postgres.<ref>:<pwd>@aws-<n>-<region>.pooler.supabase.com:5432/postgres"
cd backend
alembic upgrade head    # applique la migration 015
```

> Sans ça, la page Candidatures et `POST /mentors/apply` renverront une erreur
> (table manquante).

### B. (Optionnel) Activer l'envoi d'emails
Tant que le SMTP n'est pas configuré, **tout fonctionne sauf l'envoi d'email**
(les candidatures arrivent quand même dans le dashboard). Pour activer les
emails, ajoute dans `backend/.env.production` :

```
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=ton_email@gmail.com
SMTP_PASSWORD=mot_de_passe_application   # "App password" Google, pas le mdp normal
SMTP_FROM=ton_email@gmail.com
SMTP_USE_TLS=True
```

L'adresse **de réception** (`notification_email`) est déjà en base
(`activedutg@gmail.com`) et modifiable depuis le back-office plus tard.

> Pour Gmail : il faut créer un **mot de passe d'application** (Google Account →
> Sécurité → Validation en 2 étapes → Mots de passe des applications).

---

## ✅ Validation effectuée

- **Backend** : l'app FastAPI s'importe entièrement (toutes les routes OK),
  ruff clean, **158 tests passent** (+ 5 tests ajoutés pour le service email).
- **App étudiant** : `flutter analyze` sans erreur + **build web release OK**.
- **Dashboard admin** : `flutter analyze` sans erreur + **build web release OK**.
- Migration 015 : compile, une seule head, idempotente.

---

## 📦 Commits sur la branche `feat/mentors-partners-applications`

1. `feat(mentors)` — candidatures + gestion admin + email configurable (backend + fix page Partenaires)
2. `feat(app)` — écran « Devenir mentor »
3. `feat(admin)` — candidatures + création mentor + tâches
4. `feat(partner)` — notification email création organisation

---

## 🚀 Pour déployer (quand tu valides)

1. **Migration** : `alembic upgrade head` (étape A ci-dessus).
2. **Merger** la branche dans `develop` (via PR, comme d'habitude).
3. **Backend** : `git pull` + `docker compose up -d --build backend` sur le VPS.
4. **Fronts** : rebuild local + `scp` (app + admin), puis `docker restart`.
5. (Optionnel) configurer le SMTP pour activer les emails.

---

## 💡 Détails techniques (pour info)

- **Migration 015** : tables `mentor_applications`, `mentor_tasks` ; colonnes
  `mentors.{is_active,email,phone,source}` ; seed `app_settings.notification_email`.
- **Nouveaux fichiers backend** : `core/email.py`, `schemas/mentor.py`,
  `repositories/mentor_repository.py`, `endpoints/admin/mentor_applications.py`.
- **Endpoints ajoutés** :
  - `POST /mentors/apply` (public)
  - `GET /admin/mentor-applications` + `PATCH .../approve` + `.../reject`
  - `POST /admin/mentors` (création), `GET/POST /admin/mentors/{id}/tasks`,
    `PATCH/DELETE /admin/mentors/tasks/{id}`
- **Aucune dépendance ajoutée** : le service email utilise `smtplib` (stdlib).
- **Best-effort partout** : aucune notification email ne peut casser une action
  métier.

Bonne revue ! 🙌
