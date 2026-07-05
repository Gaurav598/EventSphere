# 10 — Testing Strategy

## Tooling
- **Pytest** as the test runner
- `httpx.AsyncClient` (or FastAPI's `TestClient`) for API-level tests
- `mongomock` / a dedicated test MongoDB instance for isolating DB tests (recommend a real Mongo test container over mocking where possible, for higher-fidelity tests)
- `fakeredis` (optional) or a real Redis test instance for Redis-dependent tests

## Test Categories

### Unit Tests (2–3 minimum, more encouraged)
Target the **service layer** in isolation (see 08_BackendArchitecture.md layering), without going through HTTP:
1. `test_password_hashing.py` — verify hash + verify functions work correctly and reject wrong passwords
2. `test_jwt_creation.py` — verify token creation and decoding round-trips correctly, and that an expired/tampered token is rejected
3. `test_event_capacity_logic.py` — verify the "is event full" business rule correctly blocks registration when `registeredCount >= capacity`

### Integration Tests (2–3 minimum, more encouraged)
Target real interactions between components (API + DB, API + Redis):
1. `test_register_and_login_flow.py` — hit `/auth/register` then `/auth/login`, assert a valid JWT is returned
2. `test_event_registration_flow.py` — create an event (as admin), register a user, assert `registeredCount` increments and a `registrations` document is created
3. `test_rate_limiting.py` — hit `/auth/login` repeatedly beyond the threshold, assert a `429` is eventually returned

### API/Contract Tests
- Assert response shape matches expected Pydantic response models (status codes, required fields present)
- Can be folded into integration tests rather than a fully separate category for a project this size

## Test Environment Setup

- Use a **separate test database** (e.g. `eventsphere_test`) — never run tests against your dev/prod MongoDB
- Consider a `docker-compose.test.yml` that spins up throwaway Mongo/Redis containers just for the test run, torn down after
- Use Pytest fixtures (`conftest.py`) to:
  - Provide a test client
  - Provide a clean DB state before each test (or per test module)
  - Provide a helper to create a test user/admin + get a valid JWT for authenticated test requests

## Example Test Structure

```
tests/
├── conftest.py
├── unit/
│   ├── test_password_hashing.py
│   ├── test_jwt_creation.py
│   └── test_event_capacity_logic.py
└── integration/
    ├── test_auth_flow.py
    ├── test_event_registration_flow.py
    └── test_rate_limiting.py
```

## What "Done" Looks Like for Testing (v1)

- [ ] At least 3 unit tests passing, covering core business rules
- [ ] At least 3 integration tests passing, covering the two most critical flows (auth, registration)
- [ ] Tests run via a single command, e.g. `pytest -v`
- [ ] Tests do not depend on or pollute your real dev database
