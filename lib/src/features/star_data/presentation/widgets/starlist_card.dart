import 'package:flutter/material.dart';
import '../../../../../theme/starlist_design_system.dart';

/// STARLIST カード - SoT準拠
/// 
/// 要件:
/// - カード：白、枠の代わりに影極薄（0, 4px, 10%透明）
/// - AI臭を排除
class StarlistCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const StarlistCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? StarlistColors.white,
        borderRadius: StarlistRadius.lgRadius,
        boxShadow: StarlistShadows.cardShadow,
      ),
      padding: padding ?? EdgeInsets.all(StarlistSpacing.md),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}


