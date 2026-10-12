# Production readiness — Phase 9 audit (2026-10-03)

This records what was audited, what was found, what changed and what is still open. It is deliberately not a claim that the app is "production ready". Real-device Android behavior and a few operational items are still unverified (see the end).

## 1. CV traceability

| CV claim | Status | Evidence |
|---|---|---|
| Multi-screen app with user auth | **Implemented** | Supabase Auth: email/password sign-up with confirmation, sign-in, reset link, change password, sign-out, account deletion, session restore, expired-session notice |
| Destination browsing | **Implemented** | Live catalog (4 categories, 20 destinations, 40 packages), Home, Explore search and filters, details, gallery, weather |
| Booking flows | **Implemented** | Server-validated, server-priced, idempotent insert; confirmation; Trips; details; cancellation via `cancel_booking` |
| Supabase DB & Storage | **Implemented** | Postgres + RLS on every table; private `avatars` bucket (owner-only), public `destination-images` |
| Firebase FCM | **Backend verified live; device delivery not verified** | Credential configured; Google OAuth handshake OK (`aspen-travel`); booking → notification → pg_net → Edge Function verified with a temporary user that had no devices (Phase 10A). Real delivery needs an Android device |
| Local notifications for trip reminders | **Implemented, not device-verified** | `flutter_local_notifications`, UTC-scheduled, cancelled on cancel or sign-out |
| Full Arabic/English with RTL | **Implemented** | All UI strings in ARB (EN/AR), RTL layouts, LTR isolation for references, phones and emails |
| GoRouter declarative navigation & deep linking | **Implemented** | `StatefulShellRoute` tabs, guarded redirects with a safe `from` return path, `rahala://rahala.app/<path>` on Android/iOS, hash URLs on web |

## 2. Audit findings and priorities

P0 means blocking, P1 important, P2 polish and P3 a later improvement.

| # | Finding | Priority | Status |
|---|---|---|---|
| 1 | **No in-app account deletion.** Required by app-store policies for apps with sign-up, and expected for user-data rights. | P1 | **Fixed:** `delete_my_account()` + Profile → Delete account |
| 2 | `MyBookingsCubit`: a slow trips response for the previous account could repopulate state after sign-out (the request generation wasn't invalidated on session change). | P1 | **Fixed** + regression test (fails without the fix) |
| 3 | **No abuse protection on bookings.** There's no payment step, so a script could create unlimited bookings, each also creating notifications and pushes. | P1 | **Fixed:** at most 10 new bookings per user per hour, enforced server-side; idempotent retries exempt; new `bookingRateLimited` message |
| 4 | Booking confirmation in an error state was a dead end (no back button, only Retry). | P1 | **Fixed:** "View my bookings" secondary action |
| 5 | **200% text size overflowed** on Home (next-trip card), the booking form (travellers stepper) and booking details (status/reference row). | P1 (a11y) | **Fixed** + 22 large-text layout tests (7 + 4 screens × EN/AR) |
| 6 | Change password existed (reset screen supports signed-in users), but nothing linked to it, and its copy assumed a reset link. | P2 | **Fixed:** Settings → Account → Change password, with signed-in wording and a back button |
| 7 | Gallery photos couldn't be opened. On the web a mouse can't drag pages, so a pure swipe viewer would have been unusable there. | P2 | **Fixed:** full-screen viewer with swipe, zoom and RTL-correct previous/next buttons (verified live in Arabic) |
| 8 | Desktop/tablet web used a phone bottom bar at any width. | P2 | **Fixed:** `NavigationRail` from 840 dp, with one widget tree so tab state survives a resize |
| 9 | The booking contact phone wasn't prefilled from the profile, and name/phone missed the profile when it loaded after the form (deep link). | P2 | **Fixed** |
| 10 | Saved tab had no refresh, so favourites saved on another device never appeared until restart. | P2 | **Fixed:** quiet pull-to-refresh that keeps the list visible and reports failures |
| 11 | Trips re-fetched after returning from details, although the shared cubit already refreshes on create/cancel. | P2 (perf) | **Fixed:** duplicate request removed |
| 12 | The "account deleted" / "signed out locally" snack bars could be cleared by the app-wide sign-out listener. | P2 | **Fixed:** shown after the sign-out frame |
| 13 | Booking details had no way back to the destination. | P2 | **Fixed:** "View destination" |
| 14 | Home search hint wrapped to two lines on narrow phones. | P2 | **Fixed** |
| 15 | Advisors: unindexed FK `notifications.booking_id`; `rls_auto_enable()` executable by `anon`. | P2 | **Fixed** (index, revoke) |
| 16 | `.gitignore` lacked generic `.env` and release-signing patterns. | P2 | **Fixed** |
| 17 | Root `README.md` was still the Flutter template. | P2 | **Fixed** |
| 18 | Android manifest comment named the wrong deep-link path. | P3 | **Fixed** |
| 19 | Leaked-password protection is off. It's a dashboard toggle on Supabase Pro and above. | P2 | **Open:** dashboard / plan setting, documented |
| 20 | Release builds are signed with the debug key (no keystore). | P1 before store release | **Open:** belongs to the APK/release phase |
| 21 | Offline catalog cache; server-side full-text search for a larger catalog | P3 | Later (see PRODUCT_UX.md) |
| 22 | Reviews/ratings, payments | P3 | Intentionally not implemented; would need real backends, never faked |

## 3. Verified correct, no change needed

- **RLS, verified live with a forged other-user JWT (rolled back):**
  - 0 visible bookings, favourites, notifications, profiles and tokens;
  - `cancel_booking` on another user's booking → `booking_not_cancellable`;
  - direct booking update, inserting a favourite as another user, the push RPCs and Vault → `42501`;
  - avatar objects invisible.
- **Anonymous access:** the catalog (20/40) is readable; bookings, profiles, token registration, cancellation and booking inserts are all refused (`42501`).
- **Bookings:**
  - price, currency, owner and status are set by the trigger; the client can only insert the chosen columns;
  - idempotency via `(user_id, client_request_id)`;
  - the client never claims success without the stored row.
- **Session switching:** favourites, notifications, profile, recently viewed, booking details and device notifications all clear or reload per user.
- **Errors:** every repository maps to `AppFailure` and localized text, with timeouts on Supabase (15–60 s) and Open-Meteo (10 s). No raw exceptions reach the UI.
- **Edge Function:** the shared-secret check, single-use claim, owner-only tokens, masked token logging and no credential in the client are unchanged and their tests pass.

## 4. What still can't be verified without Android

- **Push and permissions:** FCM token issuance, the permission prompt, background/terminated push display, and tap-to-open.
- **Reminders:** trip-reminder delivery and reboot rescheduling (`ScheduledNotificationBootReceiver`).
- **Deep links and media:** `rahala://` links from outside the app, auth-callback links, the camera/gallery picker, the Android share sheet.
- **Platform UI:** Android back gesture/predictive back, system font scaling, and the notification icon and colour.

## 5. Still to do

1. ~~Firebase service-account secret~~ **Done in Phase 10A** (configured and verified by the `fcm_auth` handshake).
2. **Android device pass:** run the checklist above on a device or emulator.
3. **Release signing:** a release keystore plus `key.properties` (git-ignored), and optionally a new application id. That needs a matching Firebase Android app first.
4. **Supabase:** enable leaked-password protection when the plan allows; review Auth email templates and SMTP for production volume.
