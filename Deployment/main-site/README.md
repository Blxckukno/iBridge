# Main Site Deployment Package

This folder contains the public main website only.

## Included
- Public pages: index, about, services, team, careers, contact, privacy, terms, security-policy
- Static assets: css, js, images, assets
- SEO/security basics: robots.txt, security.txt, manifest.json

## GitHub Pages
1. Push to `main` branch.
2. In GitHub: `Settings > Pages` set Source to `GitHub Actions`.
3. Workflow `.github/workflows/deploy-main-site.yml` will deploy this folder.

## Domain
1. In GitHub Pages settings, set your custom domain.
2. Add DNS records at your domain host:
   - `A` records to GitHub Pages IPs, or
   - `CNAME` to `<your-username>.github.io`.
3. Enable HTTPS in Pages settings after DNS propagates.

## Notes
- This package excludes internal staff portal/ticketing/intranet apps.
- If you want `Staff Portal` nav to point to a separate URL, update nav links in included HTML files.
