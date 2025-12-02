import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starlist_app/src/features/star_data/domain/star_data_item.dart';
import 'package:starlist_app/src/features/star_data/domain/star_data_repository.dart';
import 'package:starlist_app/src/features/star_data/infrastructure/mock_star_data_repository.dart';
import 'package:starlist_app/src/features/star_data/presentation/star_data_view_page_simple.dart';
import 'package:starlist_app/src/features/star_data/providers/star_data_providers.dart';

void main() {
  testWidgets('StarDataViewPageSimple displays loading state', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: StarDataViewPageSimple(
            starId: 'star_hanayama_mizuki',
            username: 'hanayama-mizuki',
          ),
        ),
      ),
    );

    // expect(find.text('読み込み中...'), findsOneWidget); // Not in UI
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('StarDataViewPageSimple displays data when loaded', (tester) async {
    final container = ProviderContainer(
      overrides: [
        starDataRepositoryProvider.overrideWithValue(
          MockStarDataRepository(),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: StarDataViewPageSimple(
            starId: 'star_hanayama_mizuki',
            username: 'hanayama-mizuki',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Should display at least one item card
    // expect(find.byType(Card), findsWidgets); // We use Container now
    expect(find.text('このデータの詳細を見る'), findsWidgets);
    expect(find.text('データがありません'), findsNothing);
  });

  testWidgets('StarDataViewPageSimple shows empty state', (tester) async {
    final emptyRepository = _EmptyStarDataRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          starDataRepositoryProvider.overrideWithValue(emptyRepository),
        ],
        child: const MaterialApp(
          home: StarDataViewPageSimple(
            starId: 'star_empty',
            username: 'empty',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('条件に合うデータがありません'), findsOneWidget);
  });
}

class _EmptyStarDataRepository implements StarDataRepository {
  @override
  Future<List<StarDataItem>> getStarData({
    required String starId,
    int limit = 50,
  }) async {
    return [];
  }

  @override
  Future<List<StarDataItem>> fetchStarData({
    required String starId,
    int limit = 50,
  }) async {
    return [];
  }

  @override
  Future<void> saveStarDataItem(StarDataItem item) async {}

  @override
  Future<void> hideStarDataItem({
    required String id,
    required String starId,
  }) async {}
}

