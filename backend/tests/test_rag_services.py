"""Tests des services RAG TutorAI (retrieval, ingestion, cablage prompt).

Embedder et repository remplaces par des faux : aucun acces reseau/DB.
"""

from uuid import uuid4

from app.core.config import get_settings
from app.services.rag.retrieval import RetrievalService
from app.services.rag.ingestion import IngestionService


# ---------------------------------------------------------------------------
# Doubles
# ---------------------------------------------------------------------------


class _FakeEmbedder:
    dim = 768

    def __init__(self):
        self.query_calls = []
        self.batch_calls = []

    async def embed_query(self, text):
        self.query_calls.append(text)
        return [0.1] * 768

    async def embed(self, texts):
        self.batch_calls.append(list(texts))
        return [[0.1] * 768 for _ in texts]


class _BoomEmbedder:
    dim = 768

    async def embed_query(self, text):
        raise RuntimeError("ollama down")

    async def embed(self, texts):
        raise RuntimeError("ollama down")


class _FakeRepo:
    def __init__(self, search_data=None):
        self.search_data = search_data or []
        self.calls = {}

    async def search(self, embedding, top_k, min_similarity, subject, source_id):
        self.calls["search"] = {
            "embedding": embedding,
            "top_k": top_k,
            "min_similarity": min_similarity,
            "subject": subject,
            "source_id": source_id,
        }
        return self.search_data

    async def insert_chunks(self, rows):
        self.calls["insert"] = rows
        return len(rows)

    async def delete_by_source(self, source_type, source_id):
        self.calls["delete"] = (source_type, source_id)
        return 3


# ---------------------------------------------------------------------------
# RetrievalService
# ---------------------------------------------------------------------------


async def test_retrieve_embeds_query_and_searches():
    emb, repo = _FakeEmbedder(), _FakeRepo(search_data=[{"chunk_text": "x"}])
    svc = RetrievalService(repository=repo, embedder=emb)

    out = await svc.retrieve("ma question", subject="maths")

    assert out == [{"chunk_text": "x"}]
    assert emb.query_calls == ["ma question"]
    assert repo.calls["search"]["subject"] == "maths"
    # Defauts de settings appliques.
    assert repo.calls["search"]["top_k"] == get_settings().RAG_TOP_K


async def test_retrieve_empty_query_short_circuits():
    emb, repo = _FakeEmbedder(), _FakeRepo()
    svc = RetrievalService(repository=repo, embedder=emb)
    assert await svc.retrieve("   ") == []
    assert emb.query_calls == []          # pas d'appel embeddings inutile
    assert "search" not in repo.calls


def test_format_context_numbers_and_cites():
    ctx = RetrievalService.format_context([
        {"title": "Fractions", "chunk_text": "un demi"},
        {"subject": "maths", "chunk_text": "deux tiers"},
    ])
    assert "[1] (Fractions) un demi" in ctx
    assert "[2] (maths) deux tiers" in ctx


def test_format_context_empty():
    assert RetrievalService.format_context([]) == ""


async def test_retrieve_context_best_effort_swallows_errors():
    svc = RetrievalService(repository=_FakeRepo(), embedder=_BoomEmbedder())
    # Ne doit PAS lever : le chat retombe sur les connaissances generales.
    assert await svc.retrieve_context("question") == ""


# ---------------------------------------------------------------------------
# IngestionService
# ---------------------------------------------------------------------------


async def test_ingest_chunks_embeds_deletes_and_inserts():
    emb, repo = _FakeEmbedder(), _FakeRepo()
    svc = IngestionService(repository=repo, embedder=emb)
    sid = uuid4()

    text = " ".join(f"phrase numero {i}" for i in range(400))  # force plusieurs chunks
    n = await svc.ingest(
        "lesson", text, source_id=sid, subject="maths", title="Cours",
        replace=True,
    )

    assert n >= 1
    # replace=True + source_id → suppression avant reinsertion.
    assert repo.calls["delete"] == ("lesson", sid)
    rows = repo.calls["insert"]
    assert len(rows) == n
    assert all(r["source_type"] == "lesson" for r in rows)
    assert all(r["source_id"] == sid for r in rows)
    assert all(len(r["embedding"]) == 768 for r in rows)
    # chunk_index sequentiel
    assert [r["chunk_index"] for r in rows] == list(range(len(rows)))


async def test_ingest_empty_text_returns_zero_and_cleans():
    emb, repo = _FakeEmbedder(), _FakeRepo()
    svc = IngestionService(repository=repo, embedder=emb)
    sid = uuid4()

    n = await svc.ingest("lesson", "   ", source_id=sid, replace=True)

    assert n == 0
    assert emb.batch_calls == []                 # rien a embed
    assert repo.calls["delete"] == ("lesson", sid)  # ancien contenu nettoye
    assert "insert" not in repo.calls


# ---------------------------------------------------------------------------
# Cablage prompt (llm_service)
# ---------------------------------------------------------------------------


async def test_build_system_prompt_unchanged_when_rag_off(monkeypatch):
    from app.services.llm_service import LLMService

    settings = get_settings()
    monkeypatch.setattr(settings, "TUTOR_RAG_ENABLED", False)

    svc = LLMService()
    base = svc._prompt_builder.build(None)
    out = await svc._build_system_prompt("une question", None)

    assert out == base  # flag off → aucun ajout RAG


async def test_build_system_prompt_appends_context_when_rag_on(monkeypatch):
    from app.services.llm_service import LLMService

    settings = get_settings()
    monkeypatch.setattr(settings, "TUTOR_RAG_ENABLED", True)

    svc = LLMService()
    base = svc._prompt_builder.build(None)

    class _StubRetrieval:
        async def retrieve_context(self, message, subject=None):
            return "[1] (Fractions) un demi"

    svc._retrieval = _StubRetrieval()
    out = await svc._build_system_prompt("une question", None)

    assert out.startswith(base)
    assert "[1] (Fractions) un demi" in out
    assert "Contenu de cours pertinent" in out
