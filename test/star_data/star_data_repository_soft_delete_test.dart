import 'package:flutter_test/flutter_test.dart';
import 'package:starlist_app/src/features/star_data/domain/star_data_item.dart';
import 'package:starlist_app/src/features/star_data/infrastructure/mock_star_data_repository.dart';

void main() {
  test('MockStarDataRepository hides items', () async {
    final repository = MockStarDataRepository();
    final starId = 'star_hanayama_mizuki';
    final items = await repository.fetchStarData(starId: starId);
    final target = items.first;

    expect(items.map((item) => item.id), contains(target.id));
    await repository.hideStarDataItem(id: target.id, starId: starId);

    final after = await repository.fetchStarData(starId: starId);
    expect(after.map((item) => item.id), isNot(contains(target.id)));
  });
}
