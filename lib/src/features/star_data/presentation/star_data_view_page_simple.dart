import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../domain/star_data_pack.dart';
import '../domain/star_data_item.dart';
import '../providers/star_data_providers.dart';
import '../utils/star_data_pack_timeline.dart';
import '../utils/star_data_display_helpers.dart';
import '../utils/star_data_category_definitions.dart';
import '../utils/star_data_service_master.dart';
import 'star_data_daily_detail_page.dart';
import 'star_data_paywall_dialog.dart';
import 'package:starlist_app/core/navigation/star_data_navigation.dart';

final selectedCategoryProvider = StateProvider<StarDataCategory?>((ref) => null);
// final selectedGenreProvider = StateProvider<StarDataGenre?>((ref) => null); // Genre unused
final selectedServiceProvider = StateProvider<String>((ref) => kServiceIdAll);
final searchKeywordProvider = StateProvider<String>((ref) => '');

final _orderedCategories = [
  StarDataCategory.youtube,
  StarDataCategory.video,
  StarDataCategory.shopping,
  StarDataCategory.music,
  StarDataCategory.receipt,
];

final _categoryFilters = [
  const _CategoryFilter(label: 'すべて', value: null),
  ..._orderedCategories.map(
    (category) => _CategoryFilter(label: category.label, value: category),
  ),
];

class _CategoryFilter {
  const _CategoryFilter({required this.label, required this.value});
  final String label;
  final StarDataCategory? value;
}

class StarDataViewPageSimple extends ConsumerStatefulWidget {
  const StarDataViewPageSimple({
    super.key,
    required this.starId,
    this.username,
  });

  final String starId;
  final String? username;

  @override
  ConsumerState<StarDataViewPageSimple> createState() =>
      _StarDataViewPageSimpleState();
}

class _StarDataViewPageSimpleState
    extends ConsumerState<StarDataViewPageSimple> {
  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(starDataPacksProvider(widget.starId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF5F5F7),
      body: SafeArea(
        child: asyncState.when(
          data: (packs) => _buildBody(context, packs, isDark),
          loading: () => _buildLoading(context),
          error: (error, stack) => _buildError(context),
        ),
      ),
    );
  }

  /// 1日分の StarDataPack をカテゴリごとのサブパックに分割する。
  ///
  /// 例: ある日のパックに YouTube 3件, Music 2件, Receipt 1件が含まれていた場合、
  ///   - YouTube 専用パック
  ///   - Music 専用パック
  ///   - Receipt 専用パック
  /// の3カードとして表示できるようにする。
  List<StarDataPack> _expandPacksByCategory(List<StarDataPack> packs) {
    final List<StarDataPack> expanded = [];

    for (final pack in packs) {
      final itemsByCategory = <String, List<StarDataItem>>{};
      for (final item in pack.items) {
        itemsByCategory.putIfAbsent(item.category, () => []).add(item);
      }

      itemsByCategory.forEach((categoryKey, items) {
        if (items.isEmpty) return;

        final count = items.length;
        final summaryText = _buildCategorySummary(categoryKey, count);

        final firstItem = items.first;
        final resolvedCategory = StarDataCategory.fromString(categoryKey);
        final resolvedGenre = StarDataGenre.fromString(firstItem.genre);

        expanded.add(
          StarDataPack(
            id: '${pack.id}_$categoryKey',
            starId: pack.starId,
            date: pack.date,
            categoryCounts: {categoryKey: count},
            mainCategory: categoryKey,
            mainSummaryText: summaryText,
            secondarySummaryText: null,
            items: List.unmodifiable(items),
            resolvedCategory: resolvedCategory,
            resolvedGenre: resolvedGenre,
          ),
        );
      });
    }

    // 元の packs は日付降順にソートされている前提だが、
    // カテゴリ展開後も日付の新しい順になるよう明示的にソートしておく。
    expanded.sort((a, b) => b.date.compareTo(a.date));
    return expanded;
  }

  /// カテゴリと件数からサマリーテキストを生成する。
  /// もともとの集約ロジックに合わせた文言を再現する。
  String _buildCategorySummary(String category, int count) {
    switch (category) {
      case 'shopping':
        return '$countつの商品を購入';
      case 'youtube':
        return '$count本の動画を視聴';
      case 'video':
        return '$count本の動画';
      case 'music':
        return '$count曲の音楽を再生';
      case 'receipt':
        return '$countつの商品を購入';
      default:
        return '$count件のデータ';
    }
  }

  Widget _buildBody(
    BuildContext context,
    List<StarDataPack> packs,
    bool isDark,
  ) {
    final searchKeyword = ref.watch(searchKeywordProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedService = ref.watch(selectedServiceProvider);
    // 「すべて」選択時は、1日1パックではなくカテゴリごとにサブパックへ展開して表示する
    final basePacks =
        selectedCategory == null ? _expandPacksByCategory(packs) : packs;

    final filteredPacks = applyStarDataPackFilters(
      basePacks,
      category: selectedCategory,
      serviceId: selectedCategory == null ? null : selectedService,
      searchQuery: searchKeyword,
    );

    // 「すべて」の場合は、今日/過去に分けずに展開済みパックをそのまま新しい順で並べる
    if (selectedCategory == null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            _buildHeader(context),
            const SizedBox(height: 12),
            _buildSearchBar(context),
            const SizedBox(height: 12),
            _buildCategoryTabs(context, selectedCategory),
            const SizedBox(height: 16),
            if (filteredPacks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    '条件に合うデータがありません',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                  ),
                ),
              )
            else ...[
              // 画面幅に応じて 1列 / 2列 レイアウトを切り替える
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900; // Web想定のブレークポイント

                  if (!isWide) {
                    // 従来どおり縦1列
                    return Column(
                      children: [
                        ...filteredPacks.asMap().entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildDataCard(
                              context,
                              entry.value,
                              isToday: entry.key == 0,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  // Webなど横幅が広い場合は2カラムで表示
                  final itemWidth = (constraints.maxWidth - 16) / 2; // カード間16pxの間隔を想定

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      ...filteredPacks.asMap().entries.map(
                        (entry) => SizedBox(
                          width: itemWidth,
                          child: _buildDataCard(
                            context,
                            entry.value,
                            isToday: entry.key == 0,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
              ],
            ),
          ),
        ),
      );
    }

    // 特定カテゴリ選択時は、従来どおり「今日のパック + 過去のDATA PACK」で表示
    final todayPack = findTodayStarDataPack(filteredPacks);
    final pastPacks = findPastStarDataPacks(filteredPacks);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 12),
              _buildSearchBar(context),
              const SizedBox(height: 12),
              _buildCategoryTabs(context, selectedCategory),
              const SizedBox(height: 12),
              _buildServiceTabs(context, selectedCategory, selectedService),
              const SizedBox(height: 16),
              if (filteredPacks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      '条件に合うデータがありません',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                    ),
                  ),
                )
              else ...[
                if (todayPack != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDataCard(context, todayPack, isToday: true),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          '今日のデータはまだありません',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                _buildPastSection(context, pastPacks),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final username = widget.username ?? widget.starId;
    final name = username.replaceAll('-', ' ').split(' ').map((part) {
      if (part.isEmpty) return part;
      return part[0].toUpperCase() + part.substring(1);
    }).join(' ');
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8D54EB), Color(0xFF25C9EF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            username.isNotEmpty ? username[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isNotEmpty ? name : 'スター',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '@$username のデータページ（プレビュー）',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.brightness_6),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: TextField(
        onChanged: (value) =>
            ref.read(searchKeywordProvider.notifier).state = value,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: 'キーワードで検索（タイトル・キーワードなど）',
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs(BuildContext context, StarDataCategory? selectedCategory) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categoryFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _categoryFilters[index];
          final isSelected = selectedCategory == filter.value;
          return ChoiceChip(
            label: Text(
              filter.label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
              ),
            ),
            selected: isSelected,
            onSelected: (_) {
              ref.read(selectedCategoryProvider.notifier).state = filter.value;
              // Reset service when category changes
              ref.read(selectedServiceProvider.notifier).state = kServiceIdAll;
            },
            selectedColor: Theme.of(context).colorScheme.primary,
            backgroundColor: Colors.transparent,
            side: BorderSide(
              color: isSelected
                  ? Colors.transparent
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _buildServiceTabs(BuildContext context, StarDataCategory category, String selectedService) {
    if (category == StarDataCategory.youtube) {
      return const SizedBox();
    }

    final services = getServicesForCategory(category);
    if (services.isEmpty) return const SizedBox();

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: services.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final service = services[index];
          final isSelected = selectedService == service.id;
          
          return ChoiceChip(
            label: Text(
              service.label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
              ),
            ),
            selected: isSelected,
            onSelected: (_) {
              ref.read(selectedServiceProvider.notifier).state = service.id;
            },
            selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            backgroundColor: Colors.transparent,
            side: BorderSide(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }

  Widget _buildDataCard(BuildContext context, StarDataPack pack,
      {bool isToday = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final category = pack.resolvedCategory ??
        StarDataCategory.fromString(pack.mainCategory);

    // YouTubeの場合は新しいデザインを適用
    if (category == StarDataCategory.youtube) {
      return _buildYoutubeDataCard(context, pack, isToday: isToday);
    }

    // 共通のカードスタイル
    final cardDecoration = BoxDecoration(
      color: isDark ? theme.colorScheme.surface : Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 16,
          offset: const Offset(0, 4),
          spreadRadius: 2,
        ),
      ],
    );

    // 共通ヘッダー（YouTubeカードと同じアバター＋アカウント名）
    final username = widget.username ?? widget.starId;
    final name = username.replaceAll('-', ' ').split(' ').map((part) {
      if (part.isEmpty) return part;
      return part[0].toUpperCase() + part.substring(1);
    }).join(' ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: cardDecoration,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header (User Info & Category Badge)
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF60A5FA), Color(0xFF34D399)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        '@$username',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // 右上にカテゴリバッジ（YouTubeのみ公開バッジも）
                  if (category == StarDataCategory.youtube) ...[
                    _buildAccessBadge(true),
                    const SizedBox(width: 8),
                  ],
                  _buildCategoryPill(
                    context,
                    pack.resolvedCategory?.label ??
                        mapStarDataCategoryLabel(pack.mainCategory),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Title
              if (category != StarDataCategory.youtube)
                Text(
                  pack.mainSummaryText,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),

              // 3. Summary
              if (pack.secondarySummaryText != null) ...[
                const SizedBox(height: 8),
                Text(
                  pack.secondarySummaryText!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.65),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // 4. Thumbnail/status row
              const SizedBox(height: 16),
              _buildPackVisualRow(context, pack),

              // 5. CTA
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handlePackCtaTap(context, pack),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF47A7A), // Salmon pink
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('このデータの詳細を見る'),
                ),
              ),
              const SizedBox(height: 8),
              // 6. Footer time (カード内の一番下に表示)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _formatRelativeTime(pack.date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildYoutubeDataCard(BuildContext context, StarDataPack pack,
      {bool isToday = false}) {
    final mainItem = pack.items.firstOrNull;
    final videoCount = pack.items.length;
    final channelName = mainItem?.extra?['channel_name'] as String? ?? 'Unknown Channel';
    final videoTitle = mainItem?.title ?? '動画タイトルなし';
    
    // ユーザー情報の取得（_buildHeaderと同じロジック）
    final username = widget.username ?? widget.starId;
    final name = username.replaceAll('-', ' ').split(' ').map((part) {
      if (part.isEmpty) return part;
      return part[0].toUpperCase() + part.substring(1);
    }).join(' ');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header (User Info & Public Badge)
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF60A5FA), Color(0xFF34D399)], // Blue to Greenish like the image
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    '@$username',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // 公開バッジ
              _buildAccessBadge(true),
              const SizedBox(width: 8),
              // YouTube視聴バッジ
              _buildCategoryPill(context, 'YouTube視聴'),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Inner Content Card（ボタンより少し狭いmaxWidthで左寄せ）
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFE4E6)), // Light pink border
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YouTube視聴動画 $videoCount本',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      videoTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF334155),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // チャンネル名（1行目・左寄せ）
                    Text(
                      channelName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // その下の行の一番右にピンク枠「+◯本の動画を視聴」
                    if (videoCount > 1) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFF47A7A)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add, size: 14, color: Color(0xFFF47A7A)),
                                const SizedBox(width: 4),
                                Text(
                                  '${videoCount - 1}本の動画を視聴',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFFF47A7A),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Tags 行は非表示にし、最小限のスペースのみ残す
          const SizedBox.shrink(),
          const SizedBox(height: 16),

          // 4. CTA Button（横幅を少し絞ったボタン）
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handlePackCtaTap(context, pack),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF47A7A), // 他カテゴリと同じサーモンピンク
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('このデータの詳細を見る'),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // 5. Footer Time
          Text(
            _formatRelativeTime(pack.date),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagItem({required String label, required String value, required bool isPrimary}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isPrimary ? const Color(0xFFFFE4E6) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isPrimary ? const Color(0xFFE11D48) : const Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF334155),
          ),
        ),
      ],
    );
  }

  // Removed _buildPastPackCard and _mapGenreLabel

  Widget _buildPastSection(BuildContext context, List<StarDataPack> pastPacks) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(context, '過去の DATA PACK'),
        const SizedBox(height: 12),
        if (pastPacks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '過去のデータパックはありません',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          )
        else
          Column(
            children: pastPacks
                .map((pack) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildDataCard(context, pack, isToday: false),
                    ))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildCategoryPill(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0), // Light pink bg
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF47A7A), // Pink border
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: Color(0xFFF47A7A), // Pink text
        ),
      ),
    );
  }

  Widget _buildPackVisualRow(BuildContext context, StarDataPack pack) {
    final theme = Theme.of(context);
    final mainItem = pack.items.firstOrNull;
    final thumbnail = mainItem?.extra?['thumbnail_url'] as String?;
    final category = pack.resolvedCategory ??
        StarDataCategory.fromString(pack.mainCategory);
    final bool isYoutube = category == StarDataCategory.youtube;
    final String primaryText = _maybeTrimmed(
          isYoutube ? mainItem?.title : pack.mainSummaryText,
        ) ??
        pack.mainSummaryText;
    final String? youtubeChannelName = isYoutube
        ? _maybeTrimmed(mainItem?.extra?['channel_name'] as String?)
        : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildServiceLogo(category: category, thumbnailUrl: thumbnail),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isYoutube) ...[
                // YouTubeの場合
                Text(
                  primaryText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (youtubeChannelName != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildMiniServiceIcon(category),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          youtubeChannelName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ] else
                // YouTube以外：従来通り
                Text(
                  primaryText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceLogo({
    required StarDataCategory category,
    String? thumbnailUrl,
  }) {
    switch (category) {
      case StarDataCategory.youtube:
        return _buildYoutubeLogo();
      case StarDataCategory.video:
        return _buildThumbnail(thumbnailUrl);
      case StarDataCategory.shopping:
        return _buildShoppingLogo();
      case StarDataCategory.music:
      case StarDataCategory.receipt:
      case StarDataCategory.other:
        return _buildThumbnail(thumbnailUrl);
    }
  }

  Widget _buildThumbnail(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFFF3F4F6),
        ),
        child: const Icon(
          Icons.play_circle_fill,
          size: 32,
          color: Color(0xFFE11D48),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        url,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: const Color(0xFFF3F4F6),
          ),
          child: const Icon(
            Icons.play_circle_fill,
            size: 32,
            color: Color(0xFFE11D48),
          ),
        ),
      ),
    );
  }

  Widget _buildYoutubeLogo() {
    const Color accent = Color(0xFFF87171);
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.play_circle_filled,
          color: accent,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildShoppingLogo() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDD5),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFA94D).withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: const Color(0xFFFF9F43).withOpacity(0.3)),
      ),
      child: const Center(
        child: Icon(
          Icons.shopping_bag,
          color: Color(0xFFEA580C),
          size: 30,
        ),
      ),
    );
  }

  Widget _buildAccessBadge(bool isPublic) {
    if (!isPublic) return const SizedBox.shrink();

    const Color base = Color(0xFF22C55E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: base.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: base.withOpacity(0.28)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.public, size: 13, color: base),
          SizedBox(width: 4),
          Text(
            '公開',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: base,
            ),
          ),
        ],
      ),
    );
  }

  // Removed _buildCategoryBadge in favor of _buildCategoryPill

  Widget _buildMiniServiceIcon(StarDataCategory category) {
    IconData icon;
    Color color;
    switch (category) {
      case StarDataCategory.youtube:
        icon = Icons.play_circle_filled;
        color = const Color(0xFFF87171);
        break;
      case StarDataCategory.video:
        icon = Icons.movie_creation_outlined;
        color = const Color(0xFF6366F1);
        break;
      case StarDataCategory.shopping:
        icon = Icons.shopping_bag;
        color = const Color(0xFFF97316);
        break;
      case StarDataCategory.music:
        icon = Icons.music_note;
        color = const Color(0xFF10B981);
        break;
      case StarDataCategory.receipt:
        icon = Icons.receipt;
        color = const Color(0xFF0EA5E9);
        break;
      case StarDataCategory.other:
        icon = Icons.apps;
        color = const Color(0xFF6B7280);
        break;
    }

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 12,
        color: color,
      ),
    );
  }

  String? _maybeTrimmed(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  String _formatRelativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) {
      return 'たった今';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分前';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}時間前';
    }
    if (diff.inDays == 1) {
      return '昨日';
    }
    return '${diff.inDays}日前';
  }

  void _handlePackCtaTap(BuildContext context, StarDataPack pack) {
    if (pack.mainCategory == 'youtube') {
      final dateKey = DateFormat('yyyy-MM-dd').format(pack.date);
      final routeName = widget.username != null
          ? starDataDailyRouteName
          : myDataDailyRouteName;
      final pathParams = widget.username != null
          ? {'username': widget.username!}
          : null;
      final queryParams = {'date': dateKey, 'category': pack.mainCategory};
      final router = GoRouter.maybeOf(context);
      if (router != null) {
        router.goNamed(
          routeName,
          pathParameters: pathParams ?? <String, String>{},
          queryParameters: queryParams,
        );
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => StarDataDailyDetailPage(
            starId: widget.starId,
            username: widget.username ?? widget.starId,
            date: DateTime(pack.date.year, pack.date.month, pack.date.day),
            mainCategory: pack.mainCategory,
          ),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PaywallPlansDialog(),
    );
  }

  // Removed _handleCardTap as it is unused.


  Widget _buildLoading(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Text(
        'データの取得中にエラーが発生しました',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
