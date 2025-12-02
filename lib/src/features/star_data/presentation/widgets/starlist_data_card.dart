import 'package:flutter/material.dart';
import '../../../../../theme/starlist_design_system.dart';

/// データカード - SoT準拠
/// 
/// 要件:
/// - データカードは白・角丸・整形された情報量
/// - 画像（YouTubeサムネなど）は角丸で統一
/// - シャドウは極薄（AI臭を避ける）
class StarlistDataCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final VoidCallback? onTap;

  const StarlistDataCard({
    super.key,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.onTap,
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
                child: imageUrl != null
                    ? Image.network(
                        imageUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholder();
                        },
                      )
                    : _buildPlaceholder(),
              ),
            ),
            // 情報
            Padding(
              padding: EdgeInsets.all(StarlistSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: StarlistColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: StarlistSpacing.xs),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: StarlistColors.textSecondary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      color: StarlistColors.graySubtle,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: StarlistColors.grayText,
        ),
      ),
    );
  }
}

