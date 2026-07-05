# 07 — Flutter Architecture

## Screens

| Screen | Purpose |
|---|---|
| Splash | App load, check stored JWT, route to Home or Login |
| Login | Email/password login |
| Signup | New user registration |
| Home / Event List | Browse events, pull-to-refresh, pagination |
| Search | Search + filter events |
| Event Details | Full event info, Register button |
| QR Ticket | Display generated QR ticket after registration |
| My Registrations | List of user's past/upcoming registrations |
| Profile | Basic user info, logout |
| Admin Dashboard | Analytics overview (charts/numbers) |
| Admin — Create/Edit Event | Form to create or update an event |

> Note: this is 10-11 screens total once split out logically; the "5-6 screens" estimate in the original brief bundles some of these together (e.g., Login+Signup as one flow, Profile folded into a drawer). Both groupings are fine — pick whichever keeps the app simple to build first, and split further later if needed.

## Recommended Architecture Pattern

**Layered / feature-first structure** with a lightweight state management solution (Provider or Riverpod — both are reasonable choices; pick one you're comfortable with rather than both).

```
lib/
├── main.dart
├── core/
│   ├── api/            # Dio/http client setup, interceptors (JWT attach)
│   ├── constants/
│   ├── theme/
│   └── utils/
├── models/              # Event, User, Registration, Ticket (data classes)
├── services/            # AuthService, EventService, RegistrationService
├── providers/           # State management (Provider/Riverpod notifiers)
├── screens/
│   ├── auth/
│   ├── home/
│   ├── search/
│   ├── event_details/
│   ├── registrations/
│   ├── ticket/
│   ├── profile/
│   └── admin/
└── widgets/             # Shared/reusable UI components
```

## Networking Layer

- Use `dio` (recommended over raw `http` for interceptor support) or `http` package
- Central API client with:
  - Base URL (configurable per environment — local Docker vs deployed)
  - Interceptor to attach `Authorization: Bearer <token>` on every request (except auth endpoints)
  - Interceptor to handle 401 → clear stored token → redirect to login

## Local Storage

- `flutter_secure_storage` for storing the JWT (avoid plain `shared_preferences` for tokens)
- `shared_preferences` acceptable for non-sensitive UI state (e.g., "seen onboarding")

## State Management Flow (Example: Event List)

1. `EventListProvider` calls `EventService.getEvents(page)`
2. `EventService` calls the FastAPI `/events` endpoint via the API client
3. Response mapped to `List<Event>` model objects
4. Provider updates state → UI rebuilds (loading → data / error states handled explicitly)

## QR Ticket Display

- Backend returns either a QR image (base64 PNG) or a raw payload string
- If raw payload: use a Flutter QR-generation package (e.g. `qr_flutter`) to render it client-side
- If base64 image: decode and display via `Image.memory`

## Error/Loading UX Pattern

Every screen fetching data should explicitly handle 3 states:
- Loading (skeleton/spinner)
- Error (retry button + readable message)
- Empty (e.g., "No events found" / "You haven't registered for anything yet")

## Admin Dashboard Charts

- Use a Flutter charting package (e.g. `fl_chart` or `syncfusion_flutter_charts`) to render:
  - Bar chart: category-wise registrations
  - Line chart: monthly registration trend
  - Simple stat cards: total registrations, upcoming events count, top event

## Build Order Recommendation

1. Auth screens (Login/Signup) + token storage
2. Event List + Event Details (read-only flows first)
3. Registration flow + QR ticket
4. My Registrations
5. Admin: Create/Edit Event
6. Admin: Analytics dashboard (last, since it depends on data existing from earlier flows)
