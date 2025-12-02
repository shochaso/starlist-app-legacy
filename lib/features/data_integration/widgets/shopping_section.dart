import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starlist_app/src/features/star_data/providers/star_data_providers.dart';
import 'package:starlist_app/src/features/star_data/domain/star_data_item.dart';
import '../models/shopping_detail_entry.dart';
import '../widgets/shopping_data_card.dart';
import '../navigation/shopping_navigation.dart';

class ShoppingSection extends ConsumerWidget {
  const ShoppingSection({
    super.key,
    required this.starId,
  });

  final String starId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(starDataItemsProvider(starId));

    return asyncItems.when(
      data: (items) {
        // Shoppingカテゴリでフィルタリング
        final shoppingItems = items.where((item) => item.category == 'shopping').toList();
        
        if (shoppingItems.isEmpty) {
          return const SizedBox.shrink();
        }

        // 日付でグループ化（同じ日付のデータをまとめる）
        final groupedByDate = <DateTime, List<StarDataItem>>{};
        for (final item in shoppingItems) {
          final date = DateTime(item.date.year, item.date.month, item.date.day);
          groupedByDate.putIfAbsent(date, () => []).add(item);
        }

        // 日付順でソート（新しい順）
        final sortedDates = groupedByDate.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sortedDates.map((date) {
            final dateItems = groupedByDate[date]!;
            final totalCount = dateItems.length;
            const previewCount = 3;
            final remainingCount = totalCount > previewCount ? totalCount - previewCount : 0;
            final previewItems = dateItems.take(previewCount).map((item) {
              return ShoppingDetailItem.fromStarDataItem(item);
            }).toList();

            final entry = ShoppingDetailEntry.fromStarDataItems(
              items: dateItems,
              starId: starId,
              source: 'star_data',
            );

            return ShoppingDataCard(
              totalCount: totalCount,
              remainingCount: remainingCount,
              createdAt: dateItems.first.createdAt,
              previewItems: previewItems,
              source: 'star_data',
              starId: starId,
              onTapDetail: () {
                navigateToShoppingDetail(context, entry);
              },
            );
          }).toList(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

