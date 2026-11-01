# CarboTrack — complete project setup

## Run locally
Open the project in VS Code and use Live Server on `index.html`. The static calculator, local profile and challenge tracker work without an account.

## Pages
- `index.html` — landing page
- `calculator.html` / `results.html` — six-category footprint estimate and chart report
- `dashboard.html` / `profile.html` — personal overview and local profile
- `challenge.html` / `certificate.html` — seven-day challenge and printable certificate
- `leaderboard.html` — opt-in campus leaderboard landing state
- `auth.html` — Supabase sign-up/sign-in interface
- `about.html`, `methodology.html`, `privacy.html` — project, methodology and privacy disclosures

## Enable Supabase
1. Create a Supabase project.
2. Open Project Settings → API and copy the Project URL and anon/public key.
3. Put both values in `js/config.js`. Never use a service_role key in browser code.
4. Run `supabase/schema.sql` in the Supabase SQL Editor.
5. In Supabase Auth, configure email verification and allowed redirect URLs for your deployed site.
6. Test sign-up, email confirmation and sign-in before enabling public accounts.

The included schema applies row-level security so users can access their own profiles, results and challenge progress. The leaderboard view is limited to users who opt in. Review and test policies before real institutional use.

## Emission-factor warning
The starter calculator currently uses simplified illustrative factors. Replace them with documented, India-relevant factors before using the result for academic research, institutional reporting or public ranking. Store factor source, year, geography, unit and uncertainty with every factor set.

## GitHub Pages
Repository Settings → Pages → Deploy from a branch → `main` → `/ (root)`. Remove the custom domain while testing the default GitHub Pages URL. Configure DNS and custom domain only after the default URL works.
