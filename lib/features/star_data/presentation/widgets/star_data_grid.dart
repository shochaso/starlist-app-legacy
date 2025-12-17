import 'package:flutter/material.dart';

import '../../domain/category.dart';
import '../../domain/star_data.dart';
import 'locked_overlay.dart';
import 'skeleton_card.dart';
import 'star_data_card.dart';

typedef StarDataTapCallback = void Function(StarData data);

class StarDataGrid extends StatelessWidget {
  const StarDataGrid({
    super.key,
    required this.state,
    required this.onCardTap,
    required this.onLike,
    required this.onComment,
    required this.showSkeleton,
    required this.skeletonCount,
  });

  final StarDataStateSnapshot state;
  final StarDataTapCallback onCardTap;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final bool showSkeleton;
  final int skeletonCount;

  @override
  Widget build(BuildContext context) {
    if (state.showDigestOnly) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'カテゴリ別プレビュー',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: state.categoryDigest.entries
                    .map(
                      (entry) => _CategoryDigestChip(
                        category: entry.key,
                        count: entry.value,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              _LockedCardRow(),
            ],
          ),
        ),
      );
    }

    if (!state.showDigestOnly && state.items.isEmpty && !showSkeleton) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: Text(
              'まだ共有されたデータがありません',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    if (showSkeleton) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        sliver: _buildGrid(
          context: context,
          itemCount: skeletonCount,
          itemBuilder: (_, __) => const SkeletonCard(),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      sliver: _buildGrid(
        context: context,
        itemCount: state.items.length,
        itemBuilder: (context, index) {
          final item = state.items[index];
          final isLocked = !state.viewerAccess.canViewItem(item.visibility);
          return StarDataCard(
            data: item,
            isLocked: isLocked,
            onTap: () => onCardTap(item),
            onLike: onLike,
            onComment: onComment,
          );
        },
      ),
    );
  }

  SliverGrid _buildGrid({
    required BuildContext context,
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
  }) {
    // Determine if we're in wide screen mode (2-column layout)
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 720;

    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        itemBuilder,
        childCount: itemCount,
      ),
      gridDelegate: isWideScreen
          ? const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              mainAxisExtent: 490,
            )
          : const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 320,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
    );
  }
}

class StarDataStateSnapshot {
  const StarDataStateSnapshot({
    required this.items,
    required this.viewerAccess,
    required this.categoryDigest,
    required this.showDigestOnly,
  });

  final List<StarData> items;
  final StarDataViewerAccess viewerAccess;
  final Map<StarDataCategory, int> categoryDigest;
  final bool showDigestOnly;
}

class _CategoryDigestChip extends StatelessWidget {
  const _CategoryDigestChip({
    required this.category,
    required this.count,
  });

  final StarDataCategory category;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(category.displayLabel),
          const SizedBox(width: 6),
          Text('$count件'),
        ],
      ),
      backgroundColor: colorScheme.surfaceContainerHighest,
    );
  }
}

class _LockedCardRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        2,
        (index) => Expanded(
          child: Container(
            height: 160,
            margin: EdgeInsets.only(left: index == 0 ? 0 : 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const LockedOverlay(
              message: 'ログインして続きを見る',
              showBlur: false,
            ),
          ),
        ),
      ),
    );
  }
}
