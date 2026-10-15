"""Outils exposés au LLM (function-calling) + dispatcher.

Définit les schémas d'outils au format OpenAI/Groq et route les appels vers
les agents. Utilisé par le tool-calling dans le chat (llm_service), derrière
le flag TUTOR_TOOLS_ENABLED.
"""

from __future__ import annotations

import json
from typing import Any
from uuid import UUID

from app.core.logging import get_logger

logger = get_logger("services.tutor.tools")


def get_tool_schemas() -> list[dict[str, Any]]:
    """Schémas des outils disponibles pour AÏDA (format OpenAI/Groq)."""
    return [
        {
            "type": "function",
            "function": {
                "name": "generate_quiz",
                "description": (
                    "Génère un petit quiz QCM pour tester l'élève sur un sujet. "
                    "À utiliser quand l'élève veut s'entraîner ou vérifier ses acquis."
                ),
                "parameters": {
                    "type": "object",
                    "properties": {
                        "topic": {
                            "type": "string",
                            "description": "Le sujet du quiz (ex: 'les fractions').",
                        },
                        "num_questions": {
                            "type": "integer",
                            "description": "Nombre de questions (1 à 10).",
                        },
                    },
                    "required": ["topic"],
                },
            },
        },
        {
            "type": "function",
            "function": {
                "name": "recommend_next_step",
                "description": (
                    "Recommande la prochaine compétence à travailler selon la "
                    "maîtrise réelle de l'élève. À utiliser quand l'élève demande "
                    "quoi réviser ou par où continuer."
                ),
                "parameters": {"type": "object", "properties": {}},
            },
        },
    ]


async def dispatch_tool(name: str, args: dict[str, Any], user_id: UUID) -> str:
    """Exécute un outil et retourne son résultat sérialisé (JSON string).

    Ne lève jamais : une erreur d'outil est renvoyée au LLM sous forme de
    message d'erreur JSON, pour qu'il puisse rebondir plutôt que de planter
    le tour de conversation.
    """
    try:
        if name == "generate_quiz":
            from app.services.tutor.agents import AssessorAgent
            topic = str(args.get("topic", "")).strip() or "révision générale"
            # Rattache le quiz à une compétence connue si le sujet en évoque une,
            # pour que les réponses puissent alimenter le BKT.
            skill_id = None
            skill_title = None
            try:
                from app.repositories.skill_repository import get_skill_repository
                skill = await get_skill_repository().find_skill_by_text(topic)
                if skill:
                    skill_id = skill.get("id")
                    skill_title = skill.get("title")
            except Exception:
                pass
            quiz = await AssessorAgent().generate_quiz(
                topic=topic,
                num_questions=int(args.get("num_questions", 3) or 3),
                skill_id=skill_id,
                skill_title=skill_title,
            )
            return json.dumps(quiz, ensure_ascii=False)

        if name == "recommend_next_step":
            from app.services.tutor.agents import PlannerAgent
            rec = await PlannerAgent().recommend(user_id)
            return json.dumps(rec, ensure_ascii=False)

        return json.dumps({"error": f"Outil inconnu : {name}"}, ensure_ascii=False)
    except Exception as e:
        logger.warning("Outil '%s' a échoué: %s", name, e)
        return json.dumps(
            {"error": "Outil temporairement indisponible."}, ensure_ascii=False
        )
