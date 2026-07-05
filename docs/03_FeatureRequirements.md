# 03 — Feature Requirements

## 3.1 User-Facing Features

### Authentication
- Register with name, email, password
- Login with email + password → returns JWT (access token; refresh token optional for v1)
- Passwords stored as salted hashes (never plaintext)

### Browse Events
- List all upcoming events (paginated)
- Each event card shows: name, category, date, location, seats remaining
- List is served from Redis cache when available (see 06_RedisUsage.md)

### Search Events
- Search by name, category, or location
- Optional filters: date range, "available seats only"

### Event Details
- Full event description
- Category-specific fields (see 04_DatabaseDesign.md — flexible schema)
- Live "seats remaining" count
- Register button (disabled if event is full or registration closed)

### Register for Event
- One registration per user per event (enforce via unique index)
- Validates capacity before confirming
- Triggers ticket + QR code generation (background task)
- Rate-limited to prevent abuse/spam registrations

### QR Code Ticket
- Each successful registration generates a unique ticket
- Ticket encodes a verifiable payload (e.g., registration ID + signature) as a QR code
- User can view/download ticket from "My Registrations"

### View Registration History
- List of all events the user has registered for
- Status: upcoming / attended / cancelled (if cancellation is supported)

## 3.2 Admin-Facing Features

### Create Event
- Admin-only endpoint
- Accepts category-specific fields (flexible payload)
- Sets capacity, registration deadline, category, location, date

### Update Event
- Edit any event field before it starts
- Cannot reduce capacity below current registration count

### Delete Event
- Soft-delete recommended (mark `isDeleted: true`) instead of hard delete, to preserve registration history/analytics

### Close Registration
- Manually close registration before capacity is reached (e.g., last-minute cutoff)

### View Registrations (per event)
- List of all users registered for a specific event
- Exportable (CSV) for offline use

### Event Analytics (Admin Dashboard)
- Top registered events
- Total registrations (platform-wide, and per event)
- Category-wise registration breakdown
- Monthly registration trends
- Upcoming events count

## 3.3 Explicit Non-Goals (v1)

To keep scope realistic for a solo/small-team build:
- No payment integration
- No seat-map / seat-number selection
- No push notifications infrastructure (Pub/Sub demo is enough; real push notification delivery is out of scope for v1)
- No multi-admin roles/permissions hierarchy (single "admin" role is enough)
- No social login (email/password only, unless you want to extend later)

## 3.4 Feature-to-Skill Mapping

| Feature | Primary Skill Demonstrated |
|---|---|
| Register/Login | JWT, Pydantic validation, password hashing |
| Browse/Search Events | MongoDB querying + indexing, Redis caching |
| Register for Event | Transactions/atomic capacity checks, background tasks |
| QR Ticket | Background tasks, file/byte generation, async I/O |
| Admin Analytics | MongoDB aggregation pipelines |
| Rate Limiting | Redis (fixed-window or sliding-window counters) |
| New Registration Notification | Redis Pub/Sub |
