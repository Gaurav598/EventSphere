import logging

from fastapi import Request
from redis.exceptions import RedisError

from app.db.redis_client import get_redis
from app.exceptions.handlers import AppException

logger = logging.getLogger(__name__)


class RateLimiter:
    def __init__(self, key_prefix: str, limit: int, window: int):
        self.key_prefix = key_prefix
        self.limit = limit
        self.window = window

    async def __call__(self, request: Request) -> None:
        client_ip = request.client.host if request.client else "unknown"
        await self.check(client_ip)

    async def check(self, identifier: str) -> None:
        redis = get_redis()
        if redis is None:
            logger.warning("Rate limiter unavailable; failing open")
            return

        key = f"ratelimit:{self.key_prefix}:{identifier}"
        try:
            created = await redis.set(key, 1, ex=self.window, nx=True)
            current = 1 if created else await redis.incr(key)
            if current == 1 and not created:
                await redis.expire(key, self.window)
            if current > self.limit:
                raise AppException(
                    code="RATE_LIMIT_EXCEEDED",
                    message="Too many requests. Please try again later.",
                    status_code=429,
                )
        except AppException:
            raise
        except RedisError:
            logger.warning("Rate limiter failed; failing open", exc_info=True)
