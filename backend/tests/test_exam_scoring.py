"""Tests de la logique de scoring d'examen (calcul du % et seuil de reussite)."""


def _score(questions, answers):
    """Reproduit la logique de scoring de submit_course_exam."""
    total_points = 0
    earned_points = 0
    correct_count = 0
    for q in questions:
        pts = q.get("points", 1)
        total_points += pts
        opts = q.get("options") or []
        chosen = answers.get(str(q["id"]))
        if chosen is not None and 0 <= chosen < len(opts) and opts[chosen].get("is_correct"):
            earned_points += pts
            correct_count += 1
    score = round((earned_points / total_points) * 100) if total_points else 0
    return score, correct_count


_QUESTIONS = [
    {"id": "q1", "points": 1, "options": [
        {"text": "A", "is_correct": True}, {"text": "B", "is_correct": False}]},
    {"id": "q2", "points": 1, "options": [
        {"text": "A", "is_correct": False}, {"text": "B", "is_correct": True}]},
    {"id": "q3", "points": 1, "options": [
        {"text": "A", "is_correct": False}, {"text": "B", "is_correct": True}]},
    {"id": "q4", "points": 1, "options": [
        {"text": "A", "is_correct": True}, {"text": "B", "is_correct": False}]},
    {"id": "q5", "points": 1, "options": [
        {"text": "A", "is_correct": True}, {"text": "B", "is_correct": False}]},
]


def test_perfect_score():
    answers = {"q1": 0, "q2": 1, "q3": 1, "q4": 0, "q5": 0}
    score, correct = _score(_QUESTIONS, answers)
    assert score == 100
    assert correct == 5


def test_eighty_percent_passes():
    # 4/5 corrects = 80%
    answers = {"q1": 0, "q2": 1, "q3": 1, "q4": 0, "q5": 1}  # q5 faux
    score, correct = _score(_QUESTIONS, answers)
    assert score == 80
    assert correct == 4
    assert score >= 80  # seuil de reussite par defaut


def test_below_threshold_fails():
    # 3/5 = 60%
    answers = {"q1": 0, "q2": 1, "q3": 1, "q4": 1, "q5": 1}  # q4,q5 faux
    score, _ = _score(_QUESTIONS, answers)
    assert score == 60
    assert score < 80


def test_unanswered_counts_as_wrong():
    answers = {"q1": 0}  # une seule reponse
    score, correct = _score(_QUESTIONS, answers)
    assert correct == 1
    assert score == 20


def test_out_of_range_index_is_wrong():
    answers = {"q1": 99, "q2": 1, "q3": 1, "q4": 0, "q5": 0}  # q1 index invalide
    score, correct = _score(_QUESTIONS, answers)
    assert correct == 4
    assert score == 80


def test_weighted_points():
    questions = [
        {"id": "a", "points": 3, "options": [{"text": "x", "is_correct": True}, {"text": "y", "is_correct": False}]},
        {"id": "b", "points": 1, "options": [{"text": "x", "is_correct": True}, {"text": "y", "is_correct": False}]},
    ]
    # Bonne reponse a la question a 3 points, mauvaise a la 1 point -> 3/4 = 75%
    score, _ = _score(questions, {"a": 0, "b": 1})
    assert score == 75
