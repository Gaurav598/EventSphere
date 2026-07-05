from fastapi import Request
from app.db.redis_client import get_redis
from app.exceptions.handlers import AppException

class RateLimiter:
    def __init__(self, key_prefix: str, limit: int, window: int):
        self.key_prefix = key_prefix
        self.limit = limit
        self.window = window

    async def __call__(self, request: Request):
        redis = get_redis()
        client_ip = request.client.host if request.client else "127.0.0.1"
        
        # If user is logged in, use user ID, else IP
        user_ident = client_ip
        if hasattr(request.state, "user_id"):
             user_ident = request.state.user_id
             
        key = f"ratelimit:{self.key_prefix}:{user_ident}"
        
        # Fixed window rate limiting
        try:
            current = await redis.incr(key)
            if current == 1:
                await redis.expire(key, self.window)
                
            if current > self.limit:
                raise AppException(
                    code="RATE_LIMIT_EXCEEDED", 
                    message=f"Too many requests. Please try again later.", 
                    status_code=429
                )
        except AppException:
            raise
        except Exception as e:
            # If Redis fails, we should log it and allow the request (fail-open)
            import logging
            logging.getLogger(__name__).warning(f"Rate limiter failed, failing open: {e}")
            pass
