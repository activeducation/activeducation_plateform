"""
Endpoints E-Learning — ActivEducation

GET  /api/v1/elearning/courses               → Catalogue des cours publies
GET  /api/v1/elearning/courses/{id}          → Detail d'un cours (modules + lecons)
GET  /api/v1/elearning/lessons/{id}          → Detail d'une lecon + contenu (auth requise)
POST /api/v1/elearning/courses/{id}/enroll   → S'inscrire a un cours (auth requise)
GET  /api/v1/elearning/my-courses            → Mes cours inscrits (auth requise)
POST /api/v1/elearning/lessons/{id}/complete → Marquer une lecon comme terminee (auth requise)
"""

from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.core.cache import get_cache, TTL_LISTS
from app.core.security import get_current_user_id, get_user_from_token
from app.repositories.elearning_repository import elearning_repository
from app.schemas.elearning import (
    CourseListItem,
    CourseDetail,
    LessonDetail,
    EnrollmentResponse,
    CompleteLessonRequest,
    CompleteLessonResponse,
    MyCoursesResponse,
    MyCourse,
)

router = APIRouter()

# Scheme Bearer avec auto_error=False pour les routes optionnellement authentifiees
_bearer_optional = HTTPBearer(auto_error=False)


async def get_optional_user_id(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(_bearer_optional),
) -> Optional[UUID]:
    """
    Dependency optionnelle : retourne l'UUID de l'utilisateur si un token valide
    est present, sinon None (sans lever d'exception).
    """
    if credentials is None:
        return None
    try:
        user_data = get_user_from_token(credentials.credentials)
        return UUID(user_data["user_id"])
    except Exception:
        return None


# =============================================================================
# CATALOGUE PUBLIC
# =============================================================================


@router.get(
    "/courses",
    response_model=list[CourseListItem],
    summary="Catalogue des cours publies",
    description=(
        "Retourne tous les cours publies, ordonnes par display_order. "
        "Si un token valide est fourni, enrichit chaque cours avec "
        "progress_pct et is_enrolled."
    ),
)
async def list_courses(
    user_id: Optional[UUID] = Depends(get_optional_user_id),
) -> list[CourseListItem]:
    cache = get_cache()
    user_id_str = str(user_id) if user_id else None

    # Cle de cache differente selon qu'on a un utilisateur ou non
    cache_key = f"elearning:courses:{user_id_str or 'anonymous'}"
    cached = cache.get(cache_key)
    if cached is not None:
        return [CourseListItem(**c) for c in cached]

    courses = await elearning_repository.get_published_courses(user_id=user_id_str)
    items = [CourseListItem(**c) for c in courses]

    cache.set(cache_key, [c.model_dump(mode="json") for c in items], ttl=TTL_LISTS)
    return items


@router.get(
    "/courses/{course_id}",
    response_model=CourseDetail,
    summary="Detail d'un cours",
    description=(
        "Retourne un cours avec ses modules et lecons. "
        "Si un token valide est fourni, enrichit avec la progression de l'utilisateur."
    ),
)
async def get_course(
    course_id: UUID,
    user_id: Optional[UUID] = Depends(get_optional_user_id),
) -> CourseDetail:
    cache = get_cache()
    user_id_str = str(user_id) if user_id else None
    cache_key = f"elearning:course:{course_id}:{user_id_str or 'anonymous'}"

    cached = cache.get(cache_key)
    if cached is not None:
        return CourseDetail(**cached)

    course_data = await elearning_repository.get_course_detail(
        course_id=str(course_id), user_id=user_id_str
    )
    if course_data is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Cours introuvable.",
        )

    detail = CourseDetail(**course_data)
    cache.set(cache_key, detail.model_dump(mode="json"), ttl=TTL_LISTS)
    return detail


# =============================================================================
# LECONS (AUTH REQUISE)
# =============================================================================


@router.get(
    "/lessons/{lesson_id}",
    response_model=LessonDetail,
    summary="Detail d'une lecon avec contenu",
    description=(
        "Retourne une lecon avec son contenu complet. "
        "Authentification requise. "
        "Si la lecon n'est pas gratuite (is_free=False), l'utilisateur doit etre "
        "inscrit au cours correspondant."
    ),
)
async def get_lesson(
    lesson_id: UUID,
    user_id: UUID = Depends(get_current_user_id),
) -> LessonDetail:
    user_id_str = str(user_id)

    lesson_data = await elearning_repository.get_lesson_detail(
        lesson_id=str(lesson_id), user_id=user_id_str
    )
    if lesson_data is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Lecon introuvable.",
        )

    # Verifier l'acces si la lecon n'est pas gratuite
    if not lesson_data.get("is_free", False):
        # Recuperer le module pour obtenir le course_id
        try:
            db = elearning_repository._db
            module_result = (
                db.client.table("elearning_modules")
                .select("course_id")
                .eq("id", lesson_data["module_id"])
                .limit(1)
                .execute()
            )
            if module_result.data:
                course_id = module_result.data[0]["course_id"]
                enrollment_result = (
                    db.client.table("elearning_enrollments")
                    .select("id")
                    .eq("user_id", user_id_str)
                    .eq("course_id", course_id)
                    .limit(1)
                    .execute()
                )
                if not enrollment_result.data:
                    raise HTTPException(
                        status_code=status.HTTP_403_FORBIDDEN,
                        detail=(
                            "Acces refuse : vous devez etre inscrit au cours "
                            "pour acceder a cette lecon."
                        ),
                    )
        except HTTPException:
            raise
        except Exception:
            # En cas d'erreur lors de la verification, on refuse l'acces par securite
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Impossible de verifier votre acces a cette lecon.",
            )

    return LessonDetail(**lesson_data)


# =============================================================================
# INSCRIPTION (AUTH REQUISE)
# =============================================================================


@router.post(
    "/courses/{course_id}/enroll",
    response_model=EnrollmentResponse,
    status_code=status.HTTP_201_CREATED,
    summary="S'inscrire a un cours",
    description=(
        "Inscrit l'utilisateur authentifie au cours specifie. "
        "Retourne 409 si l'utilisateur est deja inscrit."
    ),
)
async def enroll_in_course(
    course_id: UUID,
    user_id: UUID = Depends(get_current_user_id),
) -> EnrollmentResponse:
    # Verifier que le cours existe et est publie
    course_data = await elearning_repository.get_course_detail(
        course_id=str(course_id), user_id=None
    )
    if course_data is None or not course_data.get("is_published", False):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Cours introuvable ou non publie.",
        )

    try:
        enrollment = await elearning_repository.enroll_user(
            user_id=str(user_id), course_id=str(course_id)
        )
    except ValueError as e:
        if "already_enrolled" in str(e):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Vous etes deja inscrit a ce cours.",
            )
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )

    # Invalider le cache de la liste des cours pour cet utilisateur
    cache = get_cache()
    cache.delete_pattern(f"elearning:courses:{user_id}*")
    cache.delete_pattern(f"elearning:course:{course_id}:{user_id}*")

    return EnrollmentResponse(
        course_id=UUID(enrollment["course_id"]),
        enrolled_at=enrollment["enrolled_at"],
        progress_pct=enrollment["progress_pct"],
    )


# =============================================================================
# MES COURS (AUTH REQUISE)
# =============================================================================


@router.get(
    "/my-courses",
    response_model=MyCoursesResponse,
    summary="Mes cours inscrits",
    description="Retourne la liste des cours auxquels l'utilisateur est inscrit, avec sa progression.",
)
async def get_my_courses(
    user_id: UUID = Depends(get_current_user_id),
) -> MyCoursesResponse:
    cache = get_cache()
    cache_key = f"elearning:my-courses:{user_id}"
    cached = cache.get(cache_key)
    if cached is not None:
        return MyCoursesResponse(**cached)

    enrollments = await elearning_repository.get_user_enrollments(user_id=str(user_id))

    my_courses = []
    for enrollment in enrollments:
        course_data = enrollment["course"]
        my_courses.append(
            MyCourse(
                course=CourseListItem(**course_data),
                progress_pct=enrollment["progress_pct"],
                last_lesson_id=(
                    UUID(enrollment["last_lesson_id"])
                    if enrollment.get("last_lesson_id")
                    else None
                ),
                enrolled_at=enrollment["enrolled_at"],
            )
        )

    response = MyCoursesResponse(courses=my_courses)
    cache.set(cache_key, response.model_dump(mode="json"), ttl=TTL_LISTS)
    return response


# =============================================================================
# COMPLETION LECON (AUTH REQUISE)
# =============================================================================


@router.post(
    "/lessons/{lesson_id}/complete",
    response_model=CompleteLessonResponse,
    summary="Marquer une lecon comme terminee",
    description=(
        "Marque la lecon comme completee pour l'utilisateur authentifie. "
        "Calcule et met a jour la progression du cours. "
        "Attribue les points de recompense."
    ),
)
async def complete_lesson(
    lesson_id: UUID,
    body: CompleteLessonRequest,
    user_id: UUID = Depends(get_current_user_id),
) -> CompleteLessonResponse:
    # Verifier que la lecon existe
    lesson_data = await elearning_repository.get_lesson_detail(
        lesson_id=str(lesson_id), user_id=str(user_id)
    )
    if lesson_data is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Lecon introuvable.",
        )

    result = await elearning_repository.mark_lesson_complete(
        user_id=str(user_id),
        lesson_id=str(lesson_id),
        score=body.score,
        answers=body.answers,
    )

    # Invalider les caches de progression de cet utilisateur
    cache = get_cache()
    cache.delete_pattern(f"elearning:my-courses:{user_id}*")
    cache.delete_pattern(f"elearning:courses:{user_id}*")

    return CompleteLessonResponse(
        lesson_id=UUID(str(result["lesson_id"])),
        status=result["status"],
        points_earned=result["points_earned"],
        course_progress_pct=result.get("course_progress_pct"),
    )
