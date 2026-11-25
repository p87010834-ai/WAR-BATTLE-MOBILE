# WAR BATTLE MOBILE — website

Static landing page for the WAR BATTLE MOBILE project.

## Cloudflare Pages deployment

1. In Cloudflare Dashboard open **Workers & Pages** → **Create** → **Pages** → **Connect to Git**.
2. Select repository `p87010834-ai/WAR-BATTLE-MOBILE` and branch `main`.
3. Framework preset: **None**.
4. Build command: leave empty.
5. Build output directory: `website`.
6. Deploy. Cloudflare will assign a `*.pages.dev` address (the exact available subdomain is chosen during setup).

The site is a static HTML page and requires no build step or paid service. It does not yet include a backend, account system, news CMS, or download hosting.
