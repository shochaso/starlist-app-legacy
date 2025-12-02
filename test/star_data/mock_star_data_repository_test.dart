import 'package:flutter_test/flutter_test.dart';
import 'package:starlist_app/src/features/star_data/infrastructure/mock_star_data_repository.dart';

void main() {
  group('MockStarDataRepository', () {
    final repository = MockStarDataRepository();

    test('returns hanayama entries when starId matches', () async {
      final list = await repository.getStarData(starId: 'star_hanayama_mizuki');
      expect(list, isNotEmpty);
      expect(list.every((item) => item.starId == 'star_hanayama_mizuki'), isTrue);
    });

    test('falls back to generic when starId differs', () async {
      final list = await repository.getStarData(starId: 'star_unknown');
      expect(list, isNotEmpty);
      expect(list.first.starId, equals('star_generic'));
    });
  });
}


