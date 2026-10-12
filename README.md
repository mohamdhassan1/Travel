# Rahala — travel booking app

Rahala is a Flutter app for discovering destinations, comparing travel packages and booking trips. It is backed by Supabase (Auth, Postgres with Row Level Security, Storage and Edge Functions) and Firebase Cloud Messaging, and is fully localized in English and Arabic (right-to-left).

> **Portfolio project, no payments.** Bookings are real database records with server-computed prices, but no money is taken and no availability is invented. The app says so wherever a price or booking appears.

## Features

| Area | What it does |
|---|---|
| **Auth** | Sign up with email confirmation, sign in, password reset by email link, change password, sign out, and in-app account deletion. The session is restored on launch, and an expired session is explained to the user. |
| **Catalog** | 4 categories, 20 destinations and 40 packages from Supabase. Home has featured, recently viewed and category sections. Explore has search across English **and** Arabic text (diacritics and letter-variant normalization), category, price and trip-length filters, and sorting. |
| **Destination** | Photo header, full-screen gallery (swipe, buttons, zoom), live weather (Open-Meteo), packages, sharing and favourites. |
| **Booking** | Choose a package, date and travellers, review, then submit. The database validates the booking and computes the price. Retries are idempotent, so a lost response never creates a duplicate. Includes confirmation, a Trips tab (upcoming / past / cancelled), details, and cancellation through a server function. |
| **Notifications** | An in-app notification centre fed by database triggers; FCM push sent by a Supabase Edge Function; local trip reminders on the device. |
| **Profile** | Name, phone, private profile photo (signed URLs), travel statistics and a traveler level derived only from the user's own bookings. The level is not a rating. |
| **App** | Light and dark themes, English/Arabic with RTL, a bottom bar on phones and a side rail on wide windows, and deep links (`rahala://rahala.app/...`). |

## Architecture

```
lib/
  app/           composition root (RahalaApp), bootstrap
  core/          config, errors (AppFailure), theme tokens, shared widgets, utils
  data/          models, repositories (Supabase, Open-Meteo, device stores), media, notifications
  logic/         cubits (flutter_bloc): session, catalog, explore, booking, favourites, profile, notifications
  presentation/  screens and widgets; no SDK calls (enforced by test/unit/architecture_test.dart)
  routing/       GoRouter: StatefulShellRoute tabs, redirect policy (route_guard.dart), paths
  l10n/          ARB files (en, ar) and generated localizations
supabase/
  migrations/    schema, RLS, functions, triggers (apply in filename order)
  functions/     send-booking-notification (FCM HTTP v1 sender)
  seed.sql       sample catalog
```

- **Repositories** throw only `AppFailure`. Users see localized messages, never raw SQL or exception text.
- **App-wide cubits** follow the session: they clear on sign-out and on account switch, so one account's data never appears under another.
- **The server is the authority** for prices, booking status, ownership (RLS), cancellation rules, notification creation and push dispatch.

## Run it

Requirements: Flutter 3.44 or later (Dart 3.5+).

1. Copy `env/example.json` to `env/dev.json` and fill in your Supabase **project URL** and **publishable** key. `env/*.json` is git-ignored. The app refuses to start with a `service_role` / secret key.
2. Set up the backend as described in [`supabase/README.md`](supabase/README.md): migrations, seed, auth redirect URL, and optionally the push function.
3. Android push (optional): place your Firebase `google-services.json` in `android/app/`. It is git-ignored; see [`docs/NOTIFICATIONS.md`](docs/NOTIFICATIONS.md).
4. Run:

```bash
flutter run --dart-define-from-file=env/dev.json
```

## Tests

```bash
flutter analyze
flutter test
node --experimental-strip-types --test supabase/functions/send-booking-notification/fcm.test.ts
```

The Flutter tests use in-memory fakes that follow the backend's rules (RLS visibility, booking rules, idempotency). Widget tests drive the real router, theme and localizations.

## Verification status

| Area | Status |
|---|---|
| Flutter analyze / tests, Edge Function tests | Clean / passing (see `docs/PRODUCTION_READINESS.md` for counts) |
| Supabase RLS, storage policies, RPC privileges | Verified live with forged-identity probes in rolled-back transactions |
| Push backend (trigger → pg_net → Edge Function → Google OAuth) | Verified live, without sending to any device |
| **Push delivery to an Android device, local trip reminders on a device, `rahala://` links from outside the app** | **Not verified yet** — needs a real device or emulator |
| Web build (Chrome) | Verified: auth session, catalog, details, gallery, profile, settings, Arabic/RTL, wide layout |

## Documentation

- [`docs/PRODUCT_UX.md`](docs/PRODUCT_UX.md) — design system, navigation, screens
- [`docs/NOTIFICATIONS.md`](docs/NOTIFICATIONS.md) — in-app notifications, push, reminders
- [`docs/ANDROID_DEVICE_CHECKLIST.md`](docs/ANDROID_DEVICE_CHECKLIST.md) — what to verify on a real Android device
- [`docs/PRODUCTION_READINESS.md`](docs/PRODUCTION_READINESS.md) — Phase 9 audit, status and known limitations
- [`supabase/README.md`](supabase/README.md) — backend setup and security notes

## Photo credits

Destination photos come from Wikimedia Commons. Credits are shown on each destination and under Settings → Photo credits.
