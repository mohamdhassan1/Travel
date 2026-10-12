import 'package:shared_preferences/shared_preferences.dart';

import 'catalog_repository.dart' show isUuid;

/// Destinations the user opened recently, kept on this device only and per
/// account (keyed by user id), newest first. Nothing is sent to a server.
class RecentlyViewedStore {
  RecentlyViewedStore(this._prefs);

  final SharedPreferences _prefs;
  static const maxEntries = 10;

  static String _key(String userId) => 'recently_viewed.$userId';

  List<String> read(String userId) =>
      (_prefs.getStringList(_key(userId)) ?? const []).where(isUuid).take(maxEntries).toList();

  Future<List<String>> record(String userId, String destinationId) async {
    final ids = [destinationId, ...read(userId).where((id) => id != destinationId)].take(maxEntries).toList();
    await _prefs.setStringList(_key(userId), ids);
    return ids;
  }

  Future<void> clear(String userId) => _prefs.remove(_key(userId));
}
