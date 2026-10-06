"""Tests de l'attribution des points / XP a la completion d'une lecon."""

from unittest.mock import MagicMock, patch

from app.repositories.elearning_repository import ElearningRepository

_MODULE = "app.repositories.elearning_repository"


def test_xp_awarded_even_if_user_points_table_is_missing():
    """user_points absente (PGRST205) ne doit plus bloquer award_xp."""
    db = MagicMock()
    db.client.table.side_effect = Exception("PGRST205: table public.user_points introuvable")
    repo = ElearningRepository(db=db)

    with patch(f"{_MODULE}.invalidate_gamification_profile") as invalidate_profile, \
         patch(f"{_MODULE}.invalidate_leaderboard") as invalidate_leaderboard:
        repo._award_lesson_points("user-1", 15)

    db.client.rpc.assert_called_once_with("award_xp", {"p_user_id": "user-1", "p_amount": 15})
    invalidate_profile.assert_called_once_with("user-1")
    invalidate_leaderboard.assert_called_once()


def test_user_points_still_updated_when_table_exists():
    db = MagicMock()
    select_execute = (
        db.client.table.return_value.select.return_value.eq.return_value.limit.return_value.execute
    )
    select_execute.return_value = MagicMock(
        data=[{"id": "p1", "points_balance": 5, "total_earned": 5}]
    )
    repo = ElearningRepository(db=db)

    with patch(f"{_MODULE}.invalidate_gamification_profile"), \
         patch(f"{_MODULE}.invalidate_leaderboard"):
        repo._award_lesson_points("user-1", 10)

    db.client.rpc.assert_called_once_with("award_xp", {"p_user_id": "user-1", "p_amount": 10})
    db.client.table.return_value.update.assert_called_once_with(
        {"points_balance": 15, "total_earned": 15}
    )
