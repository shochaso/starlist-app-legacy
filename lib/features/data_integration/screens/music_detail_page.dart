import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/music_detail_entry.dart';
import '../services/data_integration_analytics.dart';

class MusicDetailPage extends StatelessWidget {
  const MusicDetailPage({
    super.key,
    required this.entry,
    required this.source,
  });

  final MusicDetailEntry? entry;
  final String source;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (entry == null || entry!.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('音楽再生の詳細'),
        ),
        body: Center(
          child: Text(
            'このデータには閲覧可能なアイテムがありません',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    // Analytics: 詳細画面表示を記録
    logMusicDetailOpen(
      starId: entry!.starId,
      totalCount: entry!.items.length,
      source: source,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('音楽再生の詳細'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // 上部サマリー
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat.yMMMd('ja').format(entry!.createdAt),
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '再生 ${entry!.items.length}曲',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // リスト
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: entry!.items.length,
                itemBuilder: (context, index) {
                  final item = entry!.items[index];
                  return _MusicItemCard(
                    item: item,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  );
                },
              ),
            ),
            // 下部CTA
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    logMusicDetailPlanCta(
                      starId: entry!.starId,
                      totalCount: entry!.items.length,
                      source: source,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('この再生履歴の詳細プランを確認する（モック）'),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.teal.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('この再生履歴の詳細プランを確認する'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MusicItemCard extends StatelessWidget {
  const _MusicItemCard({
    required this.item,
    required this.colorScheme,
    required this.textTheme,
  });

  final MusicDetailItem item;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.music_note,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.artist,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (item.album != null) ...[
              const SizedBox(height: 4),
              Text(
                'アルバム: ${item.album}',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (item.service != null) ...[
              const SizedBox(height: 4),
              Chip(
                label: Text(
                  item.service!,
                  style: textTheme.labelSmall,
                ),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
      ),
    );
  }
}



