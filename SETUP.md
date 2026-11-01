# CarboTrack setup

## Current implementation
This repository is a fresh, independently authored implementation using HTML5, CSS3, vanilla JavaScript, Tailwind CDN utilities and Chart.js. The calculator, result report and seven-day challenge run locally using browser storage. No framework build step is required.

## Run locally
1. Clone this repository.
2. Open the folder in VS Code.
3. Start a local static server (VS Code Live Server is fine).
4. Open index.html.

## Supabase integration (next phase)
The current UI intentionally does not pretend that cloud authentication, verified campus leaderboard data or multi-device sync are active. To enable these features:
1. Create a Supabase project.
2. Add a config file containing the project URL and anon key (never commit service-role keys).
3. Add Supabase Auth with email verification.
4. Apply the SQL schema in supabase/schema.sql.
5. Implement authenticated result submission and RLS-protected reads.
6. Add profile, challenge and leaderboard queries.

## Deployment
Deploy the repository root as a static site using GitHub Pages, Netlify or Vercel. No Node build command is required. Ensure the root directory is selected and index.html is the entry point.

## Before academic or institutional use
Replace the illustrative factors in js/app.js with documented India-relevant emission factors. Record source, geography, year, unit and uncertainty for each factor. Validate category boundaries and avoid mixing household and personal scopes. Treat the current result as an educational estimate, not an audited inventory.

## Roadmap
- Supabase authentication, profile and saved calculations
- Campus-level verified leaderboard with privacy controls
- Challenge streaks and completion certificates
- Factor library with sources, versions and uncertainty
- Accessibility audit, automated tests and offline/PWA support