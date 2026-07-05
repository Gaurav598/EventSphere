import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
@pytest.mark.skip(reason="Fakeredis HELLO command compatibility issue with redis-py 5+")
async def test_rate_limiting(async_client: AsyncClient):
    login_data = {
        "email": "ratelimit@example.com",
        "password": "wrongpassword"
    }
    
    # Send 5 requests (should pass limit check, but fail login)
    for _ in range(5):
        resp = await async_client.post("/api/v1/auth/login", json=login_data)
        assert resp.status_code == 401 # Invalid credentials

    # 6th request should hit rate limit (429)
    resp_limited = await async_client.post("/api/v1/auth/login", json=login_data)
    assert resp_limited.status_code == 429
    assert resp_limited.json()["error"]["code"] == "RATE_LIMIT_EXCEEDED"
