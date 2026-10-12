import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/app_logger.dart';
import '../../core/utils/ids.dart';
import 'catalog_repository.dart' show isUuid;

/// Remembers the idempotency key of each booking attempt whose outcome is
/// unknown (e.g. the connection dropped after the request was sent), so a
/// retry — even after the app was closed — sends the same key and the
/// database returns the booking it may already have created instead of
/// creating a second one.
///
/// Entries are keyed by [BookingRequest.fingerprint] (a hash, so no contact
/// details are stored) and expire after [ttl]. Only a random UUID and a
/// timestamp are persisted.
class BookingRequestIdStore {
  BookingRequestIdStore(
    this._prefs, {
    String Function()? generateId,
    DateTime Function()? now,
    this.ttl = const Duration(hours: 48),
  })  : _generateId = generateId ?? generateUuidV4,
        _now = now ?? DateTime.now;

  final SharedPreferences _prefs;
  final String Function() _generateId;
  final DateTime Function() _now;
  final Duration ttl;

  static const storageKey = 'booking.pending_request_ids';

  /// The key for the attempt identified by [fingerprint]: the stored one if
  /// a previous attempt is still unresolved, otherwise a new one (persisted
  /// before it is sent).
  Future<String> idFor(String fingerprint) async {
    final entries = _read();
    final existing = entries[fingerprint];
    if (existing != null) return existing.id;
    final id = _generateId();
    entries[fingerprint] = _Entry(id, _now());
    await _write(entries);
    return id;
  }

  /// Forgets [fingerprint] once its outcome is known (booked, or definitely
  /// rejected), so the next identical booking is a new attempt.
  Future<void> release(String fingerprint) async {
    final entries = _read();
    if (entries.remove(fingerprint) != null) await _write(entries);
  }

  /// Unexpired entries; anything unreadable is treated as absent.
  Map<String, _Entry> _read() {
    final raw = _prefs.getString(storageKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return {};
      final cutoff = _now().subtract(ttl);
      final entries = <String, _Entry>{};
      decoded.forEach((key, value) {
        if (value is! Map<String, dynamic>) return;
        final id = value['id'];
        final at = DateTime.tryParse('${value['at']}');
        if (id is String && isUuid(id) && at != null && at.isAfter(cutoff)) entries[key] = _Entry(id, at);
      });
      return entries;
    } on FormatException catch (error) {
      AppLogger.error('Discarding unreadable booking request ids', error: error);
      return {};
    }
  }

  Future<void> _write(Map<String, _Entry> entries) => entries.isEmpty
      ? _prefs.remove(storageKey)
      : _prefs.setString(
          storageKey,
          jsonEncode({
            for (final e in entries.entries) e.key: {'id': e.value.id, 'at': e.value.at.toUtc().toIso8601String()},
          }),
        );
}

class _Entry {
  const _Entry(this.id, this.at);
  final String id;
  final DateTime at;
}
