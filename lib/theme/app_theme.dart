import 'package:flutter/material.dart';

class AppColors {
  static const background    = Color(0xFF121212);
  static const card          = Color(0xFF1E1E1E);
  static const cardLight     = Color(0xFF2A2A2A);
  static const accent        = Color(0xFFBAF266);
  static const textPrimary   = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF9E9E9E);
  static const error         = Color(0xFFFF5252);
  static const warning       = Color(0xFFFFB74D);
  static const easy          = Color(0xFFBAF266);
  static const medium        = Color(0xFFFFB74D);
  static const hard          = Color(0xFFFF7043);
  static const extreme       = Color(0xFFFF5252);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.background,
      primary: AppColors.accent,
      secondary: AppColors.cardLight,
      error: AppColors.error,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),
    cardTheme: CardTheme(
      color: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge:  TextStyle(color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1),
      displayMedium: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      titleLarge:    TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
      titleMedium:   TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
      bodyLarge:     TextStyle(color: AppColors.textPrimary, fontSize: 15),
      bodyMedium:    TextStyle(color: AppColors.textSecondary, fontSize: 13),
      labelSmall:    TextStyle(color: AppColors.textSecondary, fontSize: 11, letterSpacing: 0.5),
    ),
  );
}
