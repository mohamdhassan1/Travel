# Rahala — product & UX notes (Phase 8)

## Design direction

The look is **calm, photo-led travel**. Destination photography carries the emotion, and the UI stays quiet around it.

- **Brand:** teal (sea and sky) with a terracotta accent (sand and stone), unchanged from earlier phases.
- **Typography:** Plus Jakarta Sans for Latin text and IBM Plex Sans Arabic for Arabic. Bold titles with generous line height.
- **One card language:**
  - photo cards with a bottom gradient scrim and white text, radius 20;
  - content cards with a hairline border, radius 16.
- **Motion:** restrained.
  - Cards scale to 97% while pressed. The heart "pops" when saved, and the level progress bar fills in.
  - Skeletons shimmer slowly; sections and the profile photo cross-fade.
  - All of it respects the OS "reduce motion" setting.

## Design tokens (`lib/core/theme/`)

| Token | Values |
|---|---|
| Spacing | 4 · 8 · 12 · 16 · 20 · 24 · 32 · 48 |
| Radius | sm 8 · md 12 · lg 16 · **card 20** · xl 24 · pill |
| Aspect ratios (`AppAspect`) | wide 16:10 (lists), portrait 3:4 (Home carousels), tile 4:5 (Explore grid) |
| Motion (`AppDurations`, `AppCurves`) | 150 / 250 / 400 ms; easeOutCubic (standard), easeOutBack (emphasis) |
| Touch targets | 48 dp minimum for icon buttons (themed) |

### Dark mode fix

Cards, inputs, dialogs, sheets and the navigation bar used `surfaceContainerLowest`. In dark mode that colour is darker than the page, so elevation looked inverted. They now use a *raised* surface: white on the light page, and one step brighter than the page in dark mode. A unit test checks the luminance order.

Hard-coded colours remain only for white text on photo scrims, which is intentional.

## Navigation

A GoRouter `StatefulShellRoute` with five tabs: **Home · Explore · Trips · Saved · Profile**.

- **Per-tab state:** each tab keeps its own stack and scroll position. Re-tapping the active tab returns it to its root.
- **Wide windows** (840 dp and up: tablets, desktop web) show the tabs in a side `NavigationRail` instead of the bottom bar. Both layouts share one widget tree, so tab stacks survive a resize.
- **Notifications** aren't a tab. They're opened less often than the tabs, so they live behind the bell on Home and in the Profile menu, both with unread badges.
- **Full-screen pages** use the root navigator, so they cover the tab bar and Back works as expected: destination details, the booking flow, booking details, notifications, settings and edit profile. Bottom sheets use the root navigator too, so they appear above the tab bar.
- **Paths unchanged** for deep links and push taps: `/destinations/:id`, `/bookings/:id`, `/notifications`. The legacy `/destinations` path redirects to Explore.

## Screens

**Home**
- **Greeting:** the profile's first name plus a time of day.
- **Header:** notification bell with badge, and the avatar, which opens Profile.
- **Search entry:** opens Explore with the search box focused.
- **Your next trip:** the user's soonest confirmed upcoming booking, with a countdown. With no upcoming trips it shows an honest empty card with an Explore button.
- **Browse by type:** the real categories; each opens Explore pre-filtered.
- **Featured destinations:** the catalog's own `is_featured` flag. No popularity numbers are invented.
- **Recently viewed:** stored on the device, per account.
- **Saved shortcut:** shown when the user has saved destinations.
- **More to explore:** every other destination.
- Pull to refresh, skeletons, and separate error states for trips and for the catalog.

**Explore**
- **Search:** debounced input with a clear button.
- **Filters:** category chips; a filter sheet with maximum starting price (slider range taken from real package prices) and trip length (from the package durations); a sort menu (featured, price up or down, name).
- Result count, a responsive grid of 2, 3 or 4 columns, and loading, empty, error and no-match states.
- **Matching:** searches English **and** Arabic names, countries and summaries in either UI language. Text is normalized: case, Latin accents, Arabic diacritics, tatweel, and the letter variants أإآٱ→ا, ة→ه, ى→ي.
- **Why on-device:** the catalog is one cached request of about 20 rows, so filtering it locally is instant and can't race. If the catalog grows into the hundreds, move to a server-side search RPC with full-text search.

**Profile**
- **Identity:** photo, name, email (shown left-to-right in Arabic too), phone, verification status and member-since date.
- **Traveler level** with a progress bar and a "How levels work" sheet.
- **Statistics:** trips taken, upcoming, destinations visited, countries visited.
- **Menu:** Edit profile, Notifications (with unread count), Settings, Sign out, and **Delete account** (Phase 9).
- **Delete account:** a confirmation dialog whose button stays disabled until "I understand this can't be undone" is ticked.
  - The app removes the user's photo files, then calls `delete_my_account`, which deletes the user and everything they own.
  - Only after the server succeeds is the user signed out and told the account was deleted. A refusal leaves them signed in, with a reason.
- **Change password** lives in Settings → Account. It reuses the reset screen with signed-in wording and a back button; the recovery-link flow is unchanged.

**Edit profile**
- **Fields:** name and phone, validated exactly like the database CHECK constraints.
- **Email** is read-only. There is **no password field**, so a password can't be overwritten by accident; reset has its own flow.
- **Save** is enabled only when something changed. Leaving with unsaved edits asks whether to discard them.

**Profile photo**
- **Picking** uses `image_picker`, reading the file as bytes so it works on Android and the web. It's resized to at most 1024 px at quality 85; files over 2 MB are refused before upload, and the bucket enforces the same limit.
- **Uploading** writes to the private `avatars` bucket at `<uid>/avatar-<timestamp>.<ext>`. The profile is then pointed at the new file, and only after that is the old file deleted. If the profile update fails, the new upload is removed so nothing is orphaned.
- **Displaying** uses signed URLs valid for one hour, refreshed when Profile is opened. A missing file falls back to initials.
- **Account switching:** the app-level `ProfileCubit` clears on sign-out and on a change of account, so the previous user's name and photo are never shown.

**Destination details** gains:
- **Weather now** from Open-Meteo (see below);
- a **Share** button, which shares the name, summary and `rahala://` link through the system share sheet;
- a **full-screen gallery**: tap a photo to swipe, pinch or double-tap to zoom. Previous/next buttons (mirrored in RTL) make it usable with a mouse on the web and with screen readers;
- recording of the visit as recently viewed.

## Traveler level: what it is and isn't

The level is derived **only** from the user's own bookings:

- **Completed trip:** a confirmed booking whose travel date has passed. The database has no "completed" status; this is the same rule as the "Past" filter in Trips.
- **Levels:**
  - New traveler: no completed trips;
  - Explorer: 1 completed trip;
  - Voyager: 3 trips in 2 or more countries;
  - Globetrotter: 6 trips in 3 or more countries.
- Cancelled bookings never count.
- The UI explains this, and says plainly that it **isn't a rating from other people**.

A real rating system needs a reviews model (who can review, verified stays, moderation). That's proposed for a later phase rather than faked here.

## Weather

- **Source:** Open-Meteo forecast API. It's free, needs no key and supports CORS. The `dio` package was already a dependency for this.
- **Data:** the destination's real coordinates, the current temperature and condition, and 3 days of highs and lows in the destination's own time zone.
- **Caching:** 30 minutes in memory per location.
- **Failure handling:** loads independently, so a failure shows a small retry card and never blocks the page.
- **Attribution:** shown under the card.

## Product ideas, classified

| | Idea | Status |
|---|---|---|
| A | Home, bottom navigation, Explore search and filters, Profile with real statistics, profile photo, traveler level | **Done** |
| A | Weather on destination pages | **Done** |
| A | Recently viewed (device-local, per account) | **Done** |
| A | Trip countdown on Home | **Done** |
| A | Share destination | **Done** |
| A | Skeletons, pull to refresh, press feedback, dark-mode surface fix | **Done** |
| A | Catalog expanded to 20 destinations, balancing the categories | **Done** |
| B | Reviews and ratings (needs a verified-stay reviews model, moderation and RLS) | Later |
| B | Trip preparation checklist per booking (needs a table) | Later |
| B | Booking status timeline (needs status history; the database stores only the current status) | Later |
| B | Saved searches and alerts | Later |
| B | Offline catalog cache, e.g. a persisted catalog snapshot | Later |
| B | Server-side search RPC (full-text, Arabic-aware) once the catalog grows | Later |
| B | Notification preferences on the server (opt out of push per type) | Later |
| B | Universal links (https) instead of the custom scheme | Later |
| C | "Most popular", discounts, limited-time offers, availability counters | **Not appropriate:** no real data behind them |
| C | User-to-user ratings without a review backend | **Not appropriate** |
