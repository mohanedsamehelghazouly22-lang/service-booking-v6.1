# Service Booking — Architecture

## Stack
Flutter client → Supabase (Postgres + Auth) directly, via `supabase_flutter`.
There is no separate backend service — every rule that matters (ownership,
availability, capacity, role permissions, cancellation windows) is enforced
inside Postgres, in security-definer RPC functions
(`supabase/rpc.sql`, `rpc_admin.sql`, `rpc_provider.sql`), not in the client.
The client only calls those RPCs; it never writes to a table directly for
anything that needs a rule enforced.

## Booking workflow
1. Guest browses services, locations, dates and available slots (no
   sign-in needed for browsing).
2. Picking a slot prompts sign-in (phone OTP or Google) if not already in.
3. The client calls `create_booking`, which — inside one Postgres
   transaction — locks the slot row, checks it's still enabled and in the
   future, checks remaining capacity against active bookings, then inserts
   `confirmed` (instant mode) or `pending` with a 4-hour `expires_at`
   (pending mode).
4. `my_bookings` reads the customer's own bookings; cancelling calls
   `cancel_booking`, which the backend refuses inside the 3-hour window
   before the appointment.

## Roles
- **Customer**: browses, books, sees/cancels only their own bookings.
- **Provider**: sees only bookings where `provider_id = auth.uid()`;
  can confirm a pending booking or cancel with a mandatory reason
  (`cancelled_by` + `cancellation_reason` are recorded).
- **Admin**: manages services, locations, availability (slots), which
  provider covers which service+location, user roles, and sees all
  bookings. Every admin RPC checks `current_role() = 'admin'` itself, so
  none of this depends on the client behaving.

See `SUPABASE_SETUP.md` for how the very first admin gets bootstrapped.

## UI flow
Guest/Login → Home → Service → Location → Date → Slot → Booking
confirmation → My Bookings.
Provider: Login → Provider Dashboard → Bookings list → Confirm/Cancel.
Admin: Login → Admin Console → Services / Locations / Availability /
Provider assignments / Users & roles / Bookings.

## CI/CD (`.github/workflows/flutter.yml`)
- Every push/PR: `flutter analyze` + `flutter test`.
- Push to `main`/`master`: also builds a release APK.
- Tag `vX.Y.Z`: also builds an AAB and creates a GitHub Release with the APK.
- Required repository secrets/variables: `SUPABASE_URL`,
  `SUPABASE_PUBLISHABLE_KEY` — passed to the build via `--dart-define`, read
  in `lib/main.dart` via `String.fromEnvironment`. Never commit these
  directly to the repo.
- Windows build is not yet part of this workflow (Android APK/AAB only).
