import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../theme/starlist_design_system.dart';
import '../../providers/star_data_providers.dart';
import '../../domain/star_data_item.dart';
import 'starlist_data_card.dart';
import 'starlist_horizontal_scroll_chip.dart';
import 'starlist_empty_state.dart';
import 'starlist_loading_state.dart';
import 'starlist_icon.dart';
import 'starlist_button.dart';

/// STARLIST スターのデータページ（実際のデータ統合版）
/// 
/// SoT準拠のデザインで、実際のデータを表示
class StarlistDataPageIntegrated extends ConsumerStatefulWidget {
  final String starId;
  final String starName;
  final bool isManagementMode; // スター側の管理モード

  const StarlistDataPageIntegrated({
    super.key,
    required this.starId,
    required this.starName,
    this.isManagementMode = false,
  });

  @override
  ConsumerState<StarlistDataPageIntegrated> createState() =>
      _StarlistDataPageIntegratedState();
}

class _StarlistDataPageIntegratedState
    extends ConsumerState<StarlistDataPageIntegrated> {
  String? _selectedCategory;
  String? _selectedGenre;

  // カテゴリ一覧
  final List<String> _categories = [
    'すべて',
    'YouTube',
    'Shopping',
    'Music',
    'Recipe',
  ];

  // ジャンル一覧（カテゴリごと）
  final Map<String, List<String>> _genresByCategory = {
    'YouTube': ['ゲーム', '雑談', 'Vlog', '音楽'],
    'Shopping': ['ファッション', 'コスメ', '食品', '雑貨'],
    'Music': ['J-POP', 'ロック', 'ジャズ', 'クラシック'],
    'Recipe': ['和食', '洋食', '中華', 'スイーツ'],
  };

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(starDataItemsProvider(widget.starId));

    return Scaffold(
      backgroundColor: StarlistColors.whiteBackground,
      body: CustomScrollView(
        slivers: [
          // ヘッダー
          _buildHeader(),
          
          // カテゴリ選択（横スライド）
          _buildCategorySection(),
          
          // ジャンル選択（カテゴリ選択後、横スライド）
          if (_selectedCategory != null && _selectedCategory != 'すべて')
            _buildGenreSection(),
          
          // データグリッド
          asyncData.when(
            data: (items) => _buildDataGrid(items),
            loading: () => _buildLoadingState(),
            error: (error, stack) => _buildErrorState(error),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.only(
          top: StarlistSpacing.section,
          left: StarlistSpacing.xl,
          right: StarlistSpacing.xl,
          bottom: StarlistSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // スター名
            Text(
              widget.starName,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: StarlistColors.textPrimary,
                    fontWeight: FontWeight.w300,
                  ),
            ),
            SizedBox(height: StarlistSpacing.sm),
            // サブタイトル
            Text(
              widget.isManagementMode ? 'データ管理' : 'データ',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: StarlistColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: StarlistSpacing.xl),
        child: StarlistHorizontalScrollChip(
          items: _categories,
          selectedItem: _selectedCategory,
          onItemSelected: (category) {
            setState(() {
              _selectedCategory = category;
              _selectedGenre = null; // ジャンルをリセット
            });
          },
          label: 'カテゴリ',
        ),
      ),
    );
  }

  Widget _buildGenreSection() {
    final genres = _genresByCategory[_selectedCategory] ?? [];
    
    if (genres.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.only(
          top: StarlistSpacing.xxl,
          left: StarlistSpacing.xl,
          right: StarlistSpacing.xl,
        ),
        child: StarlistHorizontalScrollChip(
          items: genres,
          selectedItem: _selectedGenre,
          onItemSelected: (genre) {
            setState(() {
              _selectedGenre = genre;
            });
          },
          label: 'ジャンル',
        ),
      ),
    );
  }

  Widget _buildDataGrid(List<StarDataItem> items) {
    // フィルタリング
    final filteredItems = items.where((item) {
      if (_selectedCategory != null && _selectedCategory != 'すべて') {
        if (item.category != _selectedCategory?.toLowerCase()) {
          return false;
        }
      }
      // ジャンルフィルタリングは実際のデータ構造に応じて実装
      return true;
    }).toList();

    if (filteredItems.isEmpty) {
      return SliverFillRemaining(
        child: StarlistEmptyState(
          title: 'データがありません',
          subtitle: '条件を変更して再度お試しください',
          icon: StarlistIcons.image,
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.only(
        top: StarlistSpacing.xxl,
        left: StarlistSpacing.xl,
        right: StarlistSpacing.xl,
        bottom: StarlistSpacing.xxl,
      ),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: StarlistSpacing.md,
          mainAxisSpacing: StarlistSpacing.md,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = filteredItems[index];
            return StarlistDataCard(
              title: item.title,
              subtitle: item.subtitle,
              imageUrl: item.extra?['thumbnail_url'] as String?,
              onTap: () => _showDetailDialog(context, item),
            );
          },
          childCount: filteredItems.length,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SliverFillRemaining(
      child: StarlistLoadingState(
        message: 'データを読み込み中...',
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return SliverFillRemaining(
      child: StarlistEmptyState(
        title: 'エラーが発生しました',
        subtitle: error.toString(),
        icon: StarlistIcons.close,
        action: StarlistButton(
          label: '再試行',
          onPressed: () {
            ref.invalidate(starDataItemsProvider(widget.starId));
          },
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context, StarDataItem item) {
    // 有料プラン誘導ポップアップを表示
    // 実装は既存の_PaywallDialogを使用
    showDialog(
      context: context,
      builder: (context) => _PaywallDialog(),
    );
  }
}

/// 有料プラン誘導ポップアップ
/// 
/// 白背景 × 枠薄グレー × 月額プラン3つのカード
/// AI臭なし（グラデなし）
class _PaywallDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(StarlistSpacing.xl),
      child: Container(
        decoration: BoxDecoration(
          color: StarlistColors.white,
          borderRadius: StarlistRadius.xlRadius,
          border: Border.all(
            color: StarlistColors.grayBorder,
            width: 1,
          ),
        ),
        padding: EdgeInsets.all(StarlistSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // タイトル
            Text(
              'このデータの詳細を見る',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: StarlistColors.textPrimary,
                    fontWeight: FontWeight.w400,
                  ),
            ),
            SizedBox(height: StarlistSpacing.sm),
            Text(
              '有料プランに加入すると、すべてのデータの詳細を閲覧できます',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: StarlistColors.textSecondary,
                  ),
            ),
            SizedBox(height: StarlistSpacing.xxl),
            // プランカード
            ...List.generate(3, (index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < 2 ? StarlistSpacing.md : 0,
                ),
                child: _PlanCard(
                  planName: ['ベーシック', 'スタンダード', 'プレミアム'][index],
                  price: ['¥980', '¥1,980', '¥2,980'][index],
                  isRecommended: index == 1,
                ),
              );
            }),
            SizedBox(height: StarlistSpacing.xl),
            // 閉じるボタン
            SizedBox(
              width: double.infinity,
              child: StarlistButton(
                label: '閉じる',
                isOutlined: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// プランカード
class _PlanCard extends StatelessWidget {
  final String planName;
  final String price;
  final bool isRecommended;

  const _PlanCard({
    required this.planName,
    required this.price,
    this.isRecommended = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(StarlistSpacing.md),
      decoration: BoxDecoration(
        color: StarlistColors.white,
        borderRadius: StarlistRadius.mdRadius,
        border: Border.all(
          color: isRecommended
              ? StarlistColors.accentBlueText
              : StarlistColors.grayBorder,
          width: isRecommended ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                planName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: StarlistColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              SizedBox(height: StarlistSpacing.xs),
              Text(
                price,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: StarlistColors.textSecondary,
                    ),
              ),
            ],
          ),
          if (isRecommended)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: StarlistSpacing.sm,
                vertical: StarlistSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: StarlistColors.accentBlue,
                borderRadius: StarlistRadius.smRadius,
              ),
              child: Text(
                'おすすめ',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: StarlistColors.accentBlueText,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

