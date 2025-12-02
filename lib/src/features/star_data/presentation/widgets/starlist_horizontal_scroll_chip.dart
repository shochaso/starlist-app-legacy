import 'package:flutter/material.dart';
import '../../../../../theme/starlist_design_system.dart';

/// 横スライド可能なチップリスト
/// 
/// SoT準拠:
/// - カテゴリは横スライド
/// - ジャンルはカテゴリを選択してから横スライド表示
/// - ペイルブルー（アクセント色）を使用
class StarlistHorizontalScrollChip extends StatelessWidget {
  final List<String> items;
  final String? selectedItem;
  final ValueChanged<String?> onItemSelected;
  final String? label;

  const StarlistHorizontalScrollChip({
    super.key,
    required this.items,
    this.selectedItem,
    required this.onItemSelected,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: StarlistColors.textPrimary,
                ),
          ),
          SizedBox(height: StarlistSpacing.md),
        ],
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => SizedBox(width: StarlistSpacing.sm),
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected = selectedItem == item;
              return _ChipItem(
                label: item,
                isSelected: isSelected,
                onTap: () {
                  onItemSelected(isSelected ? null : item);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ChipItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChipItem({
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

