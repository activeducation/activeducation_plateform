"""
Service de correspondance carrières-profil utilisateur.

Extrait de submit_test pour respecter le principe de responsabilité unique.
Gère :
- L'enrichissement des résultats avec le score de correspondance
- La diversification des recommandations (anti-biais alphabétique)
- La récupération des programmes scolaires correspondants
"""

from app.core.logging import get_logger
from app.schemas.orientation import CareerSummary, TestResult
from app.services.orientation_engine import (
    orientation_engine,
    project_to_riasec,
    EN_TO_FR,
    CODE_TO_FR,
)
from app.repositories.orientation_repository import OrientationRepository

logger = get_logger("services.career_matcher")

# Variantes d'accentuation connues
_NO_ACCENT_TO_ACCENT = {"Realiste": "Réaliste"}

# Nombre max de carrières recommandées dans la réponse
MAX_RECOMMENDATIONS = 6
# Marge de score pour regrouper en "tier" avant départage
TIER_MARGIN = 8

# Borne de sécurité sur le nombre de candidats remontés de la base.
# Ce n'est PAS une coupe de classement : on veut scorer tout le catalogue
# (~quelques dizaines de métiers) avant de trier, sinon le meilleur métier
# peut être éliminé par la base avant même d'avoir été évalué.
CANDIDATE_POOL_LIMIT = 500

# Ordre de préférence à score égal : un métier qui recrute passe devant.
_DEMAND_RANK = {"high": 3, "medium": 2, "low": 1}


def _normalize_career_trait(trait: str) -> str:
    """Normalise un trait carrière vers le français accentué."""
    return EN_TO_FR.get(trait) or CODE_TO_FR.get(trait) or _NO_ACCENT_TO_ACCENT.get(trait) or trait


def _extract_education_level(career_data: dict) -> str:
    """Extrait le niveau d'éducation minimum d'une carrière."""
    import json as _json
    edu = career_data.get("education_path")
    if isinstance(edu, str):
        try:
            edu = _json.loads(edu)
        except Exception:
            return "BAC"
    if isinstance(edu, dict):
        return edu.get("minimum_level", "BAC")
    return "BAC"


def _build_career_summary(c: dict, match_score: float, matching_traits: list[str]) -> CareerSummary:
    """Construit un objet CareerSummary à partir des données brutes de la DB."""
    return CareerSummary(
        id=c["id"],
        name=c["name"],
        description=c.get("description", ""),
        sector_name=c.get("sector_name", ""),
        job_demand=c.get("job_demand"),
        salary_avg_fcfa=c.get("salary_avg_fcfa"),
        salary_min_fcfa=c.get("salary_min_fcfa"),
        salary_max_fcfa=c.get("salary_max_fcfa"),
        image_url=c.get("image_url"),
        match_score=match_score,
        matching_traits=matching_traits,
        required_skills=(c.get("required_skills") or [])[:5],
        related_traits=c.get("related_traits") or [],
        education_minimum_level=_extract_education_level(c),
    )


def _tiebreak_key(career) -> tuple:
    """Clé de départage à score de correspondance équivalent.

    Ordre : forte demande d'emploi d'abord, puis salaire moyen, puis nom
    (stabilité). Défensif : des champs absents ou non numériques ne cassent
    pas le tri, ils retombent simplement en fin de tranche.
    """
    demand_raw = getattr(career, "job_demand", None)
    demand = _DEMAND_RANK.get(demand_raw, 0) if isinstance(demand_raw, str) else 0

    salary = getattr(career, "salary_avg_fcfa", None)
    salary = salary if isinstance(salary, (int, float)) else 0

    name = getattr(career, "name", "")
    name = name if isinstance(name, str) else ""

    return (-demand, -salary, name)


def _rank_within_tiers(ranked: list[CareerSummary]) -> list[CareerSummary]:
    """
    Départage les carrières d'une même tranche de score (±TIER_MARGIN pts)
    de façon DÉTERMINISTE : demande d'emploi, puis salaire, puis nom.

    Remplace un random.shuffle() : deux élèves au profil identique doivent
    obtenir exactement les mêmes recommandations, et l'ordre doit pouvoir
    s'expliquer ("ces métiers recrutent le plus"). Le hasard rendait le
    résultat irreproductible et injustifiable — or l'explicabilité est le
    coeur d'un outil d'orientation. L'objectif initial (ne pas retomber sur
    l'ordre alphabétique de la base) reste atteint, mais par un critère utile.
    """
    out: list[CareerSummary] = []
    i = 0
    while i < len(ranked):
        tier_score = ranked[i].match_score
        j = i
        while j < len(ranked) and (tier_score - ranked[j].match_score) <= TIER_MARGIN:
            j += 1
        out.extend(sorted(ranked[i:j], key=_tiebreak_key))
        i = j
    return out


class CareerMatcherService:
    """
    Enrichit les résultats d'orientation avec les carrières correspondantes
    et les programmes scolaires recommandés.
    """

    async def enrich_result(
        self,
        result: TestResult,
        repo: OrientationRepository,
    ) -> TestResult:
        """
        Enrichit result.recommendations avec les carrières scorées et
        result.matching_programs avec les programmes scolaires.

        Modifie result en place et le retourne.
        """
        if not result.dominant_traits:
            return result

        result.recommendations = await self._match_careers(result, repo)
        result.matching_programs = await self._fetch_school_programs(result, repo)
        return result

    async def _match_careers(
        self,
        result: TestResult,
        repo: OrientationRepository,
    ) -> list[CareerSummary]:
        """
        Récupère les carrières correspondant aux traits dominants,
        calcule leur score de correspondance et les trie.
        """
        # Les métiers ne sont indexés qu'en RIASEC (+ intelligences de Gardner),
        # alors que chaque test a son propre vocabulaire ("Leadership",
        # "Visuel"...). Sans projection, 8 tests sur 10 ne remontaient AUCUN
        # métier. On interroge et on score donc avec les traits du profil
        # ENRICHIS de leur projection RIASEC.
        projected, projected_scores = project_to_riasec(
            result.dominant_traits, result.scores
        )
        search_traits = list(dict.fromkeys([*result.dominant_traits, *projected]))
        search_scores = {**projected_scores, **result.scores}

        try:
            # On remonte TOUT le catalogue correspondant (borne de sécurité
            # seulement) : scorer d'abord, trier, puis couper. L'inverse
            # (limit=25 sans tri côté base) laissait la base décider
            # arbitrairement quels métiers seraient évalués.
            careers = await repo.get_careers_by_traits(
                search_traits, limit=CANDIDATE_POOL_LIMIT
            )
        except Exception as e:
            logger.error("Erreur récupération carrières par traits : %s", e, exc_info=True)
            return []

        if not careers:
            # Aucune correspondance possible (ex. test de maturité de projet,
            # dont les dimensions ne décrivent pas des intérêts). Mieux vaut
            # proposer les métiers les plus porteurs qu'un écran vide.
            logger.info(
                "Aucun métier pour les traits %s — repli sur les métiers porteurs",
                search_traits,
            )
            return await self._fallback_careers(repo)

        enriched: list[CareerSummary] = []
        for c in careers:
            career_traits = c.get("related_traits") or []
            match_score = orientation_engine.calculate_match_score(
                career_traits=career_traits,
                user_dominant_traits=search_traits,
                user_scores=search_scores,
            )
            normalized_traits = [_normalize_career_trait(t) for t in career_traits]
            matching = [t for t in normalized_traits if t in search_traits]

            enriched.append(_build_career_summary(c, match_score, matching))

        # Trier sur la TOTALITÉ des candidats scorés, puis seulement couper.
        enriched.sort(key=lambda r: r.match_score, reverse=True)
        return _rank_within_tiers(enriched)[:MAX_RECOMMENDATIONS]

    async def _fallback_careers(self, repo: OrientationRepository) -> list[CareerSummary]:
        """Repli : métiers les plus porteurs, quand aucun trait ne correspond.

        Le score de correspondance est laissé à 0 et matching_traits vide :
        l'app peut ainsi distinguer une vraie correspondance d'une suggestion
        de découverte, et ne pas afficher un pourcentage trompeur.
        """
        try:
            careers = await repo.get_all_careers(limit=CANDIDATE_POOL_LIMIT)
        except Exception as e:
            logger.error("Erreur récupération métiers (repli) : %s", e, exc_info=True)
            return []

        summaries = [_build_career_summary(c, 0.0, []) for c in careers]
        summaries.sort(key=_tiebreak_key)
        return summaries[:MAX_RECOMMENDATIONS]

    async def _fetch_school_programs(
        self,
        result: TestResult,
        repo: OrientationRepository,
    ) -> list:
        """Récupère les programmes scolaires pertinents pour le profil.

        Les termes de recherche combinent deux sources :
        - les secteurs éditoriaux de l'interprétation (libellés du moteur) ;
        - les secteurs et intitulés des métiers réellement recommandés, qui
          proviennent de la BASE et sont donc le vocabulaire de vérité.

        Sans les seconds, seuls les libellés codés en dur du moteur étaient
        transmis, et ils ne correspondent à aucune valeur stockée.
        """
        try:
            terms: list[str] = []
            seen: set[str] = set()

            def _add(value) -> None:
                if isinstance(value, str) and value.strip() and value not in seen:
                    seen.add(value)
                    terms.append(value)

            for sector in result.interpretation.get("recommended_sectors", []) or []:
                _add(sector)
            for career in result.recommendations or []:
                _add(getattr(career, "sector_name", None))
                _add(getattr(career, "name", None))

            if not terms:
                return []
            return await repo.get_matching_school_programs(terms, limit=8)
        except Exception as e:
            logger.error("Erreur récupération programmes scolaires : %s", e, exc_info=True)
            return []


career_matcher = CareerMatcherService()
