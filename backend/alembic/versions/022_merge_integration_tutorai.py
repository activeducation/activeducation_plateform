"""Reunifie les deux lignes de migration apres l'integration de TutorAI.

Contexte
--------
Deux chantiers ont progresse en parallele sur des bases differentes :
  - la ligne de production s'est arretee a '017a' (alignement de
    test_questions.category avec le code) ;
  - la branche TutorAI a poursuivi jusqu'a '021' (tuteur IA, RAG, maitrise des
    competences, profil d'orientation multi-facteur).

Apres fusion, Alembic voit donc DEUX tetes et `alembic upgrade head` echoue
avec "Multiple head revisions are present". Cette revision de fusion les
reunifie. Elle ne modifie aucun schema : les deux branches touchent des objets
disjoints, il n'y a rien a reconcilier.

Revision ID: 022
Revises: 017a, 021
Create Date: 2026-08-19
"""
from typing import Sequence, Union

revision: str = '022'
down_revision: Union[str, Sequence[str], None] = ('017a', '021')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Aucune operation : revision de fusion uniquement."""


def downgrade() -> None:
    """Aucune operation : revision de fusion uniquement."""
