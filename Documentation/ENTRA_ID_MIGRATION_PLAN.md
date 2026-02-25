# Entra ID Migration Plan (Post-Showcase)

## Objective
Replace showcase login (`staff-login.html`) with Microsoft Entra ID (Azure AD) SSO while preserving Staff Portal authorization.

## Phase 1: Azure Setup
- Create App Registration for iBridge Staff Portal.
- Configure redirect URI(s):
  - `https://<domain>/staff-login.html`
  - `https://<domain>/auth/callback` (recommended future endpoint)
- Enable ID tokens and access tokens.
- Define app roles: `Admin`, `IT`, `Dev`, `Staff`.

## Phase 2: Frontend Auth Refactor
- Replace build-mode/session login with MSAL.js login redirect.
- Use Entra ID ID token claims for role mapping.
- Keep a safe break-glass admin local key for emergency support.

## Phase 3: Backend Validation
- Validate JWT issuer/audience against Entra metadata.
- Map Entra groups/roles to portal authorization.
- Keep `/api/security/attacks` restricted to `Dev/IT/Admin` only.

## Phase 4: Cutover
- Disable showcase build-mode button.
- Enforce SSO-only for portal pages.
- Add rollout window + rollback plan.
