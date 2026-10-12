import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

import '../../core/errors/app_failure.dart';
import '../../core/utils/app_logger.dart';
import '../models/json_read.dart';

/// Coarse weather groups from WMO weather interpretation codes, as used by
/// Open-Meteo (https://open-meteo.com/en/docs#weathervariables).
enum WeatherKind { clear, partlyCloudy, cloudy, fog, drizzle, rain, snow, showers, thunderstorm, unknown }

WeatherKind weatherKindFor(int code) => switch (code) {
      0 => WeatherKind.clear,
      1 || 2 => WeatherKind.partlyCloudy,
      3 => WeatherKind.cloudy,
      45 || 48 => WeatherKind.fog,
      >= 51 && <= 57 => WeatherKind.drizzle,
      >= 61 && <= 67 => WeatherKind.rain,
      >= 71 && <= 77 || 85 || 86 => WeatherKind.snow,
      >= 80 && <= 82 => WeatherKind.showers,
      >= 95 && <= 99 => WeatherKind.thunderstorm,
      _ => WeatherKind.unknown,
    };

class DailyForecast extends Equatable {
  const DailyForecast({required this.date, required this.kind, required this.maxC, required this.minC});
  final DateTime date;
  final WeatherKind kind;
  final double maxC;
  final double minC;

  @override
  List<Object?> get props => [date, kind, maxC, minC];
}

/// Current conditions and a short forecast at a destination, in the
/// destination's own local time zone. Real data from Open-Meteo.
class WeatherReport extends Equatable {
  const WeatherReport({
    required this.temperatureC,
    required this.kind,
    required this.isDay,
    required this.daily,
    required this.observedAt,
  });

  factory WeatherReport.fromJson(Map<String, dynamic> json) {
    final current = json['current'];
    final daily = json['daily'];
    if (current is! Map<String, dynamic> || daily is! Map<String, dynamic>) {
      throw const FormatException('Missing current/daily weather');
    }
    List<T> list<T>(String key) {
      final value = daily[key];
      if (value is! List) throw FormatException('Missing daily.$key');
      return value.cast<T>();
    }

    final dates = list<String>('time');
    final codes = list<num>('weather_code');
    final maxes = list<num>('temperature_2m_max');
    final mins = list<num>('temperature_2m_min');
    return WeatherReport(
      temperatureC: current.number('temperature_2m'),
      kind: weatherKindFor(current.intOrNull('weather_code') ?? -1),
      isDay: (current.intOrNull('is_day') ?? 1) == 1,
      observedAt: DateTime.tryParse('${current['time']}') ?? DateTime.now(),
      daily: [
        for (var i = 0; i < dates.length && i < codes.length && i < maxes.length && i < mins.length; i++)
          DailyForecast(
            date: DateTime.parse(dates[i]),
            kind: weatherKindFor(codes[i].toInt()),
            maxC: maxes[i].toDouble(),
            minC: mins[i].toDouble(),
          ),
      ],
    );
  }

  final double temperatureC;
  final WeatherKind kind;
  final bool isDay;
  final List<DailyForecast> daily;

  /// Local time at the destination for the "current" values.
  final DateTime observedAt;

  @override
  List<Object?> get props => [temperatureC, kind, isDay, daily, observedAt];
}

abstract interface class WeatherRepository {
  Future<WeatherReport> fetch(double latitude, double longitude);
}

/// Open-Meteo forecast API: free, no API key, CORS-enabled (works on web).
/// Responses are cached in memory for [ttl] per location.
class OpenMeteoWeatherRepository implements WeatherRepository {
  OpenMeteoWeatherRepository({Dio? dio, this.ttl = const Duration(minutes: 30), DateTime Function()? now})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://api.open-meteo.com',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            )),
        _now = now ?? DateTime.now;

  final Dio _dio;
  final Duration ttl;
  final DateTime Function() _now;
  final _cache = <String, ({WeatherReport report, DateTime at})>{};

  @override
  Future<WeatherReport> fetch(double latitude, double longitude) async {
    final key = '${latitude.toStringAsFixed(2)},${longitude.toStringAsFixed(2)}';
    final cached = _cache[key];
    if (cached != null && _now().difference(cached.at) < ttl) return cached.report;
    try {
      final response = await _dio.get<Map<String, dynamic>>('/v1/forecast', queryParameters: {
        'latitude': latitude.toStringAsFixed(4),
        'longitude': longitude.toStringAsFixed(4),
        'current': 'temperature_2m,weather_code,is_day',
        'daily': 'weather_code,temperature_2m_max,temperature_2m_min',
        'timezone': 'auto',
        'forecast_days': 4,
      });
      final body = response.data;
      if (body == null) throw const FormatException('Empty weather response');
      final report = WeatherReport.fromJson(body);
      _cache[key] = (report: report, at: _now());
      return report;
    } on DioException catch (e) {
      AppLogger.error('Weather request failed', error: e.type.name);
      throw AppFailure(
        e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout
            ? FailureType.timeout
            : e.response == null
                ? FailureType.network
                : FailureType.server,
        debugMessage: 'Open-Meteo: ${e.type.name} ${e.response?.statusCode ?? ''}',
      );
    } on FormatException catch (e) {
      throw AppFailure(FailureType.invalidData, debugMessage: e.message);
    } on TypeError catch (e) {
      throw AppFailure(FailureType.invalidData, debugMessage: '$e');
    }
  }
}
