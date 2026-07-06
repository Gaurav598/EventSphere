# EventSphere

A production-grade Event Management Platform where organizations create and manage events, and users discover and register for them.

## Architecture Decisions

- **FastAPI**: Selected for its asynchronous capabilities, exceptional performance, and robust type-hinting support via Pydantic, ensuring strong API contracts.
- **MongoDB**: Used as the primary database due to its flexible document schema, making it ideal for storing dynamic event structures and scaling horizontally.
- **Redis**: Provides high-performance in-memory caching to reduce database load on heavy read operations (e.g. browsing events) and acts as a message broker for background tasks.
- **Flutter**: Chosen for its single-codebase cross-platform capabilities, enabling the creation of performant, natively compiled applications for iOS, Android, and Web from one codebase.
- **Docker**: Containerization ensures absolute consistency across development, testing, and production environments, eliminating "it works on my machine" issues.
- **JWT (JSON Web Tokens)**: Used for stateless, secure authentication. It allows horizontal scaling of the backend API without managing session state in a centralized database.
- **BackgroundTasks (FastAPI/Starlette)**: Utilized over Celery for lightweight, inline background processing (such as QR generation and caching). It reduces infrastructure overhead (no need for Celery workers/beat) while meeting the immediate performance needs of the application.

## Tech Stack
| Layer | Technology |
|---|---|
| Mobile Frontend | Flutter |
| Backend API | FastAPI (Python) |
| Primary Database | MongoDB |
| Cache / Pub-Sub | Redis |
| Containerization | Docker + Docker Compose |
| Testing | Pytest |

## Prerequisites
- Docker and Docker Compose
- Flutter SDK (for mobile/web development)
- Python 3.11+ (for local backend development)

## Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone <repository_url>
   cd eventsphere
   ```

2. **Configure the environment:**
   ```bash
   cp .env.example .env
   ```
   *(Update `JWT_SECRET` in `.env` for production environments)*

3. **Start the application:**
   ```bash
   docker compose up --build -d
   ```

## Local Development
The `docker-compose.override.yml` is automatically used by Docker Compose to bind-mount the backend directory into the container. Code changes to the FastAPI backend will trigger an automatic reload via uvicorn.

- **API Base URL**: `http://localhost:8000/api/v1`
- **API Interactive Docs (Swagger)**: `http://localhost:8000/docs`
- **Health Check**: `http://localhost:8000/health`

## Testing

### Backend
To run tests locally within the container:
```bash
docker compose exec fastapi pytest -v
```

### Frontend
```bash
cd frontend
flutter analyze
flutter test
```

## API Documentation
Full API specification and architectural documentation are available in the [`docs/`](./docs) directory.

## Project Structure
- `/backend`: FastAPI application source code, models, routers, and services.
- `/frontend`: Flutter application, providers, UI screens, and core networking.
- `/docs`: Markdown files for system architecture, database design, and feature requirements.
- `docker-compose.yml`: Production-ready service definitions.
- `docker-compose.override.yml`: Local development overrides (bind mounts).

## Screenshots
*(Insert screenshots of the User and Admin flows here)*
