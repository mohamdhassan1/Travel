import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rahala/core/config/app_config.dart';

String _legacyJwt(String role) {
  String part(Map<String, Object> m) => base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${part({'alg': 'HS256'})}.${part({'role': role, 'iss': 'supabase'})}.signature';
}

void main() {
  const url = 'https://abc.supabase.co';

  test('missing values are reported', () {
    expect(
      const AppConfig(supabaseUrl: '', supabasePublishableKey: 'k').validate(),
      ConfigIssue.missing,
    );
    expect(
      const AppConfig(supabaseUrl: url, supabasePublishableKey: '').validate(),
      ConfigIssue.missing,
    );
  });

  test('url must be https', () {
    expect(
      const AppConfig(
        supabaseUrl: 'http://abc.supabase.co',
        supabasePublishableKey: 'sb_publishable_x',
      ).validate(),
      ConfigIssue.invalidUrl,
    );
    expect(
      const AppConfig(
        supabaseUrl: 'not a url',
        supabasePublishableKey: 'sb_publishable_x',
      ).validate(),
      ConfigIssue.invalidUrl,
    );
  });

  test('publishable and legacy anon keys are accepted', () {
    expect(
      const AppConfig(
        supabaseUrl: url,
        supabasePublishableKey: 'sb_publishable_abc',
      ).validate(),
      isNull,
    );
    expect(
      AppConfig(
        supabaseUrl: url,
        supabasePublishableKey: _legacyJwt('anon'),
      ).validate(),
      isNull,
    );
  });

  test('secret and service-role keys are refused', () {
    expect(
      const AppConfig(
        supabaseUrl: url,
        supabasePublishableKey: 'sb_secret_abc',
      ).validate(),
      ConfigIssue.secretKey,
    );
    expect(
      AppConfig(
        supabaseUrl: url,
        supabasePublishableKey: _legacyJwt('service_role'),
      ).validate(),
      ConfigIssue.secretKey,
    );
  });
}
