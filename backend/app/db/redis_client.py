import logging

from redis.asyncio import Redis
from redis.exceptions import RedisError

from app.core.config import settings

logger = logging.getLogger(__name__)


class RedisClient:
    client: Redis | None = None


redis_db = RedisClient()


async def connect_to_redis() -> None:
    logger.info("Connecting to Redis...")
    client = Redis.from_url(
        settings.REDIS_URL,
        decode_responses=True,
        socket_connect_timeout=settings.REDIS_SOCKET_TIMEOUT_SECONDS,
        socket_timeout=settings.REDIS_SOCKET_TIMEOUT_SECONDS,
    )
    try:
        await client.ping()
    except RedisError:
        await client.aclose()
        redis_db.client = None
        logger.warning("Redis is unavailable; cache, rate limiting, and Pub/Sub are disabled")
        return
    redis_db.client = client
    logger.info("Connected to Redis")


async def close_redis_connection() -> None:
    logger.info("Closing Redis connection...")
    if redis_db.client is not None:
        await redis_db.client.aclose()
    redis_db.client = None
    logger.info("Redis connection closed")


def get_redis() -> Redis | None:
    return redis_db.client


async def invalidate_event_cache() -> None:
    redis = get_redis()
    if redis is None:
        return
    try:
        keys = [key async for key in redis.scan_iter(match="events:list:*", count=100)]
        if keys:
            await redis.delete(*keys)
    except RedisError:
        logger.warning("Failed to invalidate event cache", exc_info=True)
