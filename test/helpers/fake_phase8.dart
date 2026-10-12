import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:rahala/core/errors/app_failure.dart';
import 'package:rahala/data/media/photo_picker.dart';
import 'package:rahala/data/media/share_service.dart';
import 'package:rahala/data/repositories/weather_repository.dart';

/// Returns a fixed report (or a failure) without any network.
class FakeWeatherRepository implements WeatherRepository {
  FakeWeatherRepository({this.failure});

  AppFailure? failure;
  int calls = 0;

  static final report = WeatherReport(
    temperatureC: 24.4,
    kind: WeatherKind.clear,
    isDay: true,
    observedAt: DateTime(2026, 10, 3, 12),
    daily: [
      DailyForecast(date: DateTime(2026, 10, 3), kind: WeatherKind.clear, maxC: 27, minC: 18),
      DailyForecast(date: DateTime(2026, 10, 4), kind: WeatherKind.partlyCloudy, maxC: 26, minC: 17),
      DailyForecast(date: DateTime(2026, 10, 5), kind: WeatherKind.rain, maxC: 22, minC: 16),
    ],
  );

  @override
  Future<WeatherReport> fetch(double latitude, double longitude) async {
    calls++;
    final f = failure;
    if (f != null) throw f;
    return report;
  }
}

/// Hands back [next] (or null = cancelled).
class FakePhotoPicker implements PhotoPicker {
  FakePhotoPicker({this.canUseCamera = true, this.next});

  @override
  final bool canUseCamera;
  PickedPhoto? next;
  final sources = <PhotoSource>[];

  static PickedPhoto jpeg([int size = 1024]) =>
      PickedPhoto(Uint8List.fromList([0xFF, 0xD8, ...List.filled(size - 2, 1)]), 'image/jpeg');

  @override
  Future<PickedPhoto?> pick(PhotoSource source) async {
    sources.add(source);
    return next;
  }
}

/// Records shared text instead of opening a share sheet.
class FakeShareService implements ShareService {
  FakeShareService({this.available = true});
  bool available;
  final shared = <String>[];

  @override
  Future<bool> shareText(String text, {String? subject, Rect? origin}) async {
    if (!available) return false;
    shared.add(text);
    return true;
  }
}
