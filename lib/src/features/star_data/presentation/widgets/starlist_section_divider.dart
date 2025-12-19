import 'package:flutter/material.dart';
import '../../../../../theme/starlist_design_system.dart';

/// STARLIST セクション区切り - SoT準拠
/// 
/// 要件:
/// - セクションの区切りは薄いグレー 1px
/// - 枠線よりも「余白」で区切る
class StarlistSectionDivider extends StatelessWidget {
  final double? height;
  final EdgeInsetsGeometry? margin;

  const StarlistSectionDivider({
    super.key,
    this.height,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 1,
      margin: margin ?? EdgeInsets.symmetric(vertical: StarlistSpacing.lg),
      color: StarlistColors.grayBorder,
    );
  }
}

/// STARLIST セクション間の余白
/// 
/// 大量の余白でコンテンツを浮かせる（Apple風）
class StarlistSectionSpacing extends StatelessWidget {
  final double? height;

  const StarlistSectionSpacing({
    super.key,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height ?? StarlistSpacing.section);
  }
}


