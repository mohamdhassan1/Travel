/// Strict readers for database rows. Missing or mistyped required fields
/// throw [FormatException] (mapped to `FailureType.invalidData`) instead of
/// silently producing half-empty models.
extension JsonRead on Map<String, dynamic> {
  String str(String key) {
    final value = this[key];
    if (value is String && value.isNotEmpty) return value;
    throw FormatException('Expected non-empty string for "$key"', value);
  }

  String? strOrNull(String key) {
    final value = this[key];
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    throw FormatException('Expected string or null for "$key"', value);
  }

  /// Postgres `numeric` may arrive as a JSON number or a string.
  double? numOrNull(String key) {
    final value = this[key];
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw FormatException('Expected number for "$key"', value);
  }

  double number(String key) => numOrNull(key) ?? (throw FormatException('Missing number for "$key"'));

  int? intOrNull(String key) => numOrNull(key)?.toInt();

  bool boolean(String key, {bool fallback = false}) {
    final value = this[key];
    if (value == null) return fallback;
    if (value is bool) return value;
    throw FormatException('Expected bool for "$key"', value);
  }

  /// Postgres `text[]`; `null` is treated as empty.
  List<String> strList(String key) {
    final value = this[key];
    if (value == null) return const [];
    if (value is List && value.every((e) => e is String)) return List.unmodifiable(value.cast<String>());
    throw FormatException('Expected list of strings for "$key"', value);
  }

  DateTime? dateOrNull(String key) {
    final value = this[key];
    if (value == null) return null;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw FormatException('Expected ISO date for "$key"', value);
  }
}

/// Picks the Arabic or English variant of a bilingual database field.
String pickLocalized(
  String languageCode, {
  required String en,
  required String ar,
}) =>
    languageCode == 'ar' ? ar : en;
