import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/pump_app.dart';

Map<String, dynamic> _arb(String name) => jsonDecode(File('lib/l10n/$name').readAsStringSync()) as Map<String, dynamic>;

void main() {
  test(
    'Arabic ARB translates every English key with the same placeholders',
    () {
      final en = _arb('app_en.arb');
      final ar = _arb('app_ar.arb');
      Set<String> keys(Map<String, dynamic> m) => m.keys.where((k) => !k.startsWith('@')).toSet();
      Set<String> placeholders(String s) => RegExp(r'\{(\w+)\}').allMatches(s).map((m) => m[1]!).toSet();

      expect(keys(ar), keys(en), reason: 'ARB key sets differ');
      // Strings that are intentionally identical in both languages.
      const sameInBoth = {'authEmailHint', 'languageEnglish', 'languageArabic'};
      for (final key in keys(en)) {
        final e = en[key] as String;
        final a = ar[key] as String;
        expect(
          placeholders(a),
          placeholders(e),
          reason: 'placeholders differ for $key',
        );
        if (!sameInBoth.contains(key)) expect(a, isNot(e), reason: 'untranslated: $key');
      }
    },
  );

  testWidgets(
    'Arabic renders right-to-left with translated UI and validation',
    (tester) async {
      await pumpApp(
        tester,
        prefs: {'onboarding.completed': true, 'settings.locale': 'ar'},
      );

      expect(find.text('مرحبًا بعودتك'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.text('مرحبًا بعودتك'))),
        TextDirection.rtl,
      );

      await tester.tap(find.widgetWithText(FilledButton, 'تسجيل الدخول'));
      await tester.pumpAndSettle();
      expect(find.text('هذا الحقل مطلوب'), findsNWidgets(2));
    },
  );

  testWidgets('language switches at runtime from settings', (tester) async {
    await pumpApp(
      tester,
      repo: FakeAuthRepository(signedInAs: testUser),
      initialLocation: '/settings',
    );
    expect(
      Directionality.of(tester.element(find.text('Settings'))),
      TextDirection.ltr,
    );

    await tester.tap(find.text('العربية'));
    await tester.pumpAndSettle();

    expect(find.text('الإعدادات'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('الإعدادات'))),
      TextDirection.rtl,
    );
  });
}
