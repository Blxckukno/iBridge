# iBridge Full-Stack Enhancement Checklist

Date: 2026-02-24

## Completed in this pass

1. CMS content model and APIs
- Added `CMSContent` model in `BackendServices/backend/models.py`.
- Added APIs:
  - `GET /api/cms/content`
  - `PUT /api/cms/content/<section>` (protected)
  - `GET /api/cms/case-studies`
  - `POST /api/cms/case-studies` (protected)
  - `GET /api/cms/testimonials`
  - `POST /api/cms/testimonials` (protected)
- Seeded default case studies and testimonials in backend startup.

2. Lead pipeline (backend)
- Added `Lead` model in `BackendServices/backend/models.py`.
- Added APIs:
  - `POST /api/leads` (public capture)
  - `GET /api/leads` (protected)
  - `PUT /api/leads/<id>/status` (protected)
- Added duplicate-submission protection window.

3. Integration event queue tracking
- Added `IntegrationEvent` model in `BackendServices/backend/models.py`.
- Lead capture now queues CRM integration events.
- Added API:
  - `GET /api/integrations/events` (Dev/IT only)

4. Observability metrics
- Added request ID and response-time headers on all backend responses:
  - `X-Request-ID`
  - `X-Response-Time-Ms`
- Added ops metrics endpoint:
  - `GET /api/ops/metrics` (Dev/IT or internal key)

5. Main-site dynamic professional blocks
- Added frontend dynamic loader: `Website/js/main-site-dynamic.js`.
- Added styling: `Website/css/main-site-dynamic.css`.
- Wired into main page: `Website/index.html`.
- Renders:
  - operational trust signals
  - case studies (from CMS API)
  - testimonials (from CMS API)
- Includes API fallback logic for both `:5000` and `:8080` serving modes.

6. Contact form full-stack lead capture
- Updated `Website/contact.html` submit flow to:
  - `POST /api/leads`
  - `POST /api/contact`
- Added API fallback logic for both `:5000` and `:8080`.

## Outstanding (next recommended sequence)

1. Entra ID / Azure deployment integration
- Add OIDC configuration, callback handling, session mapping, and role claims enforcement.

2. Report jobs and scheduler
- Background task queue for scheduled exports/reports.

3. CRM actual delivery worker
- Retries, dead-letter queue, webhook signatures.

4. Admin content editor UI
- Staff portal screens for managing case studies/testimonials without API tools.

5. Production hardening
- Redis rate-limit storage, HTTPS termination, secret vault integration, and log shipping.
