# Service Booking

Flutter + Supabase app: customers book coin-priced services by location and
time slot; providers manage their own bookings; admins manage services,
locations, availability, provider assignments, users, and see all bookings.

## Run it
1. Follow `SUPABASE_SETUP.md` to create the schema and RPCs, and to bootstrap
   the first admin account.
2. Set the `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` repository
   secrets/variables in GitHub (Settings → Secrets and variables → Actions).
3. Push to `main`/`master` (or tag `vX.Y.Z`) — `.github/workflows/flutter.yml`
   runs `flutter analyze` + `flutter test`, then builds a release APK
   (and an AAB on tags).

## Project layout
- `supabase/` — SQL to run, in order: `schema.sql`, `rpc.sql`,
  `rpc_admin.sql`, `rpc_provider.sql`, then `seed_admin.sql` once.
- `lib/screens/customer` — browse, book, my bookings.
- `lib/screens/admin` — services, locations, availability, provider
  assignments, users & roles, bookings overview.
- `lib/screens/provider` — assigned bookings, confirm/cancel.
- `lib/main.dart` — reads Supabase config from `--dart-define`, and reactively
  routes a signed-in user to the customer / provider / admin screen based on
  their role in `public.users`.

See `PROJECT_CHECKLIST.md` for exactly what's implemented and what isn't.
