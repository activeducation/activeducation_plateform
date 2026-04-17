from uuid import uuid4


def test_submit_orientation_anonymous_succeeds_without_saving(anon_client):
    """L'endpoint accepte les soumissions anonymes (pas de 401)."""
    client, fake_repo = anon_client
    test_id = uuid4()
    payload = {"responses": {"q1": "4", "q2": "2"}}

    response = client.post(f"/api/v1/orientation/sessions/{test_id}/submit", json=payload)

    assert response.status_code == 200
    data = response.json()
    assert data["test_id"] == str(test_id)
    # La session n'est PAS sauvegardee en anonyme
    assert fake_repo.saved is False


def test_submit_orientation_success_with_mocked_dependencies(auth_client):
    """L'endpoint sauvegarde la session pour un utilisateur authentifie."""
    client, fake_repo = auth_client
    test_id = uuid4()
    payload = {"responses": {"q1": "5", "q2": "4", "q3": "3"}}

    response = client.post(f"/api/v1/orientation/sessions/{test_id}/submit", json=payload)

    assert response.status_code == 200
    data = response.json()
    assert data["test_id"] == str(test_id)
    assert isinstance(data["scores"], dict)
    assert len(data["dominant_traits"]) > 0
    assert isinstance(data["recommendations"], list)
    assert fake_repo.saved is True
