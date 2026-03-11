"""
Données de tests d'orientation locales (fallback quand Supabase est indisponible).
Contient les données de seed des fichiers database/schema.sql et database/seed_tests.sql.
"""
import uuid as _uuid


def _qid(test_id: str, idx: int) -> str:
    return str(_uuid.uuid5(_uuid.UUID(test_id), f"q{idx}"))


def _oid(qid: str, val: int) -> str:
    return str(_uuid.uuid5(_uuid.UUID(qid), f"o{val}"))


def _likert_options(qid: str, labels: list[str]) -> list[dict]:
    return [
        {"id": _oid(qid, i + 1), "option_text": lbl, "option_value": i + 1, "display_order": i + 1}
        for i, lbl in enumerate(labels)
    ]


def _build_test(
    test_id: str,
    name: str,
    description: str,
    test_type: str,
    duration: int,
    order: int,
    questions_data: list[tuple[str, str]],
    opt_labels: list[str],
) -> dict:
    questions = []
    for idx, (text, category) in enumerate(questions_data, 1):
        qid = _qid(test_id, idx)
        questions.append({
            "id": qid,
            "test_id": test_id,
            "question_text": text,
            "question_type": "likert",
            "category": category,
            "display_order": idx,
            "is_required": True,
            "options": _likert_options(qid, opt_labels),
        })
    return {
        "id": test_id,
        "name": name,
        "description": description,
        "type": test_type,
        "duration_minutes": duration,
        "display_order": order,
        "is_active": True,
        "image_url": None,
        "questions": questions,
    }


_RIASEC_OPTS = ["Pas du tout", "Un peu", "Moyennement", "Beaucoup", "Passionnement"]
_AGREE_OPTS = [
    "Pas du tout d'accord",
    "Peu d'accord",
    "Moyennement d'accord",
    "D'accord",
    "Tout a fait d'accord",
]

# =============================================================================
# TEST 1 : RIASEC
# =============================================================================
_RIASEC_QUESTIONS = [
    ("J'aime reparer des appareils electriques ou mecaniques.", "Realistic"),
    ("Je prefere travailler avec des outils et des machines.", "Realistic"),
    ("J'aime construire ou fabriquer des objets de mes mains.", "Realistic"),
    ("J'aime resoudre des problemes mathematiques complexes.", "Investigative"),
    ("Je suis curieux et j'aime comprendre comment les choses fonctionnent.", "Investigative"),
    ("J'aime mener des experiences et analyser des donnees.", "Investigative"),
    ("J'aime dessiner, peindre ou faire de la musique.", "Artistic"),
    ("J'ai une imagination debordante et j'aime creer.", "Artistic"),
    ("Je prefere m'exprimer de maniere creative plutot que suivre des regles.", "Artistic"),
    ("J'aime aider les autres et leur enseigner de nouvelles choses.", "Social"),
    ("Je suis a l'aise pour parler en public ou animer des groupes.", "Social"),
    ("Je me soucie du bien-etre des autres et j'aime les conseiller.", "Social"),
    ("J'aime diriger une equipe et prendre des decisions.", "Enterprising"),
    ("Je suis motive par la reussite et les defis ambitieux.", "Enterprising"),
    ("J'aime convaincre et negocier avec les autres.", "Enterprising"),
    ("J'aime organiser des dossiers et des donnees de maniere ordonnee.", "Conventional"),
    ("Je prefere suivre des procedures etablies et claires.", "Conventional"),
    ("Je suis minutieux et attentif aux details.", "Conventional"),
]

# =============================================================================
# TEST 2 : Intelligences Multiples
# =============================================================================
_INTELLIGENCES_QUESTIONS = [
    ("J'aime lire des livres et ecrire des histoires.", "Linguistique"),
    ("Je m'exprime facilement a l'oral et a l'ecrit.", "Linguistique"),
    ("J'apprends mieux en lisant ou en ecoutant des explications.", "Linguistique"),
    ("J'aime resoudre des enigmes et des problemes logiques.", "Logico-Mathematique"),
    ("Je suis a l'aise avec les chiffres et les calculs.", "Logico-Mathematique"),
    ("Je cherche toujours a comprendre le 'pourquoi' des choses.", "Logico-Mathematique"),
    ("Je visualise facilement des objets en 3D dans ma tete.", "Spatiale"),
    ("J'ai un bon sens de l'orientation.", "Spatiale"),
    ("J'aime dessiner, creer des schemas ou des cartes.", "Spatiale"),
    ("Je retiens facilement les melodies et les rythmes.", "Musicale"),
    ("J'aime chanter, jouer d'un instrument ou ecouter de la musique.", "Musicale"),
    ("J'apprends mieux en faisant les choses moi-meme.", "Kinesthesique"),
    ("Je suis habile de mes mains et j'aime le sport.", "Kinesthesique"),
    ("Je comprends facilement les emotions des autres.", "Interpersonnelle"),
    ("J'aime travailler en equipe et aider les autres.", "Interpersonnelle"),
    ("Je me connais bien et je sais identifier mes forces et faiblesses.", "Intrapersonnelle"),
    ("J'aime reflechir seul et planifier mes objectifs.", "Intrapersonnelle"),
    ("J'aime observer et classer les elements de la nature.", "Naturaliste"),
    ("Je suis sensible a l'environnement et a la protection de la nature.", "Naturaliste"),
]

# =============================================================================
# TEST 3 : Valeurs Professionnelles
# =============================================================================
_VALEURS_QUESTIONS = [
    ("Gagner un bon salaire est tres important pour moi.", "Remuneration"),
    ("Je veux un travail qui me permette d'aider les autres.", "Altruisme"),
    ("La securite de l'emploi est prioritaire dans mon choix de carriere.", "Securite"),
    ("Je veux etre libre et autonome dans mon travail.", "Autonomie"),
    ("Je souhaite etre reconnu et respecte pour mon travail.", "Reconnaissance"),
    ("Avoir un bon equilibre vie professionnelle/vie personnelle est essentiel.", "Equilibre"),
    ("Je veux un travail creatif ou je peux innover.", "Creativite"),
    ("Diriger une equipe et avoir du pouvoir m'attire.", "Leadership"),
    ("Je veux un metier qui a un impact positif sur la societe.", "Impact"),
    ("Apprendre continuellement de nouvelles choses est important pour moi.", "Apprentissage"),
]

# =============================================================================
# TEST 4 : MBTI Simplifie
# =============================================================================
_MBTI_QUESTIONS = [
    ("Dans un groupe, je suis plutot celui qui prend la parole en premier.", "E-I"),
    ("Je prefere les faits concrets aux idees abstraites.", "S-N"),
    ("Je prends mes decisions avec la logique plutot qu'avec les emotions.", "T-F"),
    ("Je prefere planifier a l'avance plutot qu'improviser.", "J-P"),
    ("Les fetes et les grands rassemblements me donnent de l'energie.", "E-I"),
    ("Je fais confiance a mon experience plutot qu'a mon intuition.", "S-N"),
    ("L'harmonie dans le groupe est plus importante que la verite.", "T-F"),
    ("J'aime avoir mes affaires bien rangees et organisees.", "J-P"),
]

# =============================================================================
# TEST 5 : Aptitudes Naturelles
# =============================================================================
_APTITUDES_QUESTIONS = [
    ("J'arrive facilement a expliquer des choses complexes aux autres.", "Communication"),
    ("Je suis bon en calcul mental et en mathematiques.", "Analytique"),
    ("Je suis a l'aise pour organiser des evenements ou des projets.", "Organisation"),
    ("J'ai une bonne memoire visuelle.", "Visuelle"),
    ("Je suis doue pour resoudre des conflits entre personnes.", "Mediation"),
    ("Je suis creatif et j'ai souvent des idees originales.", "Creativite"),
    ("Je suis patient et methodique dans mon travail.", "Methode"),
    ("Je m'adapte facilement aux nouvelles situations.", "Adaptabilite"),
    ("Je suis bon pour convaincre et negocier.", "Persuasion"),
    ("Je gere bien mon temps et mes priorites.", "Gestion du temps"),
]

# =============================================================================
# TEST 6 : Potentiel Entrepreneurial
# =============================================================================
_ENTREPRENEUR_QUESTIONS = [
    ("Je prefere creer mon propre chemin plutot que suivre celui des autres.", "Initiative"),
    ("L'echec ne me decourage pas, il me motive a essayer autrement.", "Resilience"),
    ("Je vois des opportunites business la ou les autres voient des problemes.", "Vision"),
    ("Je suis pret a prendre des risques calcules pour atteindre mes objectifs.", "Prise de risque"),
    ("J'ai deja vendu quelque chose ou eu une petite activite generant des revenus.", "Experience"),
    ("Je suis capable de motiver et entrainer les autres dans mes projets.", "Leadership"),
    ("Je gere bien mon argent et je comprends les bases de la finance.", "Finance"),
    ("Je suis passionne et pret a travailler dur pour realiser mes reves.", "Passion"),
]

# =============================================================================
# TEST 7 : Ancres de Carriere
# =============================================================================
_ANCRES_QUESTIONS = [
    ("Je veux devenir excellent dans un domaine technique precis.", "Technique"),
    ("Je prefere etre reconnu pour mon expertise plutot que pour mon poste.", "Technique"),
    ("Diriger des equipes et prendre des decisions me motive.", "Management"),
    ("Je me vois evoluer vers des responsabilites de coordination.", "Management"),
    ("Je veux garder ma liberte dans ma facon de travailler.", "Autonomie"),
    ("Je prefere les missions ou je peux choisir mes methodes.", "Autonomie"),
    ("La stabilite de l'emploi est une priorite pour moi.", "Securite"),
    ("Je privilegie les environnements professionnels previsibles.", "Securite"),
    ("Avoir un impact positif sur les autres est essentiel.", "Service"),
    ("Je veux contribuer a une mission utile a la societe.", "Service"),
    ("Je suis attire par les situations difficiles a relever.", "Defi"),
    ("Resoudre des problemes complexes m'enthousiasme.", "Defi"),
    ("Je veux un metier compatible avec ma vie personnelle.", "StyleDeVie"),
    ("L'equilibre global compte plus que le statut.", "StyleDeVie"),
    ("J'aime creer des projets a partir de zero.", "Entrepreneuriat"),
    ("Prendre des risques calcules ne me fait pas peur.", "Entrepreneuriat"),
]

# =============================================================================
# TEST 8 : Styles d'Apprentissage (VARK)
# =============================================================================
_VARK_QUESTIONS = [
    ("Je comprends mieux avec des schemas ou des graphiques.", "Visuel"),
    ("Les cartes mentales m'aident a retenir les informations.", "Visuel"),
    ("Je prefere regarder une demonstration plutot que lire un texte.", "Visuel"),
    ("J'apprends facilement quand on m'explique oralement.", "Auditif"),
    ("Discuter d'un sujet m'aide a mieux le maitriser.", "Auditif"),
    ("Je retiens bien les cours ecoutes ou en podcast.", "Auditif"),
    ("Lire des notes detaillees est mon meilleur moyen d'apprendre.", "LectureEcriture"),
    ("Ecrire des resumes m'aide a memoriser.", "LectureEcriture"),
    ("Je prefere les supports textes aux videos.", "LectureEcriture"),
    ("Je retiens mieux en pratiquant directement.", "Kinesthesique"),
    ("Les exercices concrets me font progresser rapidement.", "Kinesthesique"),
    ("Je prefere apprendre via des projets plutot que par theorie seule.", "Kinesthesique"),
]

# =============================================================================
# TEST 9 : Environnement de Travail Ideal
# =============================================================================
_ENVIRONNEMENT_QUESTIONS = [
    ("Je donne le meilleur de moi en travaillant avec une equipe.", "Collaboration"),
    ("Les projets collectifs me motivent davantage que les missions solo.", "Collaboration"),
    ("Je prefere organiser mon travail sans supervision constante.", "Autonomie"),
    ("Je suis plus efficace quand je decide seul de mes priorites.", "Autonomie"),
    ("Les regles claires et les procedures m'aident a performer.", "Structure"),
    ("Je prefere des objectifs et un cadre bien definis.", "Structure"),
    ("J'aime les environnements ou l'on teste de nouvelles idees.", "Innovation"),
    ("Je m'epanouis dans des organisations qui changent vite.", "Innovation"),
    ("Je prefere les activites de terrain aux taches de bureau.", "Terrain"),
    ("Bouger et voir des situations reelles me motive.", "Terrain"),
    ("J'aime analyser des donnees avant de prendre une decision.", "Analyse"),
    ("Les missions qui demandent de la rigueur intellectuelle me plaisent.", "Analyse"),
]

# =============================================================================
# TEST 10 : Maturite du Projet Professionnel
# =============================================================================
_MATURITE_QUESTIONS = [
    ("Je connais clairement mes points forts et mes limites.", "ConnaissanceDeSoi"),
    ("Je sais quelles activites me donnent de l'energie.", "ConnaissanceDeSoi"),
    ("Je peux expliquer ce qui compte vraiment pour moi dans un metier.", "ConnaissanceDeSoi"),
    ("J'ai explore plusieurs metiers qui m'interessent.", "ExplorationMetiers"),
    ("Je connais les formations necessaires pour les metiers que je vise.", "ExplorationMetiers"),
    ("Je me renseigne regulierement sur les perspectives d'emploi.", "ExplorationMetiers"),
    ("Je me sens capable de comparer plusieurs options de carriere.", "PriseDecision"),
    ("Je peux prioriser une voie professionnelle en fonction de criteres clairs.", "PriseDecision"),
    ("Je prends des decisions sans rester bloque trop longtemps.", "PriseDecision"),
    ("J'ai defini des etapes concretes pour atteindre mon objectif.", "PlanAction"),
    ("Je sais quelles competences je dois developper cette annee.", "PlanAction"),
    ("Je passe a l'action (stages, projets, rencontres) pour avancer.", "PlanAction"),
]

# =============================================================================
# Construction de tous les tests
# =============================================================================
FALLBACK_TESTS: list[dict] = [
    _build_test(
        "123e4567-e89b-12d3-a456-426614174000",
        "Test d'Interets Professionnels (RIASEC)",
        "Decouvrez les metiers qui correspondent le mieux a vos centres d'interet selon la theorie de Holland.",
        "riasec", 15, 1, _RIASEC_QUESTIONS, _RIASEC_OPTS,
    ),
    _build_test(
        "223e4567-e89b-12d3-a456-426614174001",
        "Test des Intelligences Multiples",
        "Identifie tes formes d'intelligence dominantes selon la theorie de Howard Gardner.",
        "personality", 12, 2, _INTELLIGENCES_QUESTIONS, _AGREE_OPTS,
    ),
    _build_test(
        "323e4567-e89b-12d3-a456-426614174002",
        "Test des Valeurs Professionnelles",
        "Decouvre ce qui te motive vraiment dans le travail.",
        "interests", 8, 3, _VALEURS_QUESTIONS, _AGREE_OPTS,
    ),
    _build_test(
        "423e4567-e89b-12d3-a456-426614174003",
        "Test de Personnalite (MBTI Simplifie)",
        "Decouvre ton type de personnalite parmi 16 profils possibles.",
        "personality", 10, 4, _MBTI_QUESTIONS, _AGREE_OPTS,
    ),
    _build_test(
        "523e4567-e89b-12d3-a456-426614174004",
        "Test d'Aptitudes Naturelles",
        "Identifie tes talents naturels et tes forces.",
        "aptitude", 10, 5, _APTITUDES_QUESTIONS, _AGREE_OPTS,
    ),
    _build_test(
        "623e4567-e89b-12d3-a456-426614174005",
        "Test de Potentiel Entrepreneurial",
        "Es-tu fait pour entreprendre ? Ce test evalue tes competences et ta mentalite entrepreneuriales.",
        "skills", 8, 6, _ENTREPRENEUR_QUESTIONS, _AGREE_OPTS,
    ),
    _build_test(
        "723e4567-e89b-12d3-a456-426614174006",
        "Test des Ancres de Carriere",
        "Identifie les motivations profondes qui orientent tes choix professionnels.",
        "interests", 12, 7, _ANCRES_QUESTIONS, _AGREE_OPTS,
    ),
    _build_test(
        "823e4567-e89b-12d3-a456-426614174007",
        "Test des Styles d'Apprentissage (VARK)",
        "Decouvre comment tu apprends le plus efficacement.",
        "aptitude", 8, 8, _VARK_QUESTIONS, _AGREE_OPTS,
    ),
    _build_test(
        "923e4567-e89b-12d3-a456-426614174008",
        "Test d'Environnement de Travail Ideal",
        "Determine les conditions de travail dans lesquelles tu performes le mieux.",
        "skills", 9, 9, _ENVIRONNEMENT_QUESTIONS, _AGREE_OPTS,
    ),
    _build_test(
        "a23e4567-e89b-12d3-a456-426614174009",
        "Test de Maturite du Projet Professionnel",
        "Mesure ton niveau de clarte sur ton avenir.",
        "interests", 10, 10, _MATURITE_QUESTIONS, _AGREE_OPTS,
    ),
]
