import 'dart:async';
import 'dart:ui';

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../../core/utils/app_logger.dart';
import '../../data/models/booking.dart';
import '../../data/notifications/local_reminder_notifier.dart';
import '../../l10n/app_localizations.dart';
import 'trip_reminder_policy.dart';

/// Keeps this device's scheduled trip reminders in line with the signed-in
/// user's bookings as last read from Supabase.
///
/// * Only confirmed bookings with a future reminder moment get one
///   ([TripReminderPolicy]); everything else is cancelled.
/// * One reminder per booking (stable id), so repeated syncs never duplicate:
///   an identical pending reminder is left alone, a changed one is replaced.
/// * Scoped to one user: [activate] on sign-in, [clear] on sign-out removes
///   every trip reminder so the next account never sees them.
/// * Operations run one at a time; failures are logged, never thrown — a
///   reminder problem must not break booking.
class TripReminderScheduler {
  TripReminderScheduler(
    this._notifier, {
    required bool Function() enabled,
    required Locale Function() locale,
    DateTime Function()? now,
    Duration Function(DateTime localWallClock)? utcOffsetAt,
  })  : _enabled = enabled,
        _locale = locale,
        _now = now ?? DateTime.now,
        _utcOffsetAt = utcOffsetAt;

  final LocalReminderNotifier _notifier;
  final bool Function() _enabled;
  final Locale Function() _locale;
  final DateTime Function() _now;
  final Duration Function(DateTime localWallClock)? _utcOffsetAt;

  String? _userId;

  /// Last known state of the active user's bookings, by id.
  final _bookings = <String, Booking>{};
  Future<void> _queue = Future.value();

  String? get activeUserId => _userId;

  /// Starts tracking [userId]'s bookings. A different user first clears
  /// everything left from the previous one.
  Future<void> activate(String userId) => _enqueue('activate', () async {
        if (_userId == userId) return;
        await _cancelAllTripReminders();
        _bookings.clear();
        _userId = userId;
      });

  /// Signed out: no user, no reminders.
  Future<void> clear() => _enqueue('clear', () async {
        _userId = null;
        _bookings.clear();
        await _cancelAllTripReminders();
      });

  /// The full list of [userId]'s bookings (e.g. My bookings, or the startup
  /// resync). Bookings missing from the list lose their reminders.
  Future<void> syncAll(String userId, List<Booking> bookings) => _enqueue('sync', () async {
        if (userId != _userId) return; // stale result for another session
        _bookings
          ..clear()
          ..addEntries(bookings.map((b) => MapEntry(b.id, b)));
        await _reconcile();
      });

  /// One booking was created, read or cancelled.
  Future<void> bookingChanged(String userId, Booking booking) => _enqueue('update', () async {
        if (userId != _userId) return;
        _bookings[booking.id] = booking;
        await _reconcile();
      });

  /// Re-applies the current preference / language without a network call.
  Future<void> resync() => _enqueue('resync', _reconcile);

  Future<void> _reconcile() async {
    if (!_notifier.isSupported) return;
    final now = _now();
    final lang = _locale().languageCode;
    final l10n = lookupAppLocalizations(Locale(lang));
    // Reminders may be built before the UI's localizations have loaded.
    await initializeDateFormatting(lang);

    final desired = <int, ({Booking booking, TripReminderPayload payload})>{};
    if (_userId != null && _enabled()) {
      for (final booking in _bookings.values) {
        final at = TripReminderPolicy.reminderTime(booking, now, utcOffsetAt: _utcOffsetAt);
        if (at == null) continue;
        desired[TripReminderPolicy.notificationId(booking.id)] = (
          booking: booking,
          payload: TripReminderPayload(bookingId: booking.id, at: at, languageCode: lang),
        );
      }
    }

    final pending = {
      for (final r in await _notifier.pending())
        if (TripReminderPayload.decode(r.payload) case final payload?) r.id: payload,
    };

    for (final id in pending.keys) {
      if (!desired.containsKey(id)) await _notifier.cancel(id);
    }
    for (final MapEntry(key: id, value: want) in desired.entries) {
      if (pending[id] == want.payload) continue; // already scheduled as wanted
      await _notifier.schedule(
        id: id,
        at: want.payload.at,
        title: _title(l10n, want.booking, lang),
        body: _body(l10n, want.booking, lang),
        payload: want.payload.encode(),
        channelName: l10n.tripReminderChannelName,
        channelDescription: l10n.tripReminderChannelDescription,
      );
    }
  }

  static String _title(AppLocalizations l10n, Booking booking, String lang) {
    final destination = booking.destination?.name(lang);
    return destination == null ? l10n.tripReminderTitleGeneric : l10n.tripReminderTitle(destination);
  }

  static String _body(AppLocalizations l10n, Booking booking, String lang) {
    final date = DateFormat.yMMMMEEEEd(lang).format(booking.travelDate);
    final package = booking.package?.name(lang);
    return package == null
        ? l10n.tripReminderBodyNoPackage(date, booking.reference)
        : l10n.tripReminderBody(package, date, booking.reference);
  }

  Future<void> _cancelAllTripReminders() async {
    if (!_notifier.isSupported) return;
    for (final r in await _notifier.pending()) {
      if (TripReminderPayload.decode(r.payload) != null) await _notifier.cancel(r.id);
    }
  }

  Future<void> _enqueue(String action, Future<void> Function() body) {
    final next = _queue.then((_) async {
      try {
        await body();
      } catch (error, stack) {
        AppLogger.error('Trip reminders: $action failed', error: error, stackTrace: stack);
      }
    });
    _queue = next;
    return next;
  }
}
