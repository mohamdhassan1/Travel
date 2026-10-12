import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../logic/settings/settings_cubit.dart';
import 'l10n_extensions.dart';

/// One-tap English ⇄ Arabic switch. Shows the *other* language's name so
/// it's recognisable to a reader who can't read the current one.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key, this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return TextButton.icon(
      style: onDark ? TextButton.styleFrom(foregroundColor: Colors.white) : null,
      onPressed: () => context.read<SettingsCubit>().setLocale(
            Locale(isArabic ? 'en' : 'ar'),
          ),
      icon: const Icon(Icons.translate, size: 18),
      label: Text(isArabic ? l10n.languageEnglish : l10n.languageArabic),
    );
  }
}
