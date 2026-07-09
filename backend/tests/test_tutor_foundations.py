"""Tests des fondations TutorAI (Phase 0).

Couvre :
- Ownership impose par ChatRepository (filtre user_id sur chaque requete).
- Repli memoire de SessionStore quand la persistance est desactivee.
- Conformite du provider Groq au contrat LLMProvider.
- Presence de la config LLM sortie du code.

Aucun acces reseau : le client Supabase est remplace par un faux.
"""

from types import SimpleNamespace
from uuid import uuid4

import pytest

from app.core.config import get_settings
from app.repositories.chat_repository import ChatRepository
from app.core.exceptions import QueryError
from app.services.tutor.session_store import SessionStore
from app.services.llm.providers import get_llm_provider, LLMProvider


# ---------------------------------------------------------------------------
# Faux client Supabase (aucun reseau)
# ---------------------------------------------------------------------------


class _FakeTable:
    def __init__(self, recorder, return_data):
        self._rec = recorder
        self._data = return_data

    def select(self, *a, **k):
        return self

    def update(self, data):
        self._rec["updated"].append(data)
        return self

    def delete(self):
        self._rec["deleted"] = True
        return self

    def eq(self, col, val):
        self._rec["eq"].append((col, val))
        return self

    def order(self, *a, **k):
        return self

    def limit(self, n):
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
    def __init__(self, return_data=None):
        self.recorder = {"eq": [], "tables": [], "inserted": [], "updated": []}
        self._data = return_data or []
        self.client = _FakeClient(self.recorder, self._data)

    def insert(self, table, data):
        self.recorder["inserted"].append((table, data))
        return [data]


def _repo_with_fake(return_data=None) -> tuple[ChatRepository, _FakeDB]:
    repo = ChatRepository()
    fake = _FakeDB(return_data=return_data)
    repo._db = fake
    return repo, fake


# ---------------------------------------------------------------------------
# ChatRepository — ownership
# ---------------------------------------------------------------------------


async def test_get_history_filters_by_user_id_and_orders_chronologically():
    user_id = uuid4()
    session_id = uuid4()
    # Supabase renvoie en desc (plus recent d'abord) ; le repo doit re-ordonner.
    desc_rows = [
        {"role": "assistant", "content": "B", "created_at": "2026-01-01T00:00:02Z"},
        {"role": "user", "content": "A", "created_at": "2026-01-01T00:00:01Z"},
    ]
    repo, fake = _repo_with_fake(return_data=desc_rows)

    history = await repo.get_history(session_id, user_id, limit=10)

    assert history == [
        {"role": "user", "content": "A"},
        {"role": "assistant", "content": "B"},
    ]
    # Ownership : le user_id ET le session_id doivent filtrer la requete.
    assert ("user_id", str(user_id)) in fake.recorder["eq"]
    assert ("session_id", str(session_id)) in fake.recorder["eq"]


async def test_clear_session_enforces_ownership():
    user_id = uuid4()
    session_id = uuid4()
    repo, fake = _repo_with_fake(return_data=[{"id": str(session_id)}])

    deleted = await repo.clear_session(session_id, user_id)

    assert deleted is True
    assert fake.recorder.get("deleted") is True
    assert ("user_id", str(user_id)) in fake.recorder["eq"]


async def test_clear_session_returns_false_when_nothing_deleted():
    repo, _ = _repo_with_fake(return_data=[])
    deleted = await repo.clear_session(uuid4(), uuid4())
    assert deleted is False


async def test_append_message_rejects_invalid_role():
    repo, _ = _repo_with_fake()
    with pytest.raises(QueryError):
        await repo.append_message(uuid4(), uuid4(), "root", "hack")


async def test_append_message_denormalizes_user_id():
    user_id = uuid4()
    session_id = uuid4()
    repo, fake = _repo_with_fake()

    await repo.append_message(session_id, user_id, "user", "bonjour")

    assert fake.recorder["inserted"], "un message doit avoir ete insere"
    _table, data = fake.recorder["inserted"][0]
    assert data["user_id"] == str(user_id)  # denormalise pour l'ownership
    assert data["session_id"] == str(session_id)
    assert data["role"] == "user"


# ---------------------------------------------------------------------------
# SessionStore — repli memoire quand persistance desactivee
# ---------------------------------------------------------------------------


async def test_session_store_memory_roundtrip_when_persist_disabled(monkeypatch):
    settings = get_settings()
    monkeypatch.setattr(settings, "TUTOR_PERSIST_SESSIONS", False)

    store = SessionStore()
    session_id, user_id = uuid4(), uuid4()

    await store.append(session_id, user_id, "salut", "bonjour !")
    history = await store.get_history(session_id, user_id)

    assert history == [
        {"role": "user", "content": "salut"},
        {"role": "assistant", "content": "bonjour !"},
    ]


async def test_session_store_falls_back_to_memory_on_db_error(monkeypatch):
    settings = get_settings()
    monkeypatch.setattr(settings, "TUTOR_PERSIST_SESSIONS", True)

    store = SessionStore()
    session_id, user_id = uuid4(), uuid4()

    class _BoomRepo:
        async def append_message(self, *a, **k):
            raise RuntimeError("DB down")

        async def get_history(self, *a, **k):
            raise RuntimeError("DB down")

    store._repo = _BoomRepo()

    # Ne doit pas lever : repli memoire transparent.
    await store.append(session_id, user_id, "salut", "bonjour !")
    history = await store.get_history(session_id, user_id)
    assert history == [
        {"role": "user", "content": "salut"},
        {"role": "assistant", "content": "bonjour !"},
    ]


def test_seed_from_client_filters_and_truncates():
    raw = [
        {"role": "user", "content": "1"},
        {"role": "system", "content": "ignore"},   # role non conserve
        {"role": "assistant", "content": ""},        # contenu vide ignore
        {"role": "assistant", "content": "2"},
    ]
    seeded = SessionStore.seed_from_client(raw, limit=10)
    assert seeded == [
        {"role": "user", "content": "1"},
        {"role": "assistant", "content": "2"},
    ]


# ---------------------------------------------------------------------------
# Provider LLM — contrat
# ---------------------------------------------------------------------------


def test_groq_provider_satisfies_llm_provider_protocol():
    provider = get_llm_provider("groq")
    assert isinstance(provider, LLMProvider)
    assert hasattr(provider, "complete")
    assert hasattr(provider, "stream")


def test_unknown_provider_falls_back_to_groq():
    provider = get_llm_provider("does-not-exist")
    assert isinstance(provider, LLMProvider)


# ---------------------------------------------------------------------------
# Config — constantes sorties du code
# ---------------------------------------------------------------------------


def test_llm_config_present_with_expected_defaults():
    settings = get_settings()
    assert settings.LLM_PROVIDER == "groq"
    assert settings.LLM_MODEL == "llama-3.1-8b-instant"
    assert settings.LLM_MAX_TOKENS == 800
    assert settings.TUTOR_PERSIST_SESSIONS is False
