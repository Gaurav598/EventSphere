import asyncio
from contextlib import asynccontextmanager, suppress

from fastapi import FastAPI, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from redis.exceptions import RedisError
from starlette.middleware.trustedhost import TrustedHostMiddleware

from app.background.registration_subscriber import consume_registration_events
from app.core.config import settings
from app.core.logging import setup_logging
from app.db.mongo import (
    close_mongo_connection,
    connect_to_mongo,
    get_database,
)
from app.db.redis_client import (
    close_redis_connection,
    connect_to_redis,
    get_redis,
)
from app.exceptions.handlers import add_exception_handlers
from app.middleware.logging_middleware import LoggingMiddleware
from app.routers import admin, auth, events, registrations

setup_logging()


@asynccontextmanager
async def lifespan(app: FastAPI):
    await connect_to_mongo()
    await connect_to_redis()
    subscriber_task = None
    if get_redis() is not None:
        subscriber_task = asyncio.create_task(consume_registration_events())
    try:
        yield
    finally:
        if subscriber_task is not None:
            subscriber_task.cancel()
            with suppress(asyncio.CancelledError):
                await subscriber_task
        await close_redis_connection()
        await close_mongo_connection()


app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

allow_all_origins = settings.cors_origins == ["*"]
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=not allow_all_origins,
    allow_methods=["*"],
    allow_headers=["*"],
)
if settings.allowed_hosts != ["*"]:
    app.add_middleware(
        TrustedHostMiddleware,
        allowed_hosts=settings.allowed_hosts,
    )
app.add_middleware(LoggingMiddleware)
add_exception_handlers(app)


@app.get("/health")
async def health_check():
    checks = {"mongodb": "ok", "redis": "disabled"}
    try:
        await get_database().command("ping")
    except Exception:
        checks["mongodb"] = "unavailable"

    redis = get_redis()
    if redis is not None:
        try:
            await redis.ping()
            checks["redis"] = "ok"
        except RedisError:
            checks["redis"] = "unavailable"

    is_ready = checks["mongodb"] == "ok"
    payload = {
        "status": (
            "ok"
            if is_ready and checks["redis"] == "ok"
            else "degraded"
            if is_ready
            else "unavailable"
        ),
        "version": settings.VERSION,
        "checks": checks,
    }
    if not is_ready:
        return JSONResponse(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            content=payload,
        )
    return payload


app.include_router(
    auth.router,
    prefix=f"{settings.API_V1_STR}/auth",
    tags=["auth"],
)
app.include_router(
    events.router,
    prefix=f"{settings.API_V1_STR}/events",
    tags=["events"],
)
app.include_router(
    registrations.router,
    prefix=settings.API_V1_STR,
    tags=["registrations"],
)
app.include_router(
    admin.router,
    prefix=f"{settings.API_V1_STR}/admin",
    tags=["admin"],
)
