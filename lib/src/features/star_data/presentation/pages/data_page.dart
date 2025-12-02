import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// STARLIST Data ページ（UI骨格）
/// Cursor 側のデータ Provider と接続する前段階。
class StarDataPage extends ConsumerStatefulWidget {
  const StarDataPage({
    super.key,
    required this.starName,
    required this.username,
  });

  final String starName;
  final String username;

  @override
  ConsumerState<StarDataPage> createState() => _StarDataPageState();
}

class _StarDataPageState extends ConsumerState<StarDataPage> {
  String _selectedCategory = 'すべて';
  String _selectedGenre = 'すべて';

  // TODO: Cursor 側 Provider と差し替え
  static const _categories = [
    'すべて',
    'YouTube',
    '動画',
    'ショッピング',
    '音楽',
    'レシート',
  ];

  static const Map<String, List<String>> _genresByCategory = {
    'YouTube': ['すべて', 'ゲーム', '雑談', 'Vlog', '音楽'],
    '動画': ['すべて', 'バラエティ', 'レビュー', 'Vlog'],
    'ショッピング': ['すべて', 'ファッション', 'コスメ', '雑貨'],
    '音楽': ['すべて', 'J-POP', 'ロック', 'ジャズ'],
    'レシート': ['すべて'],
  };

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).colorScheme.background;

    return SafeArea(
      child: Container(
        color: bgColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DataPageHeader(
                starName: widget.starName,
                username: widget.username,
              ),
              const SizedBox(height: 24),
              _CategoryTabs(
                categories: _categories,
                selected: _selectedCategory,
                onSelected: (value) {
                  setState(() {
                    _selectedCategory = value;
                    _selectedGenre = 'すべて';
                  });
                },
              ),
              const SizedBox(height: 16),
              _GenreTabs(
                genres: _genresByCategory[_selectedCategory] ?? const [],
                selected: _selectedGenre,
                onSelected: (value) {
                  setState(() {
                    _selectedGenre = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              _ItemsListPlaceholder(
                category: _selectedCategory,
                genre: _selectedGenre,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DataPageHeader extends StatelessWidget {
  const _DataPageHeader({
    required this.starName,
    required this.username,
  });

  final String starName;
  final String username;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE9E9EC)),
          ),
          child: const Icon(Icons.star, color: Color(0xFF1E293B)),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              starName,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '@$username',
              style: textTheme.bodySmall?.copyWith(
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          final isSelected = category == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _Chip(
              label: category,
              isSelected: isSelected,
              onTap: () => onSelected(category),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _GenreTabs extends StatelessWidget {
  const _GenreTabs({
    required this.genres,
    required this.selected,
    required this.onSelected,
  });

  final List<String> genres;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (genres.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: genres.map((genre) {
          final isSelected = genre == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _Chip(
              label: genre,
              isSelected: isSelected,
              onTap: () => onSelected(genre),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE7F5FF) : Colors.white,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: isSelected ? const Color(0xFF74C0FC) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected ? const Color(0xFF0B7285) : const Color(0xFF1E293B),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
        ),
      ),
    );
  }
}

class _ItemsListPlaceholder extends StatelessWidget {
  const _ItemsListPlaceholder({
    required this.category,
    required this.genre,
  });

  final String category;
  final String genre;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'カテゴリ: $category / ジャンル: $genre',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF64748B),
              ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE9E9EC)),
          ),
          alignment: Alignment.center,
          child: const Text(
            'データ一覧（Cursor Mock Provider 接続予定）',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
        ),
      ],
    );
  }
}
