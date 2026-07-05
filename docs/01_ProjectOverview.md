# 01 — Project Overview

## Project Name
**EventSphere** (working name — can be changed later)

## One-Line Description
A production-grade Event Management Platform where organizations create and manage events, and users discover and register for them.

## What This Project Is NOT
- Not a ticket-resale/box-office platform like BookMyShow
- Not a ride-hailing/matching platform like Uber
- No payment gateway, no seat-map booking, no movie/show domain logic

## What This Project IS
A practical, real-world platform for managing:
- College Fests
- Hackathons
- Tech Meetups
- Workshops
- Seminars
- Coding Contests
- Webinars

## The Real-World Problem

Colleges and communities running multiple events (e.g. 20 events during a fest) today typically face:

| Problem | Current (Broken) Approach |
|---|---|
| Registration collection | Google Forms |
| Data storage | Excel sheets |
| Capacity tracking | Manual, error-prone |
| Ticketing | No QR / verification system |
| Insights | No analytics at all |
| Admin visibility | No live view of registrations |

**EventSphere solves all of the above** with a single platform: structured event creation, live registration tracking, QR-based tickets, and an analytics dashboard for admins.

## Actors & Capabilities

### User
- Signup / Login
- Browse Events
- Search Events
- Register for an Event
- Download QR Ticket
- View Registration History

### Admin
- Login
- Create Event
- Edit Event
- Delete Event
- Close Registration
- View Analytics
- Export Registration Data

## Why This Project Is a Strong Learning/Portfolio Project

It naturally forces you to use — not just "tick off" — every major backend/mobile skill:

- **MongoDB**: flexible, per-category event schemas + aggregation pipelines
- **Redis**: caching, rate limiting, pub/sub — each tied to a real use case, not decorative
- **FastAPI**: full CRUD, JWT auth, dependency injection, async, background tasks
- **Flutter**: a real multi-screen app consuming the same backend
- **Docker**: multi-container local environment (FastAPI + MongoDB + Redis)
- **Testing**: unit + integration tests with Pytest
- **Deployment**: containerized, cloud-provider-agnostic deployment

## High-Level Tech Stack

| Layer | Technology |
|---|---|
| Mobile Frontend | Flutter |
| Backend API | FastAPI (Python) |
| Primary Database | MongoDB |
| Cache / Rate-Limit / Pub-Sub | Redis |
| Containerization | Docker + Docker Compose |
| Testing | Pytest |
| Deployment | Docker Compose (self-hosted) / Render (optional) |

## Success Criteria (Definition of Done for v1)

- [ ] User can sign up, log in, browse/search events, register, and get a QR ticket
- [ ] Admin can create/edit/delete events and see live registration counts
- [ ] At least 3 MongoDB aggregation-based analytics are live on the admin dashboard
- [ ] Redis caching measurably reduces DB hits on `GET /events`
- [ ] Rate limiting is active on login and registration endpoints
- [ ] A pub/sub channel fires on new registration and is consumed by at least one subscriber
- [ ] Entire backend stack runs via a single `docker compose up`
- [ ] Core flows covered by unit + integration tests
