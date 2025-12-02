import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// STARLIST UI Design System - Source of Truth準拠
/// 
/// ブランド方向性:
/// - 白基調で洗練されている
/// - 高級感がある（安っぽさが一切ない）
/// - モダンで2025年のプロダクトとして違和感がない
/// - 過度なAI臭（影、光沢、コントラスト過多）を排除
/// - Disney+, Apple, Notionのような「静かな高級感」

class StarlistColors {
  StarlistColors._();

  // ホワイト 90%
  static const white = Color(0xFFFFFFFF);
  static const whiteBackground = Color(0xFFFFFFFF);

  // グレー 10%（薄く柔らかい / #E9E9EC 程度）
  static const grayLight = Color(0xFFE9E9EC);
  static const graySubtle = Color(0xFFF5F5F7);
  static const grayBorder = Color(0xFFE9E9EC);
  static const grayText = Color(0xFF6E6E73);
  static const grayTextDark = Color(0xFF1D1D1F);

  // アクセントは1色のみ（薄い水色 or 薄いシルバー）
  static const accentBlue = Color(0xFFE8F4F8);
  static const accentBlueText = Color(0xFF5E9DB8);
  static const accentSilver = Color(0xFFF0F0F2);

  // テキスト
  static const textPrimary = Color(0xFF1D1D1F);
  static const textSecondary = Color(0xFF6E6E73);
  static const textTertiary = Color(0xFF8E8E93);
}

class StarlistSpacing {
  StarlistSpacing._();

  // 大量の余白でコンテンツを浮かせる（Apple風）
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
  static const double section = 80.0; // セクション間の余白
}

// const値としてエクスポート（constコンストラクタで使用可能）
const double starlistSpacingXs = StarlistSpacing.xs;
const double starlistSpacingSm = StarlistSpacing.sm;
const double starlistSpacingMd = StarlistSpacing.md;
const double starlistSpacingLg = StarlistSpacing.lg;
const double starlistSpacingXl = StarlistSpacing.xl;
const double starlistSpacingXxl = StarlistSpacing.xxl;
const double starlistSpacingXxxl = StarlistSpacing.xxxl;
const double starlistSpacingSection = StarlistSpacing.section;

class StarlistRadius {
  StarlistRadius._();

  // エッジを丸める（8px〜16px角丸）
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;

  static BorderRadius get smRadius => BorderRadius.circular(sm);
  static BorderRadius get mdRadius => BorderRadius.circular(md);
  static BorderRadius get lgRadius => BorderRadius.circular(lg);
  static BorderRadius get xlRadius => BorderRadius.circular(xl);
}

class StarlistShadows {
  StarlistShadows._();

  // シャドウは極薄（AI臭を避ける）
  // カード：白、枠の代わりに影極薄（0, 4px, 10%透明）
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8.0,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get subtleShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 4.0,
          offset: const Offset(0, 1),
        ),
      ];
}

class StarlistTypography {
  StarlistTypography._();

  // 日本語：SF Pro / Noto Sans JP（細め）
  // 英語：Inter / SF Pro Display
  static TextTheme get textTheme {
    final base = GoogleFonts.notoSansJpTextTheme();
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontFamily: 'SF Pro Display',
        fontWeight: FontWeight.w300,
        letterSpacing: -0.5,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontFamily: 'SF Pro Display',
        fontWeight: FontWeight.w300,
        letterSpacing: -0.5,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontFamily: 'SF Pro Display',
        fontWeight: FontWeight.w300,
        letterSpacing: -0.5,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontWeight: FontWeight.w400,
        letterSpacing: -0.3,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w400,
        letterSpacing: -0.3,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w400,
        letterSpacing: -0.3,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
    );
  }
}

/// STARLIST Theme Data - SoT準拠
class StarlistTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: StarlistColors.whiteBackground,
      colorScheme: ColorScheme.light(
        primary: StarlistColors.accentBlueText,
        onPrimary: StarlistColors.white,
        surface: StarlistColors.white,
        onSurface: StarlistColors.textPrimary,
        secondary: StarlistColors.accentBlue,
        onSecondary: StarlistColors.accentBlueText,
        outline: StarlistColors.grayBorder,
        outlineVariant: StarlistColors.grayLight,
      ),
      textTheme: StarlistTypography.textTheme,
      cardTheme: CardThemeData(
        color: StarlistColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: StarlistRadius.lgRadius,
        ),
        shadowColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: StarlistColors.grayBorder,
        thickness: 1.0,
        space: 1.0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: StarlistColors.white,
        border: OutlineInputBorder(
          borderRadius: StarlistRadius.mdRadius,
          borderSide: const BorderSide(color: StarlistColors.grayBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: StarlistRadius.mdRadius,
          borderSide: const BorderSide(color: StarlistColors.grayBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: StarlistRadius.mdRadius,
          borderSide: const BorderSide(
            color: StarlistColors.accentBlueText,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: StarlistSpacing.md,
          vertical: StarlistSpacing.md,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: StarlistColors.accentBlueText,
          foregroundColor: StarlistColors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: StarlistRadius.mdRadius,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: StarlistSpacing.lg,
            vertical: StarlistSpacing.md,
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: StarlistColors.textPrimary,
          side: const BorderSide(color: StarlistColors.grayBorder),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: StarlistRadius.mdRadius,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: StarlistSpacing.lg,
            vertical: StarlistSpacing.md,
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: StarlistColors.accentBlueText,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: StarlistRadius.mdRadius,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: StarlistSpacing.md,
            vertical: StarlistSpacing.sm,
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

