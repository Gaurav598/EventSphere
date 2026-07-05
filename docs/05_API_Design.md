# 05 — API Design

## Conventions

- Base path: `/api/v1`
- Auth: `Authorization: Bearer <JWT>` header on protected routes
- Response envelope (suggested):
```json
{
  "success": true,
  "data": {},
  "message": "string"
}
```
- Error envelope:
```json
{
  "success": false,
  "error": { "code": "string", "message": "string" }
}
```

## Auth Endpoints

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/auth/register` | none | Create a new user account |
| POST | `/auth/login` | none | Authenticate, returns JWT. **Rate-limited.** |
| GET | `/auth/me` | user | Get current logged-in user's profile |

## Event Endpoints (Public / User)

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/events` | none | List events (paginated, filterable). **Redis-cached.** |
| GET | `/events/{event_id}` | none | Get single event details |
| GET | `/events/search?q=` | none | Search events by name/category/location |

## Registration Endpoints (User)

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/events/{event_id}/register` | user | Register for an event. **Rate-limited.** |
| GET | `/registrations/me` | user | List current user's registrations |
| GET | `/registrations/{registration_id}/ticket` | user | Get QR ticket for a registration |

## Admin — Event Management

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/admin/events` | admin | Create a new event |
| PUT | `/admin/events/{event_id}` | admin | Update an event |
| DELETE | `/admin/events/{event_id}` | admin | Soft-delete an event |
| PATCH | `/admin/events/{event_id}/close-registration` | admin | Close registration manually |
| GET | `/admin/events/{event_id}/registrations` | admin | List all registrations for an event |
| GET | `/admin/events/{event_id}/registrations/export` | admin | Export registrations as CSV |

## Admin — Analytics

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/admin/analytics/top-events` | admin | Top registered events |
| GET | `/admin/analytics/category-wise` | admin | Category-wise registration counts |
| GET | `/admin/analytics/monthly-trend` | admin | Monthly registration trend |
| GET | `/admin/analytics/summary` | admin | Total registrations, upcoming events count, etc. |

## Sample Request/Response

### `POST /auth/login`
Request:
```json
{ "email": "user@example.com", "password": "secret123" }
```
Response:
```json
{
  "success": true,
  "data": { "accessToken": "eyJ...", "tokenType": "bearer" },
  "message": "Login successful"
}
```

### `POST /events/{event_id}/register`
Response (success):
```json
{
  "success": true,
  "data": { "registrationId": "665f...", "status": "confirmed" },
  "message": "Registration successful. Ticket is being generated."
}
```
Response (event full):
```json
{
  "success": false,
  "error": { "code": "EVENT_FULL", "message": "This event has reached full capacity." }
}
```

## Status Codes Used

| Code | Meaning |
|---|---|
| 200 | Success |
| 201 | Resource created |
| 400 | Validation error |
| 401 | Missing/invalid token |
| 403 | Authenticated but not authorized (e.g. non-admin hitting admin route) |
| 404 | Resource not found |
| 409 | Conflict (e.g. duplicate registration) |
| 422 | Pydantic validation failure (FastAPI default) |
| 429 | Rate limit exceeded |
| 500 | Internal server error |

## Pagination Convention

Query params: `?page=1&limit=20`
Response includes:
```json
{
  "data": [...],
  "pagination": { "page": 1, "limit": 20, "total": 134, "totalPages": 7 }
}
```
