# 11 — Folder Structure (Monorepo)

```
event-management/
├── backend/
│   ├── app/
│   │   ├── main.py
│   │   ├── core/
│   │   ├── db/
│   │   ├── models/
│   │   ├── routers/
│   │   ├── services/
│   │   ├── dependencies/
│   │   ├── background/
│   │   ├── middleware/
│   │   └── exceptions/
│   ├── tests/
│   ├── requirements.txt
│   ├── Dockerfile
│   └── .env.example
│
├── frontend/
│   └── (Flutter project — see 07_FlutterArchitecture.md for internal lib/ structure)
│
├── docker/
│   ├── docker-compose.yml
│   └── docker-compose.test.yml
│
├── docs/
│   ├── 01_ProjectOverview.md
│   ├── 02_SystemArchitecture.md
│   ├── 03_FeatureRequirements.md
│   ├── 04_DatabaseDesign.md
│   ├── 05_API_Design.md
│   ├── 06_RedisUsage.md
│   ├── 07_FlutterArchitecture.md
│   ├── 08_BackendArchitecture.md
│   ├── 09_DockerDeployment.md
│   ├── 10_TestingStrategy.md
│   ├── 11_FolderStructure.md
│   └── 12_FutureEnhancements.md
│
├── tests/                     # (optional top-level, if you prefer tests outside backend/)
│
├── scripts/
│   ├── seed_db.py             # Populate sample events/users for local dev/demo
│   └── export_registrations.py
│
├── .gitignore
└── README.md
```

## Notes on This Structure

- `backend/` and `frontend/` are kept fully independent — each could be extracted into its own repo later without much friction.
- `docker/` centralizes compose files so root-level clutter is minimized; alternatively `docker-compose.yml` can live at repo root if you prefer `docker compose up` to work from the top without a `-f` flag — either is fine, just be consistent in the README.
- `docs/` mirrors exactly the 12-document plan you already laid out — keeping the numbering in filenames preserves reading order in any file explorer or GitHub view.
- `scripts/` holds one-off utility scripts (DB seeding for demos, CSV export helper) that aren't part of the running application itself.

## Root `README.md` Should Contain (Minimum)

1. Project name + one-line description
2. Tech stack table
3. Quickstart: `docker compose up` instructions
4. Link to `/docs` folder for full documentation
5. API base URL + link to interactive docs (FastAPI auto-generates these at `/docs` via Swagger UI)
6. Test run instructions
7. Screenshots/GIFs of the Flutter app (once built) — this matters a lot for portfolio presentation
