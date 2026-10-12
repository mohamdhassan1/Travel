import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/status_view.dart';
import '../l10n/app_localizations.dart';

/// Shown instead of the app when the build is missing (or has unsafe)
/// backend configuration — fails loudly rather than half-working.
class ConfigurationErrorApp extends StatelessWidget {
  const ConfigurationErrorApp({super.key, required this.issue});

  final ConfigIssue issue;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(const Locale('en'), useGoogleFonts: false),
      darkTheme: AppTheme.dark(const Locale('en'), useGoogleFonts: false),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return Scaffold(
            body: SafeArea(
              child: StatusView(
                icon: Icons.settings_suggest_outlined,
                tone: StatusTone.error,
                title: l10n.configErrorTitle,
                message: switch (issue) {
                  ConfigIssue.missing => l10n.configErrorMissing,
                  ConfigIssue.invalidUrl => l10n.configErrorInvalidUrl,
                  ConfigIssue.secretKey => l10n.configErrorSecretKey,
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
