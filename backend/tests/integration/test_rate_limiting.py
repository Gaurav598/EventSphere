import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_login_rate_limiting(async_client: AsyncClient):
    login_data = {
        "email": "ratelimit@example.com",
        "password": "wrongpassword",
    }
    for _ in range(5):
        response = await async_client.post(
            "/api/v1/auth/login",
            json=login_data,
        )
        assert response.status_code == 401

    limited = await async_client.post(
        "/api/v1/auth/login",
        json=login_data,
    )
    assert limited.status_code == 429
    assert limited.json()["error"]["code"] == "RATE_LIMIT_EXCEEDED"
