import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starlist_app/src/features/star_data/domain/star_data_item.dart';
import 'package:starlist_app/src/features/star_data/domain/star_data_repository.dart';
import 'package:starlist_app/src/features/star_data/infrastructure/mock_star_data_repository.dart';
import 'package:starlist_app/src/features/star_data/presentation/star_data_view_page_simple.dart';
import 'package:starlist_app/src/features/star_data/presentation/star_data_daily_detail_page.dart';
import 'package:starlist_app/src/features/star_data/providers/star_data_providers.dart';

void main() {
  testWidgets('shows snackbar for YouTube category (free)', (tester) async {
    final youtubeRepository = _YoutubeOnlyRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          starDataRepositoryProvider.overrideWithValue(youtubeRepository),
        ],
        child: const MaterialApp(
          home: StarDataViewPageSimple(
            starId: 'star_test',
            username: 'test',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Find and tap "このデータの詳細を見る" button
    final viewDetailButtons = find.text('このデータの詳細を見る');
    expect(viewDetailButtons, findsWidgets);

    await tester.tap(viewDetailButtons.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(StarDataDailyDetailPage), findsOneWidget);
    expect(find.text('この先は有料プラン限定'), findsNothing);
  });

  testWidgets('shows paywall dialog for non-YouTube category', (tester) async {
    final shoppingRepository = _ShoppingOnlyRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          starDataRepositoryProvider.overrideWithValue(shoppingRepository),
        ],
        child: const MaterialApp(
          home: StarDataViewPageSimple(
            starId: 'star_test',
            username: 'test',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Find and tap "このデータの詳細を見る" button
    final viewDetailButtons = find.text('このデータの詳細を見る');
    expect(viewDetailButtons, findsWidgets);

    await tester.tap(viewDetailButtons.first);
    await tester.pumpAndSettle();

    // Should show paywall dialog
    expect(find.text('この先は有料プラン限定'), findsOneWidget);
    expect(find.text('ライトプラン'), findsOneWidget);
    expect(find.text('スタンダードプラン'), findsOneWidget);
    expect(find.text('プレミアムプラン'), findsOneWidget);
    expect(find.text('このデータは無料で閲覧できます'), findsNothing);
  });
}

class _YoutubeOnlyRepository implements StarDataRepository {
  @override
  Future<List<StarDataItem>> getStarData({
    required String starId,
    int limit = 50,
  }) async {
    return [
      StarDataItem(
        id: '1',
        starId: starId,
        date: DateTime.now(),
        category: 'youtube',
        genre: 'video_variety',
        title: 'YouTube視聴動画',
        subtitle: 'テスト動画',
        source: 'YouTube',
        createdAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<List<StarDataItem>> fetchStarData({
    required String starId,
    int limit = 50,
  }) async {
    return getStarData(starId: starId, limit: limit);
  }

  @override
  Future<void> saveStarDataItem(StarDataItem item) async {}

  @override
  Future<void> hideStarDataItem({
    required String id,
    required String starId,
  }) async {}
}

class _ShoppingOnlyRepository implements StarDataRepository {
  @override
  Future<List<StarDataItem>> getStarData({
    required String starId,
    int limit = 50,
  }) async {
    return [
      StarDataItem(
        id: '1',
        starId: starId,
        date: DateTime.now(),
        category: 'shopping',
        genre: 'shopping_work',
        title: '買い物記録',
        subtitle: 'テスト商品',
        source: 'Amazon',
        createdAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<List<StarDataItem>> fetchStarData({
    required String starId,
    int limit = 50,
  }) async {
    return getStarData(starId: starId, limit: limit);
  }

  @override
  Future<void> saveStarDataItem(StarDataItem item) async {}

  @override
  Future<void> hideStarDataItem({
    required String id,
    required String starId,
  }) async {}
}

