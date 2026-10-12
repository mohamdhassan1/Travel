/// Normalizes text for forgiving, language-aware matching:
///
/// * case-insensitive; Latin accents removed (`Türkiye` ≈ `turkiye`)
/// * Arabic: diacritics (tashkeel) and tatweel removed; alef forms (أ إ آ ٱ)
///   → ا, taa marbuta ة → ه, alef maqsura ى → ي, hamza seats ؤ ئ → و ي
/// * whitespace collapsed
String normalizeForSearch(String input) {
  final buffer = StringBuffer();
  for (final rune in input.toLowerCase().runes) {
    final mapped = _map[rune];
    if (mapped == '') continue; // dropped mark
    buffer.write(mapped ?? String.fromCharCode(rune));
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// True if every word of [query] occurs in [haystack] (both normalized).
bool matchesAllWords(String haystack, String query) {
  final q = normalizeForSearch(query);
  if (q.isEmpty) return true;
  final h = normalizeForSearch(haystack);
  return q.split(' ').every(h.contains);
}

final Map<int, String> _map = {
  // Arabic marks: fathatan … sukun, superscript alef, tatweel.
  for (var c = 0x064B; c <= 0x0652; c++) c: '',
  0x0670: '',
  0x0640: '',
  // Arabic letter variants.
  0x0623: 'ا', 0x0625: 'ا', 0x0622: 'ا', 0x0671: 'ا',
  0x0629: 'ه', 0x0649: 'ي', 0x0624: 'و', 0x0626: 'ي',
  // Latin accents (common in destination / country names).
  for (final c in 'àáâãäå'.runes) c: 'a',
  for (final c in 'èéêë'.runes) c: 'e',
  for (final c in 'ìíîïı'.runes) c: 'i',
  for (final c in 'òóôõöø'.runes) c: 'o',
  for (final c in 'ùúûü'.runes) c: 'u',
  for (final c in 'çć'.runes) c: 'c',
  for (final c in 'ñ'.runes) c: 'n',
  for (final c in 'şš'.runes) c: 's',
  for (final c in 'ğ'.runes) c: 'g',
  for (final c in 'ÿý'.runes) c: 'y',
};
