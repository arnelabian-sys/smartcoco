"""Authentication flow tests."""

from conftest import ADMIN_EMAIL, ADMIN_PASSWORD, register_user, user_headers


def test_admin_login_and_me(client):
    response = client.post(
        "/api/v1/auth/admin/login",
        json={"email": ADMIN_EMAIL, "password": ADMIN_PASSWORD},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["token_type"] == "bearer"
    assert body["user"]["role"] == "admin"
    assert body["user"]["role_label"] == "Administrator"

    me = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {body['access_token']}"},
    )
    assert me.status_code == 200
    assert me.json()["email"] == ADMIN_EMAIL


def test_admin_cannot_use_the_user_login(client):
    response = client.post(
        "/api/v1/auth/login",
        json={"email": ADMIN_EMAIL, "password": ADMIN_PASSWORD},
    )
    assert response.status_code == 403
    assert response.json()["detail"] == "admin_portal_required"


def test_regular_user_cannot_use_the_admin_portal(client):
    user_headers(client)
    response = client.post(
        "/api/v1/auth/admin/login",
        json={"email": "juan@smartcoco.ph", "password": "Password123"},
    )
    assert response.status_code == 403
    assert response.json()["detail"] == "not_administrator"


def test_register_then_login_then_logout(client):
    payload = register_user(client)
    token = payload["access_token"]
    assert payload["user"]["role"] == "farmer"
    assert payload["user"]["name"] == "Juan Dela Cruz"

    # A second login works with the same credentials.
    response = client.post(
        "/api/v1/auth/login",
        json={"email": "juan@smartcoco.ph", "password": "Password123"},
    )
    assert response.status_code == 200
    other_token = response.json()["access_token"]

    # Logging out revokes only that session.
    logout = client.post(
        "/api/v1/auth/logout", headers={"Authorization": f"Bearer {other_token}"}
    )
    assert logout.status_code == 200
    assert (
        client.get(
            "/api/v1/auth/me", headers={"Authorization": f"Bearer {other_token}"}
        ).status_code
        == 401
    )
    assert (
        client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {token}"}).status_code
        == 200
    )


def test_wrong_password_is_rejected(client):
    register_user(client)
    response = client.post(
        "/api/v1/auth/login",
        json={"email": "juan@smartcoco.ph", "password": "WrongPass1"},
    )
    assert response.status_code == 401
    assert response.json()["detail"] == "invalid_credentials"


def test_duplicate_email_is_rejected(client):
    register_user(client)
    response = client.post(
        "/api/v1/auth/register",
        json={
            "first_name": "Nena",
            "last_name": "Bautista",
            "email": "JUAN@smartcoco.ph",
            "password": "Password123",
            "role": "student",
        },
    )
    assert response.status_code == 409
    assert response.json()["detail"] == "duplicate_email"


def test_public_registration_cannot_create_admins(client):
    for role in ("admin", "researcher"):
        response = client.post(
            "/api/v1/auth/register",
            json={
                "first_name": "Bad",
                "last_name": "Actor",
                "email": f"{role}@smartcoco.ph",
                "password": "Password123",
                "role": role,
            },
        )
        assert response.status_code == 422


def test_password_policy_is_enforced(client):
    response = client.post(
        "/api/v1/auth/register",
        json={
            "first_name": "Weak",
            "last_name": "Password",
            "email": "weak@smartcoco.ph",
            "password": "onlyletters",
            "role": "user",
        },
    )
    assert response.status_code == 422


def test_profile_update_and_password_change(client):
    headers = user_headers(client)
    updated = client.patch(
        "/api/v1/users/me",
        headers=headers,
        json={"first_name": "Juanito", "last_name": "Cruz"},
    )
    assert updated.status_code == 200
    assert updated.json()["name"] == "Juanito Cruz"

    wrong = client.post(
        "/api/v1/users/me/password",
        headers=headers,
        json={"current_password": "nope", "new_password": "NewPass123"},
    )
    assert wrong.status_code == 400
    assert wrong.json()["detail"] == "wrong_password"

    changed = client.post(
        "/api/v1/users/me/password",
        headers=headers,
        json={"current_password": "Password123", "new_password": "NewPass123"},
    )
    assert changed.status_code == 200

    relogin = client.post(
        "/api/v1/auth/login",
        json={"email": "juan@smartcoco.ph", "password": "NewPass123"},
    )
    assert relogin.status_code == 200
