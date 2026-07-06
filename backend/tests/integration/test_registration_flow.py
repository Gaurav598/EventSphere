from datetime import datetime, timedelta, timezone

import pytest
from httpx import AsyncClient

from app.core.security import verify_ticket_payload


@pytest.mark.asyncio
async def test_registration_flow(
    async_client: AsyncClient,
    create_user,
):
    password = "strong-password"
    await create_user(
        name="Admin",
        email="admin@example.com",
        password=password,
        role="admin",
    )
    admin_login = await async_client.post(
        "/api/v1/auth/login",
        json={"email": "admin@example.com", "password": password},
    )
    admin_token = admin_login.json()["data"]["accessToken"]

    await async_client.post(
        "/api/v1/auth/register",
        json={
            "name": "User",
            "email": "user@example.com",
            "password": password,
        },
    )
    user_login = await async_client.post(
        "/api/v1/auth/login",
        json={"email": "user@example.com", "password": password},
    )
    user_token = user_login.json()["data"]["accessToken"]

    now = datetime.now(timezone.utc)
    event_data = {
        "name": "Test Event",
        "description": "Description",
        "category": "workshop",
        "location": "Online",
        "eventDate": (now + timedelta(days=30)).isoformat(),
        "registrationDeadline": (now + timedelta(days=29)).isoformat(),
        "capacity": 5,
    }
    created = await async_client.post(
        "/api/v1/admin/events",
        json=event_data,
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert created.status_code == 201
    event_id = created.json()["data"]["_id"]

    registration = await async_client.post(
        f"/api/v1/events/{event_id}/register",
        headers={"Authorization": f"Bearer {user_token}"},
    )
    assert registration.status_code == 201
    registration_id = registration.json()["data"]["registrationId"]

    duplicate = await async_client.post(
        f"/api/v1/events/{event_id}/register",
        headers={"Authorization": f"Bearer {user_token}"},
    )
    assert duplicate.status_code == 409

    mine = await async_client.get(
        "/api/v1/registrations/me",
        headers={"Authorization": f"Bearer {user_token}"},
    )
    assert mine.status_code == 200
    assert len(mine.json()["data"]) == 1
    assert mine.json()["data"][0]["event"]["name"] == "Test Event"

    admin_registrations = await async_client.get(
        f"/api/v1/admin/events/{event_id}/registrations",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert admin_registrations.status_code == 200
    assert len(admin_registrations.json()["data"]) == 1

    ticket = await async_client.get(
        f"/api/v1/registrations/{registration_id}/ticket",
        headers={"Authorization": f"Bearer {user_token}"},
    )
    assert ticket.status_code == 200
    assert verify_ticket_payload(ticket.json()["data"]["qrPayload"])

    events = await async_client.get("/api/v1/events")
    assert events.status_code == 200
    assert isinstance(events.json()["data"], list)
    assert events.json()["pagination"]["total"] == 1
