# 08 — Backend Architecture (FastAPI)

## Responsibilities Recap

Authentication, business logic, validation, authorization, database access, Redis integration, background tasks — all centralized here. Flutter never talks to Mongo/Redis directly.

## Recommended Folder Structure

```
backend/
├── app/
│   ├── main.py                 # FastAPI app instance, router registration, middleware
│   ├── core/
│   │   ├── config.py           # Settings (env vars via Pydantic BaseSettings)
│   │   ├── security.py         # JWT creation/verification, password hashing
│   │   └── logging.py          # Logging configuration
│   ├── db/
│   │   ├── mongo.py            # MongoDB client/connection setup
│   │   └── redis_client.py     # Redis client setup
│   ├── models/                 # Pydantic models (request/response schemas)
│   │   ├── user.py
│   │   ├── event.py
│   │   ├── registration.py
│   │   └── ticket.py
│   ├── routers/                # API route definitions
│   │   ├── auth.py
│   │   ├── events.py
│   │   ├── registrations.py
│   │   └── admin.py
│   ├── services/                # Business logic (kept separate from routers)
│   │   ├── auth_service.py
│   │   ├── event_service.py
│   │   ├── registration_service.py
│   │   └── analytics_service.py
│   ├── dependencies/            # Dependency-injection providers
│   │   ├── auth.py              # get_current_user, require_admin
│   │   └── rate_limit.py
│   ├── background/               # Background task functions
│   │   └── ticket_generator.py
│   ├── middleware/
│   │   └── logging_middleware.py
│   └── exceptions/
│       └── handlers.py           # Custom exception handlers
├── tests/
├── requirements.txt
└── Dockerfile
```

## Key Concepts & Where They Apply

### JWT
- `core/security.py`: `create_access_token()`, `decode_token()`
- Token payload: `{ "sub": user_id, "role": "user|admin", "exp": ... }`

### Dependency Injection
- `dependencies/auth.py`:
  - `get_current_user(token: str = Depends(oauth2_scheme))` → decodes JWT, fetches user, raises 401 if invalid
  - `require_admin(user = Depends(get_current_user))` → raises 403 if `user.role != "admin"`
- Routers simply declare `current_user: User = Depends(get_current_user)` — FastAPI resolves it automatically

### Pydantic
- Separate models for **input** (e.g. `EventCreate`) vs **output** (e.g. `EventResponse`) vs **DB representation** — avoids leaking internal fields (like password hashes) in API responses

### Async APIs
- Use an async Mongo driver (e.g. `motor`) so route handlers can be declared `async def` and actually benefit from non-blocking I/O
- Redis client should also be used in its async form (e.g. `redis.asyncio`)

### Background Tasks
- FastAPI's built-in `BackgroundTasks` is enough for v1 (e.g., generating the QR ticket after registration is confirmed, so the API response isn't blocked on image generation)
- For anything heavier/long-running in the future, a dedicated task queue (Celery, RQ, or Arq) would be the next step — out of scope for v1

### Custom Exception Handling
- `exceptions/handlers.py`: register handlers for domain exceptions like `EventFullException`, `DuplicateRegistrationException` → map to clean HTTP responses instead of raw 500s

### Global Middleware
- Logging middleware: log method, path, status code, response time for every request
- CORS middleware: configured for the Flutter app's origin(s)

### Configuration
- `core/config.py` using Pydantic `BaseSettings` to load from environment variables (`.env` file locally, real env vars in Docker/production):
  - `MONGO_URI`, `REDIS_URL`, `JWT_SECRET`, `JWT_EXPIRE_MINUTES`, etc.

## Layering Principle

**Routers** → thin, only handle request/response shape and call into **Services**
**Services** → contain actual business logic, call into **DB layer**
**DB layer** → raw Mongo/Redis operations only

This keeps business logic testable independent of HTTP, which matters directly for 10_TestingStrategy.md (unit-testing services without spinning up the whole API).
