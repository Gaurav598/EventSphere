import logging
from redis import asyncio as aioredis
from app.core.config import settings

logger = logging.getLogger(__name__)

class RedisClient:
    client: aioredis.Redis = None

redis_db = RedisClient()

async def connect_to_redis():
    logger.info("Connecting to Redis...")
    redis_db.client = aioredis.from_url(
        settings.REDIS_URL, 
        decode_responses=True,
        protocol=2
    )
    logger.info("Connected to Redis")

async def close_redis_connection():
    logger.info("Closing Redis connection...")
    if redis_db.client:
        await redis_db.client.close()
    logger.info("Redis connection closed")

def get_redis() -> aioredis.Redis:
    return redis_db.client
