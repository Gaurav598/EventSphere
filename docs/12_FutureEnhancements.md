# 12 — Future Enhancements (Post-v1)

These are intentionally **out of scope for v1** (see 03_FeatureRequirements.md non-goals) but worth documenting so scope creep doesn't happen mid-build, and so you have a credible "roadmap" section for interviews/portfolio.

## Product Enhancements
- Payment integration for paid events (e.g. Razorpay/Stripe)
- Seat-map / seat-number selection for physical venues
- Multi-level admin roles (super-admin, event-manager, read-only viewer)
- Event check-in flow: admin scans user's QR ticket at the venue to mark attendance
- Event feedback/ratings after attendance
- Waitlist system when an event reaches capacity
- Recurring events (e.g. weekly meetups)
- Social login (Google/GitHub OAuth)

## Technical Enhancements
- Replace FastAPI `BackgroundTasks` with a real task queue (Celery/Arq) for heavier async workloads
- Real push notification delivery (FCM) subscribing to the existing `registration.created` Pub/Sub channel
- WebSocket-based live admin dashboard (instead of polling), fed by the same Pub/Sub events
- Full-text search upgrade via a dedicated search engine (e.g. MongoDB Atlas Search or Elasticsearch) if search needs outgrow basic text indexes
- API rate limiting upgraded from fixed-window to sliding-window/token-bucket for more accurate throttling
- Horizontal scaling: multiple FastAPI containers behind a load balancer, with Redis remaining the shared cache/coordination layer
- CI/CD pipeline (GitHub Actions) running the Pytest suite automatically on every push
- Structured monitoring/alerting (e.g. Prometheus + Grafana) instead of basic logging

## Data/Analytics Enhancements
- Predictive analytics: expected turnout based on historical registration patterns
- Admin export enhancements: PDF reports, not just CSV
- Per-event revenue reporting (once payments exist)

## Why This Document Matters

Keeping this list separate from the core 12-doc plan protects the actual build timeline — it's easy to let "just one more feature" creep into v1 and stall the project. This document is the parking lot for good ideas that come up during development; they get written here instead of built immediately.
