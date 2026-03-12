"""
Endpoints de chat IA — ActivEducation

POST /api/v1/chat/message      → Envoyer un message à AÏDA
DELETE /api/v1/chat/session/{session_id} → Effacer l'historique

L'assistant AÏDA utilise Groq (gratuit) avec llama-3.1-8b-instant.
"""

import uuid
from datetime import datetime, timezone
from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from app.core.security import get_current_user_id
from app.services.llm_service import llm_service

router = APIRouter()


# ---------------------------------------------------------------------------
# Schémas
# ---------------------------------------------------------------------------


class OrientationContext(BaseModel):
    """Profil d'orientation de l'élève — envoyé par l'app mobile."""

    profile_code: Optional[str] = None
    dominant_traits: Optional[list[str]] = None
    profile_summary: Optional[str] = None
    strengths: Optional[list[str]] = None
    recommendations: Optional[list[dict]] = None
    recommended_sectors: Optional[list[str]] = None


class HistoryMessage(BaseModel):
    """Un message de l'historique envoyé par le client pour le seeding."""

    role: str = Field(..., pattern=r"^(user|assistant)$")
    content: str = Field(..., min_length=1, max_length=2000)


class ChatRequest(BaseModel):
    """Corps d'une requête de chat."""

    message: str = Field(..., min_length=1, max_length=2000,
                         description="Message de l'utilisateur")
    session_id: Optional[str] = Field(
        default=None,
        description="ID de session (créé automatiquement si absent)",
    )
    orientation_context: Optional[OrientationContext] = Field(
        default=None,
        description="Profil RIASEC de l'élève pour personnaliser la réponse",
    )
    history: Optional[list[HistoryMessage]] = Field(
        default=None,
        max_length=10,
        description="Historique récent pour restaurer le contexte après redémarrage",
    )


class ChatResponse(BaseModel):
    """Réponse d'AÏDA."""

    reply: str
    session_id: str
    timestamp: str


class SessionClearedResponse(BaseModel):
    message: str
    session_id: str


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------


@router.post(
    "/message",
    response_model=ChatResponse,
    summary="Envoyer un message à AÏDA",
    description=(
        "Envoie un message à l'assistante d'orientation AÏDA et reçoit une réponse "
        "personnalisée. L'historique de conversation est conservé par session_id. "
        "Si aucun session_id n'est fourni, un nouveau est créé automatiquement. "
        "Authentification requise (Bearer token Supabase)."
    ),
)
async def send_message(
    request: ChatRequest,
    user_id: UUID = Depends(get_current_user_id),
) -> ChatResponse:
    # L'ID utilisateur est utilisé pour namespacing la session
    # afin d'éviter les collisions entre utilisateurs différents.
    session_id = request.session_id or f"{user_id}:{uuid.uuid4()}"

    context_dict: Optional[dict] = None
    if request.orientation_context:
        context_dict = request.orientation_context.model_dump(exclude_none=True)

    client_history: Optional[list[dict]] = None
    if request.history:
        client_history = [h.model_dump() for h in request.history]

    try:
        result = await llm_service.chat(
            message=request.message,
            session_id=session_id,
            orientation_context=context_dict,
            client_history=client_history,
        )
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Le service AÏDA est temporairement indisponible.",
        )

    return ChatResponse(
        reply=result["reply"],
        session_id=session_id,
        timestamp=datetime.now(timezone.utc).isoformat(),
    )


@router.delete(
    "/session/{session_id}",
    response_model=SessionClearedResponse,
    summary="Effacer l'historique d'une session",
)
async def clear_session(
    session_id: str,
    user_id: UUID = Depends(get_current_user_id),
) -> SessionClearedResponse:
    llm_service.clear_session(session_id)
    return SessionClearedResponse(
        message="Historique de conversation effacé.",
        session_id=session_id,
    )
