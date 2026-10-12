# Notifications in Rahala

Rahala has three separate notification concepts. They are kept apart so the same event is never shown twice.

| Concept | Source of truth | Delivered by | Code |
|---|---|---|---|
| **In-app notifications** (booking confirmed / cancelled) | Supabase `notifications` rows, written by the `notify_booking_change` trigger | The app's Notifications screen and Account badge | `NotificationsRepository` → `NotificationsCubit` |
| **Remote push** for those same rows | The same `notifications` row (no extra rows) | `notifications_dispatch_push` trigger → Edge Function `send-booking-notification` → FCM HTTP v1 → device | `supabase/functions/send-booking-notification`, `PushTokenSync` |
| **Local trip reminders** | The user's confirmed bookings | Scheduled on the device by the app | `TripReminderScheduler`, `LocalReminderNotifier` |

`DeviceNotificationsCubit` coordinates push and reminders with the session. Widgets never call Firebase, the notification plugin or Supabase directly (enforced by `test/unit/architecture_test.dart`).

## Status

| Item | State |
|---|---|
| Push backend: trigger, Edge Function, single-use claim, invalid-token cleanup | **Implemented and deployed (function v4). Verified live (2026-10-04)** with an isolated, deleted-afterwards test user that had no devices. See below. |
| Firebase service account (`FIREBASE_SERVICE_ACCOUNT_JSON`) | **Configured.** The `{"check":"fcm_auth"}` handshake returned `200 fcm_auth_ok`, project `aspen-travel`: Google issued an OAuth access token. Neither the token nor the key is ever returned or logged. |
| FCM delivery to a device (`messages:send`) | **Not verified.** No real device token exists yet; no fake tokens are used. Covered by unit tests (`classifySendResult`) until an Android device registers. |
| Android: Firebase app, package id, `google-services.json` | **Verified matching** (see below). |
| Real Android device: startup, token, push, taps, reminders | **Not verified.** No device or emulator was available. Testing steps are below. |
| iOS push | Not configured (no `GoogleService-Info.plist` / APNs). The app runs; push stays off. |
| Web push | Disabled by design (no Firebase web config, VAPID key or service worker). Settings says so. |

**Live chain results (2026-10-04, temporary user with no device tokens):**
- **Confirmed booking:** booking insert → `booking_confirmed` row → post-commit pg_net request → function returns `200 no_devices`; the row is claimed.
- **Cancellation:** `cancel_booking` → `booking_cancelled` row → `200 no_devices`; claimed.
- **Stale row:** a 20-minute-old unpushed row returns `200 skipped` and is not claimed.
- **Trip reminder:** no request is made (the trigger filters it out).
- **Claim-once:** re-dispatching an already-claimed id returns `200 skipped`. An unknown id also returns `200 skipped`.
- **Malformed and unauthorized calls:**
  - malformed id, `{}` and array bodies → `400`;
  - wrong, short or missing dispatch secret → `401`, including for the handshake;
  - GET or PUT → `405`.
- **Note:** saving an Edge Function secret makes the platform redeploy the same code as a new version. The secret is only visible to that new version (here v4).

## Firebase Android configuration (verified)

- **Matching ids:** `android/app/build.gradle` has `namespace` and `applicationId` = `com.example.first_app`. `android/app/google-services.json` (git-ignored) has project `aspen-travel`, and its only Android client is `com.example.first_app`. **They match.**
- **Plugin:** the Google Services Gradle plugin `4.4.4` is applied in `android/app/build.gradle`.
- **Branding note:** only the app's display name is "Rahala". Changing the package id requires first registering a new Android app in Firebase and downloading its `google-services.json`.
- **Initialisation:** Firebase is initialised from the native config; there is no `firebase_options.dart`. `bootstrap()` initialises it time-boxed, and a failure only turns push off.

## Push architecture

```
booking insert / cancel_booking()
  └─ notify_booking_change         → one row in public.notifications (unchanged)
       └─ notifications_dispatch_push (AFTER INSERT, booking types only)
            └─ pg_net POST {notification_id}  ← sent only after COMMIT
                 └─ Edge Function send-booking-notification
                      1. header x-push-dispatch-secret == Vault secret (checked in the DB)
                      2. body: notification_id only (UUID)
                      3. FIREBASE_SERVICE_ACCOUNT_JSON present? else 503, nothing claimed
                      4. claim_notification_push(id): sets push_dispatched_at once,
                         booking types only, < 15 min old → never pushed twice
                      5. booking still exists and has the same owner
                      6. device_tokens WHERE user_id = owner (every device)
                      7. OAuth2 (RS256 JWT → access token, scope firebase.messaging)
                      8. FCM v1 messages:send per token
                      9. UNREGISTERED / SENDER_ID_MISMATCH / invalid-registration-token
                         → delete only that token row; other tokens are unaffected
```

**Security model:**
- The client never calls the sender.
- **Caller check:** the function accepts only the database trigger. The trigger holds a 256-bit secret generated inside the database (Vault `push_dispatch_secret`). It is never written to a file, a log or the app.
- **No client influence:** recipient, tokens, type and text all come from the database. A forged or replayed id can at most re-request a row that was already claimed, so nothing is sent.
- **Server-only functions:** `verify_push_dispatch_secret` and `claim_notification_push` are executable only by `service_role`.

**Payload:** deliberately minimal and deterministic.
- **Data fields:** `type`, `booking_id`, `notification_id`, `reference`.
- **Not included:** names, phone numbers, destinations or prices.
- **Text:** the English title and body are a fallback. On Android the text is localized on the device through `title_loc_key` / `body_loc_key`, using the string resources in `android/app/src/main/res/values{,-ar}/strings.xml`. These follow the **device** language, not the in-app language choice.
- **Delivery:** channel `booking_updates`, monochrome icon `ic_stat_rahala`, and one `tag` per notification.

**Multiple devices:** `device_tokens` has one row per token and many rows per user. Pushes go to every device the user has registered. Signing out removes only the current device's token.

## Required secret (name only)

| Secret | Where | Used by |
|---|---|---|
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Supabase → Edge Functions → Secrets | `send-booking-notification`, to obtain an FCM access token |

Never put this value in the app, `env/*.json`, `google-services.json`, Git, logs or documentation. `SUPABASE_URL` and the secret API key are provided to the function by the platform automatically.

### Manual step: create the Firebase credential

1. Open the Firebase Console and select project **aspen-travel**, the one that issued `google-services.json`.
2. Go to **Project settings → Cloud Messaging** and make sure **Firebase Cloud Messaging API (V1)** shows as *Enabled*. If not, enable it via the Google Cloud console link shown there.
3. Go to **Project settings → Service accounts**, click **Generate new private key**, and download the JSON. Keep it out of the repository.
4. In the Supabase Dashboard, go to **Edge Functions → Secrets**, add `FIREBASE_SERVICE_ACCOUNT_JSON`, paste the **entire JSON** as the value, and save.
   - CLI alternative: `supabase secrets set FIREBASE_SERVICE_ACCOUNT_JSON="$(cat path/to/key.json)" --project-ref khwczyuebovenwrlchdu`.
   - No redeploy is needed.
5. Delete the downloaded file, or store it in a password manager.

### Checking the credential without exposing it

These checks need the dispatch secret, so they can only be run server-side, where the secret never leaves the database. In the SQL editor:

```sql
select net.http_post(
  url := (select decrypted_secret from vault.decrypted_secrets where name = 'push_function_url'),
  headers := jsonb_build_object('Content-Type', 'application/json', 'x-push-dispatch-secret',
    (select decrypted_secret from vault.decrypted_secrets where name = 'push_dispatch_secret')),
  body := '{"check":"fcm_auth"}'::jsonb);
-- then: select status_code, content from net._http_response order by id desc limit 1;
```

| Response | Meaning |
|---|---|
| `200 {"status":"fcm_auth_ok","project_id":"aspen-travel"}` | The JSON parsed, Google issued an access token, and the project id is shown. No row is read and no message is sent. |
| `503 … "reason":"missing"` | The function has no variable with that exact name. `similar_names` lists the **names** of near-misses, e.g. a typo. |
| `503 … "reason":"invalid_json" / "not_service_account" / "missing_fields" / "bad_private_key"` | The value is there but isn't the downloaded service-account file. |
| `502 {"error":"fcm_auth_failed","detail":"oauth_token_4xx"}` | Google rejected the key, e.g. it was revoked or belongs to a deleted account. |

Notes:
- The responses never contain the key or the access token.
- Real line breaks inside `private_key`, from pasting into a text box, and a double-encoded JSON string are both accepted.

## Permission and tokens (app)

**Permission:**
- Never asked at launch.
- Asked once after the first booking, or from Settings → **Allow**.
- If refused, Settings offers **Open settings**.
- Re-read whenever the app resumes.

**Token lifecycle:**
- **Registration:** only for a signed-in user with permission, via `register_device_token`. The owner is `auth.uid()`, and the same token is never registered twice.
- **Refresh:** the new token is registered and the old one unregistered.
- **Sign-out:** the token is unregistered while the session is still valid.
- **Account switch:** the token moves to the new user.
- **Failed registration:** retried the next time the app resumes.

**Settings → Booking updates** is a status, not a switch. It shows one of:
- registered on this device;
- needs permission;
- not registered yet (it will retry);
- push not set up on this platform.

## Foreground, background, terminated

| App state | What the user sees | Tap |
|---|---|---|
| **Foreground** | The OS shows nothing. The app refreshes the in-app list and badge, and shows **one** SnackBar ("Booking confirmed · RH-…", with **View**). No local notification is created, so nothing is duplicated. | **View** goes to `/bookings/<id>` |
| **Background** | The OS shows the FCM notification on the "Booking updates" channel. | `onMessageOpenedApp` goes to `/bookings/<id>` |
| **Terminated** | The OS shows the FCM notification. | `getInitialMessage()` at startup goes to `/bookings/<id>` |

- Only a well-formed UUID is ever navigated to. The details screen re-reads the booking and shows "Booking not found" if it's gone.
- The route is protected: a signed-out user goes through login and back.
- Local reminder taps use the same path.

## Local trip reminders

- **Policy:** bookings store a travel **date** only, so the reminder fires at **09:00 device-local time on the day before the travel date**.
- **Time-zone handling:** the time is computed as local wall-clock time using the device's UTC offset **on the reminder date**, so it's DST-correct. The plugin receives the resulting absolute instant.
- **Tests:** the offset is injectable, and tests cover UTC+2, UTC+3, UTC−5, an Egypt-style DST change, month and year boundaries, and travel tomorrow after 09:00.
- **When there's no reminder:** cancelled bookings, past trips, and a trip booked for tomorrow after 09:00 today. Invalid stored dates are rejected when the booking is parsed.
- **Duplicates:** each booking has a stable id. Scheduling the same id replaces the existing reminder, and an identical pending payload is left untouched.
- **What keeps reminders current:** create, cancel, details and My bookings results, and one resync on sign-in.
- **Removal:** sign-out and account switch remove all reminders.
- **Travelling:** if the device's time zone changes, the next resync (app start) reschedules for 09:00 in the new zone.
- **Android scheduling:** inexact alarms, so no exact-alarm permission is needed. Reminders are restored after reboot.

## Android notification setup

- **Permission:** `POST_NOTIFICATIONS` in the manifest. Android 13+ asks at runtime, as described above.
- **Channels:** `trip_reminders` (local) and `booking_updates` (push). The second is created by the app with a localized name and is the FCM default channel in the manifest.
- **Icon:** `@drawable/ic_stat_rahala`, a white vector plane. It is used for reminders and as the FCM default icon. The launcher icon is unchanged.
- **Colour:** `@color/notification_accent` (`#0F766E`).
- **Release builds:** `res/raw/keep.xml` keeps the icon and push strings from being shrunk away.

## Testing on a real Android device

```bash
flutter devices
flutter run -d <android-device-id> --dart-define-from-file=env/dev.json
```

1. Sign in, then make a booking at least 2 days ahead. Allow notifications when asked.
2. In Supabase, `device_tokens` has a row for your user with platform `android`. The app never logs the token.
3. The trip reminder is pending for 09:00 local time the day before. Check it with `adb shell dumpsys alarm | findstr first_app`, or via the plugin's pending list.
4. With the credential set: an in-app SnackBar appears while the app is open (foreground). Put the app in the background and cancel the booking from another device, or create one — the system notification appears. Swipe the app away (terminated) and trigger another event — it appears, and tapping it opens `/bookings/<id>`.
5. Supabase `net._http_response` shows the function's status for each dispatch: `200 {"status":"done","sent":1,…}`.
6. Clean up: cancel the test booking. Signing out removes the token row.

## iOS and web

- **iOS:**
  - Add `ios/Runner/GoogleService-Info.plist` for an iOS app in the same Firebase project.
  - Upload an APNs key to Firebase.
  - In Xcode, enable *Push Notifications* and *Background Modes → Remote notifications*.
  - `AppDelegate.swift` already sets the notification delegate.
  - Until then, push is off and reminders work.
- **Web:** no push and no reminders. Settings shows "not available on this platform".
