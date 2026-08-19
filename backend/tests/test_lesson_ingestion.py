"""Tests de l'ingestion RAG des leçons e-learning + lesson_skills."""

from types import SimpleNamespace
from uuid import uuid4

from app.services.rag.lesson_ingestion import (
    LessonIngestionService,
    extract_lesson_text,
)
from app.repositories.skill_repository import SkillRepository


# ---------------------------------------------------------------------------
# Extraction de texte
# ---------------------------------------------------------------------------


def test_extract_lesson_text_harvests_content_and_skips_urls():
    lesson = {
        "title": "Les fractions",
        "description": "Introduction aux fractions",
        "content": {
            "lesson_type": "article",
            "data": {
                "body": "Une fraction represente une partie d'un tout.",
                "video_url": "https://example.com/video.mp4",
                "points": ["numerateur", "denominateur"],
            },
        },
    }
    text = extract_lesson_text(lesson)
    assert "Les fractions" in text
    assert "Une fraction represente une partie d'un tout." in text
    assert "numerateur" in text
    assert "https://example.com/video.mp4" not in text


def test_extract_lesson_text_deduplicates():
    lesson = {"title": "Répété", "description": "Répété"}
    assert extract_lesson_text(lesson).count("Répété") == 1


# ---------------------------------------------------------------------------
# LessonIngestionService
# ---------------------------------------------------------------------------


class _FakeElearning:
    def __init__(self, lesson):
        self._lesson = lesson

    async def get_lesson_detail(self, lesson_id, user_id=None):
        return self._lesson


class _FakeIngestion:
    def __init__(self, chunks=3):
        self.calls = []
        self._chunks = chunks

    async def ingest(self, **kwargs):
        self.calls.append(kwargs)
        return self._chunks


class _FakeIdsDB:
    def __init__(self, rows):
        self._rows = rows

    @property
    def client(self):
        table = SimpleNamespace(
            select=lambda *a, **k: SimpleNamespace(
                execute=lambda: SimpleNamespace(data=self._rows)
            )
        )
        return SimpleNamespace(table=lambda name: table)


async def test_ingest_lesson_extracts_and_ingests():
    lesson = {
        "id": "l1",
        "title": "Fractions",
        "content": {"data": {"body": "Contenu du cours suffisamment long."}},
    }
    ing = _FakeIngestion()
    svc = LessonIngestionService(elearning=_FakeElearning(lesson), ingestion=ing)

    n = await svc.ingest_lesson(uuid4())

    assert n == 3
    call = ing.calls[0]
    assert call["source_type"] == "lesson"
    assert "Fractions" in call["text"]
    assert call["replace"] is True


async def test_ingest_lesson_missing_returns_zero():
    svc = LessonIngestionService(
        elearning=_FakeElearning(None), ingestion=_FakeIngestion()
    )
    assert await svc.ingest_lesson(uuid4()) == 0


async def test_ingest_all_lessons_iterates_catalog():
    lesson = {"id": "x", "title": "T", "content": {"data": {"body": "contenu leçon"}}}
    ing = _FakeIngestion(chunks=2)
    db = _FakeIdsDB([{"id": str(uuid4())}, {"id": str(uuid4())}])
    svc = LessonIngestionService(
        elearning=_FakeElearning(lesson), ingestion=ing, db=db
    )

    res = await svc.ingest_all_lessons()

    assert res["lessons_processed"] == 2
    assert res["chunks_inserted"] == 4  # 2 leçons x 2 chunks


# ---------------------------------------------------------------------------
# SkillRepository.set_lesson_skills
# ---------------------------------------------------------------------------


class _LinkTable:
    def __init__(self, rec):
        self._rec = rec

    def delete(self):
        self._rec["deleted"] = True
        return self

    def eq(self, col, val):
        self._rec.setdefault("eq", []).append((col, val))
        return self

    def execute(self):
        return SimpleNamespace(data=[])


class _SkillDB:
    def __init__(self):
        self.rec = {}
        self.client = SimpleNamespace(table=lambda name: _LinkTable(self.rec))

    def insert(self, table, data):
        self.rec["inserted"] = (table, data)
        return data


async def test_set_lesson_skills_replaces_links():
    repo = SkillRepository()
    fake = _SkillDB()
    repo._db = fake
    lesson_id = uuid4()
    skills = [uuid4(), uuid4()]

    n = await repo.set_lesson_skills(lesson_id, skills)

    assert n == 2
    assert fake.rec["deleted"] is True          # anciens liens supprimés
    _table, rows = fake.rec["inserted"]
    assert len(rows) == 2
    assert rows[0]["lesson_id"] == str(lesson_id)


async def test_set_lesson_skills_empty_only_clears():
    repo = SkillRepository()
    fake = _SkillDB()
    repo._db = fake

    n = await repo.set_lesson_skills(uuid4(), [])

    assert n == 0
    assert fake.rec["deleted"] is True
    assert "inserted" not in fake.rec
