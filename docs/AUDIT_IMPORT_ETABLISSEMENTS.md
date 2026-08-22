# Audit — fichier `Etablissements_Superieurs_Togo_Complet.xlsx`

Date : 2026-08-22
Source : `Etablissements_Superieurs_Togo_Complet (1).xlsx` (11 feuilles, 98 établissements)
Cible : table `schools` (97 lignes) et `school_programs` (574 lignes) en production.

## Conclusion

**Le fichier ne doit pas être importé tel quel.** Une seule de ses 11 feuilles
apporte de l'information réelle : la **liste des noms d'établissements**. Les
58 autres colonnes sont, pour 35 d'entre elles, une valeur unique répétée sur
les 98 lignes — donc sans contenu par établissement. Les importer remplacerait
des données réelles déjà en base par du remplissage générique.

## Ce qui a été mesuré

Commande reproductible :

```bash
python backend/scripts/import_etablissements_xlsx.py --audit --file "<fichier>.xlsx"
```

Résultat : **35 colonnes sur 58 sont constantes** sur les 98 lignes.

| Feuille | Constat |
|---|---|
| 1. Filières | 98 lignes, **5 filières distinctes** — 88 établissements se voient attribuer « Comptabilité et Gestion ». La colonne `Description` est identique partout (« Formation professionnelle aux métiers de la gestion. »), y compris pour Médecine. |
| 2. Diplômes | 100 % identique : `Licence Professionnelle` / CAMES `Oui` / `Accrédité MESR` pour tous, universités comprises. |
| 3. Frais | Dérivés mécaniquement de la filière : 88 établissements à `350 000 F CFA`. `Mensualité` et `Autres frais` constants. |
| 4. Conditions d'admission | `Concours`, `Dossier`, `Date limite` constants (`31 Octobre` pour tout le monde). |
| 5. Infrastructures | **Toutes les colonnes constantes** : bibliothèque, labo, restaurant, terrain de sport, amphithéâtre, parking, accessibilité PMR = `Oui` pour les 98, y compris pour de petits centres de formation. `Internat` = `Non` pour les 98. |
| 6. Partenariats | 100 % identique : « Universités de la sous-région / Afrique / Académique ». |
| 7. Débouchés | 100 % identique : « Gestionnaire / Cadre », salaire « Variable ». |
| 8. Bourses | 100 % identique : « Bourse d'excellence / Mention Bien au BAC / Partielle ». |
| 9. Médias | URLs **fabriquées à partir du nom**, techniquement invalides (accents, parenthèses, apostrophes dans le domaine) — ex. `http://www.universitédelomé(ul).tg`. La base contient déjà 86 sites web réels (`https://www.ena.tg`, …). |
| 10. Documents | 100 % identique, et les libellés sont décalés : la colonne `Brochure` contient « Guide de l'étudiant » et la colonne `Guide étudiant` contient « Brochure ». |
| 11. Avis | 98 avis identiques : « Anonyme — 4/5 — Bonne formation professionnelle ». Des avis fabriqués n'ont pas leur place dans un produit destiné à orienter des élèves. |
| **5 et 11 (noms)** | **Exploitable** : 98 noms d'établissements crédibles et cohérents avec le paysage MESR togolais. |

## Comparaison avec l'existant

La base est déjà plus riche que le fichier sur tous les axes qu'il prétend couvrir :

| Champ `schools` | Rempli |
|---|---|
| `city`, `region`, `type`, `admission_info`, `degrees_offered` | 97 / 97 |
| `website` | 86 / 97 |
| `phone` | 72 / 97 |
| `founding_year` | 62 / 97 |
| `email` | 53 / 97 |
| `latitude` | 34 / 97 |
| `accreditations` | 23 / 97 |
| `infrastructure` | 21 / 97 |
| `student_count` | 3 / 97 |
| `tuition_range` | 2 / 97 |

`admission_info` contient déjà, par établissement, le niveau requis, la série
BAC, l'existence d'un concours et les dates — soit exactement ce que la
feuille 4 remplirait avec une valeur unique.

## 14 noms du fichier n'existent sur aucune liste officielle

Le rapprochement direct fichier ↔ base par similarité de nom s'est révélé peu
fiable (37 exacts, 44 ambigus, 17 sans correspondance). La comparaison a donc
été refaite contre la **liste officielle MESR 2025-2026 des 93 établissements
agréés**, extraite du communiqué ministériel (voir `reference_mesr_epes.csv`).

78 des 98 noms du fichier figurent sur cette liste. Sur les 20 restants, six
sont légitimes — établissements publics ou variantes d'écriture, tous déjà en
base : Université de Lomé, Université de Kara, ENS d'Atakpamé, Centre
international de recherche et d'étude de langues, FORMATEC, IAI-Togo.

**Les 14 autres ne figurent sur aucune liste MESR** :

ISDME, ESIM, IFMI, ISSIC, ESMT, ISMC, ESGI, ESSAM, ISMT, ESTM, ISGT, ESMF,
ISTME, ESSS.

Ils occupent les lignes 77 à 93 du fichier et suivent tous le même patron
combinatoire — « Institut/École Supérieure de {Management, Gestion,
Technologie, Sciences Appliquées} et de {Technologie, Management, Finance,
Communication} ». Au vu des 35 colonnes constantes par ailleurs, ce sont selon
toute vraisemblance des **noms fabriqués**. Ils ne doivent pas être insérés :
la plateforme oriente des élèves vers des diplômes reconnus, et un
établissement non agréé n'en délivre pas.

## Ce qui enrichit réellement la base : 21 établissements

En confrontant la liste MESR (93) à la base (97), 21 établissements agréés sont
absents. Ils constituent le seul apport défendable de cette démarche — et la
source est la liste ministérielle, pas le fichier Excel.

Le fichier `rapprochement_etablissements.csv` les contient, pré-remplis :

- **`name`** : libellé officiel MESR (homoglyphes cyrilliques du PDF nettoyés).
- **`city`** : la liste MESR ne suffixe la localité que pour les établissements
  hors Grand Lomé ; les autres sont donc à Lomé. Deux cas portent la localité
  dans leur nom : ESIA → Aného, « Le Miel de Kpové-Zion » → Kpové (**à
  confirmer**). CIB-INTA et ESASN ont été recoupés avec leur site officiel.
- **`region`** : déduite de la ville via la correspondance déjà présente en base
  (Lomé/Aného/Kpové → Maritime).
- **`type`** : déduit de la convention observée dans les 97 fiches existantes —
  « École supérieure / Haute école / École nationale » → `grande_ecole`,
  « Institut / Hôtel école / Centre » → `institut`, « Université » →
  `university`.

Aucun autre champ n'est pré-rempli : ni frais, ni infrastructures, ni avis.

À noter, la liste ministérielle elle-même contient deux doublons : « Institut
Universitaire Global Wealth » figure aux n° 59 et 68, et « Institut de
Recherche et de Formation en Développement Local » aux n° 40 et 84. Les 93
entrées numérotées correspondent donc à 91 établissements distincts. Ces
doublons sont signalés dans `reference_mesr_epes.csv` et n'ont produit qu'une
seule ligne à importer.

## Contrainte de schéma

`schools` impose `NOT NULL` sur `name`, `type` et `city` (vérifié via le schéma
OpenAPI PostgREST). Le fichier Excel ne fournissait ni ville ni type — d'où le
recours à la liste MESR.

## Marche à suivre

```bash
python backend/scripts/import_etablissements_xlsx.py --importer docs/rapprochement_etablissements.csv --dry-run
```

puis sans `--dry-run` pour écrire. L'import est idempotent : un établissement
déjà présent est ignoré. Les fiches sont créées avec `is_verified = false` —
elles restent à documenter (site, contact, programmes) avant validation.

Les feuilles 2 à 11 du fichier Excel sont à écarter intégralement. Les données
correspondantes (frais, infrastructures, débouchés, bourses) doivent être
collectées à la source.

## Suite : alignement sur la liste officielle 2026-2027

Après l'import des 21, la liste **MESR 2026-2027** (signée du 24 juillet 2026 par
le ministre délégué) a été récupérée et transcrite dans
`reference_mesr_2026_2027.csv`. Elle compte **111 établissements : 13 publics et
98 privés** — le chiffre « 98 » désigne les seuls privés, pas le total.

Elle contient elle aussi un doublon : « École supérieure de formation
professionnelle FIMAC (ESFP-FIMAC) » figure en n° 16 et n° 26 du volet privé.
En 2025-2026, le n° 16 était « CFP ANCILA », établissement distinct — d'où un
doute reporté dans `alias_etablissements.csv`.

Confrontation avec la base :

| | Nombre |
|---|---|
| Fiches correspondant à la liste 2026-2027 | 118 |
| Établissements agréés encore absents → **importés** | 17 |
| Fiches hors liste (conservées) | 17 |

Le rapprochement automatique produisait des faux négatifs dus aux renommages
officiels (« Institut UPSILON Collège de Paris Supérieur » → « Ascencia Keyce »,
« École Polytechnique de Lomé » → « École Nationale Polytechnique ») et aux
libellés courts côté ministère (« Institut supérieur Don Bosco » pour l'ISPSH
Don Bosco). Ces équivalences sont consignées, justifiées et relisibles dans
`alias_etablissements.csv` plutôt que codées en dur.

### Marquage de l'agrément plutôt que suppression

`schools.accreditations` porte désormais le millésime `MESR 2026-2027` sur les
118 fiches agréées (script `tag_accreditation_mesr.py`, réversible via
`--retirer`). **Aucune fiche n'a été supprimée ni désactivée** : filtrer sur ce
marqueur suffit à n'exposer que les établissements agréés, sans perdre les
574 programmes ni les établissements que des élèves recherchent malgré leur
absence de la liste.

Les 17 fiches sans marqueur se répartissent en trois groupes :

- **Écoles nationales d'État** — ENA, École Nationale de Sages-Femmes de Lomé,
  École Nationale des Aides Sanitaires de Sokodé, École Nationale de Formation
  Sociale, INJS. Publiques, mais absentes de la liste d'accréditation du MESR.
- **Composantes de l'Université de Lomé** — INSE, ISICA, ESTBA, École Supérieure
  d'Agronomie, IUT de Gestion. Elles sont *dans* l'UL, qui est elle-même n° 1 de
  la liste ; elles ne peuvent pas y figurer séparément.
- **Privés non réagréés en 2026-2027** — USTT, Institut Polytechnique DEFITECH,
  ESAS, HECM, École Supérieure Baptiste de Théologie, Hôtel École La Savoureuse,
  HIUI. Ces deux derniers figuraient sur la liste 2025-2026 et ont été importés
  à ce titre avant que la liste 2026-2027 ne soit disponible.

### Filtre effectif côté API et app

Le millésime n'est écrit qu'à un endroit, `Settings.SCHOOLS_ACCREDITATION_LABEL`,
et le comportement par défaut dans `Settings.SCHOOLS_ACCREDITED_ONLY` (à `True`).
Les deux sont surchargeables par variable d'environnement, sans redéploiement de
code.

| Appel | Résultat |
|---|---|
| `GET /api/v1/schools` | 118 — agréées uniquement (défaut de configuration) |
| `GET /api/v1/schools?accredited_only=true` | 118 |
| `GET /api/v1/schools?accredited_only=false` | 133 — aucune restriction |
| `GET /api/v1/search?q=…` | même périmètre que l'annuaire |

`accredited_only=false` signifie « ne pas restreindre », pas « uniquement les
non agréées » : sans cela, aucun appelant ne pourrait obtenir la liste complète.
La clé de cache intègre la valeur *effective* du filtre, sinon un changement de
configuration servirait des résultats périmés pendant tout le TTL.

Le détail d'une école (`GET /api/v1/schools/{id}`) reste accessible sans
restriction : un lien profond vers un établissement non agréé ne doit pas
renvoyer 404. Le badge `accreditations` déjà affiché dans la fiche permet à
l'élève de voir le millésime.

Côté Flutter, `SchoolRepository.getSchools(accreditedOnly: …)` expose le
paramètre ; laissé à `null`, le backend tranche.

### Verrou RLS à connaître

La policy `schools_public_read` (migration 007) expose
`is_active = true AND is_verified = true`. Les 38 fiches importées portaient
`is_verified = false` et étaient donc **invisibles de l'API publique**, agrément
ou non : le filtre n'aurait montré que 82 des 118 agréées.

`tag_accreditation_mesr.py --publier` passe `is_verified = true` sur les fiches
portant le millésime — figurer sur la liste du ministère est précisément ce qui
les vérifie. Appliqué aux 36 fiches concernées. Les deux fiches non agréées
importées (Hôtel École La Savoureuse, HIUI) restent non vérifiées, donc
invisibles.

Le script est à relancer avec une nouvelle référence à chaque rentrée.

### Correction

Le rapport indiquait plus haut que 14 noms du fichier Excel étaient fabriqués.
L'un d'eux, « Institut de Formation aux Métiers de l'Industrie (IFMI) »,
correspond vraisemblablement au **Centre de Formation aux Métiers de
l'Industrie (CFMI)**, n° 12 des établissements publics. Les 13 autres restent
absents des listes 2025-2026 et 2026-2027.

## Sources

- [Liste officielle MESR 2025-2026 (communiqué, PDF)](https://www.republicoftogo.com/content/download/117683/3019996/1)
- [MESR — liste des établissements](https://edusup.gouv.tg/liste-des-etablissements)
- [Togo First — 98 établissements privés reconnus pour 2026-2027](https://www.togofirst.com/fr/education/2707-19686-togo-98-etablissements-prives-denseignement-superieur-reconnus-par-letat-pour-lannee-academique-2026-2027)
- [Campus Togo — liste des établissements agréés](https://www.campus-togo.com/2025/01/17/togo-enseignement-superieur-voici-la-liste-des-etablissements-et-universites-privees-agrees-par-le-ministere-de-lenseigneur-superieur-et-de-la-recherche/)
- [Afreepress — les 111 établissements accrédités 2026-2027](https://afreepress.net/enseignement-superieur-au-togo-voici-les-111-etablissements-desormais-accredites-pour-2026-2027/) (liste officielle en 4 images, transcrite dans `reference_mesr_2026_2027.csv`)
