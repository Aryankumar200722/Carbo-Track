# CarboTrack — Institutional Emissions Intelligence
CarboTrack is a responsive institutional greenhouse-gas inventory platform for colleges, universities and campuses. The public estimator is an educational, anonymous experience; it is deliberately separate from the official institutional inventory.

## Deploy
Vercel project type: Other / static site. Framework preset: Other. Build command: leave blank. Output directory: `.`. Root directory: repository root. No Node build step is required. The public Supabase URL and publishable key are configured in `js/config.js`. Never expose a Supabase secret or service-role key in browser code.

## Supabase setup (run in this order)
1. Run `supabase/institutional-schema.sql` in the Supabase SQL Editor.
2. Run `supabase/departmental-access.sql` in the SQL Editor.
3. For development testing only, email confirmation can be disabled in Authentication → Sign In / Providers. Re-enable it and configure custom SMTP before production.
4. Register an account at `auth.html`. Create an institution workspace at `organization.html`.
5. Add campus buildings and facilities in `facilities.html`.
6. Register department staff at `team.html`. Staff must first create a CarboTrack account; an administrator then assigns their email to a department.
7. Enter daily or monthly activity at `data-entry.html`. Review totals in `dashboard.html` and export the activity register from `reports.html`.

## Department access
- Admin: full institution access and staff assignment.
- Institution data manager: broad activity data entry and review.
- Energy, fuel, transport, waste and procurement managers: submit activity records only for their assigned department.
- Viewer: read-only access.

The departmental SQL migration adds a department field and scoped insert/update policies. Run it after the institutional schema. It is designed to be rerun safely.

## Emission factors and quality
The CEA India grid factor seeded in the institutional schema is tagged with its source metadata for FY 2025–26. Other starter factors (diesel, petrol, LPG, landfill waste and paper) are provisional screening assumptions, not verified institution-specific lifecycle factors. Validate and document factors, reporting boundaries, gases, GWP basis, organisational consolidation approach, uncertainty and source evidence before formal disclosure.

## Current capabilities and roadmap
Implemented: public estimator; Supabase authentication; institution registration; facilities register; department role assignment for existing accounts; daily/monthly activity entry; factor snapshot at record time; scope-based dashboard; CSV activity export; responsive layout; persistent day/night theme toggle.

Planned before a production-grade deployment: secure file uploads and evidence review, invitation emails, MFA/SSO, audit-event history, factor approval/version workflow, sub-meter hierarchy, automated bill extraction with human verification, anomaly alerts, targets and baselines, multi-campus consolidation, data-quality scoring, and export formats aligned to the institution's selected reporting framework.

CarboTrack is a project prototype, not an audited or certified GHG accounting system. It must not be represented as a verified inventory until data controls and factor validation are complete.