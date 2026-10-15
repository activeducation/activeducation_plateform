"""Abstraction provider LLM pour TutorAI.

Expose un contrat unique (`LLMProvider`) et une fabrique (`get_llm_provider`)
afin que le code metier (tuteur, chat) ne depende jamais d'un fournisseur
concret. Aujourd'hui : Groq (+ fallback Ollama). Demain : embeddings,
function-calling, autres modeles — sans reecrire les appelants.
"""

from app.services.llm.providers.base import (
    LLMMessage,
    LLMProvider,
    get_llm_provider,
    register_provider,
)

__all__ = [
    "LLMMessage",
    "LLMProvider",
    "get_llm_provider",
    "register_provider",
]
