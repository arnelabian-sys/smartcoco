"""Classification + history tests."""

from conftest import admin_headers, user_headers

PNG_BYTES = bytes.fromhex(
    "89504e470d0a1a0a0000000d4948445200000001000000010806000000"
    "1f15c4890000000a49444154789c63000100000500010d0a2db40000"
    "000049454e44ae426082"
)


def test_upload_returns_a_prediction(client):
    headers = user_headers(client)
    response = client.post(
        "/api/v1/predictions",
        headers=headers,
        files={"file": ("coconut.png", PNG_BYTES, "image/png")},
    )
    assert response.status_code == 201, response.text
    body = response.json()
    assert body["status"] == "success"
    assert body["variety"]["code"] in {"TALL", "DWARF", "HYBRID"}
    assert 0.72 <= body["confidence"] <= 0.99
    assert body["image_path"].startswith("predictions/")


def test_empty_photo_is_reported_as_empty(client):
    headers = user_headers(client)
    response = client.post(
        "/api/v1/predictions",
        headers=headers,
        files={"file": ("empty.png", b"", "image/png")},
    )
    assert response.status_code == 201
    body = response.json()
    assert body["status"] == "empty"
    assert body["variety"] is None
    assert body["error_message"]


def test_broken_photo_returns_422(client):
    headers = user_headers(client)
    response = client.post(
        "/api/v1/predictions",
        headers=headers,
        files={"file": ("error.png", PNG_BYTES, "image/png")},
    )
    assert response.status_code == 422
    assert response.json()["detail"] == "classification_failed"


def test_rejects_unsupported_file_types(client):
    headers = user_headers(client)
    response = client.post(
        "/api/v1/predictions",
        headers=headers,
        files={"file": ("notes.txt", b"hello", "text/plain")},
    )
    assert response.status_code == 415


def test_history_is_private_and_paginated(client):
    juan = user_headers(client, email="juan@smartcoco.ph")
    nena = user_headers(client, email="nena@smartcoco.ph")

    for _ in range(2):
        client.post(
            "/api/v1/predictions",
            headers=juan,
            files={"file": ("coconut.png", PNG_BYTES, "image/png")},
        )

    mine = client.get("/api/v1/predictions", headers=juan)
    assert mine.status_code == 200
    assert len(mine.json()) == 2

    other = client.get("/api/v1/predictions", headers=nena)
    assert other.status_code == 200
    assert other.json() == []

    admin = client.get("/api/v1/predictions", headers=admin_headers(client))
    assert len(admin.json()) == 2


def test_single_prediction_is_protected(client):
    juan = user_headers(client, email="juan@smartcoco.ph")
    nena = user_headers(client, email="nena@smartcoco.ph")
    created = client.post(
        "/api/v1/predictions",
        headers=juan,
        files={"file": ("coconut.png", PNG_BYTES, "image/png")},
    ).json()

    assert (
        client.get(f"/api/v1/predictions/{created['id']}", headers=juan).status_code
        == 200
    )
    assert (
        client.get(f"/api/v1/predictions/{created['id']}", headers=nena).status_code
        == 403
    )
    image = client.get(f"/api/v1/predictions/{created['id']}/image", headers=juan)
    assert image.status_code == 200
    assert image.headers["content-type"].startswith("image/")


def test_statistics_for_staff(client):
    juan = user_headers(client)
    client.post(
        "/api/v1/predictions",
        headers=juan,
        files={"file": ("coconut.png", PNG_BYTES, "image/png")},
    )
    client.post(
        "/api/v1/predictions",
        headers=juan,
        files={"file": ("empty.png", b"", "image/png")},
    )

    assert client.get("/api/v1/predictions/stats", headers=juan).status_code == 403

    stats = client.get("/api/v1/predictions/stats", headers=admin_headers(client))
    assert stats.status_code == 200
    body = stats.json()
    assert body["total"] == 2
    assert body["success"] == 1
    assert body["empty"] == 1
    assert body["average_confidence"] is not None
    assert body["by_variety"][0]["count"] == 1
