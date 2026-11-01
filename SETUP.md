# CarboTrack institutional emissions tracker
CarboTrack is an institutional greenhouse-gas inventory tool for colleges and universities, not a personal carbon-footprint calculator.

Workflow: create an institution workspace; register buildings and facilities; record electricity, fuel, waste and procurement activity; apply emission factors with provenance; review monthly and Scope 1/2/3 totals; export the activity register.

Static HTML/CSS/JavaScript deployment: Vercel Framework Other, no build command, root output. Supabase public URL and publishable key are in js/config.js. Never put a service-role or secret key in browser code.

Run supabase/institutional-schema.sql in the Supabase SQL Editor. It adds institutional tables alongside the earlier prototype tables. Sign in through auth.html, create an institution workspace, register facilities in facilities.html, then enter data through data-entry.html. The first workspace creator becomes admin.

The CEA India FY 2025–26 grid factor is seeded with source metadata. Diesel, petrol, LPG, landfill waste and paper factors are provisional screening assumptions and must be validated/replaced before formal reporting. Evidence filenames are references only; file upload is not yet enabled. This prototype is not audited or certified.