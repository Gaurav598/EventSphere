import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_register_and_login_flow(async_client: AsyncClient):
    # Register
    register_data = {
        "name": "Test User",
        "email": "testuser@example.com",
        "password": "password123",
        "role": "user"
    }
    response = await async_client.post("/api/v1/auth/register", json=register_data)
    assert response.status_code == 201
    
    # Try to register again with same email
    response2 = await async_client.post("/api/v1/auth/register", json=register_data)
    assert response2.status_code == 409
    
    # Login
    login_data = {
        "email": "testuser@example.com",
        "password": "password123"
    }
    login_response = await async_client.post("/api/v1/auth/login", json=login_data)
    assert login_response.status_code == 200
    
    data = login_response.json()
    assert data["success"] is True
    assert "accessToken" in data["data"]
    
    # Get Profile
    token = data["data"]["accessToken"]
    profile_response = await async_client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert profile_response.status_code == 200
    assert profile_response.json()["data"]["email"] == "testuser@example.com"
