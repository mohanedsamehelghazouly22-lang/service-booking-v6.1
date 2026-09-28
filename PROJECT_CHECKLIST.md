# Status

## Customer
- [x] Browse services, pick a location, pick a date, pick an available slot
- [x] Booking created through a security-definer RPC with row-level locking
      (no double/over-booking, even under concurrent requests)
- [x] My bookings list, with cancel (blocked inside the 3-hour window)
- [x] Phone OTP sign-in, Google sign-in, guest browsing, sign-in/sign-up
      toggle — **requires enabling the Twilio and Google providers in
      Supabase first, see SUPABASE_SETUP.md**, the app can't do that part
- [x] Android OAuth redirect (`io.supabase.servicebooking://login-callback/`)
      registered automatically by CI on every build
- [x] Liquid-glass UI on the login and home screens

## Admin (`mohanedsamehelghazouly22@gmail.com` after bootstrap — see
## SUPABASE_SETUP.md)
- [x] Services: create/edit, enable/disable, link to locations
- [x] Locations: create/edit, enable/disable
- [x] Availability: create/delete time slots with capacity (this did not
      exist before — without it nothing was bookable)
- [x] Provider assignments: which provider covers which service+location,
      instant vs. needs-confirmation
- [x] Users & roles: promote/demote customer / provider / admin
- [x] Bookings overview, filterable by status

## Provider
- [x] See only their own assigned bookings
- [x] Confirm a pending booking
- [x] Cancel, with a mandatory reason stored on the booking
      (`cancelled_by`, `cancellation_reason`)
- [x] See their assigned services/locations

## Backend
- [x] Full Postgres schema (`supabase/schema.sql`)
- [x] Row-level security on every table; every write goes through a
      security-definer RPC (`rpc.sql`, `rpc_admin.sql`, `rpc_provider.sql`)
- [x] Reactive, role-based routing after sign-in (customer / provider /
      admin) — including on app restart with a restored session

## Not done yet
- [ ] Windows desktop build in CI (Android APK/AAB only, right now)
- [ ] Automatic pending-booking expiry (a scheduled job/edge function to
      auto-cancel bookings past their `expires_at`)
- [ ] In-app notifications
