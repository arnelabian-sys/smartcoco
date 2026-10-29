"""Health snapshot tests."""

from conftest import admin_headers, user_headers


def test_health_snapshot(client):
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    body = response.json()
    assert body["api_up"] is True
    assert body["model_up"] is True
    assert body["model_version"] == "cnn-v1.0.0"
    assert body["architecture"]
    assert body["active_varieties"] == 3
    assert body["accuracy"] > 0.9
    assert body["checks"] >= 1
    assert body["error"] is None


def test_health_history_is_admin_only(client):
    client.get("/api/v1/health")
    client.get("/api/v1/health")

    assert client.get("/api/v1/health/history").status_code == 401
    assert (
        client.get(
            "/api/v1/health/history", headers=user_headers(client)
        ).status_code
        == 403
    )

    response = client.get("/api/v1/health/history", headers=admin_headers(client))
    assert response.status_code == 200
    assert len(response.json()) >= 2
