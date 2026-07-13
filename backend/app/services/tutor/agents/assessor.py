"""AssessorAgent — génération de quiz à la volée via le LLM.

Produit un QCM structuré (JSON) sur un sujet donné, éventuellement ancré sur
un extrait de contenu de cours. Le parsing est robuste (le LLM peut entourer
le JSON de texte ou de balises Markdown).
"""

from __future__ import annotations

import json
import re
from typing import Any, Optional

from app.core.logging import get_logger
from app.core.exceptions import ExternalServiceError
from app.services.llm.providers import LLMProvider, get_llm_provider

logger = get_logger("services.tutor.agents.assessor")

_SYSTEM_PROMPT = (
    "Tu es un générateur de quiz pédagogique pour des élèves d'Afrique de "
    "l'Ouest. Tu réponds UNIQUEMENT avec du JSON valide, sans texte autour, "
    "sans balises Markdown. Format exact attendu :\n"
    '{"questions": [{"question": "...", "options": [{"text": "...", '
    '"is_correct": true|false}], "explanation": "..."}]}\n'
    "Chaque question a exactement une bonne réponse et 3 à 4 options. "
    "Les questions sont claires, progressives, et adaptées au niveau lycée."
)


class AssessorAgent:
    """Génère des quiz QCM structurés."""

    def __init__(self, provider: Optional[LLMProvider] = None) -> None:
        self._provider = provider

    def _get_provider(self) -> LLMProvider:
        if self._provider is None:
            self._provider = get_llm_provider()
        return self._provider

    async def generate_quiz(
        self,
        topic: str,
        num_questions: int = 3,
        context: Optional[str] = None,
    ) -> dict[str, Any]:
        """Génère un quiz sur `topic`. Lève ExternalServiceError si échec."""
        num_questions = max(1, min(num_questions, 10))
        user_prompt = f"Génère {num_questions} question(s) de quiz sur : {topic}."
        if context:
            user_prompt += (
                f"\n\nAppuie-toi sur cet extrait de cours :\n{context[:3000]}"
            )

        messages = [
            {"role": "system", "content": _SYSTEM_PROMPT},
            {"role": "user", "content": user_prompt},
        ]
        raw = await self._get_provider().complete(messages)
        if not raw:
            raise ExternalServiceError(
                service="llm", message="Le générateur de quiz est indisponible."
            )
        return self._parse_quiz(raw)

    @staticmethod
    def _parse_quiz(raw: str) -> dict[str, Any]:
        """Extrait et valide le JSON du quiz depuis la sortie LLM."""
        payload = AssessorAgent._extract_json(raw)
        try:
            data = json.loads(payload)
        except (json.JSONDecodeError, TypeError) as exc:
            logger.warning("Quiz JSON invalide: %s", exc)
            raise ExternalServiceError(
                service="llm", message="Réponse du générateur de quiz illisible."
            )

        questions = data.get("questions") if isinstance(data, dict) else None
        if not isinstance(questions, list) or not questions:
            raise ExternalServiceError(
                service="llm", message="Le quiz généré ne contient aucune question."
            )

        cleaned: list[dict[str, Any]] = []
        for q in questions:
            if not isinstance(q, dict):
                continue
            text = str(q.get("question", "")).strip()
            options = q.get("options")
            if not text or not isinstance(options, list) or len(options) < 2:
                continue
            norm_options = [
                {"text": str(o.get("text", "")).strip(),
                 "is_correct": bool(o.get("is_correct", False))}
                for o in options
                if isinstance(o, dict) and str(o.get("text", "")).strip()
            ]
            # Garder les questions avec exactement une bonne réponse.
            if sum(1 for o in norm_options if o["is_correct"]) != 1:
                continue
            cleaned.append({
                "question": text,
                "options": norm_options,
                "explanation": str(q.get("explanation", "")).strip(),
            })

        if not cleaned:
            raise ExternalServiceError(
                service="llm", message="Aucune question de quiz valide générée."
            )
        return {"questions": cleaned}

    @staticmethod
    def _extract_json(raw: str) -> str:
        """Isole le bloc JSON (retire fences Markdown / texte autour)."""
        raw = raw.strip()
        fenced = re.search(r"```(?:json)?\s*(\{.*\})\s*```", raw, re.DOTALL)
        if fenced:
            return fenced.group(1)
        start = raw.find("{")
        end = raw.rfind("}")
        if start != -1 and end != -1 and end > start:
            return raw[start:end + 1]
        return raw
