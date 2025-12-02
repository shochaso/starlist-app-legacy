import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../domain/star_data_daily_query.dart';
import '../domain/star_data_item.dart';
import '../providers/star_data_providers.dart';
import '../utils/star_data_display_helpers.dart';
import '../utils/star_data_pack_timeline.dart';

class StarDataDailyDetailPage extends ConsumerWidget {
  const StarDataDailyDetailPage({
    super.key,
    required this.starId,
    required this.username,
    required this.date,
    required this.mainCategory,
    this.canHide = false,
    this.overrideItems,
  });

  final String starId;
  final String username;
  final DateTime date;
  final String mainCategory;
  final bool canHide;
  final List<StarDataItem>? overrideItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = StarDataDailyQuery(
      starId: starId,
      dateOnly: date,
      category: mainCategory,
    );
    final asyncItems = overrideItems != null
        ? AsyncValue.data(overrideItems!)
        : ref.watch(starDataItemsByDayProvider(query));
    final titleText = formatStarDataPackDate(date);
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text('$titleText のデータ'),
      ),
      body: asyncItems.when(
        data: (items) => _buildContent(context, ref, items, query),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('データを取得できませんでした', style: Theme.of(context).textTheme.bodyMedium),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<StarDataItem> items,
    StarDataDailyQuery query,
  ) {
    final theme = Theme.of(context);
    if (items.isEmpty) {
      return Center(
        child: Text(
          'この日のデータはありません',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    final counts = <String, int>{};
    for (final item in items) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }

    final summary = counts.entries
        .map((entry) => '${mapStarDataCategoryLabel(entry.key)} ${entry.value}件')
        .join(' ・ ');

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        _buildSummaryCard(context, items.length, summary),
        const SizedBox(height: 20),
        Text(
          '明細',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildItemCard(context, ref, item, query),
            )),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, int total, String summary) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mapStarDataCategoryLabel(mainCategory),
            style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '$total 件のアクション',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            summary,
            style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.65),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    WidgetRef ref,
    StarDataItem item,
    StarDataDailyQuery query,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          mapStarDataCategoryLabel(item.category),
                          style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('HH:mm').format(item.date),
                        style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                ),
                if (canHide)
                  PopupMenuButton<void>(
                    onSelected: (_) => _onHideItem(context, ref, item, query),
                    itemBuilder: (_) => [
                      const PopupMenuItem<void>(
                        value: null,
                        child: Text('このデータを非表示'),
                      ),
                    ],
                    icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurface),
                  ),
              ],
            ),
          const SizedBox(height: 10),
          Text(
            item.title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            item.subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.65),
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
    Icon(Icons.circle, size: 8, color: theme.colorScheme.onSurface.withOpacity(0.7)),
              const SizedBox(width: 6),
              Text(
                item.source,
                style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onHideItem(
    BuildContext context,
    WidgetRef ref,
    StarDataItem item,
    StarDataDailyQuery query,
  ) async {
    final repository = ref.read(starDataRepositoryProvider);
    try {
      await repository.hideStarDataItem(id: item.id, starId: item.starId);
      ref.invalidate(starDataItemsByDayProvider(query));
      ref.invalidate(starDataPacksProvider(item.starId));
      ref.invalidate(todayStarDataPackProvider(item.starId));
      ref.invalidate(pastStarDataPacksProvider(item.starId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('このデータを非表示にしました')),
      );
    } catch (e) {
      print('[StarDataDailyDetailPage] Failed to hide ${item.id}: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('非表示にできませんでした')),
      );
    }
  }
}
