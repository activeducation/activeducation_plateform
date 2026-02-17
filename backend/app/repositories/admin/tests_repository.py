"""Repository pour la gestion admin des tests d'orientation."""

import uuid as uuid_lib
from typing import Any, Optional
from uuid import UUID

from app.db.supabase_client import get_supabase_client, SupabaseClient
from app.core.logging import get_logger
from app.core.exceptions import NotFoundError
from app.schemas.admin.orientation import (
    TestListResponse,
    TestSummary,
    TestDetail,
    TestCreate,
    TestUpdate,
    QuestionCreate,
    QuestionUpdate,
    QuestionSummary,
    OptionSummary,
    OptionCreate,
    OptionUpdate,
)

logger = get_logger("repositories.admin.tests")


class TestsAdminRepository:
    def __init__(self):
        self._db: SupabaseClient = get_supabase_client()

    async def list_tests(
        self,
        page: int = 1,
        per_page: int = 20,
        search: Optional[str] = None,
        test_type: Optional[str] = None,
        is_active: Optional[bool] = None,
    ) -> TestListResponse:
        offset = (page - 1) * per_page

        query = self._db.client.table("orientation_tests").select("*", count="exact")

        if test_type:
            query = query.eq("type", test_type)
        if is_active is not None:
            query = query.eq("is_active", is_active)
        if search:
            query = query.or_(f"name.ilike.%{search}%,description.ilike.%{search}%")

        result = query.order("display_order.asc").range(offset, offset + per_page - 1).execute()

        items = []
        for t in (result.data or []):
            # Count questions
            qc = self._db.client.table("test_questions").select(
                "id", count="exact"
            ).eq("test_id", t["id"]).execute()

            # Count sessions
            sc = self._db.client.table("user_test_sessions").select(
                "id", count="exact"
            ).eq("test_id", t["id"]).execute()

            items.append(TestSummary(
                id=t["id"],
                name=t["name"],
                type=t["type"],
                duration_minutes=t.get("duration_minutes", 15),
                image_url=t.get("image_url"),
                is_active=t.get("is_active", True),
                display_order=t.get("display_order", 0),
                questions_count=qc.count or 0,
                sessions_count=sc.count or 0,
            ))

        return TestListResponse(
            items=items,
            total=result.count or len(items),
            page=page,
            per_page=per_page,
        )

    async def get_test_detail(self, test_id: UUID) -> TestDetail:
        test = self._db.fetch_one(
            table="orientation_tests", id_column="id", id_value=str(test_id)
        )
        if not test:
            raise NotFoundError("Test", str(test_id))

        # Get questions with options
        questions_data = self._db.client.table("test_questions").select(
            "*, question_options(*)"
        ).eq("test_id", str(test_id)).order("display_order").execute()

        questions = []
        for q in (questions_data.data or []):
            options = [
                OptionSummary(**o) for o in (q.get("question_options") or [])
            ]
            options.sort(key=lambda x: x.display_order)
            questions.append(QuestionSummary(
                id=q["id"],
                question_text=q["question_text"],
                question_type=q["question_type"],
                category=q.get("category"),
                display_order=q.get("display_order", 0),
                is_required=q.get("is_required", True),
                options=options,
            ))

        return TestDetail(
            **test,
            questions=questions,
        )

    async def create_test(self, data: TestCreate) -> TestDetail:
        result = self._db.insert(table="orientation_tests", data=data.model_dump())
        test = result[0] if result else {}
        return TestDetail(**test, questions=[])

    async def update_test(self, test_id: UUID, data: TestUpdate) -> TestDetail:
        update_data = data.model_dump(exclude_unset=True)
        if update_data:
            result = self._db.update(
                table="orientation_tests", id_column="id",
                id_value=str(test_id), data=update_data,
            )
            if not result:
                raise NotFoundError("Test", str(test_id))
        return await self.get_test_detail(test_id)

    async def delete_test(self, test_id: UUID):
        self._db.delete(table="orientation_tests", id_column="id", id_value=str(test_id))

    async def duplicate_test(self, test_id: UUID) -> TestDetail:
        """Duplique un test avec toutes ses questions et options."""
        source = await self.get_test_detail(test_id)

        new_test_id = str(uuid_lib.uuid4())
        self._db.insert(table="orientation_tests", data={
            "id": new_test_id,
            "name": f"{source.name} (copie)",
            "description": source.description,
            "type": source.type,
            "duration_minutes": source.duration_minutes,
            "image_url": source.image_url,
            "is_active": False,
            "display_order": source.display_order + 1,
        })

        for q in source.questions:
            new_q_id = str(uuid_lib.uuid4())
            self._db.insert(table="test_questions", data={
                "id": new_q_id,
                "test_id": new_test_id,
                "question_text": q.question_text,
                "question_type": q.question_type,
                "category": q.category,
                "display_order": q.display_order,
                "is_required": q.is_required,
            })

            for o in q.options:
                self._db.insert(table="question_options", data={
                    "question_id": new_q_id,
                    "option_text": o.option_text,
                    "option_value": o.option_value,
                    "display_order": o.display_order,
                    "icon": o.icon,
                })

        return await self.get_test_detail(UUID(new_test_id))

    # Questions
    async def add_question(self, test_id: UUID, data: QuestionCreate) -> dict:
        q_data = data.model_dump(exclude={"options"})
        q_data["test_id"] = str(test_id)
        result = self._db.insert(table="test_questions", data=q_data)
        question = result[0] if result else q_data

        # Add options if provided
        for opt in data.options:
            opt_data = {**opt, "question_id": question.get("id", q_data.get("id"))}
            self._db.insert(table="question_options", data=opt_data)

        return question

    async def update_question(self, question_id: UUID, data: QuestionUpdate) -> dict:
        update_data = data.model_dump(exclude_unset=True)
        result = self._db.update(
            table="test_questions", id_column="id",
            id_value=str(question_id), data=update_data,
        )
        if not result:
            raise NotFoundError("Question", str(question_id))
        return result[0]

    async def delete_question(self, question_id: UUID):
        self._db.delete(table="test_questions", id_column="id", id_value=str(question_id))

    async def reorder_questions(self, test_id: UUID, order: list[str]):
        for idx, q_id in enumerate(order):
            self._db.update(
                table="test_questions", id_column="id",
                id_value=q_id, data={"display_order": idx},
            )

    # Options
    async def add_option(self, question_id: UUID, data: OptionCreate) -> dict:
        opt_data = data.model_dump()
        opt_data["question_id"] = str(question_id)
        result = self._db.insert(table="question_options", data=opt_data)
        return result[0] if result else opt_data

    async def update_option(self, option_id: UUID, data: OptionUpdate) -> dict:
        update_data = data.model_dump(exclude_unset=True)
        result = self._db.update(
            table="question_options", id_column="id",
            id_value=str(option_id), data=update_data,
        )
        if not result:
            raise NotFoundError("Option", str(option_id))
        return result[0]

    async def delete_option(self, option_id: UUID):
        self._db.delete(table="question_options", id_column="id", id_value=str(option_id))


_tests_admin_repo = TestsAdminRepository()


def get_tests_admin_repository() -> TestsAdminRepository:
    return _tests_admin_repo
