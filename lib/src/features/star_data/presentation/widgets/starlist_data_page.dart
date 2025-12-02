import 'package:flutter/material.dart';
import '../../../../../theme/starlist_design_system.dart';

/// STARLIST スターのデータページ - SoT準拠
/// 
/// 要件:
/// - カテゴリは横スライド
/// - ジャンルはカテゴリを選択してから横スライド表示
/// - データカードは白・角丸・整形された情報量
/// - 画像（YouTubeサムネなど）は角丸で統一
/// - 「このデータの詳細を見る」→ 有料プラン誘導のポップアップ
class StarlistDataPage extends StatefulWidget {
  final String starId;
  final String starName;
  final bool isManagementMode; // スター側の管理モード

  const StarlistDataPage({
    super.key,
    required this.starId,
    required this.starName,
    this.isManagementMode = false,
  });

  @override
  State<StarlistDataPage> createState() => _StarlistDataPageState();
}

class _StarlistDataPageState extends State<StarlistDataPage> {
  String? _selectedCategory;
  String? _selectedGenre;

  // カテゴリ一覧（例）
  final List<String> _categories = [
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
    return Scaffold(
      backgroundColor: StarlistColors.whiteBackground,
      body: CustomScrollView(
        slivers: [
          // ヘッダー
          _buildHeader(),
          
          // カテゴリ選択（横スライド）
          _buildCategorySection(),
          
          // ジャンル選択（カテゴリ選択後、横スライド）
          if (_selectedCategory != null) _buildGenreSection(),
          
          // データグリッド
          _buildDataGrid(),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'カテゴリ',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: StarlistColors.textPrimary,
                  ),
            ),
            SizedBox(height: StarlistSpacing.md),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => SizedBox(width: StarlistSpacing.sm),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;
                  return _CategoryChip(
                    label: category,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedCategory = isSelected ? null : category;
                        _selectedGenre = null; // ジャンルをリセット
                      });
                    },
                  );
                },
              ),
            ),
            SizedBox(height: StarlistSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreSection() {
    final genres = _genresByCategory[_selectedCategory] ?? [];
    
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: StarlistSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ジャンル',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: StarlistColors.textPrimary,
                  ),
            ),
            SizedBox(height: StarlistSpacing.md),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: genres.length,
                separatorBuilder: (_, __) => SizedBox(width: StarlistSpacing.sm),
                itemBuilder: (context, index) {
                  final genre = genres[index];
                  final isSelected = _selectedGenre == genre;
                  return _CategoryChip(
                    label: genre,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedGenre = isSelected ? null : genre;
                      });
                    },
                  );
                },
              ),
            ),
            SizedBox(height: StarlistSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildDataGrid() {
    // ダミーデータ（実際はAPIから取得）
    final dataItems = List.generate(12, (index) => index);

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: StarlistSpacing.xl),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: StarlistSpacing.md,
          mainAxisSpacing: StarlistSpacing.md,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return _DataCard(
              index: index,
              onTap: () => _showDetailDialog(context),
            );
          },
          childCount: dataItems.length,
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _PaywallDialog(),
    );
  }
}

/// カテゴリ/ジャンルチップ
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: StarlistSpacing.md,
          vertical: StarlistSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? StarlistColors.accentBlue : StarlistColors.white,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: isSelected
                ? StarlistColors.accentBlueText
                : StarlistColors.grayBorder,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? StarlistColors.accentBlueText
                    : StarlistColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
              ),
        ),
      ),
    );
  }
}

/// データカード
class _DataCard extends StatelessWidget {
  final int index;
  final VoidCallback onTap;

  const _DataCard({
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: StarlistColors.white,
          borderRadius: StarlistRadius.lgRadius,
          boxShadow: StarlistShadows.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 画像（角丸で統一）
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(StarlistRadius.lg),
                  topRight: Radius.circular(StarlistRadius.lg),
                ),
                child: Container(
                  width: double.infinity,
                  color: StarlistColors.graySubtle,
                  child: Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: StarlistColors.grayText,
                    ),
                  ),
                ),
              ),
            ),
            // 情報
            Padding(
              padding: EdgeInsets.all(StarlistSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'データタイトル ${index + 1}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: StarlistColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: StarlistSpacing.xs),
                  Text(
                    'サブタイトル',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: StarlistColors.textSecondary,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
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


