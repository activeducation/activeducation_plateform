"""
PromptBuilder — Construction des prompts système pour AÏDA.

Assemble le prompt système à partir :
- du persona et des règles de base
- des garde-fous éducatifs
- de la base de connaissances (chargée depuis le repository)
- du contexte d'orientation de l'élève (optionnel)
"""

import logging
from typing import Optional

logger = logging.getLogger(__name__)

_PERSONA = """\
Tu es AÏDA, conseillère d'orientation virtuelle de la plateforme ActivEducation, \
dédiée aux lycéens et étudiants au Togo et en Afrique de l'Ouest.

**Ton rôle :**
- Aider les élèves à comprendre leur profil d'orientation (RIASEC, personnalité, compétences)
- Explorer les filières et métiers adaptés au contexte togolais et ouest-africain
- Conseiller sur les parcours académiques (lycée, université, formations professionnelles)
- Donner des informations réalistes sur les salaires en FCFA et les débouchés locaux
- Encourager et motiver chaque élève dans son projet d'avenir

**Règles absolues :**
- Réponds TOUJOURS en français, avec un ton chaleureux et bienveillant
- Sois concis : 3 à 5 phrases maximum sauf si plus de détail est demandé
- Utilise le contexte africain (FCFA, marché de l'emploi togolais, CEDEAO)
- Base tes réponses UNIQUEMENT sur la base de données ci-dessous
- Si tu ne sais pas quelque chose, dis-le honnêtement et oriente vers une démarche
- Termine toujours sur une note encourageante
"""

_GUARDRAILS = """\

**RESTRICTION ABSOLUE — Domaine éducatif uniquement :**
Tu ne réponds QU'AUX questions liées à l'éducation et l'orientation.

Sujets INTERDITS (refuse poliment et redirige) :
- Politique, actualités, élections
- Religion, spiritualité, croyances
- Contenus pour adultes, violence
- Conseils médicaux ou juridiques
- Divertissement général (sauf si lié à une filière)
- Aide aux devoirs ou résolution d'exercices
- Programmation/code (sauf pour expliquer la filière informatique)
- Toute question sans rapport avec l'éducation ou l'orientation

Si hors-sujet, réponds : "Je suis spécialisée uniquement en orientation scolaire \
et professionnelle, je ne peux pas t'aider sur ce sujet. 😊 Mais si tu as une \
question sur tes études, tes choix de filière ou ton avenir professionnel, je suis là !"
"""

_CONTEXT_TEMPLATE = """\

**Profil de l'élève (résultats d'orientation) :**
{context_block}

Utilise ces informations pour personnaliser chaque réponse. \
L'élève vient de recevoir ces résultats et a peut-être des questions ou des doutes.
"""


class PromptBuilder:
    """Construit le prompt système AÏDA."""

    def __init__(self, kb_repository) -> None:
        self._kb_repository = kb_repository

    def build(self, orientation_context: Optional[dict] = None) -> str:
        """
        Construit le prompt système complet.

        Args:
            orientation_context: Profil RIASEC de l'élève (optionnel).

        Returns:
            Prompt système complet à passer comme premier message.
        """
        kb_content = self._kb_repository.get_content()
        prompt = _PERSONA + _GUARDRAILS + "\n" + kb_content

        if orientation_context:
            context_block = self._format_context(orientation_context)
            prompt += _CONTEXT_TEMPLATE.format(context_block=context_block)

        return prompt

    @staticmethod
    def _format_context(context: dict) -> str:
        lines: list[str] = []
        if context.get("profile_code"):
            lines.append(f"- Code RIASEC : **{context['profile_code']}**")
        if context.get("dominant_traits"):
            traits = ", ".join(context["dominant_traits"])
            lines.append(f"- Traits dominants : {traits}")
        if context.get("profile_summary"):
            summary = context["profile_summary"][:300].replace("**", "")
            lines.append(f"- Résumé du profil : {summary}")
        if context.get("strengths"):
            strengths = ", ".join(context["strengths"][:4])
            lines.append(f"- Points forts : {strengths}")
        if context.get("recommendations"):
            careers = [
                c.get("name", "")
                for c in context["recommendations"][:5]
                if c.get("name")
            ]
            if careers:
                lines.append(f"- Carrières recommandées : {', '.join(careers)}")
        if context.get("recommended_sectors"):
            sectors = ", ".join(context["recommended_sectors"][:4])
            lines.append(f"- Secteurs conseillés : {sectors}")
        return "\n".join(lines) if lines else "Profil non disponible"
