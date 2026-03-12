"""
Endpoints de chat IA — ActivEducation

POST /api/v1/chat/message          → Envoyer un message à AÏDA (JSON)
POST /api/v1/chat/message/stream   → Envoyer un message à AÏDA (SSE streaming)
DELETE /api/v1/chat/session/{session_id} → Effacer l'historique

L'assistant AÏDA utilise Groq (gratuit) avec llama-3.1-8b-instant.
"""

import uuid
from datetime import datetime, timezone
from typing import AsyncGenerator, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import StreamingResponse
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
    """Réponse d'AÏDA (mode non-streaming)."""

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
        "Envoie un message à l'assistante AÏDA et reçoit la réponse complète en JSON. "
        "Pour un affichage progressif mot par mot, utiliser /message/stream (SSE)."
    ),
)
async def send_message(
    request: ChatRequest,
    user_id: UUID = Depends(get_current_user_id),
) -> ChatResponse:
    session_id = request.session_id or str(uuid.uuid4())

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


@router.post(
    "/message/stream",
    summary="Envoyer un message à AÏDA (streaming SSE)",
    description=(
        "Envoie un message à AÏDA et reçoit la réponse en streaming Server-Sent Events. "
        "Le premier token apparaît en < 500ms. "
        "Format de chaque événement : 'data: {\"chunk\": \"...\"}\\n\\n'. "
        "Événement de fin : 'data: {\"done\": true, \"session_id\": \"...\"}\\n\\n'."
    ),
    response_class=StreamingResponse,
    responses={
        200: {
            "content": {"text/event-stream": {}},
            "description": "Stream SSE de la réponse AÏDA",
        }
    },
)
async def send_message_stream(
    request: ChatRequest,
    user_id: UUID = Depends(get_current_user_id),
) -> StreamingResponse:
    session_id = request.session_id or str(uuid.uuid4())

    context_dict: Optional[dict] = None
    if request.orientation_context:
        context_dict = request.orientation_context.model_dump(exclude_none=True)

    client_history: Optional[list[dict]] = None
    if request.history:
        client_history = [h.model_dump() for h in request.history]

    async def event_generator() -> AsyncGenerator[str, None]:
        try:
            async for chunk in llm_service.chat_stream(
                message=request.message,
                session_id=session_id,
                orientation_context=context_dict,
                client_history=client_history,
            ):
                if chunk.get("done"):
                    yield f'data: {{"done": true, "session_id": "{session_id}"}}\n\n'
                else:
                    content = chunk.get("chunk", "").replace('"', '\\"').replace('\n', '\\n')
                    yield f'data: {{"chunk": "{content}"}}\n\n'
        except Exception:
            yield 'data: {"error": "Le service AÏDA est temporairement indisponible."}\n\n'

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no",
        },
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
