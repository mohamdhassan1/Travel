import 'dart:convert';

/// Problems that make the build unusable against the backend.
enum ConfigIssue { missing, invalidUrl, secretKey }

/// Build-time configuration, injected with
/// `--dart-define-from-file=env/dev.json` (see `env/example.json`).
///
/// Only the Supabase *publishable* key belongs in the client. [validate]
/// refuses secret / service-role keys so they can never ship by accident.
class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabasePublishableKey,
  });

  factory AppConfig.fromEnvironment() => const AppConfig(
        supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
        supabasePublishableKey: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
      );

  final String supabaseUrl;
  final String supabasePublishableKey;

  /// Custom-scheme link Supabase redirects to after email confirmation and
  /// password recovery. Must be listed under Auth → URL Configuration →
  /// Redirect URLs in the Supabase dashboard.
  static const authRedirectUrl = 'rahala://rahala.app/auth-callback';

  ConfigIssue? validate() {
    if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
      return ConfigIssue.missing;
    }
    final uri = Uri.tryParse(supabaseUrl);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return ConfigIssue.invalidUrl;
    }
    if (_isSecretKey(supabasePublishableKey)) return ConfigIssue.secretKey;
    return null;
  }

  static bool _isSecretKey(String key) {
    if (key.startsWith('sb_secret_')) return true;
    // Legacy JWT-style keys: inspect the (unsigned) payload's `role` claim.
    final parts = key.split('.');
    if (parts.length != 3) return false;
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final claims = jsonDecode(payload);
      return claims is Map && claims['role'] == 'service_role';
    } on FormatException {
      return false;
    }
  }
}
