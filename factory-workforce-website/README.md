# Factory Workforce Management System
Static multi-page website (no build step) that stores everything in Supabase, so it works from any phone or computer.
Pages: index (sign in / sign up), contractor-*.html (8 pages), worker-*.html (6 pages).

## One-time Supabase setup
1. Supabase dashboard > SQL Editor > New query > paste `supabase/schema.sql` > Run. (Safe to run again after updates.)
2. Authentication > Sign In / Providers > Email: switch **Confirm email** OFF. (Users sign in with a user ID, not a real email.)
3. The project URL and publishable key are already set at the top of `assets/app.js` (`SB_URL`, `SB_KEY`).
   User IDs are stored as `<id>@fwms.app`; if Supabase ever rejects that address as invalid, change `ID_DOMAIN` in `assets/app.js`.

## Deploy
Upload this folder to a GitHub repository, then Vercel > Add New > Project > import it > Deploy (no build settings needed).

## How it works
- Contractor: Sign up on the first page, then fill in Settings. Add workers under Workers > Add New Worker (this creates the worker's login with a temporary password).
- Worker: signs in with the user ID and password the contractor gave, checks in and out, and sees published payslips.
- No demo accounts and no sample data.

## Limits
- There is no email or SMS password reset. Reset a forgotten password from Supabase > Authentication > Users.
- Worker passwords can be changed by the worker; the contractor cannot reset them from the app.
- Settings other than PF rate, ESI rate and half-day rate are saved but not yet used in calculations.
