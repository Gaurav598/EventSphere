import pytest
import asyncio
from httpx import AsyncClient
from mongomock_motor import AsyncMongoMockClient
import fakeredis.aioredis

from app.main import app
from app.db import mongo, redis_client
from app.core.config import settings

@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

@pytest.fixture(autouse=True)
async def setup_db_and_redis():
    # Mock MongoDB
    mongo.db.client = AsyncMongoMockClient()
    mongo.db.db = mongo.db.client[settings.MONGO_DB_NAME]
    
    # Mock Redis
    redis_client.redis_db.client = fakeredis.aioredis.FakeRedis(decode_responses=True, version=(6, 2))
    
    yield
    
    # Cleanup
    if mongo.db.client:
         pass # AsyncMongoMockClient doesn't strictly need close() in tests but we can add if needed
    if redis_client.redis_db.client:
         await redis_client.redis_db.client.close()

@pytest.fixture
async def async_client():
    async with AsyncClient(app=app, base_url="http://test") as client:
        yield client
