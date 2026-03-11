"""
Moteur de calcul pour les tests d'orientation.

Gere:
- Calcul des scores RIASEC (en francais)
- Calcul des scores de personnalite (MBTI)
- Generation d'interpretation structuree
- Calcul du score de correspondance carrieres
"""

from app.schemas.orientation import TestResult, TestType
import logging
from collections import defaultdict
from uuid import UUID

logger = logging.getLogger(__name__)
DEFAULT_TEST_ID = UUID("00000000-0000-0000-0000-000000000000")

# ============================================================================
# RIASEC : Labels et descriptions en francais
# ============================================================================

RIASEC_FR = {
    "Réaliste": {
        "code": "R",
        "en": "Realistic",
        "description": "Vous êtes pragmatique et aimez les défis concrets, techniques et physiques.",
        "forces": [
            "Habileté technique et manuelle",
            "Sens pratique et efficacité",
            "Endurance et persévérance",
            "Fiabilité dans l'exécution",
        ],
        "secteurs": [
            "Génie Civil & BTP",
            "Mécanique & Électrotechnique",
            "Agriculture & Agroalimentaire",
            "Topographie & Géomatique",
            "Maintenance & Logistique Industrielle",
        ],
    },
    "Investigateur": {
        "code": "I",
        "en": "Investigative",
        "description": "Vous êtes analytique, curieux intellectuellement et passionné par la résolution de problèmes complexes.",
        "forces": [
            "Esprit analytique et critique",
            "Curiosité intellectuelle",
            "Rigueur scientifique",
            "Capacité d'abstraction et de modélisation",
        ],
        "secteurs": [
            "Informatique & Cybersécurité",
            "Biologie & Pharmacie",
            "Mathématiques & Data Science",
            "Physique & Énergies Renouvelables",
            "Médecine & Recherche Clinique",
        ],
    },
    "Artistique": {
        "code": "A",
        "en": "Artistic",
        "description": "Vous êtes créatif, expressif et attiré par l'innovation, l'esthétique et la communication.",
        "forces": [
            "Créativité et imagination",
            "Sensibilité esthétique",
            "Originalité et innovation",
            "Expression et communication visuelle",
        ],
        "secteurs": [
            "Design Graphique & Communication Visuelle",
            "Architecture & Décoration d'Intérieur",
            "Journalisme & Médias Numériques",
            "Cinéma, Arts & Culture",
            "Marketing Créatif & UX Design",
        ],
    },
    "Social": {
        "code": "S",
        "en": "Social",
        "description": "Vous êtes empathique, aimez aider les autres et êtes motivé par le service aux personnes.",
        "forces": [
            "Empathie et écoute active",
            "Communication interpersonnelle",
            "Travail en équipe et collaboration",
            "Pédagogie et accompagnement",
        ],
        "secteurs": [
            "Sciences Infirmières & Santé Communautaire",
            "Enseignement & Sciences de l'Éducation",
            "Psychologie & Travail Social",
            "Ressources Humaines & Coaching",
            "Développement Communautaire & ONG",
        ],
    },
    "Entrepreneur": {
        "code": "E",
        "en": "Enterprising",
        "description": "Vous êtes ambitieux, leadership naturel et motivé par la prise de décision et les défis commerciaux.",
        "forces": [
            "Leadership et charisme",
            "Prise d'initiative et audace",
            "Négociation et persuasion",
            "Vision stratégique",
        ],
        "secteurs": [
            "Commerce & Gestion d'Entreprise",
            "Finance & Banque",
            "Marketing & Vente",
            "Droit des Affaires & Entrepreneuriat",
            "Management & Direction de Projets",
        ],
    },
    "Conventionnel": {
        "code": "C",
        "en": "Conventional",
        "description": "Vous êtes organisé, méthodique et à l'aise avec la précision, les procédures et l'ordre.",
        "forces": [
            "Organisation et rigueur",
            "Précision et souci du détail",
            "Fiabilité et constance",
            "Maîtrise des procédures et réglementations",
        ],
        "secteurs": [
            "Comptabilité, Audit & Contrôle de Gestion",
            "Administration Publique & Fiscalité",
            "Gestion des Systèmes d'Information",
            "Statistiques & Actuariat",
            "Secrétariat & Office Management",
        ],
    },
}

# Mapping inverse anglais -> francais
EN_TO_FR = {v["en"]: k for k, v in RIASEC_FR.items()}
CODE_TO_FR = {v["code"]: k for k, v in RIASEC_FR.items()}

# MBTI descriptions en francais
MBTI_FR = {
    "Extraversion": {"fr": "Extraversion", "desc": "Vous puisez votre énergie dans les interactions sociales."},
    "Introversion": {"fr": "Introversion", "desc": "Vous puisez votre énergie dans la réflexion intérieure."},
    "Sensing": {"fr": "Sensation", "desc": "Vous vous fiez aux faits concrets et à l'expérience."},
    "Intuition": {"fr": "Intuition", "desc": "Vous vous fiez aux possibilités et aux idées abstraites."},
    "Thinking": {"fr": "Pensée", "desc": "Vous prenez vos décisions de manière logique et objective."},
    "Feeling": {"fr": "Sentiment", "desc": "Vous prenez vos décisions en tenant compte des valeurs et des personnes."},
    "Judging": {"fr": "Jugement", "desc": "Vous préférez la planification et l'organisation."},
    "Perceiving": {"fr": "Perception", "desc": "Vous préférez la flexibilité et la spontanéité."},
}


class OrientationEngine:
    async def calculate_result(self, test_type: TestType, responses: dict, test_data: dict = None) -> TestResult:
        """
        Calcule les resultats et genere une interpretation structuree.
        """
        try:
            question_categories = {}
            if test_data and "questions" in test_data:
                for q in test_data["questions"]:
                    q_id = str(q.get("id")) if isinstance(q, dict) else str(q.id)
                    cat = q.get("category") if isinstance(q, dict) else q.category
                    question_categories[q_id] = cat

            if test_type == TestType.RIASEC:
                return self._calculate_riasec(responses, question_categories)
            elif test_type == TestType.PERSONALITY:
                return self._calculate_personality(responses, question_categories)
            elif test_type in [TestType.SKILLS, TestType.INTERESTS, TestType.APTITUDE]:
                return self._calculate_generic(responses, question_categories)
            else:
                logger.warning(f"Unknown test type {test_type}, using generic calculation")
                return self._calculate_generic(responses, question_categories)
        except Exception as e:
            logger.error(f"Error calculating result for {test_type}: {e}")
            return TestResult(
                test_id=DEFAULT_TEST_ID,
                scores={},
                dominant_traits=["Erreur de calcul"],
                recommendations=[],
                interpretation={},
            )

    def _calculate_riasec(self, responses: dict, question_categories: dict) -> TestResult:
        """Calcule les scores RIASEC avec labels francais et interpretation."""
        # Accumuler les scores bruts par categorie
        raw_scores = defaultdict(int)
        counts = defaultdict(int)

        map_codes = {
            'R': 'Réaliste', 'I': 'Investigateur', 'A': 'Artistique',
            'S': 'Social', 'E': 'Entrepreneur', 'C': 'Conventionnel',
        }
        # Also handle full English names
        en_map = {v["en"]: k for k, v in RIASEC_FR.items()}

        for q_id, value in responses.items():
            category = question_categories.get(str(q_id))

            if not category and '_' in str(q_id):
                category = str(q_id).split('_')[0]

            score_val = self._parse_score(value)

            if category:
                # Normalize to French label
                fr_cat = map_codes.get(category, en_map.get(category, category))
                raw_scores[fr_cat] += score_val
                counts[fr_cat] += 1

        # Normaliser les scores en pourcentage (0-100)
        # Chaque question a un score max de 5 (echelle Likert typique)
        scores = {}
        for trait_fr in RIASEC_FR:
            if counts[trait_fr] > 0:
                max_possible = counts[trait_fr] * 5
                scores[trait_fr] = round((raw_scores[trait_fr] / max_possible) * 100, 1)
            else:
                scores[trait_fr] = 0.0

        # Trier les traits par score
        sorted_traits = sorted(scores.items(), key=lambda x: x[1], reverse=True)
        dominant_traits = [t[0] for t in sorted_traits[:3] if t[1] > 0]

        # Generer l'interpretation
        interpretation = self._generate_riasec_interpretation(scores, dominant_traits)

        return TestResult(
            test_id=DEFAULT_TEST_ID,
            scores=scores,
            dominant_traits=dominant_traits,
            recommendations=[],
            interpretation=interpretation,
        )

    def _generate_riasec_interpretation(self, scores: dict, dominant_traits: list[str]) -> dict:
        """Genere une interpretation structuree du profil RIASEC."""
        if not dominant_traits:
            return {
                "profile_summary": "Aucun profil dominant dégagé. Prenez le temps de répondre à chaque question.",
                "strengths": [],
                "advice": "Réfléchissez à ce qui vous motive réellement dans votre quotidien.",
                "recommended_sectors": [],
            }

        primary = dominant_traits[0]
        primary_data = RIASEC_FR.get(primary, {})
        secondary = dominant_traits[1] if len(dominant_traits) > 1 else None
        secondary_data = RIASEC_FR.get(secondary, {}) if secondary else {}
        tertiary = dominant_traits[2] if len(dominant_traits) > 2 else None
        tertiary_data = RIASEC_FR.get(tertiary, {}) if tertiary else {}

        # Code et résumé court
        profile_code = "".join([RIASEC_FR.get(t, {}).get("code", "?") for t in dominant_traits])
        summary = f"Profil **{profile_code}** — {primary_data.get('description', '')}"
        if secondary:
            summary += f" Votre dimension **{secondary}** apporte une complémentarité précieuse."

        # Forces : top 3 du trait principal + 1-2 du trait secondaire
        strengths = list(primary_data.get("forces", []))[:3]
        if secondary_data:
            for s in secondary_data.get("forces", [])[:2]:
                if s not in strengths:
                    strengths.append(s)

        # Conseils personnalisés
        advice = self._generate_personalized_advice(dominant_traits, scores)

        # Secteurs pondérés par les scores des 3 traits dominants
        # Chaque trait contribue ses secteurs proportionnellement à son score
        trait_weights = [(primary, scores.get(primary, 0))]
        if secondary:
            trait_weights.append((secondary, scores.get(secondary, 0)))
        if tertiary:
            trait_weights.append((tertiary, scores.get(tertiary, 0)))

        total_weight = sum(w for _, w in trait_weights) or 1
        sectors: list[str] = []
        seen: set[str] = set()

        for trait, weight in trait_weights:
            # Nombre de secteurs proportionnel au score (min 1, max 3)
            n = max(1, round((weight / total_weight) * 5))
            for s in RIASEC_FR.get(trait, {}).get("secteurs", [])[:n]:
                if s not in seen:
                    sectors.append(s)
                    seen.add(s)

        # Compléter jusqu'à 6 si nécessaire avec les secteurs restants
        for trait, _ in trait_weights:
            if len(sectors) >= 6:
                break
            for s in RIASEC_FR.get(trait, {}).get("secteurs", []):
                if s not in seen:
                    sectors.append(s)
                    seen.add(s)

        return {
            "profile_summary": summary,
            "profile_code": profile_code,
            "strengths": strengths,
            "advice": advice,
            "recommended_sectors": sectors[:6],
        }

    def _generate_personalized_advice(self, dominant_traits: list[str], scores: dict) -> str:
        """Genere des conseils personnalises selon le profil."""
        primary = dominant_traits[0] if dominant_traits else ""
        top_score = scores.get(primary, 0)

        advice_parts = []

        # Conseil base sur la clarte du profil
        if top_score >= 80:
            advice_parts.append(
                "Votre profil est très marqué, ce qui est un atout pour cibler précisément votre orientation."
            )
        elif top_score >= 60:
            advice_parts.append(
                "Votre profil montre des tendances claires qui peuvent guider efficacement vos choix d'orientation."
            )
        else:
            advice_parts.append(
                "Votre profil est équilibré, ce qui vous donne de la flexibilité dans vos choix. "
                "Explorez plusieurs pistes avant de vous décider."
            )

        # Conseils specifiques par profil dominant
        specific_advice = {
            "Réaliste": "Privilégiez les formations pratiques (BTS, DUT, alternance). "
                       "Les filières Génie Civil, Mécanique et Agroalimentaire recrutent bien au Togo.",
            "Investigateur": "Visez les études longues (Licence, Master, Doctorat). "
                            "L'Informatique, la Data Science et les Sciences biologiques sont en forte croissance en Afrique de l'Ouest.",
            "Artistique": "Construisez un portfolio solide dès maintenant. "
                         "Le Design, le Marketing digital et l'UX ouvrent de nouvelles carrières au Togo et en Afrique.",
            "Social": "Recherchez des stages en milieu hospitalier, éducatif ou associatif pour confirmer votre vocation. "
                     "Les filières Santé Communautaire et Sciences de l'Éducation offrent de nombreux débouchés.",
            "Entrepreneur": "Rejoignez des programmes d'incubation (Woelab, CUBE) et formez-vous en gestion. "
                           "Le Droit des Affaires et le Management sont des atouts pour créer ou diriger une entreprise.",
            "Conventionnel": "Visez les certifications reconnues (comptabilité SYSCOHADA, fiscalité). "
                            "La Comptabilité, l'Audit et l'Administration Publique offrent une forte employabilité au Togo.",
        }
        if primary in specific_advice:
            advice_parts.append(specific_advice[primary])

        return " ".join(advice_parts)

    def _calculate_personality(self, responses: dict, question_categories: dict) -> TestResult:
        """Calcul de personnalite (MBTI) avec labels francais."""
        mbti_dimensions = {
            "E-I": ("Extraversion", "Introversion"),
            "S-N": ("Sensing", "Intuition"),
            "T-F": ("Thinking", "Feeling"),
            "J-P": ("Judging", "Perceiving"),
        }

        pair_totals = defaultdict(int)
        pair_counts = defaultdict(int)

        for q_id, value in responses.items():
            category = question_categories.get(str(q_id))
            if category not in mbti_dimensions:
                continue
            pair_totals[category] += self._parse_score(value)
            pair_counts[category] += 1

        if pair_counts:
            scores = {}
            dominant_traits = []

            for pair, (left_trait, right_trait) in mbti_dimensions.items():
                count = pair_counts.get(pair, 0)
                if count == 0:
                    continue

                avg = pair_totals[pair] / count
                left_score = round(((avg - 1) / 4) * 100, 1)
                right_score = round(100 - left_score, 1)

                # Use French labels
                left_fr = MBTI_FR.get(left_trait, {}).get("fr", left_trait)
                right_fr = MBTI_FR.get(right_trait, {}).get("fr", right_trait)

                scores[left_fr] = left_score
                scores[right_fr] = right_score
                dominant_traits.append(
                    left_fr if left_score >= right_score else right_fr
                )

            # Generate MBTI interpretation
            interpretation = self._generate_personality_interpretation(scores, dominant_traits)

            return TestResult(
                test_id=DEFAULT_TEST_ID,
                scores=scores,
                dominant_traits=dominant_traits,
                recommendations=[],
                interpretation=interpretation,
            )

        return self._calculate_generic(responses, question_categories)

    def _generate_personality_interpretation(self, scores: dict, dominant_traits: list[str]) -> dict:
        """Genere une interpretation pour le test de personnalite."""
        descriptions = []
        for trait in dominant_traits:
            for en_name, data in MBTI_FR.items():
                if data["fr"] == trait:
                    descriptions.append(data["desc"])
                    break

        summary = f"Type **{' / '.join(dominant_traits)}** — " + " ".join(descriptions[:2])

        return {
            "profile_summary": summary,
            "strengths": dominant_traits[:3],
            "advice": "Cherchez des environnements de travail alignés avec votre personnalité pour vous épanouir.",
            "recommended_sectors": [],
        }

    def _calculate_generic(self, responses: dict, question_categories: dict) -> TestResult:
        """Calcul generique pour les autres types de tests."""
        scores = defaultdict(int)
        counts = defaultdict(int)

        for q_id, value in responses.items():
            category = question_categories.get(str(q_id)) or "Général"
            scores[category] += self._parse_score(value)
            counts[category] += 1

        # Normaliser en pourcentage
        final_scores = {}
        for cat, raw in scores.items():
            max_possible = counts[cat] * 5
            final_scores[cat] = round((raw / max_possible) * 100, 1) if max_possible > 0 else 0

        sorted_traits = sorted(final_scores.items(), key=lambda x: x[1], reverse=True)
        dominant_traits = [t[0] for t in sorted_traits[:3] if t[1] > 0]

        return TestResult(
            test_id=DEFAULT_TEST_ID,
            scores=final_scores,
            dominant_traits=dominant_traits,
            recommendations=[],
            interpretation={
                "profile_summary": f"Vos domaines de force principaux sont : {', '.join(dominant_traits)}.",
                "strengths": dominant_traits,
                "work_style": "",
                "advice": "Explorez les métiers liés à vos points forts pour trouver votre voie.",
                "recommended_sectors": [],
            },
        )

    def _parse_score(self, value) -> int:
        try:
            return int(value)
        except (ValueError, TypeError):
            return 1

    @staticmethod
    def calculate_match_score(career_traits: list[str], user_dominant_traits: list[str], user_scores: dict) -> float:
        """
        Calcule un score de correspondance (0-100) entre un profil utilisateur et une carriere.

        Prend en compte:
        1. Le nombre de traits en commun (poids principal)
        2. Le score de l'utilisateur dans les traits correspondants (poids secondaire)
        """
        if not career_traits or not user_dominant_traits:
            return 0.0

        # Variantes sans accent -> avec accent
        no_accent_to_accent = {"Realiste": "Réaliste"}

        # Normaliser les traits de la carriere vers le francais accentue
        normalized_career = []
        for t in career_traits:
            fr = EN_TO_FR.get(t) or CODE_TO_FR.get(t) or no_accent_to_accent.get(t) or t
            normalized_career.append(fr)

        # Calculer les traits en commun
        common_traits = set(normalized_career) & set(user_dominant_traits)
        if not common_traits:
            # Check for partial match (career traits that are in user's full score list)
            all_user_traits = set(user_scores.keys())
            partial = set(normalized_career) & all_user_traits
            if partial:
                # Partial match: average of the matching trait scores, scaled down
                avg_score = sum(user_scores.get(t, 0) for t in partial) / len(partial)
                return round(avg_score * 0.5, 1)  # 50% weight for non-dominant matches
            return 0.0

        # Score base sur le nombre de traits dominants en commun
        overlap_ratio = len(common_traits) / max(len(user_dominant_traits), 1)

        # Score moyen de l'utilisateur dans les traits communs
        avg_user_score = sum(user_scores.get(t, 0) for t in common_traits) / len(common_traits)

        # Score final: 60% overlap ratio + 40% average score in matching traits
        match_score = (overlap_ratio * 60) + (avg_user_score / 100 * 40)

        return round(min(match_score, 100), 1)


orientation_engine = OrientationEngine()
