"""Decoupage de texte en chunks pour le RAG.

Approche simple et sans dependance (pas de tokenizer) : decoupage en
fenetres de ~N caracteres avec chevauchement, en cassant de preference sur
une frontiere de mot pour ne pas couper au milieu d'un terme.

~2000 caracteres ~= ~500 tokens, une taille de chunk raisonnable pour du
contenu pedagogique.
"""

from __future__ import annotations


def chunk_text(
    text: str,
    chunk_size: int = 2000,
    overlap: int = 200,
) -> list[str]:
    """Decoupe un texte en chunks avec chevauchement.

    Args:
        text: texte source (sera nettoye des espaces superflus).
        chunk_size: taille cible d'un chunk en caracteres.
        overlap: nombre de caracteres partages entre deux chunks consecutifs.

    Returns:
        Liste de chunks non vides. Liste vide si le texte est vide.
    """
    if chunk_size <= 0:
        raise ValueError("chunk_size doit etre > 0")
    if overlap < 0 or overlap >= chunk_size:
        raise ValueError("overlap doit etre dans [0, chunk_size[")

    normalized = " ".join(text.split())
    if not normalized:
        return []
    if len(normalized) <= chunk_size:
        return [normalized]

    chunks: list[str] = []
    start = 0
    n = len(normalized)

    while start < n:
        end = start + chunk_size
        if end >= n:
            chunks.append(normalized[start:].strip())
            break

        # Reculer jusqu'a la derniere espace pour ne pas couper un mot.
        split_at = normalized.rfind(" ", start, end)
        if split_at == -1 or split_at <= start:
            split_at = end  # mot plus long que la fenetre : coupe nette

        chunks.append(normalized[start:split_at].strip())
        # Avancer en gardant un chevauchement, sans jamais reculer.
        start = max(split_at - overlap, start + 1)

    return [c for c in chunks if c]
