# Public Site Governance Backlog

Last updated: March 10, 2026

## Completed in code

- Public main-site pages no longer depend on third-party font or icon CDNs.
- Static legal links are present in public HTML footers.
- Cookie notice includes an itemized storage register for current browser storage keys.
- Placeholder public analytics has been disabled until real production IDs are configured.
- Public security policy, accessibility statement, sitemap, and robots controls were refreshed.
- Contact-form abuse controls were added:
  - honeypot field
  - browser-side rate limiting
  - minimum form-fill time
  - submit lock while sending
- Backend-ready compliance logging endpoints were added:
  - `POST /api/compliance/consent`
  - `GET /api/compliance/consent`
  - `POST /api/compliance/requests`
  - `GET /api/compliance/requests`
- Server-side retention windows now apply to compliance logs:
  - consent logs: 400 days
  - rights requests: 5 years
- Public deploy sync is now scriptable through `AutomationScripts/build-main-site-deploy.ps1`

## Still requires business or legal confirmation

1. Confirm the named Information Officer and deputy details for publication.
2. Confirm the formal PAIA private-body manual reference or hosted location.
3. Confirm which company disclosures should be public:
   - registration number
   - VAT number
   - formal B-BBEE credential wording
4. Legal review and sign-off of:
   - `Website/privacy.html`
   - `Website/cookie-notice.html`
   - `Website/compliance.html`
   - `Website/terms.html`
   - `Website/security-policy.html`

## Still requires production platform work

1. Put the final public site behind infrastructure that supports real header enforcement:
   - strict CSP
   - HSTS
   - managed WAF
   - bot and rate-abuse controls
   - shared rate-limit storage such as Redis via `RATELIMIT_STORAGE_URI`
2. Add uptime monitoring and deploy alerts.
3. Add production backup and restore validation for the published site.
4. Add server-side consent and request review dashboards for operations or legal reviewers if needed.

## Deploy checklist

1. Run `AutomationScripts/build-main-site-deploy.ps1`
2. Review `Deployment/main-site`
3. Commit the synced deploy bundle
4. Push to the publish branch
5. Hard-refresh the live site after GitHub Pages updates
