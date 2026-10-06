"""Tests du deverrouillage progressif des modules e-learning."""

from app.repositories.elearning_repository import apply_progressive_unlock


def _module(is_locked, statuses):
    return {"is_locked": is_locked, "lessons": [{"status": s} for s in statuses]}


def test_locked_module_opens_when_previous_modules_completed():
    modules = [_module(False, ["completed", "completed"]), _module(True, [None])]
    apply_progressive_unlock(modules)
    assert modules[1]["is_locked"] is False


def test_locked_module_stays_locked_until_previous_completed():
    modules = [_module(False, ["completed", "in_progress"]), _module(True, [None])]
    apply_progressive_unlock(modules)
    assert modules[1]["is_locked"] is True


def test_lock_cascades_when_an_earlier_module_is_incomplete():
    modules = [
        _module(False, [None]),
        # Progression deja faite sur un module encore verrouille : il reste
        # verrouille tant que le module 1 n'est pas termine.
        _module(True, ["completed"]),
        _module(True, [None]),
    ]
    apply_progressive_unlock(modules)
    assert [m["is_locked"] for m in modules] == [False, True, True]


def test_unlocked_modules_are_never_locked():
    modules = [_module(False, [None]), _module(False, [None])]
    apply_progressive_unlock(modules)
    assert [m["is_locked"] for m in modules] == [False, False]


def test_module_without_lessons_does_not_block_the_next_one():
    modules = [_module(False, ["completed"]), _module(False, []), _module(True, [None])]
    apply_progressive_unlock(modules)
    assert modules[2]["is_locked"] is False
