"""
SafetyFilter — Détection des tentatives d'injection et des contenus hors-domaine.

Vérifie les messages utilisateurs avant de les envoyer au LLM pour détecter :
- Les injections de prompt (tentatives de modifier les instructions d'AÏDA)
- Les tentatives de sortie du domaine éducatif via des formulations spéciales
"""

import re
import logging

logger = logging.getLogger(__name__)

# Patterns d'injection de prompt courants
_INJECTION_PATTERNS = [
    r"ignore\s+(all\s+)?(previous|prior|above)\s+instructions?",
    r"forget\s+(all\s+)?instructions?",
    r"you\s+are\s+now\s+",
    r"act\s+as\s+(if\s+you\s+are\s+)?",
    r"new\s+(system\s+)?prompt\s*:",
    r"system\s*:\s*you",
    r"<\s*system\s*>",
    r"\[system\]",
    r"disregard\s+your",
    r"override\s+your",
    r"jailbreak",
    r"dan\s+mode",
    r"developer\s+mode",
]

_INJECTION_RE = re.compile(
    "|".join(_INJECTION_PATTERNS),
    re.IGNORECASE | re.DOTALL,
)


class SafetyFilter:
    """Filtre de sécurité pour les messages utilisateurs."""

    def is_injection_attempt(self, message: str) -> bool:
        """
        Détecte si le message contient une tentative d'injection de prompt.

        Returns:
            True si une tentative d'injection est détectée.
        """
        if _INJECTION_RE.search(message):
            logger.warning(
                "Injection de prompt détectée (tronqué): %.100s",
                message,
            )
            return True
        return False

    def sanitize(self, message: str) -> str:
        """
        Retourne le message nettoyé (troncature à 2000 chars, strip).
        Ne modifie pas le contenu — juste la longueur et les espaces.
        """
        return message.strip()[:2000]

    def get_rejection_message(self) -> str:
        """Message de rejet pour les tentatives d'injection."""
        return (
            "Je suis AÏDA, votre conseillère d'orientation. "
            "Je ne peux pas traiter cette requête. "
            "Avez-vous une question sur vos études ou votre orientation ?"
        )
