import 'dart:math';

final _random = Random.secure();

/// RFC 4122 version-4 UUID from a cryptographically secure source.
String generateUuidV4() {
  final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC 4122 variant
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// Deterministic, platform-independent 64-bit digest (two FNV-1a 32-bit
/// passes with different offsets) as 16 hex characters. Not cryptographic —
/// used to key local records without storing the input (e.g. contact
/// details) in plain text. Uses only 32-bit-safe arithmetic so web and native
/// produce identical results.
String stableDigest(String input) {
  final units = input.codeUnits;
  int fnv(int offset) {
    var h = offset;
    for (final unit in units) {
      h ^= unit & 0xff;
      h = _mulFnvPrime(h);
      h ^= (unit >> 8) & 0xff;
      h = _mulFnvPrime(h);
    }
    return h;
  }

  return fnv(0x811c9dc5).toRadixString(16).padLeft(8, '0') + fnv(0x01000193).toRadixString(16).padLeft(8, '0');
}

/// h × 16777619 mod 2³² using shifts (16777619 = 2²⁴ + 2⁸ + 2⁷ + 2⁴ + 2¹ + 2⁰).
int _mulFnvPrime(int h) =>
    (h +
        ((h << 1) & 0xffffffff) +
        ((h << 4) & 0xffffffff) +
        ((h << 7) & 0xffffffff) +
        ((h << 8) & 0xffffffff) +
        ((h << 24) & 0xffffffff)) &
    0xffffffff;
