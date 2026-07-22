"""Moteur d'orientation multi-criteres.

Combine les tests de la plateforme (RIASEC/MBTI) avec des criteres concrets :
notes scolaires, matieres preferees, centres d'interet, budget et projet
professionnel.

Principe de conception : chaque critere produit un sous-score 0-100 **ou None**
si la donnee est absente. Les criteres absents sont EXCLUS et les poids
renormalises — un eleve qui n'a pas passe de test (ou n'a pas saisi son budget)
n'est pas penalise, il est simplement evalue sur ce qu'on sait de lui.

Moteur pur (aucun I/O) : entierement testable.
"""

from __future__ import annotations

import unicodedata
from dataclasses import dataclass
from typing import Any, Optional

from app.core.logging import get_logger
from app.services.orientation_engine import OrientationEngine

logger = get_logger("services.orientation_match")

# Mots trop courants pour porter du sens dans un rapprochement textuel.
_STOPWORDS = {
    "de", "du", "des", "le", "la", "les", "un", "une", "et", "en", "dans",
    "pour", "avec", "sur", "au", "aux", "je", "veux", "etre", "devenir",
    "metier", "travailler", "aimerais", "plus", "tres", "mon", "ma", "mes",
}


def _normalize(text: str) -> str:
    """Minuscules, sans accents, pour comparer des libelles saisis librement."""
    if not text:
        return ""
    decomposed = unicodedata.normalize("NFKD", str(text))
    without_accents = "".join(c for c in decomposed if not unicodedata.combining(c))
    return without_accents.lower().strip()


def _tokens(text: str) -> set[str]:
    """Tokens significatifs (>= 3 caracteres, hors mots vides)."""
    normalized = _normalize(text)
    raw = "".join(c if c.isalnum() else " " for c in normalized).split()
    return {t for t in raw if len(t) >= 3 and t not in _STOPWORDS}


@dataclass(frozen=True)
class MatchWeights:
    """Poids relatifs des criteres (renormalises selon les donnees presentes)."""

    riasec: float = 35.0
    academic: float = 25.0
    interests: float = 20.0
    project: float = 10.0
    budget: float = 10.0

    @classmethod
    def from_settings(cls) -> "MatchWeights":
        from app.core.config import settings
        return cls(
            riasec=settings.ORIENTATION_WEIGHT_RIASEC,
            academic=settings.ORIENTATION_WEIGHT_ACADEMIC,
            interests=settings.ORIENTATION_WEIGHT_INTERESTS,
            project=settings.ORIENTATION_WEIGHT_PROJECT,
            budget=settings.ORIENTATION_WEIGHT_BUDGET,
        )


class OrientationMatchEngine:
    """Score la pertinence d'un metier pour un eleve, tous criteres confondus."""

    def __init__(self, weights: Optional[MatchWeights] = None) -> None:
        self._weights = weights

    def _get_weights(self) -> MatchWeights:
        if self._weights is None:
            self._weights = MatchWeights.from_settings()
        return self._weights

    # ------------------------------------------------------------------
    # Sous-scores (chacun retourne (score|None, raison|None))
    # ------------------------------------------------------------------

    @staticmethod
    def _score_riasec(
        career: dict[str, Any],
        riasec: Optional[dict[str, Any]],
    ) -> tuple[Optional[float], Optional[str]]:
        """Correspondance avec le profil RIASEC issu des tests."""
        if not riasec:
            return None, None
        dominant = riasec.get("dominant_traits") or []
        scores = riasec.get("scores") or {}
        codes = career.get("riasec_codes") or []
        if not dominant or not codes:
            return None, None
        value = OrientationEngine.calculate_match_score(codes, dominant, scores)
        reason = None
        if value >= 60:
            reason = f"Correspond à votre profil {'-'.join(dominant[:2])}"
        return value, reason

    @staticmethod
    def _score_academic(
        career: dict[str, Any],
        grades: dict[str, Any],
    ) -> tuple[Optional[float], Optional[str]]:
        """Moyenne de l'eleve dans les matieres cles du metier (notes /20)."""
        key_subjects = career.get("key_subjects") or []
        if not key_subjects or not grades:
            return None, None

        normalized_grades = {_normalize(k): v for k, v in grades.items()}
        matched: list[tuple[str, float]] = []
        for subject in key_subjects:
            value = normalized_grades.get(_normalize(subject))
            if value is None:
                continue
            try:
                matched.append((subject, float(value)))
            except (TypeError, ValueError):
                continue

        if not matched:
            return None, None

        average = sum(v for _, v in matched) / len(matched)
        score = max(0.0, min(100.0, (average / 20.0) * 100.0))
        names = ", ".join(s for s, _ in matched[:3])
        if score >= 70:
            reason = f"Vos notes en {names} soutiennent ce choix"
        elif score < 45:
            reason = f"Vos notes en {names} sont un point de vigilance"
        else:
            reason = None
        return round(score, 1), reason

    @staticmethod
    def _career_text(career: dict[str, Any]) -> set[str]:
        parts = [
            career.get("name") or "",
            career.get("sector_name") or "",
            career.get("description") or "",
            " ".join(career.get("key_subjects") or []),
        ]
        return _tokens(" ".join(parts))

    @classmethod
    def _score_interests(
        cls,
        career: dict[str, Any],
        interests: list[str],
        favorite_subjects: list[str],
    ) -> tuple[Optional[float], Optional[str]]:
        """Recouvrement entre centres d'interet / matieres preferees et le metier."""
        items = [i for i in (list(interests or []) + list(favorite_subjects or [])) if i]
        if not items:
            return None, None

        career_tokens = cls._career_text(career)
        if not career_tokens:
            return None, None

        matched_items = [item for item in items if _tokens(item) & career_tokens]
        score = (len(matched_items) / len(items)) * 100.0
        reason = None
        if matched_items:
            reason = f"En lien avec vos centres d'intérêt : {', '.join(matched_items[:2])}"
        return round(min(score, 100.0), 1), reason

    @classmethod
    def _score_project(
        cls,
        career: dict[str, Any],
        career_project: Optional[str],
    ) -> tuple[Optional[float], Optional[str]]:
        """Alignement avec le projet professionnel exprime par l'eleve."""
        if not career_project or not career_project.strip():
            return None, None

        project_tokens = _tokens(career_project)
        if not project_tokens:
            return None, None

        career_name = _normalize(career.get("name") or "")
        # Mention explicite du metier dans le projet -> alignement maximal.
        if career_name and career_name in _normalize(career_project):
            return 100.0, "Correspond directement à votre projet professionnel"

        career_tokens = cls._career_text(career)
        matched = project_tokens & career_tokens
        if not matched:
            return 0.0, None
        score = min(100.0, (len(matched) / len(project_tokens)) * 100.0)
        reason = "Cohérent avec votre projet professionnel" if score >= 40 else None
        return round(score, 1), reason

    @staticmethod
    def _score_budget(
        programs: Optional[list[dict[str, Any]]],
        budget: Optional[int],
    ) -> tuple[Optional[float], Optional[str]]:
        """Faisabilite financiere : formation la moins chere vs budget annuel."""
        if not budget or budget <= 0 or not programs:
            return None, None

        tuitions = [
            p.get("tuition_annual_fcfa")
            for p in programs
            if p.get("tuition_annual_fcfa") is not None
        ]
        if not tuitions:
            return None, None

        cheapest = min(int(t) for t in tuitions)
        if cheapest <= budget:
            return 100.0, f"Accessible dès {cheapest:,} FCFA/an, dans votre budget".replace(",", " ")
        if cheapest <= budget * 1.25:
            return 60.0, "Légèrement au-dessus de votre budget"
        if cheapest <= budget * 1.5:
            return 30.0, "Nettement au-dessus de votre budget"
        return 0.0, "Hors de votre budget actuel"

    # ------------------------------------------------------------------
    # API publique
    # ------------------------------------------------------------------

    def score_career(
        self,
        profile: dict[str, Any],
        career: dict[str, Any],
        riasec: Optional[dict[str, Any]] = None,
        programs: Optional[list[dict[str, Any]]] = None,
    ) -> dict[str, Any]:
        """Score global 0-100 d'un metier pour un eleve, avec le detail par critere.

        Les criteres sans donnee sont exclus et les poids renormalises.
        """
        w = self._get_weights()

        riasec_score, riasec_reason = self._score_riasec(career, riasec)
        academic_score, academic_reason = self._score_academic(
            career, profile.get("grades") or {}
        )
        interests_score, interests_reason = self._score_interests(
            career,
            profile.get("interests") or [],
            profile.get("favorite_subjects") or [],
        )
        project_score, project_reason = self._score_project(
            career, profile.get("career_project")
        )
        budget_score, budget_reason = self._score_budget(
            programs, profile.get("budget_annual_fcfa")
        )

        factors = [
            ("riasec", riasec_score, w.riasec, riasec_reason),
            ("academic", academic_score, w.academic, academic_reason),
            ("interests", interests_score, w.interests, interests_reason),
            ("project", project_score, w.project, project_reason),
            ("budget", budget_score, w.budget, budget_reason),
        ]

        available = [(n, s, weight, r) for n, s, weight, r in factors if s is not None]
        breakdown = {n: s for n, s, _, _ in factors}

        if not available:
            return {
                "career_id": career.get("id"),
                "career_name": career.get("name"),
                "score": 0.0,
                "breakdown": breakdown,
                "reasons": [],
                "factors_used": 0,
            }

        total_weight = sum(weight for _, _, weight, _ in available) or 1.0
        weighted = sum(s * weight for _, s, weight, _ in available) / total_weight

        reasons = [r for _, _, _, r in available if r]

        return {
            "career_id": career.get("id"),
            "career_name": career.get("name"),
            "score": round(min(max(weighted, 0.0), 100.0), 1),
            "breakdown": breakdown,
            "reasons": reasons,
            "factors_used": len(available),
        }

    def rank_careers(
        self,
        profile: dict[str, Any],
        careers: list[dict[str, Any]],
        riasec: Optional[dict[str, Any]] = None,
        programs_by_career: Optional[dict[str, list[dict[str, Any]]]] = None,
        limit: int = 10,
    ) -> list[dict[str, Any]]:
        """Classe les metiers du plus au moins pertinent pour l'eleve."""
        programs_by_career = programs_by_career or {}
        results = [
            self.score_career(
                profile,
                career,
                riasec=riasec,
                programs=programs_by_career.get(str(career.get("id"))),
            )
            for career in careers
        ]
        results.sort(key=lambda r: r["score"], reverse=True)
        return results[:limit]


orientation_match_engine = OrientationMatchEngine()
