"""Tests du tool-calling TutorAI (boucle d'outils, dispatch, provider)."""

import json
from uuid import uuid4

from app.services.tutor.tools import get_tool_schemas, dispatch_tool
from app.services.llm.groq_provider import GroqProvider


# ---------------------------------------------------------------------------
# Schémas d'outils
# ---------------------------------------------------------------------------


def test_tool_schemas_expose_expected_tools():
    names = [t["function"]["name"] for t in get_tool_schemas()]
    assert "generate_quiz" in names
    assert "recommend_next_step" in names


# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------


async def test_dispatch_unknown_tool_returns_error_json():
    out = await dispatch_tool("outil_inexistant", {}, uuid4())
    parsed = json.loads(out)
    assert "error" in parsed


async def test_dispatch_never_raises_on_failure(monkeypatch):
    # generate_quiz sans provider fonctionnel : dispatch doit encapsuler
    # l'erreur en JSON plutôt que de lever.
    out = await dispatch_tool("generate_quiz", {"topic": "x"}, uuid4())
    parsed = json.loads(out)
    assert isinstance(parsed, dict)  # soit un quiz, soit {"error": ...}


# ---------------------------------------------------------------------------
# Boucle _run_with_tools
# ---------------------------------------------------------------------------


class _ToolThenAnswerProvider:
    """1er appel : demande un outil. 2e appel : répond."""

    def __init__(self):
        self.calls = 0

    async def complete_with_tools(self, messages, tools):
        self.calls += 1
        if self.calls == 1:
            return {
                "content": None,
                "tool_calls": [
                    {"id": "c1", "function": {"name": "outil_inconnu", "arguments": "{}"}}
                ],
            }
        return {"content": "réponse finale", "tool_calls": None}

    async def complete(self, messages):
        return "completion simple"

    async def stream(self, messages):  # pragma: no cover
        yield "x"


class _NoToolProvider:
    async def complete_with_tools(self, messages, tools):
        return {"content": "réponse directe", "tool_calls": None}

    async def complete(self, messages):
        return "completion simple"

    async def stream(self, messages):  # pragma: no cover
        yield "x"


async def test_run_with_tools_executes_tool_then_returns_answer():
    from app.services.llm_service import LLMService

    svc = LLMService()
    provider = _ToolThenAnswerProvider()
    svc._provider = provider

    reply = await svc._run_with_tools(
        [{"role": "user", "content": "fais-moi un quiz"}], uuid4()
    )

    assert reply == "réponse finale"
    assert provider.calls == 2  # 1 appel outil + 1 réponse


async def test_run_with_tools_returns_content_when_no_tool_call():
    from app.services.llm_service import LLMService

    svc = LLMService()
    svc._provider = _NoToolProvider()

    reply = await svc._run_with_tools([{"role": "user", "content": "salut"}], uuid4())
    assert reply == "réponse directe"


# ---------------------------------------------------------------------------
# Provider — complete_with_tools sans clé Groq
# ---------------------------------------------------------------------------


async def test_complete_with_tools_without_groq_returns_dict():
    # Pas de GROQ_API_KEY en test → repli Ollama (injoignable) → dict propre.
    provider = GroqProvider()
    out = await provider.complete_with_tools([{"role": "user", "content": "hi"}], [])
    assert "content" in out and "tool_calls" in out
    assert out["tool_calls"] is None
