# Android device verification checklist

Everything here was prepared and checked **in code and configuration only** (Phase 12). None of it has run on a real Android device yet. Tick each item on a device or emulator and record the result.

## 0. Setup

- **Device:** Android 8+ (API 26+), ideally one on Android 13+ to see the notification-permission prompt. The app supports API 24+.
- **Files:** `android/app/google-services.json` (Firebase project `aspen-travel`, package `com.example.first_app`) and `env/dev.json` must be present locally. Both are git-ignored.
- **Supabase → Authentication → URL Configuration:** must allow the redirect URL `rahala://rahala.app/auth-callback`.
- **Backend:** the Edge Function credential is already configured. A check: `{"check":"fcm_auth"}` → `200 fcm_auth_ok` (see NOTIFICATIONS.md).
- **Run:** `flutter run -d <device-id> --dart-define-from-file=env/dev.json`

## 1. Install and launch

| # | Check | Expected |
|---|---|---|
| 1.1 | Launcher icon | Teal Rahala icon with a white plane, not the Flutter logo. On Android 13+ with themed icons, the monochrome plane. |
| 1.2 | First launch | Splash, then onboarding (language toggle works), then login |
| 1.3 | Dark/light system theme | The app follows it (Settings → Theme → System) |

## 2. Auth and deep links

| # | Check | Expected |
|---|---|---|
| 2.1 | Register, then open the confirmation email **on the device** | The link opens Rahala (`rahala://rahala.app/auth-callback?code=…`) and the user lands signed in on Home |
| 2.2 | Forgot password, then open the email link on the device | The app opens on "Choose a new password" and can't leave it until the password is set |
| 2.3 | Sign out, then reopen a booking link: `adb shell am start -a android.intent.action.VIEW -d "rahala://rahala.app/bookings/<id>"` | Login, then the booking after signing in |
| 2.4 | `adb shell am start -a android.intent.action.VIEW -d "rahala://rahala.app/destinations/<id>"` | Destination details |
| 2.5 | Kill the app, reopen | Still signed in (session restored) |

## 3. Notifications

| # | Check | Expected |
|---|---|---|
| 3.1 | Make the first booking at least 2 days ahead | The Android 13+ permission prompt is shown once, after the booking (not at launch) |
| 3.2 | Allow notifications | A `device_tokens` row for the user, platform `android` |
| 3.3 | Trip reminder | Pending for 09:00 local time the day before (`adb shell dumpsys alarm`) |
| 3.4 | Reboot the device | The reminder is still pending, restored by `ScheduledNotificationBootReceiver` |
| 3.5 | Booking event with the app open | One in-app SnackBar, no system banner |
| 3.6 | Booking event with the app in the background | A system notification on the "Booking updates" channel with the plane icon. Text follows the **device** language, not the in-app setting. |
| 3.7 | Same with the app swiped away (terminated) | The notification appears; tapping it opens `/bookings/<id>` |
| 3.8 | Tap a trip reminder | Opens that booking |
| 3.9 | Cancel the booking | Its reminder is removed and a cancellation push is received |
| 3.10 | Sign out | The token row is removed and reminders are cleared |
| 3.11 | Two devices on one account | Both receive the push (`net._http_response` shows `"sent":2`) |
| 3.12 | Uninstall on one device, then trigger an event | That device's token is removed by the function (`"removed":1`) |
| 3.13 | Deny the permission | Settings shows "blocked" with **Open settings**; the app works normally |

Inspect each dispatch in SQL:

```sql
select id, status_code, content from net._http_response order by id desc limit 5;
```

The response should contain only statuses and counts.

## 4. Device features

| # | Check | Expected |
|---|---|---|
| 4.1 | Profile → photo → Choose from gallery | Android photo picker; the photo uploads and shows |
| 4.2 | Profile → photo → Take a photo | The system camera app opens; no camera permission is asked for, because the app declares none |
| 4.3 | Remove photo | Initials shown; the file is deleted from `avatars/<uid>/` |
| 4.4 | Destination → Share | Android share sheet with name, summary and the `rahala://` link |
| 4.5 | Back gesture (Android 13+; predictive back is the default at target SDK 36) | Normal back everywhere. The booking review step goes back to the details step. Edit profile with changes asks to discard. |
| 4.6 | Display size / font size at maximum | No clipped or overlapping text (200% is covered by tests) |
| 4.7 | Keyboard on the booking form and auth forms | Fields stay visible above the keyboard (`adjustResize`) |
| 4.8 | Arabic (in-app toggle) | Full RTL; back arrows and chevrons mirrored |

## 5. Clean-up after testing

Do these from the app:
- cancel the test bookings;
- sign out, so the test device's token is removed.

Or delete the test account through Profile → Delete account, which removes all of its data.
