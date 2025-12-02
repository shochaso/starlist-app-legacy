import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starlist_app/src/features/star_data/providers/star_data_providers.dart';
import 'package:starlist_app/src/features/star_data/domain/star_data_item.dart';
import '../models/music_detail_entry.dart';
import '../widgets/music_listen_card.dart';
import '../navigation/music_navigation.dart';

class MusicSection extends ConsumerWidget {
  const MusicSection({
    super.key,
    required this.starId,
  });

  final String starId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(starDataItemsProvider(starId));

    return asyncItems.when(
      data: (items) {
        // Musicカテゴリでフィルタリング
        final musicItems = items.where((item) => item.category == 'music').toList();
        
        if (musicItems.isEmpty) {
          return const SizedBox.shrink();
        }

        // 日付でグループ化（同じ日付のデータをまとめる）
        final groupedByDate = <DateTime, List<StarDataItem>>{};
        for (final item in musicItems) {
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
              return MusicDetailItem.fromStarDataItem(item);
            }).toList();

            final entry = MusicDetailEntry.fromStarDataItems(
              items: dateItems,
              starId: starId,
              source: 'star_data',
            );

            return MusicListenCard(
              totalCount: totalCount,
              remainingCount: remainingCount,
              createdAt: dateItems.first.createdAt,
              previewItems: previewItems,
              source: 'star_data',
              starId: starId,
              onTapDetail: () {
                navigateToMusicDetail(context, entry);
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

