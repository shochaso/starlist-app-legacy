import 'package:flutter/material.dart';
import '../../../../../theme/starlist_design_system.dart';

/// STARLIST タイポグラフィ - SoT準拠
/// 
/// よく使うテキストスタイルの定義
class StarlistTypography {
  StarlistTypography._();

  /// ディスプレイテキスト（大見出し）
  static TextStyle displayLarge(BuildContext context) {
    return Theme.of(context).textTheme.displayLarge?.copyWith(
          color: StarlistColors.textPrimary,
          fontWeight: FontWeight.w300,
          letterSpacing: -0.5,
        ) ??
        const TextStyle();
  }

  /// ヘッドラインテキスト（中見出し）
  static TextStyle headlineLarge(BuildContext context) {
    return Theme.of(context).textTheme.headlineLarge?.copyWith(
          color: StarlistColors.textPrimary,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.3,
        ) ??
        const TextStyle();
  }

  /// タイトルテキスト（小見出し）
  static TextStyle titleLarge(BuildContext context) {
    return Theme.of(context).textTheme.titleLarge?.copyWith(
          color: StarlistColors.textPrimary,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ) ??
        const TextStyle();
  }

  /// 本文テキスト（通常）
  static TextStyle bodyLarge(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: StarlistColors.textPrimary,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
        ) ??
        const TextStyle();
  }

  /// 本文テキスト（セカンダリ）
  static TextStyle bodyMediumSecondary(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: StarlistColors.textSecondary,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
        ) ??
        const TextStyle();
  }

  /// キャプションテキスト（小さなテキスト）
  static TextStyle bodySmall(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(
          color: StarlistColors.textSecondary,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
        ) ??
        const TextStyle();
  }

  /// ラベルテキスト（ボタンなど）
  static TextStyle labelLarge(BuildContext context) {
    return Theme.of(context).textTheme.labelLarge?.copyWith(
          color: StarlistColors.textPrimary,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ) ??
        const TextStyle();
  }
}

