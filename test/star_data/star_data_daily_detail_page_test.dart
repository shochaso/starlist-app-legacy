import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starlist_app/src/features/star_data/domain/star_data_item.dart';
import 'package:starlist_app/src/features/star_data/domain/star_data_repository.dart';
import 'package:starlist_app/src/features/star_data/presentation/star_data_daily_detail_page.dart';
import 'package:starlist_app/src/features/star_data/providers/star_data_providers.dart';

void main() {
  testWidgets('owner can hide data and it disappears', (tester) async {
    final now = DateTime.now();
    final items = [
      StarDataItem(
        id: 'item-1',
        starId: 'star-test',
        date: now,
        category: 'youtube',
        genre: 'video_variety',
        title: 'YouTubeデータ',
        subtitle: 'チャンネルA',
        source: 'YouTube',
        createdAt: now,
      ),
      StarDataItem(
        id: 'item-2',
        starId: 'star-test',
        date: now.subtract(const Duration(days: 1)),
        category: 'shopping',
        genre: 'shopping_work',
        title: '買い物記録',
        subtitle: '店舗B',
        source: 'Amazon',
        createdAt: now,
      ),
    ];

    final repository = _TestStarDataRepository(items);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          starDataRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: StarDataDailyDetailPage(
            starId: 'star-test',
            username: 'star-test',
            date: now,
            mainCategory: 'youtube',
            canHide: true,
            overrideItems: items,
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.byIcon(Icons.more_vert), findsWidgets);

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    final menuFinder = find.ancestor(
      of: find.byIcon(Icons.more_vert).first,
      matching: find.byType(PopupMenuButton<void>),
    );
    final menu = tester.widget<PopupMenuButton<void>>(menuFinder);
    menu.onSelected?.call(null);
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.isHidden('item-1'), isTrue);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('non-owner does not see hide action', (tester) async {
    final now = DateTime.now();
    final items = [
      StarDataItem(
        id: 'item-1',
        starId: 'star-test',
        date: now,
        category: 'youtube',
        genre: 'video_variety',
        title: 'YouTubeデータ',
        subtitle: 'チャンネルA',
        source: 'YouTube',
        createdAt: now,
      ),
    ];

    final repository = _TestStarDataRepository(items);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          starDataRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: StarDataDailyDetailPage(
            starId: 'star-test',
            username: 'star-test',
            date: DateTime(2025, 1, 1),
            mainCategory: 'youtube',
            canHide: false,
            overrideItems: items,
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.byIcon(Icons.more_vert), findsNothing);
  });
}

class _TestStarDataRepository implements StarDataRepository {
  _TestStarDataRepository(this._items);

  final List<StarDataItem> _items;
  final _hidden = <String>{};

  @override
  Future<List<StarDataItem>> getStarData({
    required String starId,
    int limit = 50,
  }) async {
    return fetchStarData(starId: starId, limit: limit);
  }

  @override
  Future<List<StarDataItem>> fetchStarData({
    required String starId,
    int limit = 50,
  }) async {
    return _items
        .where((item) => item.starId == starId && !_hidden.contains(item.id))
        .take(limit)
        .toList();
  }

  @override
  Future<void> saveStarDataItem(StarDataItem item) async {}

  @override
  Future<void> hideStarDataItem({
    required String id,
    required String starId,
  }) async {
    _hidden.add(id);
  }

  bool isHidden(String id) => _hidden.contains(id);
}
