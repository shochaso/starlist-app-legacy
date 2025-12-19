import 'package:flutter/material.dart';
import '../../../../../theme/starlist_design_system.dart';

/// STARLIST ボタン - SoT準拠
/// 
/// 要件:
/// - ボタン：細身・丸め、色は薄いブルー or グレー
/// - AI臭を排除
class StarlistButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isOutlined;
  final IconData? icon;
  final bool isLoading;

  const StarlistButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isPrimary = false,
    this.isOutlined = false,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: StarlistColors.textPrimary,
          side: const BorderSide(color: StarlistColors.grayBorder),
          shape: RoundedRectangleBorder(
            borderRadius: StarlistRadius.mdRadius,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: StarlistSpacing.lg,
            vertical: StarlistSpacing.md,
          ),
        ),
        child: _buildContent(),
      );
    }

    if (isPrimary) {
      return ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: StarlistColors.accentBlueText,
          foregroundColor: StarlistColors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: StarlistRadius.mdRadius,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: StarlistSpacing.lg,
            vertical: StarlistSpacing.md,
          ),
        ),
        child: _buildContent(),
      );
    }

    // デフォルト：テキストボタン
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: StarlistColors.accentBlueText,
        shape: RoundedRectangleBorder(
          borderRadius: StarlistRadius.mdRadius,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: StarlistSpacing.md,
          vertical: StarlistSpacing.sm,
        ),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            isPrimary ? StarlistColors.white : StarlistColors.accentBlueText,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          SizedBox(width: StarlistSpacing.sm),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
      );
    }

    return Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
    );
  }
}


