"""Reference data tests for /varieties."""

from conftest import admin_headers, user_headers


def test_requires_authentication(client):
    assert client.get("/api/v1/varieties").status_code == 401


def test_lists_active_varieties(client):
    headers = user_headers(client)
    response = client.get("/api/v1/varieties", headers=headers)
    assert response.status_code == 200
    codes = {item["code"] for item in response.json()}
    assert codes == {"TALL", "DWARF", "HYBRID"}


def test_only_admins_can_manage_varieties(client):
    headers = user_headers(client)
    payload = {
        "code": "CATIGAN",
        "name": "Catigan Green Dwarf",
        "description": "Green dwarf coconut from Catigan, Davao.",
    }
    assert client.post("/api/v1/varieties", headers=headers, json=payload).status_code == 403


def test_admin_create_update_and_deactivate(client):
    headers = admin_headers(client)
    created = client.post(
        "/api/v1/varieties",
        headers=headers,
        json={
            "code": "catigan",
            "name": "Catigan Green Dwarf",
            "local_name": "Lubi Catigan",
            "description": "Green dwarf coconut from Catigan, Davao.",
        },
    )
    assert created.status_code == 201, created.text
    variety = created.json()
    assert variety["code"] == "CATIGAN"

    duplicate = client.post(
        "/api/v1/varieties",
        headers=headers,
        json={
            "code": "CATIGAN",
            "name": "Duplicate",
            "description": "Should not be saved.",
        },
    )
    assert duplicate.status_code == 409

    updated = client.patch(
        f"/api/v1/varieties/{variety['id']}",
        headers=headers,
        json={"description": "Updated description for the dataset."},
    )
    assert updated.status_code == 200
    assert updated.json()["description"].startswith("Updated")

    deactivated = client.delete(
        f"/api/v1/varieties/{variety['id']}", headers=headers
    )
    assert deactivated.status_code == 200
    assert deactivated.json()["active"] is False

    # Normal listing hides it; the admin can request inactive rows.
    visible = client.get("/api/v1/varieties", headers=headers).json()
    assert "CATIGAN" not in {item["code"] for item in visible}

    all_rows = client.get(
        "/api/v1/varieties?include_inactive=true", headers=headers
    ).json()
    assert "CATIGAN" in {item["code"] for item in all_rows}
