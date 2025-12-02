import 'package:flutter_test/flutter_test.dart';
import 'package:starlist_app/src/features/star_data/application/star_data_pack_aggregator.dart';
import 'package:starlist_app/src/features/star_data/domain/star_data_item.dart';

void main() {
  test('aggregates items per day with main category priority', () {
    final items = [
      StarDataItem(
        id: '1',
        starId: 'star',
        date: DateTime(2025, 11, 28, 9),
        category: 'youtube',
        genre: 'video_variety',
        title: 'YouTube 1',
        subtitle: '',
        source: 'YouTube',
        createdAt: DateTime.now(),
      ),
      StarDataItem(
        id: '2',
        starId: 'star',
        date: DateTime(2025, 11, 28, 12),
        category: 'shopping',
        genre: 'shopping_work',
        title: 'Shopping 1',
        subtitle: '',
        source: 'Amazon',
        createdAt: DateTime.now(),
      ),
      StarDataItem(
        id: '3',
        starId: 'star',
        date: DateTime(2025, 11, 28, 14),
        category: 'shopping',
        genre: 'shopping_work',
        title: 'Shopping 2',
        subtitle: '',
        source: 'Amazon',
        createdAt: DateTime.now(),
      ),
      StarDataItem(
        id: '4',
        starId: 'star',
        date: DateTime(2025, 11, 29, 10),
        category: 'receipt',
        genre: 'receipt',
        title: 'Receipt',
        subtitle: '',
        source: 'Receipt',
        createdAt: DateTime.now(),
      ),
    ];

    final packs = aggregateStarDataIntoPacks(items);
    expect(packs.length, 2);
    final shoppingPack = packs.firstWhere(
      (pack) => pack.mainCategory == 'shopping',
      orElse: () => throw AssertionError('shopping pack missing'),
    );
    expect(shoppingPack.mainSummaryText, '2つの商品を購入');
    expect(shoppingPack.secondarySummaryText, '他1件のデータ');
    final receiptPack = packs.firstWhere(
      (pack) => pack.mainCategory == 'receipt',
      orElse: () => throw AssertionError('receipt pack missing'),
    );
    expect(receiptPack.mainSummaryText, '1件のレシート');
  });
}
