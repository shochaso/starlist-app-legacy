import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/youtube_history_provider.dart';
import '../models/youtube_preview_entry.dart';
import '../models/youtube_watch_detail_entry.dart';
import '../navigation/youtube_navigation.dart';
import 'youtube_watch_card.dart';

class YouTubeWatchSection extends ConsumerWidget {
  const YouTubeWatchSection({
    super.key,
    this.title = 'YouTube視聴ログ',
    this.subtitle,
    this.groups,
    this.padding,
    this.source = 'star_data',
  });

  final String title;
  final String? subtitle;
  final List<YouTubeHistoryGroup>? groups;
  final EdgeInsetsGeometry? padding;
  final String source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<YouTubeHistoryGroup> effectiveGroups =
        groups ?? ref.watch(groupedYoutubeHistoryProvider);
    if (effectiveGroups.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: effectiveGroups.length,
            itemBuilder: (context, index) {
              final group = effectiveGroups[index];
              final previews = group.items
                  .take(_CardConstants.maxPreviewRows)
                  .map((item) => YoutubePreviewEntry(
                        title: item.title,
                        channel: item.channel,
                      ))
                  .toList();
              final detailEntries = group.items
                  .map(YoutubeWatchDetailEntry.fromHistoryItem)
                  .toList();
              final args = YoutubeWatchDetailArgs(
                entries: detailEntries,
                createdAt: group.importedAt,
                label: 'YouTube視聴動画 ${group.itemCount}本',
                subtitle: 'Session: ${group.sessionId}',
                sourceLabel: source,
              );
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < effectiveGroups.length - 1 ? 12 : 0,
                ),
                child: YoutubeWatchCard(
                  totalCount: group.itemCount,
                  previews: previews,
                  createdAt: group.importedAt,
                  source: source,
                  onTapDetail: () => navigateToYoutubeWatchDetail(context, args),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

const _CardConstants = _YoutubeWatchSectionConstants();

class _YoutubeWatchSectionConstants {
  const _YoutubeWatchSectionConstants();

  int get maxPreviewRows => 3;
}

