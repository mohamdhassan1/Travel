import 'package:flutter_test/flutter_test.dart';
import 'package:rahala/core/errors/app_failure.dart';
import 'package:rahala/data/models/catalog_models.dart';
import 'package:rahala/data/models/user_profile.dart';
import 'package:rahala/data/repositories/catalog_repository.dart';

import '../helpers/fake_data_repositories.dart';

void main() {
  group('DestinationSummary.fromJson', () {
    test('parses a destination_summaries row', () {
      final d = DestinationSummary.fromJson(destinationRow());
      expect(d.slug, 'cairo');
      expect(d.name('en'), 'Cairo');
      expect(d.name('ar'), 'القاهرة');
      expect(d.country('ar'), 'مصر');
      expect(d.fromPrice, 180);
      expect(d.currency, 'USD');
      expect((d.minDays, d.maxDays), (2, 4));
      expect(d.hasPackages, isTrue);
    });

    test('accepts numeric values serialised as strings', () {
      final d = DestinationSummary.fromJson({
        ...destinationRow(),
        'from_price': '420.50',
        'latitude': '30.0444',
      });
      expect(d.fromPrice, 420.5);
      expect(d.latitude, closeTo(30.0444, 1e-9));
    });

    test('trims char(3) padding from the currency', () {
      expect(
        DestinationSummary.fromJson({
          ...destinationRow(),
          'currency': 'USD ',
        }).currency,
        'USD',
      );
    });

    test(
      'a destination without packages has no price instead of a fake one',
      () {
        final d = DestinationSummary.fromJson(
          destinationRow(fromPrice: null, packageCount: 0),
        );
        expect(d.fromPrice, isNull);
        expect(d.hasPackages, isFalse);
      },
    );

    test('rejects rows missing required fields', () {
      expect(
        () => DestinationSummary.fromJson(
          {...destinationRow()}..remove('name_en'),
        ),
        throwsFormatException,
      );
      expect(
        () => DestinationSummary.fromJson({
          ...destinationRow(),
          'cover_image': '',
        }),
        throwsFormatException,
      );
      expect(
        () => DestinationSummary.fromJson({
          ...destinationRow(),
          'latitude': 'north',
        }),
        throwsFormatException,
      );
      expect(
        () => DestinationSummary.fromJson({
          ...destinationRow(),
          'is_featured': 'yes',
        }),
        throwsFormatException,
      );
    });
  });

  group('parseRows', () {
    test('skips individually malformed rows', () {
      final rows = [
        destinationRow(),
        {...destinationRow(slug: 'bad')}..remove('slug'),
        destinationRow(slug: 'rome'),
      ];
      final parsed = parseRows(rows, DestinationSummary.fromJson, 'test');
      expect(parsed.map((d) => d.slug), ['cairo', 'rome']);
    });

    test('fails when every row is malformed', () {
      expect(
        () => parseRows(
          [
            <String, dynamic>{'id': 'x'},
          ],
          DestinationSummary.fromJson,
          'test',
        ),
        throwsA(
          isA<AppFailure>().having(
            (f) => f.type,
            'type',
            FailureType.invalidData,
          ),
        ),
      );
    });

    test('an empty result is valid (empty state, not an error)', () {
      expect(parseRows(const [], DestinationSummary.fromJson, 'test'), isEmpty);
    });
  });

  test('TravelCategory.fromJson', () {
    final c = TravelCategory.fromJson(const {
      'id': 'beach',
      'name_en': 'Beaches',
      'name_ar': 'شواطئ',
      'icon': 'beach',
      'sort_order': 3,
    });
    expect(c.name('ar'), 'شواطئ');
    expect(c.sortOrder, 3);
  });

  test('UserProfile.fromJson tolerates an empty name and parses dates', () {
    final p = UserProfile.fromJson(const {
      'id': 'u1',
      'full_name': '',
      'phone': null,
      'avatar_path': null,
      'preferred_locale': 'ar',
      'created_at': '2026-10-01T10:00:00+00:00',
      'updated_at': '2026-10-01T10:00:00+00:00',
    });
    expect(p.fullName, '');
    expect(p.preferredLocale, 'ar');
    expect(p.createdAt, DateTime.utc(2026, 10, 1, 10));
  });
}
