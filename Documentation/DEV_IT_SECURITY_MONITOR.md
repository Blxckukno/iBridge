# Dev/IT Security Attack Monitoring

## What was added
- Restricted API endpoint: `/api/security/attacks`
- Internal monitoring page: `Website/TicketingSystem/frontend/security-attacks.html`

Only users in Dev/IT roles/departments (via JWT) or users with the internal key can access the endpoint.

## Access options
1. JWT role/department access:
   - Allowed roles: `admin`, `developer`, `devops`, `security`, `it`
   - Allowed departments containing: `it`, `dev`, `developer`, `security`, `technology`
2. Internal key access:
   - Set `INTERNAL_SECURITY_KEY` in backend environment
   - Send header `X-Internal-Security-Key: <your key>`

## Example (PowerShell)
```powershell
$env:INTERNAL_SECURITY_KEY="replace-with-strong-secret"
cd BackendServices\backend
python app.py
```

Then open:
- `http://<host>:5000/TicketingSystem/frontend/security-attacks.html`

Enter the same key in the page and click **Load Attack Feed**.

## Notes
- If no security events exist yet, the feed will return `0` events.
- Events are read from `logs/security-events.log`.
