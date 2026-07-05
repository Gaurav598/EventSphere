# 04 — Database Design (MongoDB)

## Why MongoDB Over a Relational DB Here

Different event types carry fundamentally different fields:

```json
// Workshop
{
  "name": "Docker Workshop",
  "speaker": "XYZ",
  "duration": "3 Hours"
}
```

```json
// Hackathon
{
  "name": "Hackathon",
  "teamSize": 4,
  "prize": 50000
}
```

```json
// Seminar
{
  "name": "AI Seminar",
  "certificate": true
}
```

Modeling this in a relational DB would mean either a giant sparse table with dozens of nullable columns, or a maze of category-specific side tables. MongoDB's document model lets each event store exactly the fields relevant to its category, inside one flexible collection — this is a genuinely appropriate use case for MongoDB, not just a "because we're learning it" choice.

## Collections

### 1. `users`

```json
{
  "_id": "ObjectId",
  "name": "string",
  "email": "string (unique, indexed)",
  "passwordHash": "string",
  "role": "user | admin",
  "createdAt": "datetime",
  "updatedAt": "datetime"
}
```

### 2. `events`

```json
{
  "_id": "ObjectId",
  "name": "string",
  "description": "string",
  "category": "string (workshop | hackathon | seminar | meetup | webinar | contest)",
  "location": "string",
  "eventDate": "datetime",
  "registrationDeadline": "datetime",
  "capacity": "number",
  "registeredCount": "number (denormalized counter, kept in sync on registration)",
  "isRegistrationOpen": "boolean",
  "isDeleted": "boolean (soft delete flag)",
  "createdBy": "ObjectId (ref: users._id, admin who created it)",
  "categoryFields": "object (flexible, category-specific — e.g. { speaker, duration } or { teamSize, prize })",
  "createdAt": "datetime",
  "updatedAt": "datetime"
}
```

> Note: `registeredCount` is a denormalized field. It trades a small amount of write complexity (must be kept accurate, ideally via atomic `$inc` at registration time) for much faster reads on "seats remaining" checks — this is a deliberate, common MongoDB pattern rather than an accident.

### 3. `registrations`

```json
{
  "_id": "ObjectId",
  "userId": "ObjectId (ref: users._id)",
  "eventId": "ObjectId (ref: events._id)",
  "status": "confirmed | cancelled",
  "registeredAt": "datetime"
}
```

- **Unique compound index** on `(userId, eventId)` to enforce "one registration per user per event".

### 4. `tickets`

```json
{
  "_id": "ObjectId",
  "registrationId": "ObjectId (ref: registrations._id, unique)",
  "qrPayload": "string (signed/encoded string embedded in the QR code)",
  "qrImageRef": "string (path or base64 reference to generated QR image)",
  "isValid": "boolean",
  "generatedAt": "datetime"
}
```

## Recommended Indexes

| Collection | Index | Purpose |
|---|---|---|
| `users` | `email` (unique) | Fast login lookup, enforce uniqueness |
| `events` | `eventDate` | Sort/filter upcoming events |
| `events` | `category` | Filter by category |
| `events` | `location` | Search by location |
| `events` | Text index on `name`, `description` | Search functionality |
| `registrations` | `(userId, eventId)` (unique compound) | Prevent duplicate registration |
| `registrations` | `eventId` | Fast "list registrations for event" |
| `tickets` | `registrationId` (unique) | 1:1 lookup from registration to ticket |

## Aggregation Pipeline Examples

### Top Registered Events
```json
[
  { "$group": { "_id": "$eventId", "totalRegistrations": { "$sum": 1 } } },
  { "$sort": { "totalRegistrations": -1 } },
  { "$limit": 5 }
]
```

### Category-Wise Registration Counts
```json
[
  { "$lookup": { "from": "events", "localField": "eventId", "foreignField": "_id", "as": "event" } },
  { "$unwind": "$event" },
  { "$group": { "_id": "$event.category", "count": { "$sum": 1 } } }
]
```

### Monthly Registration Trend
```json
[
  { "$group": {
      "_id": { "$dateToString": { "format": "%Y-%m", "date": "$registeredAt" } },
      "count": { "$sum": 1 }
  }},
  { "$sort": { "_id": 1 } }
]
```

### Upcoming Events Count
```json
[
  { "$match": { "eventDate": { "$gte": "ISODate(now)" }, "isDeleted": false } },
  { "$count": "upcomingEvents" }
]
```

## Data Integrity Notes

- Registration capacity checks + `registeredCount` increment should happen as atomically as possible (e.g., a single `findOneAndUpdate` with a capacity guard condition) to avoid race conditions when multiple users register concurrently near full capacity.
- Prefer soft deletes (`isDeleted: true`) for events so historical registrations/analytics remain valid even after an event is "removed" from public listings.
