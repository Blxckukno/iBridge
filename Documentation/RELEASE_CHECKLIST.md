# Release Checklist

## Pre-release
- Confirm backend health: `/api/health` is `200`.
- Import latest ticket CSV.
- Run `AutomationScripts/run-daily-ops.ps1`.
- Review newest file under `Documentation/reports/`.
- Confirm no missing links/handlers/API calls in sweep.

## Security
- Ensure production secrets are set (`SECRET_KEY`, `JWT_SECRET_KEY`, `INTERNAL_SECURITY_KEY`).
- Verify `/api/security/attacks` returns `403` without key.
- Verify `/api/security/attacks` returns `200` with Dev/IT key.
- Review `logs/security-events.log`.

## Functional
- Main site pages load and nav is consistent.
- Staff Portal access only through `staff-login.html`.
- Dashboard metrics match imported ticket dataset.
- Ticket activity renders imported entries.

## Final
- Create backup snapshot.
- Publish release notes.
- Execute stakeholder demo script.
