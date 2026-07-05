# 09 — Docker & Deployment

## Containers

| Service | Image | Purpose |
|---|---|---|
| `fastapi` | Custom (built from `backend/Dockerfile`) | Backend API |
| `mongodb` | `mongo:latest` (pin a specific version once you decide) | Primary database |
| `redis` | `redis:latest` (pin a specific version once you decide) | Cache / rate-limit / pub-sub |

> I'm not fully certain what the current recommended stable tags are at the time you build this — check Docker Hub for `mongo` and `redis` directly and pin an explicit version (e.g. `mongo:7`, `redis:7`) rather than relying on `latest`, since `latest` can change under you and break reproducibility.

## Example `docker-compose.yml` (illustrative skeleton — adjust to your actual code)

```yaml
version: "3.9"

services:
  fastapi:
    build: ./backend
    ports:
      - "8000:8000"
    environment:
      - MONGO_URI=mongodb://mongodb:27017
      - REDIS_URL=redis://redis:6379
      - JWT_SECRET=${JWT_SECRET}
    depends_on:
      - mongodb
      - redis
    volumes:
      - ./backend:/app

  mongodb:
    image: mongo:7
    ports:
      - "27017:27017"
    volumes:
      - mongo_data:/data/db

  redis:
    image: redis:7
    ports:
      - "6379:6379"

volumes:
  mongo_data:
```

## One-Command Startup

```
docker compose up --build
```

This should bring up FastAPI + MongoDB + Redis together, with FastAPI able to reach the other two via their service names (`mongodb`, `redis`) as hostnames — this is one of the main benefits of Compose's default network.

## Environment Variables

Use a `.env` file (not committed to git) for secrets like `JWT_SECRET`. Add `.env` to `.gitignore`.

## Deployment Strategy (No AWS)

Per project scope, AWS/EC2 is explicitly **not** used for deployment. Documented deployment options instead:

### Option 1: Docker Compose Deployment (Recommended for this project)
- Deploy the same `docker-compose.yml` on any VM/server you already have access to (or a free-tier VM from any provider)
- This is the most "portable" option and matches exactly what you tested locally

### Option 2: Render (Optional)
- Render supports deploying from a Dockerfile or `docker-compose`-like multi-service setup
- I'm not fully certain of Render's current exact feature set/pricing for multi-container deployments — verify directly on Render's official docs before committing to this path, since PaaS platform features change over time.

### Option 3: Local Production Simulation
- Run `docker compose up` on your own machine/college server and treat it as a "production-like" environment for demo purposes
- Perfectly acceptable for a portfolio project where the goal is to demonstrate the architecture, not to run a live public service indefinitely

## Production Hygiene Checklist (Even for a Local/Demo Deployment)

- [ ] `.env` file excluded from version control
- [ ] MongoDB/Redis not exposed on public ports if deployed on a shared/public VM (bind to `127.0.0.1` or use Docker's internal network only)
- [ ] FastAPI running behind a reverse proxy (e.g. Nginx) if publicly accessible, with HTTPS via Let's Encrypt/Certbot
- [ ] Health-check endpoint (e.g. `GET /health`) for container orchestration to verify readiness
