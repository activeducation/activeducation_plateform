"""
Endpoints API pour le module Orientation.

Gere:
- Liste et details des tests d'orientation
- Sessions de test
- Soumission et calcul des resultats
- Recommandations de carrieres
- Endpoints mobile-friendly (camelCase)
"""

from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, Query, Request

from app.core.logging import get_logger
from app.core.exceptions import TestNotFoundError, QueryError
from app.core.security import get_current_user_id
from app.schemas.orientation import (
    OrientationTest,
    OrientationTestSummary,
    TestResult,
    TestSubmission,
    Career,
    CareerSummary,
    MobileOrientationTest,
    MobileQuestion,
    MobileOption,
    MobileCareer,
    MobileEducationPath,
    MobileSalaryInfo,
    MobileJobOutlook,
)
from app.services.orientation_engine import orientation_engine
from app.repositories.orientation_repository import (
    get_orientation_repository,
    OrientationRepository,
)
from app.middleware.rate_limiter import standard_limit, strict_limit

logger = get_logger("api.orientation")

router = APIRouter()


# =============================================================================
# DEPENDENCY
# =============================================================================


def get_repo() -> OrientationRepository:
    """Dependency pour obtenir le repository."""
    return get_orientation_repository()


# =============================================================================
# TESTS ENDPOINTS
# =============================================================================


@router.get("/tests", response_model=list[OrientationTestSummary])
@standard_limit()
async def get_available_tests(
    request: Request,
    repo: OrientationRepository = Depends(get_repo),
):
    """
    Liste tous les tests d'orientation disponibles.
    Retourne un resume de chaque test sans les questions.
    """
    try:
        tests = await repo.get_all_tests(active_only=True)

        summaries = [
            OrientationTestSummary(
                id=test["id"],
                name=test["name"],
                description=test["description"],
                type=test["type"],
                duration_minutes=test["duration_minutes"],
                image_url=test.get("image_url"),
                is_active=test.get("is_active", True),
            )
            for test in tests
        ]

        logger.info(f"Retrieved {len(summaries)} tests")
        return summaries

    except Exception as e:
        logger.error(f"Error retrieving tests: {e}")
        raise QueryError("Impossible de recuperer la liste des tests")


@router.get("/tests/{test_id}", response_model=OrientationTest)
@standard_limit()
async def get_test(
    request: Request,
    test_id: UUID,
    repo: OrientationRepository = Depends(get_repo),
):
    """
    Recupere un test specifique avec toutes ses questions.
    """
    try:
        test = await repo.get_test_by_id(test_id)
        return _convert_db_test_to_schema(test)

    except TestNotFoundError:
        raise
    except Exception as e:
        logger.error(f"Error retrieving test {test_id}: {e}")
        raise QueryError("Impossible de recuperer ce test")


# =============================================================================
# MOBILE-FRIENDLY ENDPOINTS (camelCase JSON)
# =============================================================================


@router.get("/mobile/tests")
@standard_limit()
async def get_mobile_tests(
    request: Request,
    repo: OrientationRepository = Depends(get_repo),
):
    """
    Liste tous les tests au format mobile (camelCase).
    Retourne les tests complets avec questions et options.
    """
    try:
        tests = await repo.get_all_tests(active_only=True)
        mobile_tests = [_convert_db_test_to_mobile(t) for t in tests]
        logger.info(f"Retrieved {len(mobile_tests)} mobile tests")
        return mobile_tests
    except Exception as e:
        logger.error(f"Error retrieving mobile tests: {e}")
        raise QueryError("Impossible de recuperer les tests mobile")


@router.get("/mobile/tests/{test_id}")
@standard_limit()
async def get_mobile_test(
    request: Request,
    test_id: UUID,
    repo: OrientationRepository = Depends(get_repo),
):
    """
    Recupere un test specifique au format mobile (camelCase).
    """
    try:
        test = await repo.get_test_by_id(test_id)
        return _convert_db_test_to_mobile(test)
    except TestNotFoundError:
        raise
    except Exception as e:
        logger.error(f"Error retrieving mobile test {test_id}: {e}")
        raise TestNotFoundError(str(test_id))


@router.get("/mobile/careers")
@standard_limit()
async def get_mobile_careers(
    request: Request,
    sector: Optional[str] = Query(None, description="Filtrer par secteur"),
    limit: int = Query(50, ge=1, le=100),
    repo: OrientationRepository = Depends(get_repo),
):
    """
    Liste les carrieres au format mobile (camelCase).
    Retourne les details complets de chaque carriere.
    """
    try:
        careers = await repo.get_all_careers(sector=sector, limit=limit)
        return [_convert_db_career_to_mobile(c) for c in careers]
    except Exception as e:
        logger.error(f"Error fetching mobile careers: {e}")
        raise QueryError("Impossible de recuperer les carrieres mobile")


@router.get("/mobile/careers/{career_id}")
@standard_limit()
async def get_mobile_career(
    request: Request,
    career_id: UUID,
    repo: OrientationRepository = Depends(get_repo),
):
    """
    Recupere les details d'une carriere au format mobile (camelCase).
    """
    career = await repo.get_career_by_id(career_id)
    return _convert_db_career_to_mobile(career)


# =============================================================================
# TEST SUBMISSION
# =============================================================================


@router.post("/sessions/{test_id}/submit", response_model=TestResult)
@strict_limit("30/minute")
async def submit_test(
    request: Request,
    test_id: UUID,
    submission: TestSubmission,
    user_id: UUID = Depends(get_current_user_id),
    repo: OrientationRepository = Depends(get_repo),
):
    """
    Soumet les reponses d'un test et calcule les resultats.
    Retourne les scores, l'interpretation, les carrieres avec score de correspondance,
    et les programmes scolaires recommandes.
    """
    try:
        test = await repo.get_test_by_id(test_id)
        test_type = test["type"]
    except TestNotFoundError:
        raise
    except Exception:
        test_type = "riasec"
        test = None

    result = await orientation_engine.calculate_result(
        test_type=test_type,
        responses=submission.responses,
        test_data=test,
    )
    result.test_id = test_id

    try:
        session = await repo.create_test_session(user_id, test_id)

        # Enrichir les recommandations avec carrieres + score de correspondance
        if result.dominant_traits:
            try:
                careers = await repo.get_careers_by_traits(result.dominant_traits, limit=8)
                enriched_recs = []
                for c in careers:
                    career_traits = c.get("related_traits") or []
                    match_score = orientation_engine.calculate_match_score(
                        career_traits=career_traits,
                        user_dominant_traits=result.dominant_traits,
                        user_scores=result.scores,
                    )
                    # Calculer les traits en commun (normaliser accents + langues)
                    from app.services.orientation_engine import EN_TO_FR, CODE_TO_FR
                    _no_accent = {"Realiste": "Réaliste"}
                    normalized_ct = [EN_TO_FR.get(t) or CODE_TO_FR.get(t) or _no_accent.get(t) or t for t in career_traits]
                    matching = [t for t in normalized_ct if t in result.dominant_traits]

                    enriched_recs.append(CareerSummary(
                        id=c["id"],
                        name=c["name"],
                        description=c.get("description", ""),
                        sector_name=c.get("sector_name", ""),
                        job_demand=c.get("job_demand"),
                        salary_avg_fcfa=c.get("salary_avg_fcfa"),
                        salary_min_fcfa=c.get("salary_min_fcfa"),
                        salary_max_fcfa=c.get("salary_max_fcfa"),
                        image_url=c.get("image_url"),
                        match_score=match_score,
                        matching_traits=matching,
                        required_skills=(c.get("required_skills") or [])[:5],
                        related_traits=career_traits,
                        education_minimum_level=_extract_education_level(c),
                    ))

                # Trier par score de correspondance decroissant
                enriched_recs.sort(key=lambda r: r.match_score, reverse=True)
                result.recommendations = enriched_recs[:6]
            except Exception as e:
                logger.error(f"Error fetching recommended careers: {e}")
                result.recommendations = []

            # Recuperer les programmes scolaires correspondants
            try:
                sectors = result.interpretation.get("recommended_sectors", [])
                if sectors:
                    programs = await repo.get_matching_school_programs(sectors, limit=8)
                    result.matching_programs = programs
            except Exception as e:
                logger.error(f"Error fetching matching school programs: {e}")
                result.matching_programs = []

        await repo.complete_test_session(
            session_id=UUID(session["id"]),
            user_id=user_id,
            test_id=test_id,
            responses=submission.responses,
            result=result,
        )
        logger.info(
            f"Test submitted successfully",
            extra={
                "test_id": str(test_id),
                "user_id": str(user_id),
                "dominant_traits": result.dominant_traits,
            },
        )
    except Exception as e:
        logger.warning(f"Could not save test results to DB: {e}")

    return result


def _extract_education_level(career_data: dict) -> str:
    """Extrait le niveau d'education minimum d'une carriere."""
    edu = career_data.get("education_path")
    if isinstance(edu, str):
        import json
        try:
            edu = json.loads(edu)
        except Exception:
            return "BAC"
    if isinstance(edu, dict):
        return edu.get("minimum_level", "BAC")
    return "BAC"


# =============================================================================
# CAREERS ENDPOINTS (standard snake_case)
# =============================================================================


@router.get("/careers", response_model=list[CareerSummary])
@standard_limit()
async def get_careers(
    request: Request,
    sector: Optional[str] = Query(None, description="Filtrer par secteur"),
    limit: int = Query(50, ge=1, le=100, description="Nombre max de resultats"),
    repo: OrientationRepository = Depends(get_repo),
):
    """Liste les carrieres disponibles."""
    try:
        careers = await repo.get_all_careers(sector=sector, limit=limit)
        return [
            CareerSummary(
                id=c["id"],
                name=c["name"],
                sector_name=c["sector_name"],
                job_demand=c.get("job_demand"),
                salary_avg_fcfa=c.get("salary_avg_fcfa"),
                image_url=c.get("image_url"),
            )
            for c in careers
        ]
    except Exception as e:
        logger.error(f"Error fetching careers: {e}")
        raise QueryError("Impossible de recuperer les carrieres")


@router.get("/careers/{career_id}", response_model=Career)
@standard_limit()
async def get_career(
    request: Request,
    career_id: UUID,
    repo: OrientationRepository = Depends(get_repo),
):
    """Recupere les details d'une carriere."""
    career = await repo.get_career_by_id(career_id)
    return career


@router.get("/recommendations", response_model=list[CareerSummary])
@standard_limit()
async def get_recommendations(
    request: Request,
    traits: str = Query(
        ...,
        description="Traits RIASEC separes par virgule (ex: R,I,A)",
        examples=["R,I,A"],
    ),
    limit: int = Query(10, ge=1, le=20),
    repo: OrientationRepository = Depends(get_repo),
):
    """Recupere les carrieres recommandees selon les traits RIASEC."""
    trait_list = [t.strip().upper() for t in traits.split(",") if t.strip()]

    trait_mapping = {
        "R": "Realistic",
        "I": "Investigative",
        "A": "Artistic",
        "S": "Social",
        "E": "Enterprising",
        "C": "Conventional",
    }
    full_traits = [trait_mapping.get(t, t) for t in trait_list]

    try:
        careers = await repo.get_careers_by_traits(full_traits, limit=limit)
        return [
            CareerSummary(
                id=c["id"],
                name=c["name"],
                sector_name=c["sector_name"],
                job_demand=c.get("job_demand"),
                salary_avg_fcfa=c.get("salary_avg_fcfa"),
                image_url=c.get("image_url"),
            )
            for c in careers
        ]
    except Exception as e:
        logger.error(f"Error fetching recommendations: {e}")
        raise QueryError("Impossible de recuperer les recommandations")


# =============================================================================
# CONVERSION HELPERS
# =============================================================================


def _convert_db_test_to_mobile(db_test: dict) -> dict:
    """Convertit un test de la DB vers le format mobile camelCase."""
    questions = []
    for q in db_test.get("questions", []):
        options = [
            {
                "id": str(opt["id"]),
                "text": opt.get("option_text", opt.get("text", "")),
                "value": str(opt.get("option_value", opt.get("value", 0))),
                "icon": opt.get("icon"),
                "emoji": opt.get("emoji"),
            }
            for opt in q.get("options", [])
        ]

        # Map DB question_type to mobile format
        db_type = q.get("question_type", q.get("type", "likert"))
        mobile_type = _map_question_type(db_type)

        questions.append({
            "id": str(q["id"]),
            "text": q.get("question_text", q.get("text", "")),
            "type": mobile_type,
            "category": q.get("category"),
            "options": options,
            "imageAsset": q.get("image_asset"),
            "sectionTitle": q.get("section_title"),
            "sliderLeftLabel": q.get("slider_left_label"),
            "sliderRightLabel": q.get("slider_right_label"),
        })

    return {
        "id": str(db_test["id"]),
        "name": db_test["name"],
        "description": db_test["description"],
        "type": db_test["type"],
        "durationMinutes": db_test.get("duration_minutes", 15),
        "questions": questions,
        "imageUrl": db_test.get("image_url"),
    }


def _map_question_type(db_type: str) -> str:
    """Mappe les types de question DB vers les types mobile Dart."""
    mapping = {
        "likert": "likert",
        "multiple_choice": "multipleChoice",
        "boolean": "boolean",
        "scenario": "scenario",
        "this_or_that": "thisOrThat",
        "thisOrThat": "thisOrThat",
        "ranking": "ranking",
        "slider": "slider",
    }
    return mapping.get(db_type, db_type)


def _convert_db_career_to_mobile(db_career: dict) -> dict:
    """Convertit une carriere de la DB vers le format mobile camelCase."""
    education = db_career.get("education_path") or {}
    if isinstance(education, str):
        import json
        education = json.loads(education)

    return {
        "id": str(db_career["id"]),
        "name": db_career["name"],
        "description": db_career.get("description", ""),
        "sector": db_career.get("sector_name", ""),
        "requiredSkills": db_career.get("required_skills") or [],
        "relatedTraits": db_career.get("related_traits") or [],
        "educationPath": {
            "minimumLevel": education.get("minimum_level", "BAC"),
            "recommendedFormations": education.get("recommended_formations", []),
            "schoolsInTogo": education.get("schools_in_togo", []),
            "durationYears": education.get("duration_years", 3),
            "certifications": education.get("certifications"),
        },
        "salaryInfo": {
            "minMonthlyFCFA": db_career.get("salary_min_fcfa") or 0,
            "maxMonthlyFCFA": db_career.get("salary_max_fcfa") or 0,
            "averageMonthlyFCFA": db_career.get("salary_avg_fcfa") or 0,
            "experienceNote": db_career.get("salary_note") or "",
        },
        "outlook": {
            "demand": db_career.get("job_demand") or "medium",
            "trend": db_career.get("growth_trend") or "stable",
            "description": db_career.get("outlook_description") or "",
            "topEmployers": db_career.get("top_employers") or [],
            "entrepreneurshipPotential": db_career.get("entrepreneurship_potential", False),
        },
        "imageUrl": db_career.get("image_url"),
    }


# =============================================================================
# LEGACY CONVERSION HELPERS
# =============================================================================


def _convert_db_test_to_schema(db_test: dict) -> OrientationTest:
    """Convertit un test de la DB vers le schema Pydantic."""
    from app.schemas.orientation import Question, Option

    questions = []
    for q in db_test.get("questions", []):
        options = [
            Option(
                id=str(opt["id"]),
                text=opt.get("option_text", opt.get("text", "")),
                value=opt.get("option_value", opt.get("value", 0)),
                icon=opt.get("icon"),
            )
            for opt in q.get("options", [])
        ]

        questions.append(
            Question(
                id=str(q["id"]),
                text=q.get("question_text", q.get("text", "")),
                type=q.get("question_type", q.get("type", "likert")),
                category=q.get("category"),
                options=options,
            )
        )

    return OrientationTest(
        id=db_test["id"],
        name=db_test["name"],
        description=db_test["description"],
        type=db_test["type"],
        duration_minutes=db_test.get("duration_minutes", 15),
        image_url=db_test.get("image_url"),
        questions=questions,
        is_active=db_test.get("is_active", True),
        display_order=db_test.get("display_order", 0),
    )


