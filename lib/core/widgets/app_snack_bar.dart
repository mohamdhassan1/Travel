import 'package:flutter/material.dart';

extension AppSnackBar on BuildContext {
  /// Replaces any visible snack bar with [message].
  void showSnack(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), action: action));
  }
}
