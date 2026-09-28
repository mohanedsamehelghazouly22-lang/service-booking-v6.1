# Supabase setup

Run these files in the Supabase SQL editor, **in this exact order**:

1. `supabase/schema.sql` — creates every table (`users`, `services`, `locations`,
   `service_locations`, `slots`, `bookings`, `provider_assignments`), enables
   row-level security, and creates the `current_role()` helper.
2. `supabase/rpc.sql` — customer-facing booking RPCs (`create_booking`,
   `cancel_booking`), with row locking so a slot can never be over-booked.
3. `supabase/rpc_admin.sql` — every admin RPC (services, locations, slots,
   provider assignments, users/roles, bookings overview).
4. `supabase/rpc_provider.sql` — every provider RPC (their bookings, confirm,
   cancel with a required reason, assigned locations).

Then, in Project Settings → API, copy the **Project URL** and the
**publishable key** — these are what the app's `SUPABASE_URL` and
`SUPABASE_PUBLISHABLE_KEY` GitHub secrets/variables should hold; the CI
workflow passes them to `flutter build` via `--dart-define`.

## Enabling sign-in (do this before testing login)

Neither sign-in method works out of the box — Supabase disables every auth
provider until you configure it. This is why you saw
"Unsupported phone provider" and "Unsupported provider: provider is not
enabled": nothing is broken in the app, the providers are just off.

### Google (needed for the admin bootstrap below)
1. In [Google Cloud Console](https://console.cloud.google.com), create/select
   a project → **APIs & Services → OAuth consent screen** → fill it in
   (External is fine; add your own email as a test user if it stays in
   "Testing" mode).
2. **APIs & Services → Credentials → Create Credentials → OAuth client ID**
   → Application type **Web application**.
3. Under **Authorized redirect URIs**, add:
   `https://<your-project-ref>.supabase.co/auth/v1/callback`
   (find `<your-project-ref>` in Supabase → Project Settings → API, or in
   your Project URL).
4. Copy the **Client ID** and **Client secret**.
5. In Supabase → **Authentication → Providers → Google** → enable it, paste
   the Client ID and secret, save.
6. In Supabase → **Authentication → URL Configuration → Redirect URLs**,
   add: `io.supabase.servicebooking://login-callback/`
   (without this, Supabase itself refuses to redirect back into the app
   after Google login succeeds).

The Android side of this redirect (the app registering that
`io.supabase.servicebooking://login-callback/` link with the OS) is now
handled automatically by CI — see "Android OAuth redirect" below.

### Phone (Twilio)
1. Create a Twilio account (trial credit is enough to test) and get an
   Account SID, Auth Token, and a Twilio phone number capable of sending
   SMS to your country.
2. Supabase → **Authentication → Providers → Phone** → enable it, choose
   Twilio, paste those three values, save.
3. The app already normalizes local Egyptian numbers (e.g. `01287772237`)
   into E.164 (`+201287772237`) before sending, so you can type the number
   either way.

Until Twilio is configured, use **Continue with Google** or **Browse as
guest** — phone sign-in will keep failing regardless of the app code.

### Android OAuth redirect
Supabase's OAuth flow opens a browser, then needs Android to hand control
back to the app via the `io.supabase.servicebooking://login-callback/`
link. The `android/` folder isn't committed to this repo (CI generates it
fresh via `flutter create .` when it's missing), so the CI workflow now has
an extra **"Register OAuth redirect deep link"** step, right after the
Android project is created, that patches `AndroidManifest.xml` to add the
matching intent-filter automatically on every build. You don't need to do
anything for this — it's already in `.github/workflows/flutter.yml`. If you
ever commit a real `android/` folder yourself (e.g. because you added
another native plugin), keep that same intent-filter in
`android/app/src/main/AndroidManifest.xml` inside the `<activity>` block.

## Making the first admin (mohanedsamehelghazouly22@gmail.com)

There is no admin yet inside a brand-new database, so nobody can open the
admin console to promote themselves. Bootstrap it once, by hand:

1. Install/run the app and sign in once as
   `mohanedsamehelghazouly22@gmail.com` using **"Continue with Google"**
   (email must be populated, so phone-OTP sign-in won't work for this step).
   This creates that user's row in `public.users` with role `customer`.
2. Run `supabase/seed_admin.sql` in the SQL editor. It promotes that account
   to `role = 'admin'`.
3. Sign out and back in (or just reopen the app) — the reactive session
   gate in `main.dart` will now route that account straight to the admin
   console.

To make someone a provider afterwards, you don't need SQL: sign in as
admin → **Users & roles** → tap the account → choose `provider`. Then
assign them to a service + location from **Provider assignments**.
