import 'package:intl/intl.dart';

/// Locale-aware money formatting: no decimals for whole amounts.
String formatPrice(double amount, String currency, String localeTag) {
  final whole = amount == amount.roundToDouble();
  return NumberFormat.simpleCurrency(
    locale: localeTag,
    name: currency,
    decimalDigits: whole ? 0 : 2,
  ).format(amount);
}
