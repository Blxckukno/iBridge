# Ticket Intake + LMS Resource Integration

## 1) Multi-channel Ticket Intake API

Endpoint:
- `POST /api/tickets/intake`

Purpose:
- Create IT tickets from external channels (email parser, chatbot, webhook, forms).
- Automatically returns `ticket_number` in format `IBR-000001`.

Headers:
- `Content-Type: application/json`
- `X-Intake-Key: <value>` (optional now, required when `IBRIDGE_INTAKE_KEY` env var is set)

Payload example:
```json
{
  "source": "chatbot",
  "title": "VPN not connecting",
  "description": "User cannot connect from home office",
  "priority": "high",
  "category": "network",
  "requester": {
    "name": "Jane Doe",
    "email": "jane.doe@ibridge.co.za",
    "phone": "+27 11 000 0000",
    "department": "Operations"
  },
  "channel_id": "teams-chat-123",
  "external_message_id": "msg-456",
  "labels": ["remote", "vpn"],
  "context": {
    "device": "Windows 11",
    "location": "Johannesburg"
  }
}
```

Response example:
```json
{
  "message": "Ticket created from intake",
  "ticket_number": "IBR-000147",
  "ticket": {
    "id": 147,
    "ticket_number": "IBR-000147",
    "title": "VPN not connecting"
  }
}
```

Audit feed for Dev/IT:
- `GET /api/tickets/intake/events`
- Requires authenticated Dev/IT role.

## 2) LMS Curated Training Resources

Data source file:
- `Website/data/lms-training-resources.json`

Tracks currently mapped:
- `web-development`
- `data-science`
- `cybersecurity`

Read resources:
- `GET /api/lms/training-resources`
- Optional filter: `GET /api/lms/training-resources?track=cybersecurity`

Track interactions:
- `POST /api/lms/training-resources/<resource_id>/start`
- `POST /api/lms/training-resources/<resource_id>/complete`

Completion behavior:
- Logs activity in `ActivityLog`.
- Applies progress delta to the matched LMS course enrollment.
- Updates user progress tracking.

## 3) Frontend Wiring

LMS UI updates:
- `Website/lms-platform.html`
- Added **Curated Training Resources** panel with:
  - `Open` button (logs start + opens resource URL)
  - `Mark Complete` button (logs completion + updates progress)

Auth helper updates:
- `Website/js/ibridge-auth.js`
- Added methods:
  - `createIntakeTicket(...)`
  - `getLmsTrainingResources(...)`
  - `startLmsTrainingResource(...)`
  - `completeLmsTrainingResource(...)`

## 4) Runtime Note

After code changes:
1. Restart backend:
   - `python BackendServices/backend/app.py`
2. Hard refresh frontend (`Ctrl+F5`).

