"""Administrator account-management tests."""

from conftest import admin_headers, register_user, user_headers


def test_admin_lists_accounts_with_activity(client):
    user_headers(client)  # juan signs up and is online
    headers = admin_headers(client)

    response = client.get("/api/v1/users", headers=headers)
    assert response.status_code == 200
    emails = {item["email"] for item in response.json()}
    assert emails == {"admin@smartcoco.ph", "juan@smartcoco.ph"}

    maria = next(item for item in response.json() if item["email"] == "juan@smartcoco.ph")
    assert maria["role_label"] == "Farmer"
    assert maria["login_count"] == 1
    assert maria["last_login_at"] is not None
    assert maria["online"] is True


def test_user_stats(client):
    user_headers(client)
    headers = admin_headers(client)
    stats = client.get("/api/v1/users/stats", headers=headers)
    assert stats.status_code == 200
    body = stats.json()
    assert body["total_accounts"] == 2
    assert body["admins"] == 1
    assert body["total_logins"] >= 2
    assert body["online_now"] >= 1


def test_search_and_role_filters(client):
    user_headers(client)
    register_user(
        client,
        email="nena@smartcoco.ph",
        first_name="Nena",
        last_name="Bautista",
        role="student",
    )
    headers = admin_headers(client)

    search = client.get("/api/v1/users?q=nena", headers=headers).json()
    assert [item["email"] for item in search] == ["nena@smartcoco.ph"]

    students = client.get("/api/v1/users?role=student", headers=headers).json()
    assert [item["email"] for item in students] == ["nena@smartcoco.ph"]

    assert client.get("/api/v1/users?role=admin", headers=headers).json()[0][
        "email"
    ] == "admin@smartcoco.ph"


def test_disable_account_blocks_login(client):
    user_headers(client)
    accounts = client.get("/api/v1/users", headers=admin_headers(client)).json()
    juan = next(item for item in accounts if item["email"] == "juan@smartcoco.ph")

    headers = admin_headers(client)
    disabled = client.patch(
        f"/api/v1/users/{juan['id']}/status",
        headers=headers,
        json={"status": "disabled"},
    )
    assert disabled.status_code == 200
    assert disabled.json()["status"] == "disabled"

    login = client.post(
        "/api/v1/auth/login",
        json={"email": "juan@smartcoco.ph", "password": "Password123"},
    )
    assert login.status_code == 403
    assert login.json()["detail"] == "account_disabled"


def test_admin_can_promote_a_researcher(client):
    user_headers(client)
    accounts = client.get("/api/v1/users", headers=admin_headers(client)).json()
    juan = next(item for item in accounts if item["email"] == "juan@smartcoco.ph")

    promoted = client.patch(
        f"/api/v1/users/{juan['id']}/role",
        headers=admin_headers(client),
        json={"role": "researcher"},
    )
    assert promoted.status_code == 200
    assert promoted.json()["role_label"] == "Extension Worker / Researcher"


def test_non_admin_cannot_manage_users(client):
    headers = user_headers(client)
    assert client.get("/api/v1/users", headers=headers).status_code == 403
    assert client.get("/api/v1/users/stats", headers=headers).status_code == 403
