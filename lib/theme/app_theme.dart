import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

class AppTheme {
  static const Color primaryColor = AppColors.brand;

  static ThemeData get lightTheme => buildTheme(isDark: false);
  static ThemeData get darkTheme => buildTheme(isDark: true);
}

ThemeData buildTheme({bool isDark = false}) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: isDark ? Brightness.dark : Brightness.light,
  );
  const tokens = AppTokens.defaultTokens;
  final textTheme = GoogleFonts.notoSansJpTextTheme(base.textTheme);

  // ダークテーマ用の色定義
  final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bg;
  final cardColor = isDark ? const Color(0xFF2A2A2A) : AppColors.card;
  final textColor = isDark ? const Color(0xFFE0E0E0) : AppColors.text;
  final borderColor = isDark ? const Color(0xFF404040) : AppColors.border;
  final primaryColor = isDark ? const Color(0xFF4ECDC4) : AppColors.brand;

  return base.copyWith(
    scaffoldBackgroundColor: bgColor,
    colorScheme: base.colorScheme.copyWith(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: primaryColor,
      onPrimary: isDark ? Colors.black : Colors.white,
      surface: cardColor,
      onSurface: textColor,
      background: bgColor,
      onBackground: textColor,
    ),
    textTheme: textTheme.apply(
      bodyColor: textColor,
      displayColor: textColor,
    ),
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: tokens.radius.lgRadius,
        side: BorderSide(color: borderColor),
      ),
      margin: EdgeInsets.all(tokens.spacing.md),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primaryColor),
      ),
      contentPadding: EdgeInsets.all(tokens.spacing.md),
    ),
    extensions: const [AppTokens.defaultTokens],
  );
}
