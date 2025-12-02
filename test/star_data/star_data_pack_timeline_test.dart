import 'package:flutter_test/flutter_test.dart';
import 'package:starlist_app/src/features/star_data/domain/star_data_item.dart';
import 'package:starlist_app/src/features/star_data/domain/star_data_pack.dart';
import 'package:starlist_app/src/features/star_data/utils/star_data_category_definitions.dart';
import 'package:starlist_app/src/features/star_data/utils/star_data_pack_timeline.dart';

StarDataPack _makePack({
  required String id,
  required DateTime date,
  required String category,
  int count = 1,
  String mainSummary = 'summary',
  String? secondary,
}) {
  // Helper mapping for test
  final catEnum = StarDataCategory.fromString(category);
  
  final item = StarDataItem(
    id: 'item-$id',
    starId: 'star_timeline',
    date: date,
    category: category,
    genre: 'genre_$category',
    title: 'Title $category',
    subtitle: 'Subtitle $category',
    source: 'Source',
    createdAt: DateTime.now(),
  );
  return StarDataPack(
    id: id,
    starId: 'star_timeline',
    date: date,
    categoryCounts: {category: count},
    mainCategory: category,
    mainSummaryText: mainSummary,
    secondarySummaryText: secondary,
    items: [item],
    resolvedCategory: catEnum,
    resolvedGenre: StarDataGenre.other,
  );
}

void main() {
  test('findTodayStarDataPack and past limit work', () {
    final now = DateTime.now();
    final todayPack = _makePack(
      id: 'today',
      date: now,
      category: 'youtube',
      count: 2,
      mainSummary: 'YouTube視聴',
    );
    final yesterday = _makePack(
      id: 'yesterday',
      date: now.subtract(const Duration(days: 1)),
      category: 'shopping',
      count: 3,
    );
    final twoDaysAgo = _makePack(
      id: 'twoDays',
      date: now.subtract(const Duration(days: 2)),
      category: 'music',
      count: 1,
    );

    final packs = [todayPack, yesterday, twoDaysAgo];
    expect(findTodayStarDataPack(packs), todayPack);
    final past = findPastStarDataPacks(packs, maxDays: 2);
    expect(past.length, 2);
    expect(past.first, yesterday);
    expect(past.last, twoDaysAgo);
  });

  test('filterStarDataPacksByCategory limits by category counts', () {
    final now = DateTime.now();
    final youtubePack = _makePack(
      id: '1',
      date: now,
      category: 'youtube',
    );
    final shoppingPack = _makePack(
      id: '2',
      date: now.subtract(const Duration(days: 1)),
      category: 'shopping',
    );
    final filtered = filterStarDataPacksByCategory([youtubePack, shoppingPack], StarDataCategory.shopping);
    expect(filtered.length, 1);
    expect(filtered.first.mainCategory, 'shopping');
  });

  test('searchStarDataPacks matches main summary and item titles', () {
    final now = DateTime.now();
    final matchingPack = _makePack(
      id: 'a',
      date: now,
      category: 'youtube',
      mainSummary: 'YouTube視聴動画 3本',
    );
    final otherPack = _makePack(
      id: 'b',
      date: now.subtract(const Duration(days: 1)),
      category: 'shopping',
    );
    final results = searchStarDataPacks(
      [matchingPack, otherPack],
      '動画',
    );
    expect(results, contains(matchingPack));
    expect(results, isNot(contains(otherPack)));
  });
}
