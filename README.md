# EventSphere

A production-grade Event Management Platform where organizations create and manage events, and users discover and register for them.

## Tech Stack
| Layer | Technology |
|---|---|
| Mobile Frontend | Flutter |
| Backend API | FastAPI (Python) |
| Primary Database | MongoDB |
| Cache / Rate-Limit / Pub-Sub | Redis |
| Containerization | Docker + Docker Compose |
| Testing | Pytest |

## Quickstart

Run the following command to start the backend, MongoDB, and Redis:

```bash
docker compose up --build
```

- **API Base URL**: `http://localhost:8000/api/v1`
- **API Interactive Docs**: `http://localhost:8000/docs`

## Documentation

Full project documentation is available in the [`docs/`](./docs) directory.

## Testing

Run tests in the backend container:

```bash
cd backend
pytest -v
```
