# Supabase backend

The app talks to Supabase with the **publishable key only**. All data access is
enforced by Row Level Security and explicit grants defined in
[`migrations/`](migrations/).

## 1. Apply the schema

Either:

- **Dashboard:** open *SQL Editor → New query*, paste the contents of
  `migrations/20260929000000_initial_schema.sql`, and run it, **or**
- **CLI:** `supabase link --project-ref <ref>` then `supabase db push`.

The script is idempotent; re-running it is safe.

It creates:

| Object | Purpose | Access |
|---|---|---|
| `profiles` | Name, phone, avatar path, locale. Row auto-created on sign-up. | Owner read/update (limited columns) |
| `categories`, `destinations`, `destination_packages` | Travel catalog | Public read; writes via dashboard only |
| `destination_summaries` (view) | Card data + "from" price | Public read (respects base-table RLS) |
| `search_destinations()` | Server-side search/filter/sort | anon + authenticated |
| `favorites` | Saved destinations | Owner only |
| `bookings` | Reservations. Price, currency, reference and status are set **by the database** | Owner read/insert; cancel via `cancel_booking()` |
| `device_tokens` | FCM tokens | Owner read; write via `register_device_token()` / `unregister_device_token()` |
| `notifications` | In-app notification center, written by a booking trigger | Owner read / mark read / delete |
| Storage `avatars` | Private; users only touch `<their-uid>/…` | Owner only |
| Storage `destination-images` | Public catalog photos | Public read; upload via dashboard |


## 1b. Load the sample catalog

First run `migrations/20261001000000_package_natural_key.sql` (adds the package
natural key the seed upserts on; safe to re-run). Then run [`seed.sql`](seed.sql) the same way (SQL Editor, or `supabase db reset` locally,
which applies migrations then the seed). It upserts 4 categories, 20 destinations
and 40 packages in English and Arabic (8 destinations were added in Phase 8 to
balance Beaches and Islands), and never touches user tables.

- **Prices are illustrative sample values.** There is no inventory or payment.
- **No ratings, reviews or testimonials** are seeded.
- **Images** are hotlinked from Wikimedia Commons (Featured/Quality images).
  Each destination's `image_credit` column names the photographers and licences
  (CC BY, CC BY-SA, FAL, CC0). No image files are stored in the repo.

## 1c. Booking idempotency, read receipts, hardening

Run `migrations/20261002000000_booking_idempotency_and_hardening.sql` (safe to
re-run). It adds:

- `bookings.client_request_id` with a unique `(user_id, client_request_id)`
  constraint. The app sends one random UUID per booking attempt and reuses it
  on retry (kept on the device until the outcome is known), so a retry after a
  lost response returns the existing booking instead of creating a duplicate.
- `mark_notifications_read(p_ids uuid[] default null)`: `SECURITY INVOKER`, so
  RLS still applies; stamps `read_at` with the server clock for the caller's
  own unread rows (`null` = all) and returns them.
- Revokes `EXECUTE` on the trigger functions (`handle_new_user`,
  `notify_booking_change`, `prepare_booking`, `set_updated_at`) from
  `public`/`anon`/`authenticated` (Security Advisor 0028/0029). Triggers keep
  working: Postgres checks that privilege only when a trigger is created.

## 1d. Push notifications (FCM sender)

The details and security model are in [`docs/NOTIFICATIONS.md`](../docs/NOTIFICATIONS.md).

1. **Run `migrations/20261003000000_push_dispatch.sql`.** It is safe to re-run. It:
   - enables `pg_net`;
   - adds `notifications.push_dispatched_at`;
   - generates the Vault secret `push_dispatch_secret`;
   - creates the `notifications_dispatch_push` trigger and the service-role-only functions `verify_push_dispatch_secret` and `claim_notification_push`.
2. **Deploy the function** without JWT verification. It authorizes the database trigger itself, and the caller (`pg_net`) has no user JWT:
   ```bash
   supabase functions deploy send-booking-notification --no-verify-jwt --project-ref <project-ref>
   ```
3. **Point the trigger at the function.** This is once per project; the URL is not secret:
   ```sql
   select vault.create_secret(
     'https://<project-ref>.supabase.co/functions/v1/send-booking-notification',
     'push_function_url', 'send-booking-notification endpoint');
   ```
   Until this is set, the trigger does nothing.
4. **Add the Firebase credential** as the Edge Function secret `FIREBASE_SERVICE_ACCOUNT_JSON` (Dashboard → Edge Functions → Secrets). How to create it is in `docs/NOTIFICATIONS.md` → "Manual step". Never commit it or put it in the app. Until it's set, the function answers `503 fcm_not_configured` and claims nothing.
5. **Check the result:** `select id, status_code, content from net._http_response order by id desc limit 5;`

For this project (`khwczyuebovenwrlchdu`), steps 1–3 are done. Step 4 is pending.

The logic tests need no credentials:

```bash
node --experimental-strip-types --test supabase/functions/send-booking-notification/fcm.test.ts
```

## 1e. Account deletion and hardening (Phase 9)

Run `migrations/20261004000000_account_deletion_and_hardening.sql`. It is safe to re-run.

- **`delete_my_account()`** lets a signed-in user delete their own account, which store policies require for apps with sign-up.
  - It runs as security definer and is executable by `authenticated` only.
  - It deletes `auth.users` for `auth.uid()`. Profiles, bookings (with their notifications), favourites and device tokens go with it through the existing `ON DELETE CASCADE` keys.
  - The app first removes the user's own files from the private `avatars` bucket through the Storage API.
  - The function refuses (`avatar_cleanup_required`) while any of those files remain, so a photo is never left orphaned.
- **Booking abuse cap:** `prepare_booking` refuses an 11th new booking within a rolling hour for the same user (`booking_rate_limited`).
  - A retry of an already-stored request (same `client_request_id`) is exempt, so idempotent retries still return the existing booking.
  - This guards against scripted spam (bookings → notifications → pushes). It says nothing about availability.
- **Indexes and hygiene:**
  - `bookings (user_id, created_at)` for the cap;
  - `notifications (booking_id)` for the cascade foreign key;
  - `EXECUTE` revoked on the project's `rls_auto_enable()` event-trigger function for API roles.

Verified live in rolled-back transactions:
- a temporary user's 11th booking is refused, while a retried request id still reaches the unique constraint;
- deleting the account removes the user, profile, bookings, favourites and notifications;
- a forged other-user identity sees 0 rows of private data and cannot cancel, update, insert or read Vault.

## 2. Auth settings (Dashboard → Authentication)

- **URL Configuration → Redirect URLs:** add `rahala://rahala.app/auth-callback`.
  Email-confirmation and password-reset links return to the app through it.
- **Providers → Email:** enabled. "Confirm email" is currently **on**, and the
  app handles that (shows *Check your inbox* after sign-up).
- **Google:** not configured, so the app doesn't offer Google sign-in.
- **Leaked-password protection** (Authentication → Sign In / Providers →
  Email, "Prevent use of leaked passwords"): **not enabled**. It can only be
  turned on in the dashboard (no SQL or API used here can change it), and
  Supabase offers it on the Pro plan and above. Enable it there when available.

## 3. Security notes

- Never put the `service_role` / `sb_secret_…` key in the app. `AppConfig`
  refuses to start if one is supplied.
- RLS is enabled on every table; no policy uses `using (true)` on user data.
- Security-definer functions pin `search_path = ''` and check `auth.uid()`.
- `device_tokens` is read-only for clients (owner-only `select`). The app
  writes it only through `register_device_token` (owner = `auth.uid()`, one
  row per token, so a token moves to whoever signs in on that device) and
  `unregister_device_token` (deletes only the caller's row). Neither is
  executable by `anon`. Pushes are sent only by the `send-booking-notification`
  Edge Function (section 1d), which holds the Firebase credential as a
  function secret; the app never has it.
