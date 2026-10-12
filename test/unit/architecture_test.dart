import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static guards for layering and secrets.
void main() {
  Iterable<File> dartFiles(String dir) =>
      Directory(dir).listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  test('widgets never talk to Supabase, Firebase or the notification plugin directly', () {
    for (final file in dartFiles('lib/presentation')) {
      final source = file.readAsStringSync();
      for (final banned in ['supabase_flutter', 'firebase_core', 'firebase_messaging', 'flutter_local_notifications']) {
        expect(source, isNot(contains('package:$banned/')), reason: '${file.path} imports $banned');
      }
    }
  });

  test('Firebase and the notification plugin are only used behind their service interfaces', () {
    for (final file in dartFiles('lib')) {
      final source = file.readAsStringSync();
      final usesPlugins =
          source.contains('package:firebase_') || source.contains('package:flutter_local_notifications/');
      if (usesPlugins) {
        expect(file.path.replaceAll(r'\', '/'), startsWith('lib/data/notifications/'), reason: file.path);
      }
    }
  });

  test('no server credentials in source or platform config', () {
    final roots = ['lib', 'android', 'ios', 'web', 'supabase'];
    final banned = [
      RegExp(r'"type"\s*:\s*"service_account"'),
      // A real PEM body (placeholders in tests/docs don't match).
      RegExp(r'-----BEGIN (RSA )?PRIVATE KEY-----\s*[A-Za-z0-9+/]{40,}'),
      RegExp(r'"private_key_id"\s*:\s*"[0-9a-f]{20,}"'),
      RegExp(r'sb_secret_[A-Za-z0-9]'),
      RegExp(r'AAAA[A-Za-z0-9_-]{7}:APA91b'), // legacy FCM server key
    ];
    for (final root in roots) {
      final dir = Directory(root);
      if (!dir.existsSync()) continue;
      for (final file in dir.listSync(recursive: true).whereType<File>()) {
        final path = file.path.replaceAll(r'\', '/');
        if (path.contains('/build/') || path.contains('/.dart_tool/') || path.contains('/ephemeral/')) continue;
        if (!RegExp(r'\.(dart|json|plist|xml|gradle|kts|js|ts|toml|html|sql|properties|swift|md)$').hasMatch(path)) {
          continue;
        }
        final text = file.readAsStringSync();
        for (final pattern in banned) {
          expect(pattern.hasMatch(text), isFalse, reason: '$path matches $pattern');
        }
      }
    }
  });
}
