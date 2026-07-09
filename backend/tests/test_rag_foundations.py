"""Tests des fondations RAG TutorAI (Phase 2).

Couvre :
- Decoupage en chunks (frontieres, chevauchement, cas limites).
- Contrat EmbeddingProvider + fabrique (Ollama, dim=768).
- ContentChunkRepository : recherche via RPC, insertion, suppression.
- Config RAG.

Aucun acces reseau : Supabase est remplace par un faux.
"""

from types import SimpleNamespace
from uuid import uuid4

import pytest

from app.core.config import get_settings
from app.services.rag.chunking import chunk_text
from app.services.rag.embeddings import get_embedding_provider, EmbeddingProvider
from app.repositories.content_chunk_repository import ContentChunkRepository


# ---------------------------------------------------------------------------
# Chunking
# ---------------------------------------------------------------------------


def test_chunk_empty_returns_empty():
    assert chunk_text("") == []
    assert chunk_text("   \n  ") == []


def test_chunk_short_text_single_chunk():
    out = chunk_text("Bonjour le monde", chunk_size=2000)
    assert out == ["Bonjour le monde"]


def test_chunk_normalizes_whitespace():
    out = chunk_text("a\n\n  b\t c", chunk_size=2000)
    assert out == ["a b c"]


def test_chunk_long_text_splits_with_bounds():
    text = " ".join(f"mot{i}" for i in range(200))  # bien > 50 chars
    chunks = chunk_text(text, chunk_size=50, overlap=10)
    assert len(chunks) > 1
    assert all(0 < len(c) <= 50 for c in chunks)
    # Le premier chunk est un prefixe du texte normalise.
    assert text.startswith(chunks[0])


def test_chunk_invalid_params():
    with pytest.raises(ValueError):
        chunk_text("x", chunk_size=0)
    with pytest.raises(ValueError):
        chunk_text("x", chunk_size=100, overlap=100)


# ---------------------------------------------------------------------------
# Embedding provider — contrat
# ---------------------------------------------------------------------------


def test_ollama_embedding_provider_satisfies_contract():
    provider = get_embedding_provider("ollama")
    assert isinstance(provider, EmbeddingProvider)
    assert provider.dim == 768
    assert hasattr(provider, "embed") and hasattr(provider, "embed_query")


def test_unknown_embedding_provider_falls_back_to_ollama():
    provider = get_embedding_provider("does-not-exist")
    assert isinstance(provider, EmbeddingProvider)
    assert provider.dim == 768


# ---------------------------------------------------------------------------
# ContentChunkRepository (faux Supabase)
# ---------------------------------------------------------------------------


class _FakeTable:
    def __init__(self, recorder, return_data):
        self._rec = recorder
        self._data = return_data

    def delete(self):
        self._rec["deleted"] = True
        return self

    def eq(self, col, val):
        self._rec["eq"].append((col, val))
        return self

    def execute(self):
        return SimpleNamespace(data=self._data)


class _FakeClient:
    def __init__(self, recorder, return_data):
        self._rec = recorder
        self._data = return_data

    def table(self, name):
        self._rec["tables"].append(name)
        return _FakeTable(self._rec, self._data)


class _FakeDB:
    def __init__(self, return_data=None, rpc_data=None):
        self.recorder = {"eq": [], "tables": [], "inserted": [], "rpc": []}
        self._data = return_data or []
        self._rpc_data = rpc_data or []
        self.client = _FakeClient(self.recorder, self._data)

    def insert(self, table, data):
        self.recorder["inserted"].append((table, data))
        return data

    def rpc(self, fn, params):
        self.recorder["rpc"].append((fn, params))
        return self._rpc_data


def _repo_with_fake(return_data=None, rpc_data=None):
    repo = ContentChunkRepository()
    fake = _FakeDB(return_data=return_data, rpc_data=rpc_data)
    repo._db = fake
    return repo, fake


async def test_search_calls_match_rpc_with_params():
    hit = {"id": str(uuid4()), "chunk_text": "reponse", "similarity": 0.9}
    repo, fake = _repo_with_fake(rpc_data=[hit])

    emb = [0.1] * 768
    results = await repo.search(emb, top_k=3, min_similarity=0.5, subject="maths")

    assert results == [hit]
    fn, params = fake.recorder["rpc"][0]
    assert fn == "match_content_chunks"
    assert params["query_embedding"] == emb
    assert params["match_count"] == 3
    assert params["min_similarity"] == 0.5
    assert params["filter_subject"] == "maths"
    assert params["filter_source_id"] is None


async def test_insert_chunks_builds_rows_and_serializes_source_id():
    repo, fake = _repo_with_fake()
    source_id = uuid4()
    n = await repo.insert_chunks([
        {
            "source_type": "lesson",
            "source_id": source_id,
            "subject": "maths",
            "title": "Fractions",
            "chunk_index": 0,
            "chunk_text": "un demi",
            "embedding": [0.0] * 768,
        }
    ])
    assert n == 1
    _table, rows = fake.recorder["inserted"][0]
    assert rows[0]["source_id"] == str(source_id)  # UUID serialise
    assert rows[0]["chunk_text"] == "un demi"
    assert rows[0]["metadata"] == {}


async def test_insert_chunks_empty_is_noop():
    repo, fake = _repo_with_fake()
    n = await repo.insert_chunks([])
    assert n == 0
    assert fake.recorder["inserted"] == []


async def test_delete_by_source_filters_type_and_id():
    source_id = uuid4()
    repo, fake = _repo_with_fake(return_data=[{"id": "1"}, {"id": "2"}])
    deleted = await repo.delete_by_source("lesson", source_id)
    assert deleted == 2
    assert fake.recorder.get("deleted") is True
    assert ("source_type", "lesson") in fake.recorder["eq"]
    assert ("source_id", str(source_id)) in fake.recorder["eq"]


# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------


def test_rag_config_defaults():
    settings = get_settings()
    assert settings.TUTOR_RAG_ENABLED is False
    assert settings.EMBEDDING_PROVIDER == "ollama"
    assert settings.EMBEDDING_DIM == 768
    assert settings.RAG_TOP_K == 4
