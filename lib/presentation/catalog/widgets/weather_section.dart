import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../data/repositories/weather_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../logic/catalog/weather_cubit.dart';
import '../../../logic/common/load_state.dart';
import '../../common/l10n_extensions.dart';

IconData weatherIcon(WeatherKind kind, {bool isDay = true}) => switch (kind) {
      WeatherKind.clear => isDay ? Icons.wb_sunny_outlined : Icons.nightlight_outlined,
      WeatherKind.partlyCloudy => isDay ? Icons.wb_cloudy_outlined : Icons.nights_stay_outlined,
      WeatherKind.cloudy => Icons.cloud_outlined,
      WeatherKind.fog => Icons.foggy,
      WeatherKind.drizzle || WeatherKind.rain || WeatherKind.showers => Icons.water_drop_outlined,
      WeatherKind.snow => Icons.ac_unit,
      WeatherKind.thunderstorm => Icons.thunderstorm_outlined,
      WeatherKind.unknown => Icons.device_thermostat,
    };

String weatherLabel(AppLocalizations l10n, WeatherKind kind) => switch (kind) {
      WeatherKind.clear => l10n.weatherClear,
      WeatherKind.partlyCloudy => l10n.weatherPartlyCloudy,
      WeatherKind.cloudy => l10n.weatherCloudy,
      WeatherKind.fog => l10n.weatherFog,
      WeatherKind.drizzle => l10n.weatherDrizzle,
      WeatherKind.rain => l10n.weatherRain,
      WeatherKind.snow => l10n.weatherSnow,
      WeatherKind.showers => l10n.weatherShowers,
      WeatherKind.thunderstorm => l10n.weatherThunderstorm,
      WeatherKind.unknown => l10n.weatherUnknown,
    };

/// "Weather now" at the destination, from Open-Meteo. Loads on its own: a
/// failure here never hides the rest of the destination.
class WeatherSection extends StatelessWidget {
  const WeatherSection({super.key, required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (context) => WeatherCubit(context.read<WeatherRepository>(), latitude, longitude)..load(),
        child: const _WeatherView(),
      );
}

class _WeatherView extends StatelessWidget {
  const _WeatherView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<WeatherCubit>().state;
    final muted = context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant);

    final Widget body = switch (state.status) {
      LoadStatus.loading || LoadStatus.empty => const SkeletonBox(height: 112, radius: AppRadius.lgAll),
      LoadStatus.failure => Card(
          child: ListTile(
            leading: const Icon(Icons.cloud_off_outlined),
            title: Text(l10n.weatherUnavailable),
            trailing: TextButton(onPressed: context.read<WeatherCubit>().load, child: Text(l10n.commonRetry)),
          ),
        ),
      LoadStatus.success => _Report(report: state.data!),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSwitcher(duration: AppDurations.medium, child: KeyedSubtree(key: ValueKey(state.status), child: body)),
        const SizedBox(height: AppSpacing.xxs),
        Text(l10n.weatherSource, style: muted),
      ],
    );
  }
}

class _Report extends StatelessWidget {
  const _Report({required this.report});
  final WeatherReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    String temp(double c) => l10n.weatherDegrees(c.round());
    final days = report.daily.take(3).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Semantics(
              label: '${weatherLabel(l10n, report.kind)}, ${temp(report.temperatureC)}',
              excludeSemantics: true,
              child: Row(
                children: [
                  Icon(weatherIcon(report.kind, isDay: report.isDay), size: 36, color: context.colors.secondary),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(temp(report.temperatureC), style: context.textStyles.headlineSmall),
                      Text(
                        weatherLabel(l10n, report.kind),
                        style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final day in days)
                    Flexible(
                      child: Semantics(
                        label: '${DateFormat.EEEE(locale).format(day.date)}: ${weatherLabel(l10n, day.kind)}, '
                            '${temp(day.maxC)} / ${temp(day.minC)}',
                        excludeSemantics: true,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(DateFormat.E(locale).format(day.date), style: context.textStyles.labelSmall),
                            const SizedBox(height: 2),
                            Icon(weatherIcon(day.kind), size: AppSizes.iconMd, color: context.colors.onSurfaceVariant),
                            const SizedBox(height: 2),
                            Text(
                              '${day.maxC.round()}° / ${day.minC.round()}°',
                              style: context.textStyles.labelSmall,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
