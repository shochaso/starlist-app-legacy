import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starlist_app/src/features/star_data/domain/star_data_item.dart';
import 'package:starlist_app/src/features/star_data/domain/star_data_repository.dart';
import 'package:starlist_app/src/features/star_data/presentation/star_data_view_page_simple.dart';
import 'package:starlist_app/src/features/star_data/providers/star_data_providers.dart';

void main() {
  testWidgets('renders header, tabs, and past section', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          starDataRepositoryProvider.overrideWithValue(_MultiDayRepository()),
        ],
        child: const MaterialApp(
          home: StarDataViewPageSimple(
            starId: 'hanayama-mizuki',
            username: 'hanayama-mizuki',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('@hanayama-mizuki のデータページ（プレビュー）'), findsOneWidget);
    // expect(find.text('のデータページ（プレビュー）'), findsOneWidget); // Merged into above
    expect(find.text('TODAY DATA PACK'), findsWidgets);
    expect(find.text('過去の DATA PACK'), findsOneWidget);
    expect(find.text('このデータの詳細を見る'), findsWidgets);
    expect(find.text('動画（YouTube）'), findsWidgets);
    expect(find.text('ショッピング'), findsWidgets);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.widgetWithText(TextField, 'キーワードで検索（タイトル・キーワードなど）'), findsOneWidget);
    final allChipFinder = find.widgetWithText(ChoiceChip, 'すべて');
    expect(allChipFinder, findsOneWidget);
    final allChip = tester.widget<ChoiceChip>(allChipFinder);
    expect(allChip.selected, isTrue);

    final youtubeChipFinder = find.widgetWithText(ChoiceChip, '動画（YouTube）').first;
    await tester.tap(youtubeChipFinder);
    await tester.pumpAndSettle();
    final youtubeChip = tester.widget<ChoiceChip>(youtubeChipFinder);
    expect(youtubeChip.selected, isTrue);

    // Verify service chips appear
    expect(find.widgetWithText(ChoiceChip, 'YouTube'), findsWidgets);
    expect(find.widgetWithText(ChoiceChip, 'Prime Video'), findsWidgets);
  });
}

class _MultiDayRepository implements StarDataRepository {
  @override
  Future<List<StarDataItem>> getStarData({
    required String starId,
    int limit = 50,
  }) async {
    final now = DateTime.now();
    return [
      StarDataItem(
        id: 'today-1',
        starId: starId,
        date: now,
        category: 'youtube',
        genre: 'video_variety',
        title: 'YouTubeデータパック',
        subtitle: 'テスト動画',
        source: 'youtube',
        createdAt: now,
      ),
      StarDataItem(
        id: 'past-1',
        starId: starId,
        date: now.subtract(const Duration(days: 1)),
        category: 'shopping',
        genre: 'shopping_work',
        title: 'ショッピング記録',
        subtitle: 'テスト商品',
        source: 'amazon',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  @override
  Future<List<StarDataItem>> fetchStarData({
    required String starId,
    int limit = 50,
  }) async =>
      getStarData(starId: starId, limit: limit);

  @override
  Future<void> saveStarDataItem(StarDataItem item) async {}

  @override
  Future<void> hideStarDataItem({
    required String id,
    required String starId,
  }) async {}
}
