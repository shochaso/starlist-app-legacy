import 'package:test/test.dart';

import 'package:starlist_app/src/features/star_data/utils/star_data_pack_id.dart';

void main() {
  group('buildPackId', () {
    test('builds expected format for standard inputs', () {
      final result = buildPackId('hanayama-mizuki', DateTime(2025, 10, 7));
      expect(result, 'hanayama-mizuki::2025-10-07');
    });

    test('pads month and day with zeros when needed', () {
      final result = buildPackId('kato-junichi', DateTime(2025, 3, 5));
      expect(result, 'kato-junichi::2025-03-05');
    });

    test('throws when username is empty or whitespace', () {
      expect(() => buildPackId(' ', DateTime(2025, 4, 1)),
          throwsA(isA<ArgumentError>()));
    });
  });
}
