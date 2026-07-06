import asyncio
import logging

from redis.exceptions import RedisError

from app.db.redis_client import get_redis

logger = logging.getLogger(__name__)


async def consume_registration_events() -> None:
    redis = get_redis()
    if redis is None:
        return

    pubsub = redis.pubsub()
    try:
        await pubsub.subscribe("registration.created")
        async for message in pubsub.listen():
            if message["type"] == "message":
                logger.info("Consumed registration.created event: %s", message["data"])
    except asyncio.CancelledError:
        raise
    except RedisError:
        logger.warning("Registration subscriber stopped after a Redis error", exc_info=True)
    finally:
        await pubsub.aclose()
