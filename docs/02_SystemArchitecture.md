# 02 — System Architecture

## High-Level Architecture Diagram

```
                        Flutter App (Mobile Client)
                                    │
                          REST API calls (HTTPS/JSON)
                                    │
                          ┌─────────────────────┐
                          │   FastAPI Backend    │
                          │  (Auth, Business     │
                          │   Logic, Validation) │
                          └─────────┬───────────┘
                    ┌───────────────┴───────────────┐
                    │                               │
            ┌───────▼────────┐             ┌────────▼────────┐
            │    MongoDB      │             │      Redis       │
            │ (Persistent     │             │ (Cache, Rate     │
            │  Data Store)    │             │  Limit, Pub/Sub) │
            └─────────────────┘             └──────────────────┘
```

## Component Responsibilities

### Flutter App
- Renders UI (login, browse, search, event details, registration, tickets, admin dashboard)
- Talks only to FastAPI over REST
- Stores JWT locally (secure storage) for authenticated requests
- Renders QR ticket (from a base64/QR-payload returned by the API)

### FastAPI Backend
- Single source of truth for business logic
- Authenticates users (JWT-based)
- Validates all inbound data (Pydantic schemas)
- Talks to MongoDB for persistence
- Talks to Redis for caching, rate limiting, and pub/sub
- Runs background tasks (e.g., ticket generation, notification dispatch)

### MongoDB
- Stores Users, Events, Registrations, Tickets
- Chosen for schema flexibility across different event types (see 04_DatabaseDesign.md)

### Redis
- **Cache**: reduces load on MongoDB for hot read paths (e.g. `GET /events`)
- **Rate Limiter**: protects login & registration endpoints from abuse
- **Pub/Sub**: broadcasts "new registration" events to any live listeners (e.g., admin dashboard, notification worker)

## Request Flow Examples

### Example 1: Browsing Events (Cache Hit Path)
1. Flutter calls `GET /events`
2. FastAPI checks Redis cache key (e.g. `events:list:page1`)
3. If cache hit → return cached JSON directly (Mongo is never touched)
4. If cache miss → query MongoDB → store result in Redis with TTL → return response

### Example 2: User Registers for an Event
1. Flutter calls `POST /events/{id}/register` with JWT
2. FastAPI validates JWT → checks rate limit for this user/IP
3. FastAPI checks event capacity in MongoDB
4. If capacity available → create a `registrations` document → trigger background task to generate ticket + QR
5. FastAPI publishes a `registration.created` event to a Redis Pub/Sub channel
6. Response returned to user with registration confirmation; ticket becomes available shortly after (via background task)

### Example 3: Admin Views Analytics
1. Flutter (admin) calls `GET /admin/analytics`
2. FastAPI runs MongoDB aggregation pipelines (top events, category-wise counts, monthly trends)
3. Result optionally cached briefly in Redis (analytics don't need to be real-time to the second)
4. JSON response rendered as charts/tables in Flutter admin dashboard

## Why This Architecture

- **Separation of concerns**: Flutter never talks to MongoDB/Redis directly — everything is mediated by FastAPI. This keeps business rules centralized and the mobile app "dumb" (a good practice).
- **Cache-aside pattern** for Redis: simple, well-understood, and directly demonstrates a real caching strategy rather than an artificial one.
- **Async-first backend**: FastAPI's async support lets I/O-bound calls (Mongo, Redis) run without blocking, which matters once concurrent users start hitting the same endpoints.

## Non-Functional Considerations

| Concern | Approach |
|---|---|
| Scalability | Stateless FastAPI containers behind a reverse proxy (can scale horizontally) |
| Security | JWT auth, password hashing (bcrypt/argon2), input validation via Pydantic |
| Observability | Structured logging + basic request/response logging middleware |
| Resilience | Redis used as a cache, not as the source of truth — if Redis is down, app should degrade gracefully to direct Mongo reads |
