# L'espace mentorat — guide du développeur

> État au 31 août 2026, branche `integration/tutorai`.
> Migration `030`. 14 tests dédiés dans `backend/tests/test_mentorship.py`.

Avant cette version, les mentors n'étaient qu'un **annuaire** : on les
consultait, sans jamais pouvoir les solliciter. Les tables
`mentor_relationships` et `mentor_availability` existaient depuis le
`schema.sql` historique mais aucun code ne les lisait, et le front déclarait
déjà dans `api_endpoints.dart` des routes (`/mentors/{id}/request`,
`/mentor-relationships`) que le backend n'implémentait pas.

---

## Table des matières

1. [La contrainte qui a décidé de la conception](#1-la-contrainte-qui-a-décidé-de-la-conception)
2. [Ce que font les autres plateformes](#2-ce-que-font-les-autres-plateformes)
3. [Fichiers concernés](#3-fichiers-concernés)
4. [Modèle de données](#4-modèle-de-données)
5. [Le parcours, étape par étape](#5-le-parcours-étape-par-étape)
6. [Le lien signé du mentor](#6-le-lien-signé-du-mentor)
7. [Les suggestions](#7-les-suggestions)
8. [Reproduire en local](#8-reproduire-en-local)
9. [Déploiement](#9-déploiement)
10. [Ce qui n'est pas fait](#10-ce-qui-nest-pas-fait)
11. [Pièges et invariants](#11-pièges-et-invariants)

---

## 1. La contrainte qui a décidé de la conception

Relevé en production avant d'écrire la moindre ligne :

```
mentors total : 4
  avec user_id : 0
  sans user_id : 4
  actifs+verifies : 2
```

**Aucun mentor n'a de compte utilisateur.** Un espace où le mentor se connecte
pour accepter une demande, discuter et planifier aurait donc été construit pour
un côté qui ne peut pas se connecter.

Le modèle retenu ne suppose pas de compte côté mentor :

- la relation est identifiée par la paire (mentor, élève) ;
- les actions du mentor passent par un **lien signé** envoyé par email ;
- le canal des séances est celui qui existe réellement au Togo — WhatsApp,
  téléphone, présentiel — plutôt que la visio.

Si des comptes mentors sont ouverts plus tard, rien n'est à défaire : il suffit
d'ajouter une seconde voie d'accès aux mêmes endpoints.

---

## 2. Ce que font les autres plateformes

Recherche menée le 31 août 2026. Le socle est identique partout :
**matching → réservation de séance → communication → objectifs → avis →
pilotage**. Les moteurs de matching évaluent jusqu'à 20 dimensions (objectifs,
compétences, disponibilités, style de mentorat, séniorité). Le parcours
ADPList / MentorCruise se résume à *parcourir → lire le profil et les avis →
réserver un créneau de 30 à 60 minutes*.

Pour un public jeune, la littérature ajoute une couche absente des outils RH :
consentement, cadre géré, standards de conduite, échanges dans un environnement
contrôlé.

Sur la contrainte locale, WhatsApp est documenté comme le canal qui **passe en
bande passante faible**, avec des usages pédagogiques éprouvés en Afrique.
L'asynchrone y est la norme, pas le repli.

### Les quatre écarts assumés

| Marché | ActivEducation | Pourquoi |
|---|---|---|
| Score de compatibilité opaque | Termes de correspondance affichés | Un élève doit lire *pourquoi* on lui propose quelqu'un |
| Visio par défaut | WhatsApp / téléphone / présentiel / visio | La visio ne passe pas partout ; la plateforme enregistre le canal, elle n'héberge pas l'appel |
| Mise en relation nue | Objectif obligatoire | Le mentor décide sur un but écrit ; c'est ce qui sépare les programmes qui tiennent de ceux qui s'éteignent |
| Classement instable | Tri déterministe | Deux mentors ex æquo permutaient à chaque ouverture : la liste avait l'air tirée au sort |

Le premier écart n'est possible que parce qu'ActivEducation possède déjà un
moteur d'orientation en amont (voir [ORIENTATION.md](ORIENTATION.md)). Aucune
plateforme généraliste n'a cette entrée.

Sources :
[Qooper — AI matching](https://www.qooper.io/blog/mentoring-software-with-ai-matching) ·
[ADPList — plateformes comparées](https://adplist.org/guides/best-mentorship-platforms) ·
[Cal.com — workflows mentorat](https://cal.com/workflows/workflows-for-mentoring-programs) ·
[Mentoring For Youth — safeguarding](https://www.mentoringforyouth.com/safeguarding-policy) ·
[MIT News — WhatsApp low-tech learning](https://news.mit.edu/2020/mit-study-promise-of-whatsapp-for-low-tech-distance-learning-0806) ·
[UNISA — WhatsApp distance education](https://pmc.ncbi.nlm.nih.gov/articles/PMC9124049/)

---

## 3. Fichiers concernés

### Backend

| Fichier | Rôle |
|---|---|
| `app/api/v1/endpoints/mentorship.py` | Endpoints élève + lien signé du mentor |
| `app/repositories/mentorship_repository.py` | Accès données, capacité, suggestions |
| `app/schemas/mentor.py` | Section « ESPACE MENTORAT » en fin de fichier |
| `app/api/v1/router.py` | Enregistrement avec `prefix=""` |
| `alembic/versions/030_espace_mentorat.py` | Migration |
| `tests/test_mentorship.py` | 14 tests |

Le préfixe vide est délibéré : les chemins couvrent `/mentors/{id}/request`,
`/mentor-relationships` et `/mentorship/*`, tels que le front les déclarait
déjà.

### Application Flutter

| Fichier | Rôle |
|---|---|
| `features/mentors/data/models/mentorship_model.dart` | `Mentorship`, `MentorSession`, `MentorSuggestion`, `SessionChannel` |
| `features/mentors/presentation/pages/mentorship_page.dart` | « Mon espace mentorat », deux onglets |
| `features/mentors/presentation/widgets/mentorship_request_sheet.dart` | Demande + proposition de séance |
| `core/constants/api_endpoints.dart` | `relationshipSessions`, `mentorSuggestions` |
| `router/app_router.dart` | Route `/mentorship` |
| `features/mentors/presentation/pages/mentors_page.dart` | Point d'entrée dans l'AppBar |

---

## 4. Modèle de données

### `mentor_relationships`

Préexistait au `schema.sql`, complétée par la migration 030.

| Colonne | Note |
|---|---|
| `mentor_id`, `mentee_id` | `UNIQUE(mentor_id, mentee_id)` — une seule relation par paire |
| `status` | `pending` → `active` \| `cancelled`, puis `completed` |
| `goal` | **ajouté** — objectif de l'élève, obligatoire à la création |
| `message` | message libre, facultatif |
| `preferred_channel` | **ajouté**, contrainte `CHECK` sur les 4 canaux |
| `decided_at`, `decline_reason` | **ajoutés** |
| `started_at`, `ended_at` | posés à la décision |

### `mentor_sessions` (nouvelle)

| Colonne | Note |
|---|---|
| `relationship_id` | `ON DELETE CASCADE` |
| `scheduled_at`, `duration_min` | défaut 45 min |
| `channel` | `whatsapp` \| `telephone` \| `presentiel` \| `visio` |
| `status` | `proposed` → `confirmed` → `done`, ou `cancelled` |
| `proposed_by` | `mentee` \| `mentor` |
| `topic`, `notes` | libres |

### RLS

Les deux tables ont **RLS actif sans aucune politique**. Ce n'est pas un oubli :
en PostgreSQL cela signifie « personne ne lit », hormis `service_role` qui la
contourne. Le backend interroge avec `service_role` et ne transmet **jamais** le
JWT de l'élève à Supabase — `auth.uid()` y est toujours `NULL`, donc une
politique par utilisateur ne filtrerait rien. **C'est le backend qui est la
frontière de sécurité**, d'où les vérifications d'appartenance explicites à
chaque endpoint (`_owned_relationship`). Voir [RLS_AUDIT.md](RLS_AUDIT.md).

### Capacité

`mentors.max_mentees` (défaut 5) et `mentors.current_mentees` existaient déjà.
`current_mentees` est **recompté** depuis les relations actives
(`refresh_mentee_count`), jamais incrémenté : deux acceptations simultanées
feraient diverger un compteur incrémenté.

---

## 5. Le parcours, étape par étape

```
Élève                         Backend                        Mentor (sans compte)
  │                              │                                  │
  ├─ POST /mentors/{id}/request ─►                                  │
  │   goal, message, canal       │ contrôles :                      │
  │                              │  · mentor actif + vérifié        │
  │                              │  · pas de relation existante     │
  │                              │  · < 3 demandes en attente       │
  │                              │  · places restantes > 0          │
  │                              ├─ email + lien signé ────────────►│
  │                              │                                  │
  │                              ◄─ GET  /mentorship/invitation/… ──┤
  │                              ◄─ POST /mentorship/invitation/… ──┤ accepte / décline
  │                              │  → status active, recomptage     │
  ├─ GET /mentor-relationships ──►                                  │
  │   statut, séances            │                                  │
  ├─ POST …/sessions ────────────► séance proposée                  │
  ├─ PATCH …/sessions/{id} ──────► confirmée / annulée / annotée    │
```

### Les endpoints

| Route | Auth | Rôle |
|---|---|---|
| `POST /mentors/{id}/request` | JWT élève | Envoie la demande — `10/hour` |
| `GET /mentor-relationships` | JWT élève | Mes mentorats, mentor et séances inclus |
| `POST /mentor-relationships/{id}/sessions` | JWT élève | Propose une séance (relation `active` requise) |
| `PATCH /mentor-relationships/{id}/sessions/{sid}` | JWT élève | Confirme, annule, annote |
| `GET /mentorship/suggestions` | JWT élève | Mentors classés par le profil d'orientation |
| `GET /mentorship/invitation/{id}?token=` | Jeton | Le mentor lit la demande — `20/hour` |
| `POST /mentorship/invitation/{id}?token=` | Jeton | Le mentor décide — `20/hour` |

### Garde-fous

- Les coordonnées du mentor ne sont **jamais** renvoyées par l'API publique.
- Le lien d'invitation **n'expose pas l'identité de l'élève** : le mentor décide
  sur l'objectif, pas sur la personne.
- Quota de 3 demandes en attente par élève — une demande immobilise une place.
- La capacité est vérifiée **deux fois** : à l'envoi et à l'acceptation.
- `_owned_relationship` renvoie la même erreur pour « n'existe pas » et « ne
  vous appartient pas » : distinguer les deux révélerait quelles relations
  existent.
- Une séance est vérifiée comme appartenant à **cette** relation ; sinon
  connaître un identifiant de séance suffirait à la modifier.

---

## 6. Le lien signé du mentor

```python
def invitation_token(relationship_id) -> str:
    secret = get_settings().SECRET_KEY.encode()
    message = f"mentorship-invitation:{relationship_id}".encode()
    return hmac.new(secret, message, hashlib.sha256).hexdigest()[:40]
```

Propriétés voulues :

- **rien à stocker** — le jeton se recalcule, aucune colonne, aucune expiration
  à gérer ;
- **lié à une seule relation** — un mentor ne peut pas répondre à la demande
  d'un autre ;
- **non fabricable** — sans `SECRET_KEY` ;
- **révocable en bloc** — une rotation de `SECRET_KEY` invalide tous les liens
  déjà envoyés.

La comparaison utilise `hmac.compare_digest` et non `==` : une comparaison naïve
laisse fuiter le jeton caractère par caractère via le temps de réponse.

La décision est **idempotente** : recliquer sur le lien renvoie la relation
telle quelle, sans erreur ni changement.

Le lien absolu est construit depuis `request.base_url`, l'adresse par laquelle
l'API vient réellement d'être appelée. Aucune URL de base n'est stockée en
configuration — elle divergerait du déploiement.

---

## 7. Les suggestions

`GET /mentorship/suggestions` lit le profil d'orientation de l'élève
(`student_orientation_profile` : `interests`, `favorite_subjects`,
`career_project`) et le rapproche de ce que le mentor annonce (`specialty`,
`expertise_areas`).

Le rapprochement est un recouvrement de termes normalisés — sans accents, sans
casse, mots vides écartés (`de`, `des`, `sciences`, `métier`…). Sans ce filtre,
« sciences » rapprocherait n'importe quoi.

La réponse renvoie `match_terms`, la liste des termes communs, **affichée telle
quelle dans l'app** : l'élève lit « correspond à : génie, électricité » plutôt
qu'un score.

Tri : pertinence, puis note, **puis nom**. Le dernier critère n'est pas
décoratif — sans lui, deux mentors ex æquo permutent à chaque appel.

Sans profil, le classement retombe sur la note. Le drapeau `personalized` de la
réponse dit lequel des deux s'applique, et l'app affiche franchement « complétez
votre test d'orientation pour que ces mentors soient classés selon votre
profil » plutôt que de promettre une personnalisation qui n'a pas eu lieu.

---

## 8. Reproduire en local

```bash
cd backend
python -m pytest tests/test_mentorship.py -q
```

Les tests couvrent le jeton (stabilité, unicité par relation, non-réversibilité,
dépendance à `SECRET_KEY`), la normalisation des termes et le classement des
suggestions (pertinence, déterminisme, places restantes, profil vide). Ils
n'exigent **aucune base** : le repository est instancié via `__new__` et reçoit
un faux client Supabase, sur le modèle de `test_schools_accreditation_filter.py`.

Pour appeler l'API :

```bash
curl -H "Authorization: Bearer $JWT" http://localhost:8000/api/v1/mentorship/suggestions
```

---

## 9. Déploiement

```bash
cd backend && alembic upgrade head
```

Puis rebuild de l'application élève. Le dashboard admin n'est pas touché.

L'envoi de l'email au mentor est **best-effort** : si SMTP n'est pas configuré,
la demande est quand même enregistrée, mais le mentor ne reçoit pas son lien.
Vérifier `SMTP_HOST` avant d'annoncer la fonctionnalité aux élèves.

---

## 10. Ce qui n'est pas fait

**La messagerie.** C'est le manque principal. Elle a besoin que le canal côté
mentor soit tranché d'abord — relais email, ou ouverture de comptes mentors.
La construire avant reviendrait à choisir cette architecture par accident.
Les tables `conversations` et `messages` du `schema.sql` ne conviennent pas
telles quelles : elles relient deux `user_profiles`, or les mentors n'ont pas de
compte. Une table portée par `relationship_id` avec un `sender_role`
(`mentee` / `mentor`) serait le bon modèle.

Restent aussi :

- **écriture des avis** — `mentor_reviews` existe et est lue par
  `GET /mentors/{id}/reviews`, mais aucune route n'écrit ;
- **supervision admin** des relations en cours ;
- **proposition de séance côté mentor** — seul l'élève propose aujourd'hui ;
- **`mentor_availability`** reste inutilisée : la disponibilité est négociée
  séance par séance plutôt que par créneaux publiés ;
- **rattachement à la gamification** — une séance tenue pourrait alimenter les
  défis existants.

---

## 11. Pièges et invariants

**Le front avait pris de l'avance.** `api_endpoints.dart` déclarait
`requestMentor()` et `mentorRelationships` bien avant que le backend les
implémente. Vérifier ce fichier avant d'inventer de nouvelles routes.

**`prefix=""` dans le router.** Le router `mentorship` porte ses chemins
complets. Ne pas lui ajouter de préfixe : les URLs attendues par le front
casseraient.

**Pas de jointure PostgREST entre `mentors` et `mentor_relationships`.** Les
tables viennent du `schema.sql` historique et ne portent pas de clé étrangère
que PostgREST sache suivre. `list_for_mentee` fait donc trois requêtes bornées
plutôt qu'un `select` imbriqué.

**`current_mentees` se recompte, ne s'incrémente pas.** Voir §4.

**Le canal par défaut n'est pas la visio.** Si un jour la liste `CHANNELS`
change, elle est dupliquée à trois endroits : la migration 030 (contrainte
`CHECK`), `SESSION_CHANNELS` dans `schemas/mentor.py`, et l'enum
`SessionChannel` côté Flutter. Les trois doivent rester alignés.

**Ne jamais réintroduire de valeur par défaut inventée.** Le champ
`is_public` des écoles a montré le coût de cette habitude : trois couches
répondant « publique » sur une donnée que personne ne connaissait. Ici, un
champ absent reste `null` et l'interface s'abstient — c'est délibéré. Voir
[AUDIT_IMPORT_ETABLISSEMENTS.md](AUDIT_IMPORT_ETABLISSEMENTS.md).
