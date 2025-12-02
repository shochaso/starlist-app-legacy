import 'package:flutter/material.dart';
import '../../../../../theme/starlist_design_system.dart';

/// STARLIST ローディング状態 - SoT準拠
/// 
/// データ読み込み中の表示
class StarlistLoadingState extends StatelessWidget {
  final String? message;

  const StarlistLoadingState({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(StarlistSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  StarlistColors.accentBlueText,
                ),
              ),
            ),
            if (message != null) ...[
              SizedBox(height: StarlistSpacing.md),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: StarlistColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// STARLIST スケルトンカード
/// 
/// ローディング中のプレースホルダー
class StarlistSkeletonCard extends StatelessWidget {
  const StarlistSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: StarlistColors.white,
        borderRadius: StarlistRadius.lgRadius,
        boxShadow: StarlistShadows.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 画像プレースホルダー
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(StarlistRadius.lg),
                topRight: Radius.circular(StarlistRadius.lg),
              ),
              child: Container(
                width: double.infinity,
                color: StarlistColors.graySubtle,
              ),
            ),
          ),
          // テキストプレースホルダー
          Padding(
            padding: EdgeInsets.all(StarlistSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 16,
                  decoration: BoxDecoration(
                    color: StarlistColors.grayLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(height: StarlistSpacing.xs),
                Container(
                  width: 120,
                  height: 12,
                  decoration: BoxDecoration(
                    color: StarlistColors.grayLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

