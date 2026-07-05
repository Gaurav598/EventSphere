# 06 — Redis Usage

Redis is included for three concrete, justified use cases — not just because it's "expected" in the stack.

## 1. Caching — Popular Events / `GET /events`

**Problem it solves**: `GET /events` will be the most frequently hit endpoint. Without caching, every page load hits MongoDB.

**Design**:
- Cache key pattern: `events:list:page:{page}:filters:{hash_of_filters}`
- TTL: 5 minutes (short enough that new events / capacity changes appear reasonably fresh)
- On cache hit → return cached JSON, skip MongoDB entirely
- On cache miss → query MongoDB → `SET` the result with `EX 300` → return response
- **Cache invalidation**: when an admin creates/updates/deletes an event, proactively delete relevant cache keys (or use a short TTL and accept brief staleness — acceptable for this use case)

**Pseudo-flow**:
```
GET /events?page=1
  → key = "events:list:page:1"
  → value = redis.get(key)
  → if value exists: return value
  → else:
      data = mongo.find(...)
      redis.set(key, json(data), ex=300)
      return data
```

## 2. Rate Limiting — Login & Registration APIs

**Problem it solves**: prevent brute-force login attempts and spam/bulk registration abuse.

**Design** (fixed-window counter, simplest correct approach):
- Key pattern: `ratelimit:login:{ip_or_user_id}` and `ratelimit:register:{user_id}`
- On each request:
  1. `INCR` the key
  2. If the key was just created (count == 1), set an expiry (e.g. `EXPIRE key 60`)
  3. If count exceeds threshold (e.g. 5 login attempts per 60s, or 10 registrations per hour per user) → return `429 Too Many Requests`

**Suggested thresholds** (tune as needed — these are starting points, not hard requirements):
| Endpoint | Limit |
|---|---|
| `POST /auth/login` | 5 attempts / 60 seconds per IP |
| `POST /events/{id}/register` | 10 attempts / 60 minutes per user |

> A sliding-window or token-bucket algorithm is more accurate than fixed-window, but fixed-window via `INCR` + `EXPIRE` is simple, well-understood, and enough to demonstrate the concept correctly.

## 3. Pub/Sub — New Registration Notification

**Problem it solves**: when a registration happens, other parts of the system (e.g., an admin live-dashboard, a notification worker) should be able to react without polling MongoDB.

**Design**:
- Channel name: `registration.created`
- On successful registration, FastAPI publishes:
```json
{
  "eventId": "...",
  "userId": "...",
  "registrationId": "...",
  "timestamp": "..."
}
```
- A subscriber process (can be a simple background task or a separate small worker script) listens on `registration.created` and, for v1, can simply log it / update an in-memory counter that an admin "live" endpoint reads. Full push-notification delivery is out of scope (see 03_FeatureRequirements.md non-goals).

## 4. (Optional) Session/Profile Cache

- Cache a user's profile (`user:profile:{user_id}`) after first fetch to avoid repeated Mongo lookups for frequently-accessed profile data (e.g., displaying "Welcome, {name}" on every screen).
- Optional for v1 — only add if time permits, since it's the least differentiated of the four use cases.

## Redis Data Structures Used

| Use Case | Redis Type | Commands |
|---|---|---|
| Caching | String (JSON blob) | `GET`, `SET ... EX` |
| Rate Limiting | String (counter) | `INCR`, `EXPIRE` |
| Pub/Sub | Pub/Sub channel | `PUBLISH`, `SUBSCRIBE` |
| Session Cache (optional) | String (JSON blob) | `GET`, `SET ... EX` |

## Failure Mode Consideration

If Redis becomes unavailable, the app should **not** go down:
- Caching: fall back to a direct MongoDB query (slower, but functional)
- Rate limiting: fail-open or fail-closed is a deliberate choice — document whichever you pick (fail-open = allow the request through if Redis is down, prioritizing availability; fail-closed = reject, prioritizing protection)
- Pub/Sub: non-critical path — if publish fails, log and continue; it should never block the registration response
