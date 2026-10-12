import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Thin logging facade. Never pass passwords, tokens or keys to it.
abstract final class AppLogger {
  static void info(String message, {String name = 'rahala'}) {
    if (kDebugMode) developer.log(message, name: name);
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String name = 'rahala',
  }) {
    developer.log(
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }
}
