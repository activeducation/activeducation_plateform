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


# Modeles retires par Groq. Les figer ici evite d'y revenir par megarde : le
# service renvoie alors un 404 sur /chat/completions et AIDA devient muette,
# sans erreur visible cote application.
GROQ_RETIRED_MODELS = {
    "llama-3.1-8b-instant",
    "llama-3.1-70b-versatile",
    "mixtral-8x7b-32768",
}


def test_llm_config_present_with_expected_defaults():
    """Verifie l'intention de la configuration, pas un instantane de valeurs.

    Figer le nom exact du modele rendait ce test faux des que Groq en retirait
    un — ce qui est arrive. On controle donc ce qui compte reellement.
    """
    settings = get_settings()
    assert settings.LLM_PROVIDER == "groq"

    assert settings.LLM_MODEL, "un modele doit etre configure"
    assert settings.LLM_MODEL not in GROQ_RETIRED_MODELS, (
        f"{settings.LLM_MODEL} a ete retire par Groq. Lister les modeles "
        "disponibles via GET https://api.groq.com/openai/v1/models"
    )

    # Les modeles a raisonnement consomment une partie du budget avant de
    # rediger : trop bas, la reponse revient vide.
    assert settings.LLM_MAX_TOKENS >= 1000

    # Les fonctionnalites tuteur restent desactivees par defaut.
    assert settings.TUTOR_PERSIST_SESSIONS is False


# ---------------------------------------------------------------------------
# Cablage llm_service + endpoint
# ---------------------------------------------------------------------------


async def test_session_store_db_mode_ensures_session_before_messages(monkeypatch):
    settings = get_settings()
    monkeypatch.setattr(settings, "TUTOR_PERSIST_SESSIONS", True)

    store = SessionStore()
    rec = {"ensure": [], "append": []}

    class _RecRepo:
        async def ensure_session(self, s, u, **k):
            rec["ensure"].append((s, u))

        async def append_message(self, s, u, role, content, token_count=None):
            rec["append"].append((s, u, role, content))

    store._repo = _RecRepo()
    sid, uid = uuid4(), uuid4()

    await store.append(sid, uid, "q", "a")

    # La session doit etre garantie (FK) AVANT tout message.
    assert rec["ensure"] == [(sid, uid)]
    assert rec["append"] == [
        (sid, uid, "user", "q"),
        (sid, uid, "assistant", "a"),
    ]


async def test_llm_service_threads_user_id_to_store():
    from app.services.llm_service import LLMService

    svc = LLMService()

    class _StubProvider:
        async def complete(self, messages):
            return "reponse test"

        async def stream(self, messages):
            yield "reponse test"

    calls = {}

    class _StubStore:
        async def get_history(self, session_id, user_id, limit=None):
            return []

        def seed_from_client(self, client_history, limit):
            return []

        async def append(self, session_id, user_id, user_message, assistant_reply, token_count=None):
            calls["append"] = (session_id, user_id)

    svc._provider = _StubProvider()
    svc._store = _StubStore()

    uid, sid = uuid4(), uuid4()
    result = await svc.chat("bonjour", session_id=sid, user_id=uid)

    assert result["reply"] == "reponse test"
    # Le user_id de l'auth (pas le prefixe client) doit remonter au store.
    assert calls["append"] == (sid, uid)


def test_resolve_session_parses_legacy_prefixed_id():
    from app.api.v1.endpoints.chat import _resolve_session

    user_id = uuid4()
    inner = uuid4()
    raw = f"{user_id}:{inner}"

    session_uuid, session_str = _resolve_session(raw, user_id)

    assert session_uuid == inner          # UUID extrait du suffixe
    assert session_str == raw             # id client-facing preserve


def test_resolve_session_generates_when_absent():
    user_id = uuid4()
    from app.api.v1.endpoints.chat import _resolve_session

    session_uuid, session_str = _resolve_session(None, user_id)

    assert session_str == f"{user_id}:{session_uuid}"
