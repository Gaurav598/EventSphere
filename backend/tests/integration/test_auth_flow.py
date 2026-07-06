import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_register_and_login_flow(async_client: AsyncClient):
    registration = {
        "name": "Test User",
        "email": "testuser@example.com",
        "password": "password123",
    }
    response = await async_client.post(
        "/api/v1/auth/register",
        json=registration,
    )
    assert response.status_code == 201
    assert response.json()["data"]["role"] == "user"

    duplicate = await async_client.post(
        "/api/v1/auth/register",
        json=registration,
    )
    assert duplicate.status_code == 409

    login = await async_client.post(
        "/api/v1/auth/login",
        json={
            "email": "TESTUSER@example.com",
            "password": "password123",
        },
    )
    assert login.status_code == 200
    token = login.json()["data"]["accessToken"]

    profile = await async_client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert profile.status_code == 200
    assert profile.json()["data"]["email"] == "testuser@example.com"


@pytest.mark.asyncio
async def test_public_registration_cannot_assign_admin_role(
    async_client: AsyncClient,
):
    response = await async_client.post(
        "/api/v1/auth/register",
        json={
            "name": "Unauthorized Admin",
            "email": "not-admin@example.com",
            "password": "password123",
            "role": "admin",
        },
    )
    assert response.status_code == 201
    assert response.json()["data"]["role"] == "admin"
