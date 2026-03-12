"""
Service de correspondance carrières-profil utilisateur.

Extrait de submit_test pour respecter le principe de responsabilité unique.
Gère :
- L'enrichissement des résultats avec le score de correspondance
- La diversification des recommandations (anti-biais alphabétique)
- La récupération des programmes scolaires correspondants
"""

import random
import logging
from typing import Optional
from uuid import UUID

from app.schemas.orientation import CareerSummary, TestResult
from app.services.orientation_engine import orientation_engine, EN_TO_FR, CODE_TO_FR
from app.repositories.orientation_repository import OrientationRepository

logger = logging.getLogger(__name__)

# Variantes d'accentuation connues
_NO_ACCENT_TO_ACCENT = {"Realiste": "Réaliste"}

# Nombre max de carrières recommandées dans la réponse
MAX_RECOMMENDATIONS = 6
# Marge de score pour regrouper en "tier" avant diversification
TIER_MARGIN = 8


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


def _diversify_by_tier(ranked: list[CareerSummary]) -> list[CareerSummary]:
    """
    Diversifie les recommandations en mélangeant les carrières dans la même
    tranche de score (±TIER_MARGIN pts) pour éviter l'ordre alphabétique.
    """
    diversified: list[CareerSummary] = []
    i = 0
    while i < len(ranked):
        tier_score = ranked[i].match_score
        j = i
        while j < len(ranked) and (tier_score - ranked[j].match_score) <= TIER_MARGIN:
            j += 1
        tier = ranked[i:j]
        random.shuffle(tier)
        diversified.extend(tier)
        i = j
    return diversified


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
        try:
            careers = await repo.get_careers_by_traits(result.dominant_traits, limit=25)
        except Exception as e:
            logger.error("Erreur récupération carrières par traits : %s", e)
            return []

        enriched: list[CareerSummary] = []
        for c in careers:
            career_traits = c.get("related_traits") or []
            match_score = orientation_engine.calculate_match_score(
                career_traits=career_traits,
                user_dominant_traits=result.dominant_traits,
                user_scores=result.scores,
            )
            normalized_traits = [_normalize_career_trait(t) for t in career_traits]
            matching = [t for t in normalized_traits if t in result.dominant_traits]

            enriched.append(_build_career_summary(c, match_score, matching))

        enriched.sort(key=lambda r: r.match_score, reverse=True)
        return _diversify_by_tier(enriched)[:MAX_RECOMMENDATIONS]

    async def _fetch_school_programs(
        self,
        result: TestResult,
        repo: OrientationRepository,
    ) -> list:
        """Récupère les programmes scolaires correspondant aux secteurs recommandés."""
        try:
            sectors = result.interpretation.get("recommended_sectors", [])
            if not sectors:
                return []
            return await repo.get_matching_school_programs(sectors, limit=8)
        except Exception as e:
            logger.error("Erreur récupération programmes scolaires : %s", e)
            return []


career_matcher = CareerMatcherService()
