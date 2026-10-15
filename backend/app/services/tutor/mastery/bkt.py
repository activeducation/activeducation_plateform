"""Bayesian Knowledge Tracing (BKT) — mise a jour de la maitrise.

Modele probabiliste standard des Intelligent Tutoring Systems. A chaque
reponse (correcte/incorrecte) a un exercice ciblant une competence, on met a
jour la probabilite que l'eleve maitrise cette competence.

Quatre parametres :
- p_init   : probabilite de maitrise initiale (avant toute observation).
- p_transit: probabilite d'apprendre la competence a chaque opportunite.
- p_slip   : probabilite de se tromper alors qu'on maitrise (etourderie).
- p_guess  : probabilite de repondre juste par chance sans maitriser.

Reference : Corbett & Anderson (1994).
"""

from __future__ import annotations

from dataclasses import dataclass


def _clamp01(x: float) -> float:
    return min(max(x, 0.0), 1.0)


@dataclass(frozen=True)
class BktParams:
    """Parametres d'un modele BKT (par defaut : valeurs raisonnables)."""

    p_init: float = 0.3
    p_transit: float = 0.15
    p_slip: float = 0.1
    p_guess: float = 0.2

    @classmethod
    def from_settings(cls) -> "BktParams":
        from app.core.config import settings
        return cls(
            p_init=settings.BKT_P_INIT,
            p_transit=settings.BKT_P_TRANSIT,
            p_slip=settings.BKT_P_SLIP,
            p_guess=settings.BKT_P_GUESS,
        )


def bkt_update(prior: float, correct: bool, params: BktParams) -> float:
    """Retourne la nouvelle probabilite de maitrise apres une observation.

    Deux etapes :
    1. Posterior bayesien p(maitrise | reponse observee).
    2. Transition d'apprentissage (l'eleve a pu apprendre pendant l'exercice).

    Args:
        prior: probabilite de maitrise avant cette reponse [0,1].
        correct: True si la reponse est correcte.
        params: parametres BKT.

    Returns:
        Nouvelle probabilite de maitrise, dans [0,1].
    """
    prior = _clamp01(prior)
    p_slip = params.p_slip
    p_guess = params.p_guess

    if correct:
        numerator = prior * (1.0 - p_slip)
        denominator = prior * (1.0 - p_slip) + (1.0 - prior) * p_guess
    else:
        numerator = prior * p_slip
        denominator = prior * p_slip + (1.0 - prior) * (1.0 - p_guess)

    posterior = numerator / denominator if denominator > 0 else prior

    # Transition : l'eleve peut avoir appris pendant l'opportunite.
    p_new = posterior + (1.0 - posterior) * params.p_transit
    return _clamp01(p_new)
