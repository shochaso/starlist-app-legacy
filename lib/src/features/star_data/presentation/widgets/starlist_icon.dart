import 'package:flutter/material.dart';
import '../../../../../theme/starlist_design_system.dart';

/// STARLIST アイコン - SoT準拠
/// 
/// 要件:
/// - すべてLucide Icons（細線）
/// - 塗りつぶし禁止
/// - 黒 or 濃いグレーで統一
/// 
/// 注意: 実際の実装では、lucide_icons_flutterパッケージを使用
/// ここでは、Material Iconsのoutlinedバージョンを使用
class StarlistIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;
  final bool isPrimary;

  const StarlistIcon({
    super.key,
    required this.icon,
    this.size,
    this.color,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size ?? 24,
      color: color ??
          (isPrimary
              ? StarlistColors.accentBlueText
              : StarlistColors.textPrimary),
    );
  }
}

/// よく使うアイコンの定義
class StarlistIcons {
  StarlistIcons._();

  // カテゴリアイコン
  static const youtube = Icons.play_circle_outline;
  static const shopping = Icons.shopping_bag_outlined;
  static const music = Icons.music_note_outlined;
  static const recipe = Icons.restaurant_outlined;

  // アクションアイコン
  static const search = Icons.search_outlined;
  static const filter = Icons.tune_outlined;
  static const close = Icons.close_outlined;
  static const arrowBack = Icons.arrow_back_outlined;
  static const arrowForward = Icons.arrow_forward_outlined;
  static const more = Icons.more_horiz_outlined;

  // データアイコン
  static const image = Icons.image_outlined;
  static const video = Icons.video_library_outlined;
  static const link = Icons.link_outlined;
  static const calendar = Icons.calendar_today_outlined;
  static const time = Icons.access_time_outlined;

  // 管理アイコン（スター側）
  static const edit = Icons.edit_outlined;
  static const delete = Icons.delete_outlined;
  static const visibility = Icons.visibility_outlined;
  static const visibilityOff = Icons.visibility_off_outlined;
  static const sort = Icons.sort_outlined;
}


