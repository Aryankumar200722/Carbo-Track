# CarboTrack institutional emissions tracker
CarboTrack is a campus greenhouse-gas inventory tool, not a personal carbon-footprint calculator.

Workflow: create institution workspace; register campus facilities; record electricity, fuel, waste and procurement activity; apply emission factors with provenance; review monthly and scope totals; export activity register.

Deploy as static HTML/CSS/JavaScript on Vercel (Framework Other, no build command, output directory root). Supabase public URL and publishable key are in js/config.js. Never place a service-role or secret key in browser code.

Run supabase/institutional-schema.sql in Supabase SQL Editor. This adds institutional tables and leaves the previous prototype tables intact. Sign in through auth.html, then create an institution workspace. The first creator becomes admin. The current UI includes workspace creation, activity entry, dashboard and CSV reporting; facility-management and invitations UI remain to be added.

The CEA India FY 2025–26 grid factor is seeded as an official-source factor. Other seeded factors are provisional screening assumptions and must be validated/replaced before formal reporting. Evidence filenames are references only; file upload is not yet enabled. The system is not audited or certified.