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

  Widget _buildBody(
    BuildContext context,
    List<StarDataPack> packs,
    bool isDark,
  ) {
    final searchKeyword = ref.watch(searchKeywordProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedService = ref.watch(selectedServiceProvider);
    final filteredPacks = applyStarDataPackFilters(
      packs,
      category: selectedCategory,
      serviceId: selectedCategory == null ? null : selectedService,
      searchQuery: searchKeyword,
    );
    final todayPack = findTodayStarDataPack(filteredPacks);
    final pastPacks = findPastStarDataPacks(filteredPacks);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 12),
          _buildSearchBar(context),
          const SizedBox(height: 12),
          _buildCategoryTabs(context, selectedCategory),
          if (selectedCategory != null) ...[
            const SizedBox(height: 12),
            _buildServiceTabs(context, selectedCategory, selectedService),
          ],
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
            const SizedBox(height: 24),
            _buildPastSection(context, pastPacks),
          ],
        ],
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
          decoration: BoxDecoration(
            gradient: const LinearGradient(
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
        color: Theme.of(context).colorScheme.background,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: cardDecoration,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Row with Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isToday)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white24
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'TODAY DATA PACK',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.5,
                          color: isDark ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                    )
                  else
                    const SizedBox(), // Spacer

                  // 右上にカテゴリを表示
                  _buildCategoryPill(
                      context, pack.resolvedCategory?.label ?? mapStarDataCategoryLabel(pack.mainCategory)),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Title
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
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            _formatRelativeTime(pack.date),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
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
    final serviceLabel = _maybeTrimmed(mainItem?.source);
    final category = pack.resolvedCategory ??
        StarDataCategory.fromString(pack.mainCategory);
    final bool isYoutube = category == StarDataCategory.youtube;
    final String primaryText = _maybeTrimmed(
          isYoutube ? mainItem?.title : pack.mainSummaryText,
        ) ??
        pack.mainSummaryText;
    final String secondaryText = _resolveSecondaryLabel(
      category: category,
      mainItem: mainItem,
      fallbackServiceLabel: serviceLabel,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildServiceLogo(category: category, thumbnailUrl: thumbnail),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      primaryText,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildAccessBadge(isYoutube),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildMiniServiceIcon(category),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      secondaryText,
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
          Icons.play_arrow_rounded,
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
        icon = Icons.play_arrow_rounded;
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
        icon = Icons.receipt_long;
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

  String _resolveSecondaryLabel({
    required StarDataCategory category,
    StarDataItem? mainItem,
    String? fallbackServiceLabel,
  }) {
    final candidates = <String?>[
      _maybeTrimmed(mainItem?.subtitle),
      if (category == StarDataCategory.youtube)
        _maybeTrimmed(mainItem?.extra?['channel_name'] as String?),
      fallbackServiceLabel,
      mapStarDataCategoryLabel(category.name),
    ];
    return candidates.firstWhere((value) => value != null, orElse: () => '')!;
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
