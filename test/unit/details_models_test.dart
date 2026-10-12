import 'package:flutter_test/flutter_test.dart';
import 'package:rahala/data/models/catalog_models.dart';

import '../helpers/fake_data_repositories.dart';

void main() {
  group('DestinationDetails.fromJson', () {
    test('parses a destinations row with localized fields', () {
      final d = DestinationDetails.fromJson(destinationDetailsRow());
      expect(d.name('en'), 'Cairo');
      expect(d.name('ar'), 'القاهرة');
      expect(d.description('ar'), startsWith('تجمع'));
      expect(d.bestSeason('en'), 'October – April');
      expect(d.bestSeason('ar'), 'أكتوبر – أبريل');
      expect(d.gallery, hasLength(2));
      expect(d.imageCredit, contains('Wikimedia'));
      expect(d.latitude, closeTo(30.0444, 1e-9));
    });

    test('optional fields may be null', () {
      final d = DestinationDetails.fromJson({
        ...destinationDetailsRow(),
        'best_season_en': null,
        'best_season_ar': null,
        'gallery': null,
        'image_credit': null,
      });
      expect(d.bestSeason('en'), isNull);
      expect(d.gallery, isEmpty);
      expect(d.imageCredit, isNull);
    });

    test('a single-language season falls back to the other language', () {
      final d = DestinationDetails.fromJson({...destinationDetailsRow(), 'best_season_ar': null});
      expect(d.bestSeason('ar'), 'October – April');
    });

    test('rejects malformed rows', () {
      expect(() => DestinationDetails.fromJson({...destinationDetailsRow()}..remove('description_en')),
          throwsFormatException);
      expect(
          () => DestinationDetails.fromJson({
                ...destinationDetailsRow(),
                'gallery': const [1, 2]
              }),
          throwsFormatException);
    });
  });

  group('TravelPackage.fromJson', () {
    test('parses a destination_packages row', () {
      final p = TravelPackage.fromJson(packageRow());
      expect(p.name('en'), 'Pyramids & Old Cairo Discovery');
      expect(p.name('ar'), 'اكتشاف الأهرامات والقاهرة القديمة');
      expect(p.durationDays, 4);
      expect(p.pricePerPerson, 420);
      expect(p.maxTravelers, 8);
      expect(p.includes('en'), contains('Airport transfers'));
      expect(p.includes('ar'), contains('التنقل من وإلى المطار'));
    });

    test('numeric(10,2) prices may arrive as strings; char(3) currency is trimmed', () {
      final p = TravelPackage.fromJson({...packageRow(), 'price_per_person': '1150.00', 'currency': 'USD '});
      expect(p.pricePerPerson, 1150);
      expect(p.currency, 'USD');
    });

    test('missing includes fall back to the other language, then to empty', () {
      expect(TravelPackage.fromJson({...packageRow(), 'includes_ar': const <String>[]}).includes('ar'), hasLength(2));
      expect(
          TravelPackage.fromJson({...packageRow(), 'includes_ar': null, 'includes_en': null}).includes('en'), isEmpty);
    });

    test('rejects values that would mislead the traveller', () {
      expect(() => TravelPackage.fromJson({...packageRow(), 'price_per_person': 0}), throwsFormatException);
      expect(() => TravelPackage.fromJson({...packageRow(), 'duration_days': 0}), throwsFormatException);
      expect(() => TravelPackage.fromJson({...packageRow(), 'max_travelers': null}), throwsFormatException);
      expect(() => TravelPackage.fromJson({...packageRow()}..remove('currency')), throwsFormatException);
    });
  });
}
